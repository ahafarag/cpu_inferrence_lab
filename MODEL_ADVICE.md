# MODEL_ADVICE.md — model-switch advice log

Every time Claude advises a model switch (or advises staying put at a decision point), it is logged here.
Purpose: find out over time whether the advice was right. Wrong advice is expected and is useful data.

Rule: Claude appends one row per advice. The owner fills in "Outcome" after the task.

Pattern being tested: plan / gates / research on Opus, execution / benchmarks on Sonnet.

## Log

| # | Date | Task | Advice | Why | Outcome (owner fills in) | Right? |
|---|------|------|--------|-----|--------------------------|--------|
| 1 | 2026-10-12 | Read `PLAN.md` Status at session start (Phase 0) | Stay on Sonnet | Cheap lookup, no reasoning needed; Phase 0 is execution work | | |
| 2 | 2026-10-12 | Fill `HARDWARE.md`, then build llama.cpp and run first benchmark (Phase 0 tasks 1-2) | Stay on Sonnet | Shell probing and benchmark runs; no design decisions | | |
| 3 | 2026-10-12 | Debug llama.cpp build failure, fix benchmark script, run Q4/Q8 (Phase 0 task 2) | Stay on Sonnet | Build/PATH debugging and script fixes were routine; no plan or gate decision involved | | |
| 4 | 2026-10-12 | Next: bitnet.cpp build and run (Phase 0 task 3) | Stay on Sonnet | Same build-and-measure pattern; switch to Opus only at Gate 0 (scoring ideas 1-4) | | |
| 5 | 2026-10-12 | Gate 0: score ideas 1-4 with `BENEFIT_GATE.md` once bitnet.cpp + PowerInfer are measured | **Switch to Opus** | Judgement over thin, conflicting evidence; this decides what the next 3-4 weeks go to. A quick feasibility read (above in IDEAS.md) was done on Sonnet and should be re-checked on Opus | | |
| 7 | 2026-10-12 | Phase 1 step 3: routing log + cache replay, then Gate 1 verdict | Stay on Sonnet for the replay; **switch to Opus for Gate 1** | Replay is scripted measurement; the pass/stop call and what to publish is judgement | | |
| 9 | 2026-10-12 | After Gate 1: Phase 1b prerequisites (parameterise setup scripts, MODELS.md with SHA256, Dockerfile), README results section | **Switch back to Sonnet** | Mechanical packaging with clear specs; return to Opus at Gate 1b (claim check) | | |
| 8 | 2026-10-12 | Gate 1: is a predictor-based prefetcher worth building, or publish the characterisation + read-ahead finding and go to Phase 1b? | **Switch to Opus** | Evidence is complete and ambiguous (oracle 3x, practical predictor unmeasured); this is the pass/stop call and decides weeks of work | | |
| 6 | 2026-10-12 | Phase 1 kill-test: MoE in-RAM vs streamed benchmark, routing log, LRU replay | **Switch back to Sonnet** | Execution with fixed stop rules; return to Opus only at Gate 1 (did the kill-test pass?) | | |

## Switch triggers (reference)

| Situation | Model |
|-----------|-------|
| Session-start status read, running benchmarks, filling `HARDWARE.md`, editing results | Sonnet |
| Revising `PLAN.md`, Plan mode | Opus |
| Gate decision, scoring an idea with `BENEFIT_GATE.md` | Opus |
| Deep research (papers, engine internals, finding the gap) | Opus |
