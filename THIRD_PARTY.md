# Third-Party Components

`docker-mediaproc`'s own source code is WTFPL — see [LICENSE](LICENSE). Do what the fuck you want with it.

The **published Docker image**, though, installs a pile of third-party media tools via `apt-get` in the [Dockerfile](Dockerfile), and some of those are GPL. This doesn't relicense psyb0t's code, but if you redistribute the built image, you're on the hook for GPL compliance on these components same as anyone else who ships a container full of GPL binaries.

| Component            | Kind                        | SPDX License(s)      | Source                                                    | Where it lives                     | Note                                                                 |
| --------------------- | --------------------------- | --------------------- | ---------------------------------------------------------- | ----------------------------------- | --------------------------------------------------------------------- |
| ffmpeg                | image-package (apt, PPA)    | GPL-2.0-or-later*     | https://ffmpeg.org                                          | installed into the published Docker image | Built with GPL-enabled config via `ppa:ubuntuhandbook1/ffmpeg7`; corresponding source at upstream and the PPA (https://launchpad.net/~ubuntuhandbook1/+archive/ubuntu/ffmpeg7) |
| sox                    | image-package (apt)          | GPL-2.0-or-later      | https://sourceforge.net/projects/sox/                       | installed into the published Docker image | corresponding source at upstream                                     |
| libsox-fmt-all         | image-package (apt)          | GPL-2.0-or-later      | https://sourceforge.net/projects/sox/                       | installed into the published Docker image | corresponding source at upstream                                     |
| frei0r-plugins         | image-package (apt)          | GPL-2.0-or-later      | https://frei0r.dyne.org                                     | installed into the published Docker image | corresponding source at upstream                                     |
| imagemagick            | image-package (apt)          | ImageMagick License (permissive) | https://imagemagick.org                          | installed into the published Docker image | ImageMagick's own license, not GPL; permissive, attribution appreciated |
| ladspa-sdk             | image-package (apt)          | GPL-2.0-or-later      | https://www.ladspa.org                                       | installed into the published Docker image | corresponding source at upstream                                     |
| swh-plugins            | image-package (apt)          | GPL-2.0-or-later      | https://github.com/swh/ladspa                                | installed into the published Docker image | corresponding source at upstream                                     |
| tap-plugins            | image-package (apt)          | GPL-2.0-or-later      | https://tomscii.sig7.se/tap-plugins/                         | installed into the published Docker image | corresponding source at upstream                                     |
| cmt                    | image-package (apt)          | GPL-2.0-or-later      | https://packages.debian.org/source/sid/cmt                   | installed into the published Docker image | corresponding source at upstream                                     |

\* ffmpeg's actual license depends on build configuration (LGPL vs GPL, plus whichever codecs/filters are enabled). The build used here comes from the `ppa:ubuntuhandbook1/ffmpeg7` PPA with GPL components enabled, so treat it as GPL-2.0-or-later for compliance purposes.

A copy of the GPL-2.0 license text is included at [LICENSES/GPL-2.0.txt](LICENSES/GPL-2.0.txt).

Fonts bundled in the image (DejaVu, Liberation, Noto, etc.) and any other `apt` packages not listed above (e.g. `lv2-dev`, `lilv-utils`, `fontconfig`) come with their own permissive/font licenses (mostly OFL/permissive) and aren't tracked here individually — check the respective Debian/Ubuntu package if you need exact terms.
