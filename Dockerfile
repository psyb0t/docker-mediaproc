FROM ubuntu:24.04

ARG MEDIAPROC_UID=1000
ARG MEDIAPROC_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

# Install openssh-server, latest ffmpeg, sox, imagemagick, fonts, and effect plugins
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        python3 \
        software-properties-common \
        ca-certificates && \
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

# Create mediaproc user
RUN if getent group ${MEDIAPROC_GID} > /dev/null 2>&1; then \
        groupmod -n mediaproc $(getent group ${MEDIAPROC_GID} | cut -d: -f1); \
    else \
        groupadd -g ${MEDIAPROC_GID} mediaproc; \
    fi && \
    if getent passwd ${MEDIAPROC_UID} > /dev/null 2>&1; then \
        usermod -l mediaproc -g mediaproc -d /home/mediaproc -m $(getent passwd ${MEDIAPROC_UID} | cut -d: -f1); \
    else \
        useradd -m -u ${MEDIAPROC_UID} -g mediaproc -s /bin/bash mediaproc; \
    fi

# Setup directories and mount points
RUN mkdir -p /var/run/sshd /work /usr/share/fonts/custom && \
    chown mediaproc:mediaproc /work /home/mediaproc && \
    chmod 755 /work /usr/share/fonts/custom && \
    touch /home/mediaproc/authorized_keys && \
    chmod 644 /home/mediaproc/authorized_keys

# Copy configs
COPY sshd_config /etc/ssh/sshd_config
COPY --chmod=755 media-wrapper /usr/local/bin/media-wrapper
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Generate host keys
RUN ssh-keygen -A

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
