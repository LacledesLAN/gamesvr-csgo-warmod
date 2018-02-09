#!/bin/bash

#!/bin/bash -i
declare LLCK_LOGFILE="/app/ll-tests/gamesvr-csgo-tourney.log";
declare LLCK_CMD="/app/srcds_run -game csgo +game_type 0 +game_mode 1 -console +map de_nuke -norestart -insercure +sv_lan 1";
declare LLCK_CMD_TIMEOUT=60;

: > $LLCK_LOGFILE
if [ ! -f $LLCK_LOGFILE ]; then
    echo 'Failed to create logfile: '"$LLCK_LOGFILE"'. Verify file system permissions.';
    exit 1;
fi;

# $1 -> text we want to find in the log file
# $2 -> description of why we want text to exist
function should_have() {
    if ! grep -i -q "$1" "$LLCK_LOGFILE"; then
        echo $'FAIL: '"$2";
        LLCK_HASFAILS=true;
    else
        echo $'PASS: '"$2";
    fi;
}

# $1 -> text we *don't* want to find in the log file
# $2 -> description of why we don't want text to exist
function should_lack() {
    if grep -i -q "$1" "$LLCK_LOGFILE"; then
        echo $'FAIL: '"$2";
        LLCK_HASFAILS=true;
    else
        echo $'PASS: '"$2";
    fi;
    return 0;
}

declare LLCK_HASFAILS=false;

echo $'\n\n[RUNNING APP FOR '"$LLCK_CMD_TIMEOUT SECONDS]";
echo $'Command: '"$LLCK_CMD";
echo "Running under $(id)";

SCREEN_RCFILE=$(mktemp);
echo "logfile $LLCK_LOGFILE" > "$SCREEN_RCFILE";

SCREEN_ID=LLCHECKS.$$.$RANDOM;
# shellcheck disable=SC2086
screen -c "$SCREEN_RCFILE" -m -d -L -S "$SCREEN_ID" $LLCK_CMD

SCREEN_PID="$(screen -ls | grep $SCREEN_ID | awk -F . '{print $1}' | awk '{print $1}')";
unset SCREEN_ID;

if [[ ! -z "${SCREEN_PID// }" ]]; then      # Make sure screen session isn't already terminated
    # shellcheck disable=SC2086
    while ps -p $SCREEN_PID > /dev/null; do
        if [ $LLCK_CMD_TIMEOUT -le 0 ]; then
            kill -9 -"$SCREEN_PID";
            echo "done.";
            break;
        fi;
        if (( LLCK_CMD_TIMEOUT % 5 == 0 )); then
            echo -n "$LLCK_CMD_TIMEOUT...";
        fi;
        (( LLCK_CMD_TIMEOUT-- ))
        sleep 1;
    done
    unset LLCK_CMD_TIMEOUT;
fi;

rm -f "$SCREEN_RCFILE"; unset SCREEN_RCFILE;

screen -wipe > /dev/null;

if [ -s $LLCK_LOGFILE ]; then               # Make sure log file isn't empty
    echo $'\n[LOGFILE OUTPUT]';
    cat $LLCK_LOGFILE;
else
    echo $'\n\nOUTPUT LOG IS EMPTY!\n\n';
    exit 1;
fi;

echo $'\n[RUNNING CHECKS ON LOGFILE]';

should_have 'Setting breakpad minidump AppID = 740' 'Sever started executing';
should_lack 'Server restart in 10 seconds' 'Server is not boot-looping';
should_lack 'Running the dedicated server as root' 'Server is not running under root';
should_have 'Game.dll loaded for "Counter-Strike: Global Offensive"' 'srcds_run loaded CSGO';
should_have '[SM/MM Information]' 'Meta Mod and Source Mod are both running';
should_have '\[warmod.smx\] Current Map' 'WarMod is bootstrapped';
should_have 'Server is hibernating' 'srcds_run succesfully hibernated';
should_have 'Server logging enabled.' 'Logging is enabled';
should_have 'Server logging data to file logs/' 'Server is logging to the logs directory';
should_have 'WarMod \[BFG\] WarmUp Config Loaded' 'WarMod loaded config properly';
should_have '======================BEGIN SERVER STATUS======================' 'LL status mod ran';
should_lack '<Error>' 'LL status mod reports no errors';
should_have 'Server Status-LL MOD' 'LL status mod reports itself';
should_have '\[BFG\] WarMod' 'LL status mod reports WarMod';
should_have 'Log Connections - LL Mod' 'LL status mod reports LL version of "log connections"';
should_have 'Admin File Reader' 'LL status mod reports admin file reader';
should_have 'Basic Info Triggers' 'LL status mod reports basic info triggers';
should_have 'Basic Comm Control' 'LL status mod reports basic comm control';
should_have 'Anti-Flood' "LL status mod reports anti-flood";
#should_lack 'Successfully updated gamedata file "' 'SourceMod is not self updating'
#should_lack 'SourceMod has been updated, please reload it or restart your server' 'SourceMod is not requesting restart'

echo $'\n\n[FINAL RESULT]';

if [ $LLCK_HASFAILS = true ]; then
    echo $'Checks have failures!\n\n\n';
    exit 1;
fi;

echo $'All checks passed!\n\n\n';
exit 0;
