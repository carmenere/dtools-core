# dtools
The project **dtools-core** contains various primitives for writing scripts for _dev_, _build_, _deploy_ and _test_ automation.<br>

<br>

# Getting started
## Prepare
1. Create directory `dtools` inside root directory of a project (e.g. `project_root_dir` dir):
```bash
mkdir dtools
```
2. Go to `dtools`:
```bash
cd dtools
```
3. Create `core` directory as **git submodule**:
```bash
git submodule add git@github.com:carmenere/dtools.git core
```
4. Create directory `locals`:
```bash
mkdir locals
```
5. Add `**/locals/` to file `.gitignore`.
6. Create `rc.sh` in `locals` directory:
```bash
touch locals/rc.sh
```
7. Add the following code to **each** `rc.sh` file you have just created:
```bash
function load() {
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi
  local self_dir="$(dirname $(realpath "${self}"))"

  dt_rc_load $(basename "${self_dir}") "${self_dir}"
}

load $0
```
8. Run `cp -r core/example/vars vars`. This creates copy of `core/example/vars` in your `dtools`. But you can adjust `dtools/vars` for your project later.
9. If you want to **overwrite vars locally** (don't touch git repo) you must create **appropriate file** in `dtools/locals` and change appropriate vars there.
10. All **variants for autocomplete** are configured in `autocompletions.sh` file.
10. Go back to `project_root_dir` and run `. ./dtools/core/rc.sh`.
11. Add following function `reinit_dtools` to **startup files** of shell, e.g. `~/.zshrc`, `~/.bashrc`:
```shell
function reinit_dtools() {
. ./dtools/core/rc.sh
}
```
And now you can run `reinit_dtools` in the directory where `dtools` is.<br>

<br>

## `dtools` layout
```bash
project_root_dir
├── ...
├── dtools/
│   ├── .gitignore
│   ├── core/   # This directory is a git submodule to 'https://github.com/carmenere/dtools' project.
│   │   ├── lib
│   │   ├── ...
│   │   └── rc.sh
│   ├── locals/   # Must be added to .gitignore (**/locals/). It is for overwriting project defaults in local devel environment.
│   │   ├── ...
│   │   └── rc.sh
│   └── vars/
│       ├── ...
│       └── autocompletions.sh

├── ...
```

<br>