# Git branch shorthand setup

`setup-gscb.sh` installs the `gscb` shell function for creating a Git branch
from the command line.

## Supported shells

- **macOS:** Zsh, configured in `${ZDOTDIR:-$HOME}/.zshrc`
- **Windows:** Bash (for example, Git Bash), configured in `~/.bashrc` and
  `~/.bash_profile`

The script detects macOS and common Windows Bash environments. If it cannot
detect the OS, it prompts you to choose one. You can also specify it directly.

## Setup

Run the script from this directory:

```sh
# macOS
chmod +x setup-gscb.sh
./setup-gscb.sh --os macos

# Windows, from Git Bash
bash setup-gscb.sh --os windows
```

The `--os` option accepts `macos` or `windows`. If you omit it, the script
detects the current OS when possible, or presents a selection prompt.
Running the setup again safely replaces the script's managed configuration
block. Other profile content is preserved.

After setup, open a new terminal or reload the profile:

```sh
# macOS Zsh
source ~/.zshrc

# Windows Bash
source ~/.bashrc
```

## Usage

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
