#!/usr/bin/env node
// Normalize and validate an A2UI component spec before browser preview.
//
// Inputs:  --input <source.a2ui.json>  --artifact-id <id>  [--out-dir <dir>]
// Outputs: <out-dir>/normalized.a2ui.json
//          <out-dir>/normalize-report.json
//
// HTML preview generation is owned by the existing render pipeline
// (assets/templates/a2ui-preview-template.html + Template Injection in
// prompts/execute.md). This script does not emit HTML — it produces
// the validated, normalized spec JSON that the template injection
// step consumes via the {{A2UI_JSON}} placeholder.
//
// Exit codes:
//   0  success — normalized files written, no constraint violations
//   1  schema validation failure or cycle detected
//   2  I/O error (input not readable, etc.)
//
// This adapter intentionally has no external dependencies: the validator
// is hand-rolled JSON Schema interpretation for the small subset our
// schema uses (required, enum, pattern, oneOf, $ref-to-#/definitions).
// That keeps the refiner's `npm` surface clean.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..');
const SCHEMA_PATH = join(REPO_ROOT, 'references/schemas/a2ui-component.schema.json');

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i].replace(/^--/, '');
    args[key] = argv[i + 1];
  }
  return args;
}

function fail(stage, message, details) {
  const report = {
    status: 'failed',
    stage,
    message,
    details: details ?? null,
  };
  process.stderr.write(JSON.stringify(report, null, 2) + '\n');
  return report;
}

// Minimal subset of JSON Schema needed for our A2UI schema:
//   - type, required, enum, pattern, additionalProperties (object only)
//   - properties / patternProperties
//   - items
//   - oneOf (no full draft semantics — first match wins)
//   - $ref pointing into #/definitions/<name>
//   - allOf with simple if/then required-chain (skipped here; codified separately)
function validate(schema, instance, path = '$', root = schema, errors = []) {
  if (schema.$ref) {
    const ref = schema.$ref;
    if (!ref.startsWith('#/definitions/')) {
      errors.push({ path, message: `Unsupported $ref: ${ref}` });
      return errors;
    }
    const name = ref.slice('#/definitions/'.length);
    const target = root.definitions?.[name];
    if (!target) {
      errors.push({ path, message: `Missing definition: ${name}` });
      return errors;
    }
    return validate(target, instance, path, root, errors);
  }

  if (schema.oneOf) {
    let matched = false;
    for (const sub of schema.oneOf) {
      const subErrors = [];
      validate(sub, instance, path, root, subErrors);
      if (subErrors.length === 0) {
        matched = true;
        break;
      }
    }
    if (!matched) {
      errors.push({ path, message: `No oneOf branch matched` });
    }
    return errors;
  }

  if (schema.type) {
    const actual = Array.isArray(instance)
      ? 'array'
      : instance === null
        ? 'null'
        : typeof instance;
    const expected = Array.isArray(schema.type) ? schema.type : [schema.type];
    if (!expected.includes(actual)) {
      errors.push({ path, message: `expected ${expected.join('|')}, got ${actual}` });
      return errors;
    }
  }

  if (schema.enum && !schema.enum.includes(instance)) {
    errors.push({ path, message: `value not in enum: ${JSON.stringify(schema.enum)}` });
  }

  if (typeof instance === 'string' && schema.pattern) {
    const re = new RegExp(schema.pattern);
    if (!re.test(instance)) {
      errors.push({ path, message: `does not match pattern ${schema.pattern}` });
    }
  }

  if (schema.required && instance && typeof instance === 'object' && !Array.isArray(instance)) {
    for (const key of schema.required) {
      if (!(key in instance)) {
        errors.push({ path, message: `missing required field "${key}"` });
      }
    }
  }

  if (schema.properties && instance && typeof instance === 'object' && !Array.isArray(instance)) {
    for (const [key, subschema] of Object.entries(schema.properties)) {
      if (key in instance) {
        validate(subschema, instance[key], `${path}.${key}`, root, errors);
      }
    }
  }

  if (
    schema.patternProperties &&
    instance &&
    typeof instance === 'object' &&
    !Array.isArray(instance)
  ) {
    for (const [pat, subschema] of Object.entries(schema.patternProperties)) {
      const re = new RegExp(pat);
      for (const key of Object.keys(instance)) {
        if (re.test(key)) {
          validate(subschema, instance[key], `${path}["${key}"]`, root, errors);
        }
      }
    }
  }

  if (
    schema.additionalProperties === false &&
    instance &&
    typeof instance === 'object' &&
    !Array.isArray(instance)
  ) {
    const known = new Set([
      ...Object.keys(schema.properties ?? {}),
      ...Object.keys(schema.patternProperties ?? {}),
    ]);
    const patterns = Object.keys(schema.patternProperties ?? {}).map((p) => new RegExp(p));
    for (const key of Object.keys(instance)) {
      if (!known.has(key) && !patterns.some((re) => re.test(key))) {
        errors.push({ path: `${path}.${key}`, message: 'unexpected property' });
      }
    }
  }

  if (schema.items && Array.isArray(instance)) {
    instance.forEach((item, idx) => {
      validate(schema.items, item, `${path}[${idx}]`, root, errors);
    });
  }

  return errors;
}

// Walk component tree and collect (binding-id -> ref-target) edges plus
// referenced ids per component. Returns { graph, refsFromComponents }.
function collectBindingGraph(spec) {
  const graph = new Map(); // binding id -> Set<binding id>
  const refsFromComponents = new Set(); // binding ids referenced from components

  const bindings = spec.bindings ?? {};
  for (const [id, binding] of Object.entries(bindings)) {
    const out = new Set();
    if (binding.kind === 'ref' && binding.ref) {
      out.add(binding.ref);
    }
    graph.set(id, out);
  }

  function walk(component) {
    if (!component) return;
    if (component.bindings) {
      for (const value of Object.values(component.bindings)) {
        if (value && typeof value === 'object' && '$ref' in value) {
          refsFromComponents.add(value.$ref);
        }
      }
    }
    if (Array.isArray(component.children)) {
      component.children.forEach(walk);
    }
  }
  walk(spec.root);

  return { graph, refsFromComponents };
}

function detectCycles(graph) {
  const WHITE = 0,
    GRAY = 1,
    BLACK = 2;
  const color = new Map([...graph.keys()].map((k) => [k, WHITE]));
  const path = [];
  let cycle = null;

  function dfs(node) {
    if (cycle) return;
    color.set(node, GRAY);
    path.push(node);
    for (const next of graph.get(node) ?? []) {
      if (!graph.has(next)) continue; // unknown ref — flagged elsewhere
      const c = color.get(next);
      if (c === GRAY) {
        const start = path.indexOf(next);
        cycle = path.slice(start).concat(next);
        return;
      } else if (c === WHITE) {
        dfs(next);
        if (cycle) return;
      }
    }
    color.set(node, BLACK);
    path.pop();
  }

  for (const node of graph.keys()) {
    if (color.get(node) === WHITE) {
      dfs(node);
      if (cycle) break;
    }
  }
  return cycle;
}

function findUndefinedRefs(spec, refsFromComponents) {
  const defined = new Set(Object.keys(spec.bindings ?? {}));
  const undef = [];
  for (const ref of refsFromComponents) {
    if (!defined.has(ref)) undef.push(ref);
  }
  for (const [id, binding] of Object.entries(spec.bindings ?? {})) {
    if (binding.kind === 'ref' && binding.ref && !defined.has(binding.ref)) {
      undef.push(`${id} -> ${binding.ref}`);
    }
  }
  return undef;
}

function normalize(spec) {
  // Deterministic key ordering: version, metadata, bindings, root.
  // Inside components: id, type, props, bindings, children.
  // Inside bindings (top-level map): keys sorted alphabetically.
  const out = {};
  if ('version' in spec) out.version = spec.version;
  if ('metadata' in spec) out.metadata = spec.metadata;
  if ('bindings' in spec && spec.bindings) {
    out.bindings = {};
    for (const key of Object.keys(spec.bindings).sort()) {
      out.bindings[key] = spec.bindings[key];
    }
  }
  if ('root' in spec) out.root = normalizeComponent(spec.root);
  return out;
}

function normalizeComponent(component) {
  if (!component || typeof component !== 'object') return component;
  const out = {};
  if ('id' in component) out.id = component.id;
  if ('type' in component) out.type = component.type;
  if ('props' in component) out.props = component.props;
  if ('bindings' in component) out.bindings = component.bindings;
  if (Array.isArray(component.children)) {
    out.children = component.children.map(normalizeComponent);
  }
  return out;
}

function loadJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function ensureDir(path) {
  if (!existsSync(path)) mkdirSync(path, { recursive: true });
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const input = args.input;
  const artifactId = args['artifact-id'] ?? 'a2ui-default';
  const outDir = args['out-dir'] ?? join('dist/previews', artifactId);

  if (!input) {
    process.stderr.write('Usage: normalize-a2ui.mjs --input <file> --artifact-id <id> [--out-dir <dir>]\n');
    process.exit(2);
  }

  let spec;
  try {
    spec = loadJson(input);
  } catch (err) {
    fail('read', `Cannot read or parse ${input}`, String(err));
    process.exit(2);
  }

  const schema = loadJson(SCHEMA_PATH);
  const schemaErrors = validate(schema, spec);

  const { graph, refsFromComponents } = collectBindingGraph(spec);
  const undefRefs = findUndefinedRefs(spec, refsFromComponents);
  const cycle = detectCycles(graph);

  const violations = [];
  if (schemaErrors.length) violations.push({ kind: 'schema', errors: schemaErrors });
  if (undefRefs.length) violations.push({ kind: 'undefined_bindings', refs: undefRefs });
  if (cycle) violations.push({ kind: 'binding_cycle', cycle });

  ensureDir(outDir);

  const report = {
    status: violations.length === 0 ? 'success' : 'failed',
    artifact_id: artifactId,
    input,
    schema: SCHEMA_PATH,
    violations,
    generated_at: new Date().toISOString(),
  };

  if (violations.length) {
    writeFileSync(join(outDir, 'normalize-report.json'), JSON.stringify(report, null, 2));
    process.stderr.write(JSON.stringify(report, null, 2) + '\n');
    process.exit(1);
  }

  const normalized = normalize(spec);
  writeFileSync(join(outDir, 'normalized.a2ui.json'), JSON.stringify(normalized, null, 2));
  writeFileSync(join(outDir, 'normalize-report.json'), JSON.stringify(report, null, 2));
  process.stdout.write(`OK ${outDir}\n`);
}

main();
