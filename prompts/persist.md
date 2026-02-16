# Phase 5: Persist

## Objective

Write all validated state from the current iteration to disk. Ensure state files are consistent, schema-compliant, and ready for the next iteration or final output.

## Rules

1. **Idempotent writes** — Re-running Persist with the same inputs produces identical output
2. **Never skip persistence** — Even partial results must be persisted
3. **Validate before writing** — Check schemas before committing state
4. **Atomic updates** — Write complete files, never partial updates

## Persistence Procedure

### Step 1: Update `artifact_manifest.json`

Write or update the manifest with:
- `artifact_type` — The domain being refined
- `variants` — Array of generated files with names and paths
- `sizes` — Dimensions/sizes for applicable formats
- `generation_timestamp` — ISO 8601 timestamp of this iteration

Validate against `references/schemas/artifact-manifest.schema.json` before writing.

### Step 2: Update `constraints.json`

Persist the current constraint state:
- Mark satisfied constraints with `validated: true`
- Update `last_checked` timestamp for each constraint
- Preserve original severity and validation hooks

Validate against `references/schemas/constraints.schema.json` before writing.

### Step 3: Append to `refinement_log.md`

Append an iteration entry:

```markdown
## Iteration {N} — {ISO timestamp}

### Actions Taken
- {list of actions from Execute phase}

### Constraint Status
- {constraint_id}: {satisfied | violated} — {details}

### Reflection Summary
- Convergence: {continue | terminate}
- Reason: {convergence rationale}

### Files Modified
- {list of files created or modified}
```

### Step 4: Update `decisions.md`

Append the convergence decision:

```markdown
### Iteration {N} Decision

- **Decision**: {continue | terminate}
- **Iteration**: {N} of {max_iterations}
- **Blocking violations remaining**: {count}
- **Rationale**: {why continuing or terminating}
- **Next focus**: {what the next iteration should address, if continuing}
```

### Step 5: Ensure `dist/` contents

Verify all files referenced in `artifact_manifest.json` exist in `dist/`:
- For each variant in the manifest, confirm the file exists
- Log any missing files as errors
- If files are missing, flag for re-execution

## Deterministic Execution

Use code interpreter or e2b sandbox for:
- JSON schema validation (parse + validate against schema)
- File existence checks
- Timestamp generation
- Manifest integrity verification

## Output

After Persist completes, the following must be true:
- `artifact_manifest.json` is valid JSON matching its schema
- `constraints.json` is valid JSON matching its schema
- `refinement_log.md` has an entry for the current iteration
- `decisions.md` has the convergence decision for the current iteration
- All files in `dist/` referenced by the manifest exist
