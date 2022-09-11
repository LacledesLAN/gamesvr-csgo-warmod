# escape=`

FROM lacledeslan/gamesvr-csgo-warmod:latest

HEALTHCHECK NONE

ARG BUILDNODE="unspecified"
ARG SOURCE_COMMIT

LABEL maintainer="Laclede's LAN <contact @lacledeslan.com>" `
      com.lacledeslan.build-node=$BUILDNODE `
      org.label-schema.schema-version="1.0" `
      org.label-schema.url="https://github.com/LacledesLAN/README.1ST" `
      org.label-schema.vcs-ref=$SOURCE_COMMIT `
      org.label-schema.vendor="Laclede's LAN" `
      org.label-schema.description="LL Counter-Strike GO Warmod Hasty Server" `
      org.label-schema.vcs-url="https://github.com/LacledesLAN/gamesvr-csgo-warmod"

#
# Begun, the hasty hacks have
#
RUN FILE="/app/csgo/cfg/gamemode_competitive_server.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "bot_difficulty 0" >> $FILE &&`
        echo "bot_quota 2" >> $FILE &&`
        echo "bot_zombie 1" >> $FILE &&`
        echo "mp_buytime 5" >> $FILE &&`
        echo "mp_c4timer 25" >> $FILE &&`
        echo "mp_defuser_allocation 2" >> $FILE &&`
        echo "mp_freezetime 5" >> $FILE &&`
        echo "mp_halftime_duration 8" >> $FILE &&`
        echo "mp_match_restart_delay 12" >> $FILE &&`
        echo "mp_maxrounds 4" >> $FILE &&`
        echo "mp_overtime_maxrounds 3" >> $FILE &&`
        echo "mp_win_panel_display_time 3" >> $FILE &&`
        echo "sv_cheats 1" >> $FILE &&`
        echo "wm_min_ready 1" >> $FILE

RUN FILE="/app/csgo/cfg/server.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "sv_cheats 1" >> $FILE

RUN FILE="/app/csgo/cfg/warmod/on_match_end.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "mp_win_panel_display_time 3" >> $FILE

RUN FILE="/app/csgo/cfg/warmod/ruleset_default.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "bot_zombie 1" >> $FILE &&`
        echo "mp_maxrounds 4" >> $FILE &&`
        echo "mp_overtime_maxrounds 3" >> $FILE

RUN FILE="/app/csgo/cfg/warmod/ruleset_global.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "sv_cheats 1" >> $FILE &&`
        echo "wm_min_ready 1" >> $FILE

RUN FILE="/app/csgo/cfg/warmod/ruleset_knife.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "bot_zombie 1" >> $FILE &&`
        echo "mp_maxrounds 4" >> $FILE &&`
        echo "mp_overtime_maxrounds 3" >> $FILE

RUN FILE="/app/csgo/cfg/warmod/ruleset_overtime.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "bot_zombie 1" >> $FILE &&`
        echo "mp_maxrounds 4" >> $FILE &&`
        echo "mp_overtime_maxrounds 3" >> $FILE

RUN FILE="/app/csgo/cfg/warmod/ruleset_playout.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "bot_zombie 1" >> $FILE &&`
        echo "mp_maxrounds 4" >> $FILE &&`
        echo "mp_overtime_maxrounds 3" >> $FILE

RUN FILE="/app/csgo/cfg/warmod/ruleset_warmup.cfg" &&`
        echo $'\n' >> "$FILE" &&`
        echo $'\n' >> "$FILE" &&`
        echo "mp_buytime 5" >> $FILE &&`
        echo "mp_freezetime 5" >> $FILE &&`
        echo "sv_cheats 1" >> $FILE

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
