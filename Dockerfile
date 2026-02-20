FROM psyb0t/lockbox:v2.1.4

ENV LOCKBOX_USER=mediaproc

# Install latest ffmpeg, sox, imagemagick, fonts, and effect plugins
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository -y ppa:ubuntuhandbook1/ffmpeg7 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        # Sox audio processor
        sox \
        libsox-fmt-all \
        # ImageMagick
        imagemagick \
        # Video effect plugins (used via -vf frei0r=...)
        frei0r-plugins \
        # Audio effect plugins (used via -af ladspa=...)
        ladspa-sdk \
        swh-plugins \
        tap-plugins \
        cmt \
        # LV2 audio plugins (used via -af lv2=...)
        lv2-dev \
        lilv-utils \
        # Core fonts
        fonts-dejavu-core \
        fonts-dejavu-extra \
        fonts-liberation \
        fonts-liberation2 \
        fonts-freefont-ttf \
        fonts-ubuntu \
        fonts-roboto \
        fonts-open-sans \
        fonts-droid-fallback \
        # Emoji fonts
        fonts-noto-color-emoji \
        fonts-noto-core \
        fonts-noto-extra \
        fonts-noto-cjk \
        fonts-noto-cjk-extra \
        fonts-noto-mono \
        # International fonts
        fonts-wqy-zenhei \
        fonts-wqy-microhei \
        fonts-thai-tlwg \
        fonts-khmeros \
        fonts-lao \
        fonts-tibetan-machine \
        fonts-indic \
        fonts-arabeyes \
        fonts-hosny-amiri \
        fonts-farsiweb \
        # Additional fonts
        fonts-hack \
        fonts-firacode \
        fonts-inconsolata \
        fontconfig && \
    fc-cache -f -v && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Custom fonts mount point
RUN mkdir -p /usr/share/fonts/custom && \
    chmod 755 /usr/share/fonts/custom

# Allowed media commands
COPY allowed.json /etc/lockbox/allowed.json

# Font cache rebuild on startup (when custom fonts are mounted)
COPY --chmod=755 10-fontcache.sh /etc/lockbox/entrypoint.d/10-fontcache.sh
