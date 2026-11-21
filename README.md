# Shell shortcuts setup

Use one setup script to add convenient command-line shortcuts to your shell:

- `gscb` creates a new branch, switches to it, and pushes it to `origin` with
  upstream tracking.
- `gacp` stages changes, commits them, and pushes the commit.
- `k` is a shorthand alias for the Kubernetes CLI, `kubectl`.

## Supported shells

- **macOS:** Zsh, configured in `${ZDOTDIR:-$HOME}/.zshrc`
- **Windows:** Bash (for example, Git Bash), configured in `~/.bashrc` and
  `~/.bash_profile`

The setup script detects macOS and common Windows Bash environments. If it
cannot detect the OS, it prompts you to choose one. You can also specify it
directly.

## Setup

Run the setup script from this directory to install all three shortcuts:

```sh
# macOS
chmod +x setup.sh
./setup.sh --os macos

# Windows, from Git Bash
bash setup.sh --os windows
```

The `--os` option accepts `macos` or `windows`. If omitted, the script detects
the current OS when possible, or prompts you to choose. It adds shortcuts that
are not already configured, preserves other profile content, and replaces the
previous individual setup-script blocks with one managed block. It is safe to
run again.

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

The function runs `git switch -c`, then pushes the branch with
`git push -u origin <branch-name>` so Git sets up upstream tracking. The branch
name must not already exist, and the repository must have an `origin` remote
configured. Git errors are displayed as usual.

### Add, commit, and push

From inside a Git working tree, quote the commit message:

```sh
gacp "my commit message"
```

The function runs `git add .`, `git commit -m "my commit message"`, then
`git push`, stopping if any step fails. Branches created with `gscb` already
have their upstream configured. For branches created another way, set an
upstream before using `gacp`, for example with
`git push -u origin my-new-branch-name`.

### Kubernetes CLI

Use `k` anywhere you would use `kubectl`:

```sh
k get pods
k describe deployment my-deployment
```
