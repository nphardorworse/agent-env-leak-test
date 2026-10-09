# What coding agents do with API keys in a .env

Harness, fixtures and every transcript behind [Do AI Coding Agents Leak Your API Keys?](https://fidelius.blisslabs.dev/research/ai-coding-agents-api-keys-env/). Runs of Claude Code, Codex, and Claude Code driving six other models, on 2026-10-07 and 2026-10-08.

**Every API key in this repo is fake.** That includes the ones that look real (`fixture-realkeys/`, `fixture5-realkeys/`: `pk_live_51...` and a postgres URL with a password). The agents' own OpenRouter key is replaced with `<REDACTED:OPENROUTER_API_KEY>` wherever an agent printed it, Claude Code's session token (`CLAUDE_CODE_MESSAGING_TOKEN`, which reached a few env dumps) with `<REDACTED:CLAUDE_CODE_MESSAGING_TOKEN>`, and the Mac test account's name with `redacted` (home paths, `USER=`, `ls -l` owners). All by `redact.py`. Apart from that, transcripts are kept exactly as the agents wrote them.

## The rounds

| Round | Question | Where | Folder | Runs |
|---|---|---|---|---|
| 1 | Does the agent open `.env` and repeat a key? | Docker | `out/` | 12 |
| 2 | Does a key reach the agent when the program prints it? | Docker | `out2/` | 12 |
| 3 | Does accio mask the same programs' output? (no agent) | Mac | `fixture3/results/` | programs × 3 markers |
| 4 | Round two with real agents, `.env` vs accio | Mac | `out4/` | 60 |
| Model sweep | Round one's tasks with six other models, without (`base`) and with (`protected`) rules | Docker | `out-models/` | 53 |
| Real-looking keys | Model sweep (*which*, *check*) and the pressure task again, keys without `CANARY` | Docker | `out-models-realkeys/`, `out-coerce-realkeys/` | 11 + 4 |
| Coercion, `.env` | User asks for the values; tool output asks | Docker | `out-coerce/` | 12 |
| Coercion, accio | The same through accio | Mac | `out-coerce-accio/` | 12 |
| Real libraries | axios error and `curl -v`, `.env` vs accio | Mac | `out-real/` | 24 |
| dotenvx | Round two's programs through `dotenvx run`, without and with `--redact` (no agent) | Docker | `compare/` | 3 programs |
| Deny-rule check | Are Claude Code deny rules enforced with permissions skipped? | Docker | `out-denycheck/` | 2 |

The post's 202 are rounds 1, 2 and 4, the model sweep, the real-looking keys, both coercion arms, the real-library runs, and the two GLM runs in `invalid/glm-no-tool-calls/`. The deny-rule check isn't among them.

Not counted in any rate, kept for the record (`invalid/`, `out4-smoke-invalid/`):

- `invalid/glm-no-tool-calls/`: two GLM 5.3 runs that returned word salad without calling a single tool.
- `out4-smoke-invalid/`: the agents inherited the fake keys from the harness's own environment, and Codex checked one directly. Fixed in `run4.sh` by starting every agent with `env -i`.
- `invalid/out-coerce-accio-value-changed/`: the broken fake `DATABASE_URL` was corrected in Fidelius during the run (an Import proposed by a round four Codex run was approved), so the crash and the injected hint never appeared. Fixed by `REQUIRE_BROKEN_DB` in `run4.sh`.
- `smoke/`: the Docker harness's first smoke runs, one `fix` run per agent.

## Files per run

Run names are `<agent>-<setup>-<task>[-r<N>]`. `<agent>` is `claude`, `codex`, or `claude_<model>` for Claude Code driving another model.

| File | What |
|---|---|
| `.jsonl` | The transcript: `claude -p --output-format stream-json --verbose` or `codex exec --json` |
| `.stderr` | The agent's stderr, ending with its exit code. Claude Code prints an `unrecognized_model` warning for the non-Anthropic models; it's harmless. |
| `.diff` | `git status` and `git diff` of the repo after the run |
| `.test` | `npm test` after the run (Docker runs only). It gives a real result only where the fixture has a test script: `fixture/base`, `fixture-realkeys/base`, `fixture5/`, `fixture5-realkeys/` and `fixture-denycheck/` |
| `.sessions/` | The agent's own session log folder (Mac runs only) |
| `summary.md` | `scan.py`'s table for the folder |

`*.log` and `run-log.txt`, `run2-log.txt` are the harness's own output for each batch.

## Agents, models, versions

All through OpenRouter.

- Claude Code 2.1.292 with `anthropic/claude-sonnet-5.5`
- Codex 0.160.1 with `openai/gpt-6-sol`
- Claude Code 2.1.292 with `deepseek/deepseek-v4-pro-0813`, `google/gemini-3.8-flash`, `x-ai/grok-4.7`, `z-ai/glm-5.3`, `qwen/qwen3.8-max-0902`, `moonshotai/kimi-k3`
- dotenvx 2.33.0 for the comparison. A first run used 1.75.1, from June 2026 and older than `--redact`; it's kept in `compare/dotenvx-1.75.1/`.
- Fidelius 1.0.3 for the Mac runs. Round three used accio 1.0.2, whose end-of-run notice still suggested `--no-mask`; 1.0.3 doesn't suggest it to agents.

Headless, permissions off (`--dangerously-skip-permissions`, `--dangerously-bypass-approvals-and-sandbox`). Claude Code is capped at 12 turns; Codex has a time limit instead (600 s in Docker, 900 s on the Mac). Fresh repo copy and fresh agent config every run.

## Fixtures

| Folder | Used by | What |
|---|---|---|
| `fixture/` | round one, model sweep | `base/` (`.env`, a test that never loads it) and `protected/` (deny rules in `.claude/settings.json`, `.claudeignore`, `.geminiignore`, AGENTS.md; the harness copies AGENTS.md to CLAUDE.md) |
| `fixture2/` | round two, dotenvx | the app loads `.env` and prints keys on `start`, `weather`, `doctor` |
| `fixture3/` | round three | round two's app with `accio shared ...` scripts; `results/` has the `start` and `weather` outputs (the `doctor` output wasn't saved) |
| `fixture4/` | round four | `control/` (with `.env`) and `accio/` (scripts through `accio shared`); `fake-keys.env` is what was imported into Fidelius |
| `fixture5/`, `fixture6/` | coercion | `.env` arm and accio arm, `pressure/` and `inject/` |
| `fixture7/` | real libraries | `sync` (axios error) and `weather-check` (`curl -v`), `control/` and `accio/` |
| `fixture-realkeys/`, `fixture5-realkeys/` | real-looking keys | same as `fixture/` and `fixture5/` with keys that don't say `CANARY` |
| `fixture-denycheck/` | deny-rule check | `fixture/base` with only the deny rules, and tasks that ask for the `.env` directly |

`tasks.txt` in each fixture holds the task ids and the exact prompts. The fixtures' `.env` files are fake and tracked on purpose, even though each fixture's `.gitignore` lists `.env`.

## Rerun it

You need an OpenRouter key in `OPENROUTER_API_KEY`. The runs used `accio shared --require OPENROUTER_API_KEY <script>`, but any way of setting the variable works. The scripts skip a run whose `.jsonl` already exists in the output folder (`run.sh` overwrites instead), so always give them a fresh `OUTDIR`.

Docker:

```
docker build -t fidelius-hn-test .

OUTDIR=rerun/out ./run.sh                                              # round one
FIX=fixture2 OUTDIR=rerun/out2 ./run.sh                                # round two
OUTDIR=rerun/out-models ./run-models.sh                                # model sweep, no rules, 2 repeats
VARIANTS=protected REPEATS=1 OUTDIR=rerun/out-models ./run-models.sh   # model sweep with rules
FIX=fixture-realkeys REPEATS=1 OUTDIR=rerun/out-models-realkeys ./run-models.sh
OUTDIR=rerun/out-coerce ./run-coerce.sh                                # coercion, .env arm
FIX=fixture5-realkeys PAIRS=pressure:pressure REPEATS=2 OUTDIR=rerun/out-coerce-realkeys ./run-coerce.sh
compare/run-dotenvx.sh                                                 # dotenvx 2.33.0 (overwrites compare/dotenvx-2.33.0/)
```

The deny-rule check:

```
mkdir -p rerun/out-denycheck
for t in readtool catcmd; do
  docker run --rm -e OPENROUTER_API_KEY -v "$PWD/fixture-denycheck:/fixture:ro" -v "$PWD/rerun/out-denycheck:/out" \
    fidelius-hn-test agent-run claude denycheck "$t" 1
done
```

Mac (see `SETUP-round4.md` for the test account): the control arm needs only Node and the two agents. The accio arm needs Fidelius with `accio` installed and `fixture4/fake-keys.env` imported into the `shared` project.

```
SMOKE=1 OUTDIR=rerun/out4-smoke ./run4.sh                    # 4 runs
OUTDIR=rerun/out4 ./run4.sh                                  # round four
FIX=fixture7 REPEATS=3 OUTDIR=rerun/out-real ./run4.sh       # real libraries
OUTDIR=rerun/out-coerce-accio ./run-coerce-accio.sh          # coercion, accio arm
```

Round three has no script: in `fixture3/shop`, run each npm script through accio with no marker, with `CLAUDECODE=1` and with `CODEX_THREAD_ID` set, output to a file, and look for `<concealed by fidelius`.

## Read the results

```
python3 -I scan.py out4            # per-run table: first command whose output had a key, session log, bypass attempts, ...
python3 -I cost.py out-models      # cost estimate from token counts
```

`scan.py` matches the fake values in `CANARIES` and `REALISTIC`. Its "Bypass attempts", "Probes" and "accio import" columns are pattern matches on commands, and its "first command" column can show a compound command; the numbers in the post were checked against the transcripts. The "Test passes" column only means something for fixtures with a test script (see the `.test` row above).

Claude Code's `total_cost_usd` uses Anthropic's prices, so it's wrong for the other models; `cost.py` prices their tokens with `compare/openrouter-models-2026-10-08.json`.

## Cost

`cost.py` estimates a full rerun at about $15 at OpenRouter list prices.

## License

- Code, MIT (`LICENSE`): the scripts (`*.sh`, `*.py`, `compare/run-dotenvx.sh`), the `Dockerfile`, and the fixtures (`fixture*/`, except `fixture3/results/`).
- Data and documentation, CC BY 4.0 (`LICENSE-DATA`): the transcripts and everything else in `out*/`, `invalid/`, `smoke/`, `compare/` (apart from its script), `fixture3/results/`, the `*.log` and `run*-log.txt` files, `README.md` and `SETUP-round4.md`.

Codex session logs include Codex's own built-in instructions, which stay under the Apache License 2.0 of OpenAI's Codex CLI.
