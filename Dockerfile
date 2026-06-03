FROM node:24-trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @earendil-works/pi-coding-agent \
    && npm cache clean --force

RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh -o /tmp/rtk-install.sh \
    && sh /tmp/rtk-install.sh \
    && rm /tmp/rtk-install.sh \
    && ln -sf /root/.local/bin/rtk /usr/local/bin/rtk \
    && rtk --version

COPY pi-container-entrypoint.sh /usr/local/bin/pi-container-entrypoint
RUN chmod +x /usr/local/bin/pi-container-entrypoint

WORKDIR /workspace

ENTRYPOINT ["pi-container-entrypoint"]
CMD []
