# escape=`

FROM lacledeslan/gamesvr-csgo-warmod

HEALTHCHECK NONE

ARG BUILDNODE="unspecified"
ARG SOURCE_COMMIT

LABEL maintainer="Laclede's LAN <contact @lacledeslan.com>" `
      com.lacledeslan.build-node=$BUILDNODE `
      org.label-schema.schema-version="1.0" `
      org.label-schema.url="https://github.com/LacledesLAN/README.1ST" `
      org.label-schema.vcs-ref=$SOURCE_COMMIT `
      org.label-schema.vendor="Laclede's LAN" `
      org.label-schema.description="LL Counter-Strike GO Warmod Overtime Server" `
      org.label-schema.vcs-url="https://github.com/LacledesLAN/gamesvr-csgo-warmod"

# This hack makes me cry (╯︵╰,) - doesn't help that POSIX shell doesn't support arrays either....
RUN FILE="/app/csgo/cfg/gamemode_competitive_server.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo '//===OVERTIME HACK' >> "$FILE" &&`
        echo 'mp_maxrounds "7"' >> "$FILE" &&`
        echo 'mp_startmoney "10000" ' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
    FILE="/app/csgo/cfg/warmod/ruleset_default.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo '//===OVERTIME HACK' >> "$FILE" &&`
        echo 'mp_maxrounds "7"' >> "$FILE" &&`
        echo 'mp_startmoney "10000" ' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
    FILE="/app/csgo/cfg/warmod/ruleset_global.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo '//===OVERTIME HACK' >> "$FILE" &&`
        echo 'mp_maxrounds "7"' >> "$FILE" &&`
        echo 'mp_startmoney "10000" ' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
    FILE="/app/csgo/cfg/warmod/ruleset_playout.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo '//===OVERTIME HACK' >> "$FILE" &&`
        echo 'mp_maxrounds "7"' >> "$FILE" &&`
        echo 'mp_startmoney "10000" ' >> "$FILE" &&`
        echo $'\n' >> "$FILE"

COPY --chown=CSGOWarmod:root /dist.linux /app/

# UPDATE USERNAME & ensure permissions
RUN usermod -l CSGOWarmodOvertime CSGOWarmod &&`
    chmod +x /app/ll-tests/*.sh &&`
    chmod 774 /app/csgo/cfg/*.cfg &&`
    chmod 774 /app/csgo/cfg/warmod/*.cfg

USER CSGOWarmodOvertime

WORKDIR /app/

CMD ["/bin/bash"]

ONBUILD USER root
