# Our Snoop37 fork

Repository: https://github.com/wesmattison/snoop37

## Remotes and branches

| Remote | Repository | Purpose |
| --- | --- | --- |
| `origin` | `wesmattison/snoop37` | Our branches and features |
| `upstream` | `genkigenki/sloop-fm1` | SMK port; normally integrate `upstream/snoop37` |
| `sloop` | `isod89/sloop-fm1` | Original musical firmware; inspect `sloop/main` |

- `snoop37`: clean mirror of genkigenki's `snoop37`; no local feature commits.
- `develop`: our integration branch, starting from Snoop37 2.7.1.
- `feature/<name>`: focused changes branched from `develop`.
- `sync/<date>`: review and test upstream updates before merging into `develop`.

The default push remote is `origin`. Upstream push URLs are disabled locally.
Pulls allow fast-forward only, fetches prune deleted remote branches, and Git's
rerere remembers conflict resolutions (review reused resolutions before committing).
These settings are local: a new clone must configure them again.

## Start a feature

Run from the repository root with a clean working tree:

```sh
git switch develop
git pull --ff-only origin develop
git switch -c feature/my-feature
# Make focused changes and run the relevant checks.
git push -u origin feature/my-feature
```

Open feature PRs against `wesmattison/snoop37:develop`. Keep hardware changes,
musical features, and formatting changes in separate commits where practical.
Use merges for published integration history; do not force-push shared branches.

## Bring in upstream updates

```sh
git fetch --all --prune
git switch snoop37
git merge --ff-only upstream/snoop37
git push origin snoop37
git switch develop
git pull --ff-only origin develop
git switch -c sync/YYYY-MM-DD
git merge --no-ff upstream/snoop37
```

Resolve any conflicts, review the resulting changes, and run the applicable build
and tests before pushing the sync branch and opening a PR into our `develop`.
Use `git merge --abort` to abandon an unresolved merge. If the mirror cannot
fast-forward, stop and inspect the upstream history; do not reset or force-push it.
Choose a unique sync branch name each time.

Normally take original SLOOP changes through genkigenki's port, which integrates
them with the SMK hardware adaptations. To see changes not yet in the port:

```sh
git log --oneline upstream/snoop37..sloop/main
```

Do not automatically merge both sources into `develop`. If we need an upstream
fix before the port includes it, use a separate integration branch and explicitly
review SMK compatibility. A direct merge or cherry-pick can conflict with the port.

## Build and validation

### Configured Windows environment

Ubuntu-24.04 is installed in WSL2. The initial build environment uses the Linux
`root` account, with JieLi toolchain `jieli-linux-toolchains-20260730.1` linked at
`/root/.jieli/toolchain` and SDK tag `AC79NN_SDK_V1.2.1_2023-12-13` checked out at
`/root/fw-AC79_AIoT_SDK` (commit `d179b4484759423312073f5fbb232501aa491047`).
Ubuntu packages include build-essential, git, curl, xz-utils, ca-certificates,
python3, python3-pil, and nodejs. Node 24.22.0 from nodejs.org (archive SHA-256
checked against its published checksum) is installed under `/opt/snoop37-node/`
and linked as `/usr/local/bin/node`, ahead of Ubuntu's Node 18. Node 18 lacks
`CompressionStream('deflate-raw')`, which the web tests require. Python is 3.12.3;
the JieLi compiler reports clang 4.0.1. No hardware access is needed to build.

From PowerShell in this checkout:

```powershell
.\build-snoop37-wsl.ps1
```

This explicitly selects the SMK-37 Pro target and the Snoop37 appearance, and
returns an error if compilation fails. It builds the existing Windows checkout
through WSL; there is no second source copy to synchronize. It does not flash.
The upstream builder can retry automatically with `FELUCCA_LOGO_TEXT=1` if the
graphical logo would exceed flash capacity; this occurred on the initial build.

Initial validation on 2026-10-19: the Pro and FM-1 reference builds succeeded,
the Pro package identity/layout/CRC test passed, and all 182 golden audio renders
matched, including all tested second-core modes. The full host suite was not
green: ThreadSanitizer could not start (`unexpected memory mapping`), and static
instruction budgets were exceeded for `drums_mix` (6793 vs. 6153 baseline, over
the 10% allowance) and `fm1_alnk0_irq` (268 vs. 174). The first web run used Node
18 and failed on deflate-raw; the full `node web/test_web.mjs` rerun passed under
Node 24. Playwright/PWA checks were skipped because Playwright was not installed;
WASM preview was not built. Checks requiring external official stock packages
were skipped (`SMK_STOCK_DIR` was not set).
The PowerShell launcher was tested with a second Pro build, byte-identical to
the first: package 651206 bytes, SHA-256
`4a3343a884a041ba8940c0bf0856315f1b847636fb68a7b567d173bac438e172`.
Logs are local ignored files: `build/smk37-build.log`, `build/fm1-build.log`,
`build/host-tests.log`, and `build/web-tests-node24.log`. No firmware was flashed.

### Upstream build commands

Follow `BUILDING.md` and `SMK37.md` for toolchain and SDK prerequisites. On Windows,
the hardware build needs Linux x86-64 through WSL2 (or another supported Linux
environment). In that environment, the Pro target with the Snoop37 appearance is:

```sh
BOARD=smk37 SNOOP37=1 sh build.sh
```

The package is `build/sloop-smk37.fwsc`. The upstream host suite uses FM-1 build
artifacts, so rebuild that target before running the suite:

```sh
sh build.sh
sh tests/run_tests.sh
```

Those commands share intermediate build outputs. Rebuild the SMK target afterward
if an SMK package is needed. Preserve known-good firmware and record the source
commit of any hardware-tested package. Building or merging does not install it;
follow the model-specific installation and backup instructions in `SMK37.md`.
Never commit private flash dumps, device calibration, credentials, or SDK binaries.

## Recreate local Git setup

```sh
git remote add upstream https://github.com/genkigenki/sloop-fm1.git
git remote add sloop https://github.com/isod89/sloop-fm1.git
git remote set-url --push upstream DISABLED
git remote set-url --push sloop DISABLED
git config remote.pushDefault origin
git config push.default simple
git config pull.ff only
git config fetch.prune true
git config rerere.enabled true
git fetch --all --prune
```

Add only missing remotes if they already exist. Track our mirror with
`git switch --track origin/snoop37` when it is not already a local branch.
