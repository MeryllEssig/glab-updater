# glab-updater

A simple shell script to install or update [glab](https://gitlab.com/gitlab-org/cli) (the GitLab CLI) to the latest stable version.

## Features

- Detects the latest release automatically via the GitLab API
- Skips installation if already up to date
- Supports **Linux** and **macOS** (amd64, arm64)
- Installs to `~/.local/bin` by default (customizable)

## Usage

```bash
./setup-glab.sh
```

To install to a custom directory:

```bash
GLAB_INSTALL_DIR=/usr/local/bin ./setup-glab.sh
```

> [!NOTE]
> If the install directory is not writable, the script will automatically use `sudo`.

## Requirements

- `bash`, `curl`, `tar`, `grep`
