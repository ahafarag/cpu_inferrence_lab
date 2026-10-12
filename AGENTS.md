# AGENTS.md — cpu-inference-lab

Instructions for any AI coding agent (Codex, Cursor, Gemini CLI, etc.). Claude Code reads `CLAUDE.md`, which contains the same rules in more detail; if both are present, `CLAUDE.md` wins on conflict.

## Project in one paragraph

Measure existing CPU-first LLM inference engines (llama.cpp, bitnet.cpp, PowerInfer), find a real gap in sparsity / quantization / speculative decoding on consumer hardware, and build one small, finishable systems tool that is both technically feasible and beneficial to the owner (visibility, opportunities, income). Owner is an experienced DevOps / data-platform engineer with an AI research background, working on Windows + WSL.

## Rules (non-negotiable)

1. Measure first. No feature code before `benchmarks/results.csv` has baseline rows.
2. Every idea gets scored with `BENEFIT_GATE.md` and recorded in `IDEAS.md` before any work. Low score = do not start, and say so.
3. No paid resources (cloud GPU, paid APIs) without a written cost estimate and justification. Default to the owner's machine.
4. Time-box every task; stop and report at 2× the estimate.
5. All numbers come from scripts in `benchmarks/`. Never from memory.
6. Every kept result gets a short public write-up draft in `content/`.

## Style

- English only, in code, docs and replies.
- Concise. Bottom line first. No preamble.
- Say "no" clearly when something is infeasible or not worth it, then propose the nearest workable alternative.
- Keep scope small. Resist adding features.

## Layout

See `CLAUDE.md` → "Repo layout". Source of truth for status is `PLAN.md` → "Status".

## Start / end of session

Start: read `PLAN.md` Status, read tail of `benchmarks/results.csv`, state the next task in one line.
End: update `PLAN.md` Status, append benchmark rows, record decisions in `IDEAS.md`, commit with a result-stating message.

## Agent roles (when running multiple agents)

- **bench**: builds and runs engines, appends to `results.csv`, never edits docs other than `HARDWARE.md`.
- **research**: reads papers/repos, updates `RESEARCH_NOTES.md`, proposes ideas into `IDEAS.md` with a draft scorecard. Never writes code.
- **build**: implements the one idea that passed the gate. Only exists after a gate decision in `PLAN.md`.
- **content**: turns rows in `results.csv` and decisions in `IDEAS.md` into drafts in `content/`. Never invents numbers.
