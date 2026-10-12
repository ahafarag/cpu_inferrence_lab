# BENEFIT_GATE.md — scoring rubric for any idea

Use this before starting ANY idea, feature or sub-project. Fill the table in `IDEAS.md`. Be harsh. The purpose is to reduce wasted money, time and effort.

## Part A — Feasibility (can it be done, here, by this owner?)

| # | Question | Score 0–3 |
|---|---|---|
| A1 | Can it run on the owner's own machine (no paid GPU/cloud)? 3 = yes fully, 0 = needs datacenter hardware | |
| A2 | Does the owner already have the skills (infra, Python, Linux, systems)? 3 = yes, 0 = needs a new discipline (e.g. CUDA kernels, model pretraining) | |
| A3 | Can a kill-test (prove/disprove the core assumption) be done in ≤ 2 weekends? 3 = yes, 0 = needs months before any signal | |
| A4 | Does an existing open-source base exist to build on (so we don't start from zero)? 3 = yes, mature; 0 = nothing | |
| A5 | Is the gap real? Has nobody shipped it already? 3 = verified gap (searched GitHub, arXiv, HN); 0 = already exists and is good | |

**Feasibility total /15.** Below 9 → NO, regardless of benefit.

## Part B — Benefit (what does the owner get?)

| # | Question | Score 0–3 |
|---|---|---|
| B1 | **Visibility**: will it produce something people share (benchmark table, tool, demo video)? Where? (LinkedIn, r/LocalLLaMA, HN, TikTok) | |
| B2 | **Audience fit**: does it strengthen the owner's positioning (AI + infra + cost reduction)? | |
| B3 | **Money, direct**: can it be sold, sponsored, or turned into a paid service within 3 months? | |
| B4 | **Money, indirect**: does it create freelance/consulting leads or a stronger profile for roles? | |
| B5 | **Academic**: usable for [ACADEMIC_PROGRAM] (paper, workshop, thesis chapter)? | |
| B6 | **Reusability**: does it feed other owner projects (gateway, agents, content pipeline)? | |

**Benefit total /18.** Below 8 → NO.

## Part C — Cost (what does it burn?)

| # | Question | Estimate |
|---|---|---|
| C1 | Money (hardware, subscriptions, APIs) — must be a number in EUR | |
| C2 | Time to kill-test (hours) | |
| C3 | Time to usable v1 (hours) | |
| C4 | Opportunity cost: which other owner project does this delay? | |

## Decision

- **GO** if Feasibility ≥ 9 AND Benefit ≥ 8 AND C1 ≤ what the owner explicitly approves AND C2 ≤ 20 h.
- **MAYBE** if one threshold is missed by ≤ 2 points → shrink the idea until it passes, or drop.
- **NO** otherwise. Write one sentence why in `IDEAS.md`. Rejected ideas stay in the file so they are not re-proposed.

## Red flags (automatic NO)

- "We'll need a GPU to test properly."
- "It'll be clearer after a few weeks of research."
- No concrete public output after the kill-test, even if it fails.
- Requires pretraining a model from scratch.
- Competes head-on with a well-funded project doing the same thing well.
