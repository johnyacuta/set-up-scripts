# Shell setup scripts

This repository contains shell setup scripts for convenient command-line shortcuts:

- `gscb` creates and switches to a new branch.
- `gacp` stages changes, commits them, and pushes the commit.
- `k` is a shorthand alias for the Kubernetes CLI, `kubectl`.

## Supported shells

- **macOS:** Zsh, configured in `${ZDOTDIR:-$HOME}/.zshrc`
- **Windows:** Bash (for example, Git Bash), configured in `~/.bashrc` and
  `~/.bash_profile`

Each setup script detects macOS and common Windows Bash environments. If it
cannot detect the OS, it prompts you to choose one. You can also specify it
directly.

## Setup

Run the relevant script from this directory:

```sh
# macOS
chmod +x setup-gscb.sh
./setup-gscb.sh --os macos
./setup-gacp.sh --os macos
./setup-kubernetes.sh --os macos

# Windows, from Git Bash
bash setup-gscb.sh --os windows
bash setup-gacp.sh --os windows
bash setup-kubernetes.sh --os windows
```

The `--os` option accepts `macos` or `windows`. If omitted, each script detects
the current OS when possible, or prompts you to choose. Running a setup script
again safely replaces its managed configuration block; other profile content
is preserved.

After setup, open a new terminal or reload the profile:

```sh
# macOS Zsh
source ~/.zshrc

# Windows Bash
source ~/.bashrc
```

## Usage

### Create a branch

From inside a Git working tree:

```sh
gscb my-new-branch-name
```

You can optionally pass a repository path. A dot means the current directory:

```sh
gscb my-new-branch-name .
gscb my-new-branch-name ../another-repository
```

The function runs `git switch -c`, so Git creates and checks out the new branch.
The branch name must not already exist. Git errors are displayed as usual.

### Add, commit, and push

From inside a Git working tree, quote the commit message:

```sh
gacp "my commit message"
```

The function runs `git add .`, `git commit -m "my commit message"`, then
`git push`, stopping if any step fails. Git must have a push destination
configured for the current branch; for a new branch, set its upstream first,
for example with `git push -u origin my-new-branch-name`.

### Kubernetes CLI

Use `k` anywhere you would use `kubectl`:

```sh
k get pods
k describe deployment my-deployment
```
