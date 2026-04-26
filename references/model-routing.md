# Artifact Refiner — Model Routing

The refiner uses tiered model selection at the phase level. Iteration (delta generation) and finalization (manifest write) are mechanical and run on small models. Evaluation (constraint violation judgment) requires calibrated scoring and routes to a medium model.

## Policy Source

```
project.json → model_policy.phases.refiner-*
project.json → model_policy.registry.<class>.<active_environment>
```

If `project.json` is absent or lacks `model_policy`, treat all phases as `frontier` and log a warning to `.refiner/<artifact_name>/model-routing.log`.

## Phase → Class Map

| Phase Key            | Class    | Rationale                                                          |
|----------------------|----------|--------------------------------------------------------------------|
| `refiner-iterate`    | small    | Constraint-diff delta generation per violation. Mechanical edits.  |
| `refiner-evaluate`   | medium   | Constraint violation judgment. Needs calibrated scoring rubric.    |
| `refiner-finalize`   | small    | Manifest write, log commit, archive. No reasoning required.        |

## When to Override

The defaults assume direct content (`direct:*`) refinement against a clear constraint set. Override to a higher class when:

- **Meta-prompt refinement (`meta:*`)** — prompt quality evaluation benefits from `frontier` for `refiner-evaluate`
- **First-iteration creative seed** — initial artifact generation from scratch (no prior version) may use `medium` for `refiner-iterate` if the constraint set is sparse
- **Cross-domain artifacts** — artifacts that span domain adapters (e.g., logo + brand voice + UI mock) may need `frontier` evaluation

Specify overrides in the artifact's state file under `model_overrides`:

```json
{
  "artifact_name": "acme-logo",
  "model_overrides": {
    "refiner-evaluate": "frontier"
  }
}
```

## Routing Directive

Emit a directive at each phase transition for external orchestrators:

```
[MODEL_ROUTING] phase=refiner-iterate class=small model=Qwen3.5-9B-Q8_0 env=local
```

Append to `.refiner/<artifact_name>/model-routing.log`.

## Fallback Rule

If `model_policy` is absent from `project.json`:

- Treat all phases as `frontier`
- Log: `[WARN] model_policy absent — defaulting to frontier for all refiner phases`
- Do not silently downgrade evaluation to a smaller model
