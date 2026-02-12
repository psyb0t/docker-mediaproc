# docker-mediaproc

[![Docker Hub](https://img.shields.io/docker/v/psyb0t/mediaproc?sort=semver&label=Docker%20Hub)](https://hub.docker.com/r/psyb0t/mediaproc)

Containerized media processing tools over SSH. Drop files in, run ffmpeg/sox/imagemagick over SSH, get your shit out.

Built on top of [psyb0t/lockbox](https://github.com/psyb0t/docker-lockbox) - see that repo for the security model, file operations, path sandboxing, and all the SSH lockdown details.

## Features

- **FFmpeg 7.1** with frei0r, LADSPA, and LV2 plugins - video effects, audio effects, all the good shit
- **Sox** - audio processing swiss army knife
- **ImageMagick** - image manipulation, conversion, thumbnails, whatever
- **2200+ fonts** - emoji, CJK, Arabic, Thai, Indic, monospace, you fuckin' name it

## Quick Start

### install.sh (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/psyb0t/docker-mediaproc/main/install.sh | sudo bash
```

This sets up `~/.mediaproc/` with the docker-compose file, authorized_keys, and work directory, then drops a `mediaproc` command into `/usr/local/bin`. Uses your UID/GID so you don't end up with shit permissions on files like some fuckin' animal.

Add your SSH key and start it:

```bash
cat ~/.ssh/id_rsa.pub >> ~/.mediaproc/authorized_keys
mediaproc start -d
ssh -p 2222 mediaproc@localhost "ffmpeg -version"
```

```bash
mediaproc start           # foreground
mediaproc start -d        # detached
mediaproc start -d -p 22  # detached on custom port (default 2222)
mediaproc stop            # stop
mediaproc upgrade         # pull latest image, asks to stop/restart if running
mediaproc status          # show status
mediaproc logs            # show logs
```

### docker run

If you just wanna run it raw without the install script:

```bash
docker pull psyb0t/mediaproc

cat ~/.ssh/id_rsa.pub > authorized_keys
mkdir -p work

docker run -d \
  --name mediaproc \
  --restart unless-stopped \
  -p 2222:22 \
  -e "LOCKBOX_UID=$(id -u)" \
  -e "LOCKBOX_GID=$(id -g)" \
  -v $(pwd)/authorized_keys:/etc/lockbox/authorized_keys:ro \
  -v $(pwd)/work:/work \
  psyb0t/mediaproc

ssh -p 2222 mediaproc@localhost "ffmpeg -version"
```

## Allowed Commands

That's it. That's the list. Everything else gets a nice "not allowed" message.

| Command    | Description                                  |
| ---------- | -------------------------------------------- |
| `ffmpeg`   | Video/audio encoding, transcoding, filtering |
| `ffprobe`  | Media file analysis                          |
| `sox`      | Audio processing                             |
| `soxi`     | Audio file info                              |
| `convert`  | Image conversion/manipulation                |
| `identify` | Image file info                              |
| `magick`   | ImageMagick CLI                              |

Plus all the [lockbox file operations](https://github.com/psyb0t/docker-lockbox#file-operations) (`put`, `get`, `ls`, `rm`, `mkdir`, `rmdir`, `rrmdir`).

## Usage Examples

```bash
# Upload a file, process it, download the result
ssh mediaproc@host "put input.mp4" < input.mp4
ssh mediaproc@host "ffmpeg -i /work/input.mp4 -c:v libx264 /work/output.mp4"
ssh mediaproc@host "get output.mp4" > output.mp4

# Get video info as JSON
ssh mediaproc@host "ffprobe -v quiet -print_format json -show_format /work/video.mp4"

# Apply frei0r glow effect
ssh mediaproc@host "ffmpeg -i /work/in.mp4 -vf frei0r=glow:0.5 /work/out.mp4"

# Convert audio format
ssh mediaproc@host "sox /work/input.wav /work/output.mp3"

# Resize image
ssh mediaproc@host "convert /work/input.png -resize 50% /work/output.png"

# Create thumbnail
ssh mediaproc@host "convert /work/input.jpg -thumbnail 200x200 /work/thumb.jpg"
```

## Fonts

Over 2200 fonts covering pretty much every script and use case:

- **Core**: DejaVu, Liberation, Ubuntu, Roboto, Open Sans
- **Emoji & CJK**: Noto Color Emoji, Noto Sans CJK (Chinese, Japanese, Korean)
- **Monospace**: Fira Code, Hack, Inconsolata
- **International**: Arabic, Thai, Khmer, Lao, Tibetan, Indic scripts

Need more? Mount your custom fonts to `/usr/share/fonts/custom` and the container will pick them up on startup. Font cache gets rebuilt automatically.

## SSH Client Config

Stop typing port numbers like it's 1995. Add this kinda shit to `~/.ssh/config`:

```
Host mediaproc
    HostName localhost
    Port 2222
    User mediaproc
```

Then just: `ssh mediaproc "ffmpeg -version"`

## Building

```bash
make build
make test    # build + run integration tests
```

## License

This project is licensed under [WTFPL](LICENSE) - Do What The Fuck You Want To Public License.
