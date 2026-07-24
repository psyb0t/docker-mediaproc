# mediaproc setup

## Quick Install

The installer creates `~/.mediaproc/` (docker-compose, authorized_keys, work
directory) and drops a `mediaproc` command into `/usr/local/bin`. The container
it stands up is a [lockbox](https://github.com/psyb0t/docker-lockbox)-hardened
SSH sandbox (key-auth, whitelisted commands only — see the Security model in
SKILL.md).

Because the installer runs as **root**, pin it to a released tag and read it
before running — don't pipe a mutable `main` branch straight into a root shell:

```bash
# Pick a released tag: https://github.com/psyb0t/docker-mediaproc/releases
REF=vX.Y.Z
curl -fsSL "https://raw.githubusercontent.com/psyb0t/docker-mediaproc/${REF}/install.sh" -o install.sh
less install.sh            # review exactly what runs as root
sudo bash install.sh
```

## Starting

```bash
# Add your SSH key
cat ~/.ssh/id_rsa.pub >> ~/.mediaproc/authorized_keys

# Basic start (detached)
mediaproc start -d

# With resource limits
mediaproc start -d -c 4 -r 4g -s 2g

# Custom port
mediaproc start -d -p 2223

# Custom fonts directory
mediaproc start -d -f /path/to/fonts
```

All flags persist to `~/.mediaproc/.env` — next `start` reuses the last values.

## Management

```bash
mediaproc stop                # stop
mediaproc upgrade             # pull latest image, asks to stop/restart
mediaproc uninstall           # stop and remove everything
mediaproc status              # show status
mediaproc logs                # show container logs
```

## Configuration

| Flag | Env var            | Default    | Description           |
| ---- | ------------------ | ---------- | --------------------- |
| `-p` | `MEDIAPROC_PORT`   | `2222`     | SSH port              |
| `-f` | `MEDIAPROC_FONTS_DIR` | `./fonts` | Custom fonts directory |
| `-c` | `MEDIAPROC_CPUS`   | `0`        | CPU limit (0 = unlimited) |
| `-r` | `MEDIAPROC_MEMORY` | `0`        | RAM limit (0 = unlimited) |
| `-s` | `MEDIAPROC_SWAP`   | `0`        | Swap limit (0 = no swap)  |
