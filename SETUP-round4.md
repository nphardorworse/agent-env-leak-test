# Round four setup: the test account on the old Mac

The account must stay signed out of iCloud, so no real secrets sync to it. Fidelius needs macOS 15 or later.

## 1. Tools

1. Command Line Tools (for git): `xcode-select --install`
2. Node 22 or later: the macOS installer from nodejs.org.
3. A user-level npm folder, so installs don't need admin:
   ```
   npm config set prefix ~/.npm-global
   echo 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' >> ~/.zshrc
   ```
   Open a new Terminal window.
4. The same agent versions as rounds one and two:
   ```
   npm install -g @anthropic-ai/claude-code@2.1.292 @openai/codex@0.160.1
   ```
   Check with `claude --version` and `codex --version`. If a version is gone, install the nearest one and note it in the research note.

## 2. Fidelius

1. Install the current Fidelius release in this account and open it.
2. Setup > Install accio Command. Check: `accio list` in a new Terminal window.
3. Fake keys: in this folder, `accio import shared fixture4/fake-keys.env`, then click Import in the preview. (The runs used the `shared` project, the only one on Fidelius's free tier; the npm scripts in `fixture4/accio` call `accio shared`.)
4. OpenRouter key: make a new key on openrouter.ai just for this test, with a credit limit of about $10. Add it in Fidelius to the `shared` project as `OPENROUTER_API_KEY`, next to the fake keys (doctor.sh filters it out of its output; run4.sh starts every agent with a clean environment so the fake keys don't reach it that way). The agents see this key in their own environment anyway, which is why it gets its own cap. Delete it on OpenRouter after the test.
5. Check the masking notice: `CLAUDECODE=1 accio shared node -e 'console.log(process.env.PAYMENTS_KEY)' > /tmp/m.txt; cat /tmp/m.txt`. The file should say `<concealed by fidelius: PAYMENTS_KEY>`, and the notice in the Terminal should not mention `--no-mask`.

## 3. Run

From a plain Terminal window, in this folder:

```
SMOKE=1 accio shared --require OPENROUTER_API_KEY ./run4.sh
```

That's 4 runs (2 agents × 2 arms, the start task). Send `out4/summary.md` and the `out4` folder back. If the control runs show the key and the accio runs show `<concealed by fidelius`, rename `out4` to `out4-smoke` and start the full run (60 runs, about an hour):

```
accio shared --require OPENROUTER_API_KEY ./run4.sh
```

It skips runs that already have a transcript, so it's safe to start again after a stop.
