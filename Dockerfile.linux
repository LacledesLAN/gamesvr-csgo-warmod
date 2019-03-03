# escape=`

FROM lacledeslan/gamesvr-csgo

HEALTHCHECK NONE

ARG BUILDNODE="unspecified"
ARG SOURCE_COMMIT

LABEL maintainer="Laclede's LAN <contact @lacledeslan.com>" `
      com.lacledeslan.build-node=$BUILDNODE `
      org.label-schema.schema-version="1.0" `
      org.label-schema.url="https://github.com/LacledesLAN/README.1ST" `
      org.label-schema.vcs-ref=$SOURCE_COMMIT `
      org.label-schema.vendor="Laclede's LAN" `
      org.label-schema.description="LL Counter-Strike Warmod Server" `
      org.label-schema.vcs-url="https://github.com/LacledesLAN/gamesvr-csgo-warmod"

# `RUN true` lines are work around for https://github.com/moby/moby/issues/36573
COPY --chown=CSGO:root /dist /app
RUN true
COPY --chown=CSGO:root /dist.linux /app/

# UPDATE USERNAME & ensure permissions
RUN usermod -l CSGOWarmod CSGO &&`
    chmod +x /app/ll-tests/*.sh &&`
    mkdir -p /app/csgo/logs &&`
    chmod 774 /app/csgo/logs

USER CSGOWarmod

WORKDIR /app/

CMD ["/bin/bash"]

ONBUILD USER root
