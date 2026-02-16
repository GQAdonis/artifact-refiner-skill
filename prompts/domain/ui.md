UI Refiner Module

Domain

React / HTML / UI Concept Artifacts

Purpose

Refine UI artifacts into structurally sound, accessible, production-ready interface outputs using PMPO orchestration.

This module handles both conceptual UI artifacts and executable UI codebases.

⸻

Inputs
	•	specification (from Specify phase)
	•	plan (from Plan phase)
	•	existing UI files (optional)

⸻

Responsibilities
	1.	Refine component hierarchy
	2.	Normalize layout to grid system
	3.	Enforce design token usage
	4.	Validate semantic HTML structure
	5.	Validate accessibility compliance
	6.	Execute build or preview steps if required

⸻

Deterministic Execution Triggers

Invoke code_interpreter when:
	•	Writing or modifying React/HTML files
	•	Running build processes (npm build, vite build, etc.)
	•	Generating static previews
	•	Performing accessibility checks
	•	Running linters or formatters
	•	Validating CSS token usage

⸻

Common Constraints
	•	WCAG AA contrast compliance
	•	Proper semantic tags
	•	ARIA attribute correctness
	•	Design token consistency
	•	Spacing scale normalization
	•	No inline style violations (unless intentional)

⸻

Validation Checklist

During Execute and Reflect phases, validate:
	•	File structure correctness
	•	Successful build (if applicable)
	•	No console errors
	•	No missing imports
	•	Accessibility thresholds met

⸻

Expected Outputs
	•	Refined UI files
	•	Build output (if applicable)
	•	Validation logs
	•	Updated artifact_manifest.json

⸻

Reflection Focus
	•	Visual hierarchy clarity
	•	Structural soundness
	•	Accessibility compliance
	•	Token adherence
	•	Build stability

⸻

Termination Conditions

Refinement ends when:
	•	All constraints satisfied
	•	Build succeeds without errors
	•	Accessibility checks pass
	•	No structural regressions remain