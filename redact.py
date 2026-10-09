"""Replace real secrets in saved transcripts, and the test account's user name. Never prints a value.

    python3 -I redact.py FOLDER                       # keys from the environment, e.g. OPENROUTER_API_KEY
    REDACT_USER=<account> python3 -I redact.py FOLDER # also the Mac test account's name, as "redacted"

Claude Code's own session token (CLAUDE_CODE_MESSAGING_TOKEN) reaches env dumps the agents ran; its
values are collected from NAME=value lines and replaced wherever they occur.
Works on raw bytes, so files are changed only where a match is."""
import os, re, sys, pathlib

names = ["OPENROUTER_API_KEY"]
values = {n: os.environ[n] for n in names if len(os.environ.get(n, "")) >= 8}
pairs = [(v.encode(), f"<REDACTED:{n}>".encode()) for n, v in values.items()]
# The account name shows up in home paths (/Users/<account>), USER=<account> and ls -l owners.
user = os.environ.get("REDACT_USER", "")
if len(user) >= 4:
    pairs.append((user.encode(), b"redacted"))
files = [f for f in pathlib.Path(sys.argv[1]).rglob("*") if f.is_file() and ".git" not in f.parts]
seen = rb'((?:[^\\"\s]|\\(?!n))+)'  # a value up to whitespace, a quote or an escaped newline
for name in ["CLAUDE_CODE_MESSAGING_TOKEN"]:
    found = {m.group(1) for f in files for m in re.finditer(name.encode() + b"=" + seen, f.read_bytes())}
    pairs += [(v, f"<REDACTED:{name}>".encode()) for v in found if len(v) >= 8 and not v.startswith(b"<")]
changed = 0
for f in files:
    data = f.read_bytes()
    new = data
    for old, rep in pairs:
        new = new.replace(old, rep)
    if new != data:
        f.write_bytes(new)
        changed += 1
print(f"redacted {len(pairs)} value(s) in {changed} file(s)")
