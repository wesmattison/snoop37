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
