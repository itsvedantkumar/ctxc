# ctxc

**A bash CLI that compiles a repository into a token-budgeted context pack for local LLMs.**

[![test](https://github.com/itsvedantkumar/ctxc/actions/workflows/test.yml/badge.svg)](https://github.com/itsvedantkumar/ctxc/actions/workflows/test.yml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![runs on](https://img.shields.io/badge/runs%20on-macOS%20%2B%20Linux-lightgrey.svg)](#limits)

I run small models locally (qwen2.5-coder, llama3.1) and got tired of hand-picking files to
paste into the prompt. Every "paste your repo" tool I tried wanted Node, or an API key, or
ignored the fact that a 7B model at 32k context cannot swallow the whole tree anyway. ctxc
is one bash script, no dependencies beyond git, and a budget it actually respects instead
of printing a warning and shipping you 90k tokens anyway.

## Usage

```bash
ctxc ~/Projects/vstack > pack.txt
ctxc ~/Projects/vstack --model llama3.1:8b --budget 32768
ctxc . --include '*.go' --exclude '*_test.go' --list
```

The pack goes to stdout, everything else (notes, warnings) to stderr, so `ctxc . > pack.txt`
stays clean. `--json` emits the manifest alone for scripting:

```json
{"tool":"ctxc","version":"0.3.0","model":"qwen2.5-coder:7b","budget":8192,"files":14,"est_tokens":7912}
```

## How the budget works

Files are estimated at 4.0 chars per token — crude, but deterministic, and for code-heavy
text it lands within ~15% of the real tokenizer. Files are packed in git's ordering, each
one only if it still fits the budget; the first file that doesn't fit emits a note to
stderr and everything after it is skipped too. If nothing fits at all, ctxc refuses with
exit 2 rather than emitting an empty pack — an empty pack is how you quietly blow an
afternoon debugging a model that "lost" your context.

| Flag | What it does |
| --- | --- |
| `--model NAME` | model name written into the manifest |
| `--budget N` | token budget (default 8192, env `CTXC_BUDGET`) |
| `--max-bytes N` | skip files larger than this (default 65536) |
| `--include` / `--exclude` | globs, exclude wins, repeatable |
| `--list` | print the files that would be packed, exit |
| `--no-ignore` | do not respect `.gitignore` (implied when there is no git) |

## What it reads

Git repos: `git ls-files --cached --others --exclude-standard`, so tracked files plus
untracked-but-not-ignored ones, and `.gitignore` is honored without re-implementing it.
Everything else (`.git`, `node_modules`, `dist`, venvs, pycache) is excluded by name.
No git? It walks the directory and tells you `.gitignore` was skipped.

## Limits

The 4.0 chars-per-token estimate is calibrated on English comments plus code; a repo of
minified JSON will overshoot. Binary files are not detected — `--max-bytes` is your friend.
There is no prompt template, no chunking, no AST awareness: this is the "give me the files
that fit" layer, and it stays that way.

## Development

```bash
bash test/run.sh
```

The suite runs the real binary against a tiny fixture repo — exit codes, filter behavior,
budget edge cases, the JSON shape. CI runs it on macOS and Linux, because the last bash
portability bug I shipped only reproduced on one of them.

## License

MIT
