# CLAUDE.md — cpu-inference-lab

Instructions for Claude Code working in this repo. Read fully before doing anything.

## What this project is

An experimental lab to reduce what an LLM must load to run inference, so useful models run on CPU / small-GPU machines.
Three levers: sparsity (load fewer weights), quantization (fewer bits per weight), more tokens per weight read (speculative / multi-token decoding).

The goal is NOT "invent a new architecture". The goal is: measure the existing engines first, find a gap, build one small systems-level thing that is (a) technically feasible and (b) beneficial to the owner.

Owner: [OWNER_NAME]. [OWNER_BACKGROUND]. Comfortable with infra, Linux, Python, CI/CD. Dev machine: Windows + WSL (assume no datacenter GPU unless `HARDWARE.md` says otherwise).

## Hard rules

1. **Measure before building.** Phase 0 (baseline benchmarks) must be complete and recorded in `benchmarks/results.csv` before any code for ideas 1–4 is written. If `benchmarks/results.csv` has no rows, your job is Phase 0.
2. **Benefit gate on every idea.** Before proposing or starting any new direction, score it with `BENEFIT_GATE.md` and write the score into `IDEAS.md`. An idea without a scorecard is not started. If the score says NO, say so plainly; do not soften it.
3. **No wasted spend.** Prefer free/open tools. Never suggest paid cloud GPUs, paid APIs or subscriptions without an explicit cost estimate and a one-line justification. Default to the owner's own machine.
4. **Time-box.** Every task gets a time estimate before starting. If actual > 2× estimate, stop and report instead of pushing on.
5. **Reproducible.** Every benchmark number must be reproducible by a script in `benchmarks/`. No numbers from memory, no numbers from a one-off terminal session.
6. **Public by default.** Every result worth keeping also becomes a short public write-up draft in `content/` (LinkedIn post, README section, or blog). Visibility is one of the benefits this project exists to produce.

## Working style

- Direct and concise. No preamble, no restating the request, no "great question".
- English only in all files, commits and replies. Do not mix Arabic into technical text.
- Bottom line first, then detail.
- When something is impossible or a bad idea, say "no" and give the reason in one or two sentences, then offer the nearest thing that works.
- Push back on scope creep. The owner has many parallel projects; this one must stay small and finishable.

## Working copy vs backup

- **Work in `[WORKING_COPY_PATH]`** (WSL: `[WORKING_COPY_WSL_PATH]`). WSL cannot read `G:`.
- `[BACKUP_DIR]` is the cloud backup only. Run `sync.ps1` (C: → G:, one-way, no deletes) at the end of each session and after any completed task.
- Models (`*.gguf`) and llama.cpp builds live in WSL home (`~`), not in the repo, and are never synced.

## Repo layout

```
CLAUDE.md          this file
AGENTS.md          same rules for non-Claude agents (Codex, etc.)
README.md          public-facing description (keep it honest, update as results land)
PLAN.md            phases, gates, current status — update "Status" after every session
BENEFIT_GATE.md    scoring rubric for any idea
MODEL_ADVICE.md    log of model-switch advice and whether it was right
IDEAS.md           scored ideas, decisions, rejected ideas with reasons
RESEARCH_NOTES.md  the three levers, key papers/engines, open gaps
HARDWARE.md        owner's machine spec — fill in during Phase 0 before any benchmark
benchmarks/        scripts + results.csv (the only source of truth for numbers)
content/           drafts of public posts / write-ups generated from results
```

## Session protocol

At the start of each session:
1. Read `PLAN.md` → "Status" section.
2. Read the last 10 rows of `benchmarks/results.csv` if it exists.
3. State in one line what phase we are in and what the next task is.
4. Whenever you advise a model switch (or advise staying put at a decision point), append a row to `MODEL_ADVICE.md`.

At the end of each session:
1. Update `PLAN.md` → "Status" (date, what was done, what's next, blockers).
2. If a benchmark ran, append to `benchmarks/results.csv`.
3. If a decision was made, record it in `IDEAS.md`.
4. Commit with a message that states the result, not the activity ("llama.cpp Q4 7B: 6.1 tok/s on CPU" not "ran benchmarks").

## Commands (fill in during Phase 0)

```
# benchmarks/run_llamacpp.sh <model.gguf>      → appends a row to results.csv
# benchmarks/run_bitnet.sh <model>             → appends a row to results.csv
# benchmarks/run_powerinfer.sh <model>         → appends a row to results.csv
# benchmarks/compare.py                        → prints a table from results.csv
```

## What "done" looks like for Phase 0

- `HARDWARE.md` filled (CPU, RAM, RAM bandwidth estimate, GPU if any, SSD type, OS/WSL version).
- Same prompt set run on llama.cpp (Q4 and Q8), bitnet.cpp, PowerInfer (if it builds on this machine), with tokens/sec (prompt + generation), peak RAM, and a quality check (same 10 prompts, scored 1–5 by the owner).
- `benchmarks/compare.py` prints the comparison.
- A gate decision in `PLAN.md`: which of ideas 1–4 (if any) to pursue, with its scorecard.
