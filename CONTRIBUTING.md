# Contributing

Thanks for helping improve VibeGesture.

## Before you start

- Read the product requirements in [`docs/PRD.md`](docs/PRD.md)
- Read the system structure in [`docs/TECH_ARCHITECTURE.md`](docs/TECH_ARCHITECTURE.md)
- Read the execution details in [`docs/TECH_IMPLEMENTATION_PLAN.md`](docs/TECH_IMPLEMENTATION_PLAN.md)
- Prefer the stable baseline tag `stable-20260418` when you want a known-good reference point

## Working rules

- Keep runtime behavior predictable and conservative
- Prefer small, reviewable changes
- Preserve the existing state machine and keyboard dispatch boundaries
- Avoid introducing new gesture families or broad scope expansions unless the task explicitly asks for them

## Validate your changes

Run:

```bash
swift test
bash scripts/build_bundle.sh
```

If your change affects the app bundle or startup path, also verify the generated `.app` launches correctly.

## What to include in a PR

- What changed
- Why it changed
- How you tested it
- Any follow-up risks or edge cases
