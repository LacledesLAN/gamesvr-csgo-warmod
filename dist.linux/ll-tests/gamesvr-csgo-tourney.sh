#!/bin/bash

if [ -z "$PS1" ]; then
    echo This shell is not interactive
else
    echo This shell is interactive
fi

printenv;

echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=";
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-";

declare LLTEST_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare LLTEST_RESULTS="";
declare LLTEST_HASFAILS=false;
declare LLTEST_LOGFILE="$LLTEST_SCRIPTDIR/gamesvr-csgo-tourney.log";
declare LLTEST_COMMAND="$LLTEST_SCRIPTDIR/../srcds_run -game csgo +game_type 0 +game_mode 1 -console +map de_nuke";


# $1 -> text you want to find
# $2 -> description of why we want text to exist
function should_have() {
    if ! grep -i -q "$1" "$LLTEST_LOGFILE"; then
        LLTEST_RESULTS+=$'\nFAIL: '"$2";
        LLTEST_HASFAILS=true;
    else
        LLTEST_RESULTS+=$'\nPASS: '"$2";
    fi;
}


# $1 -> text you don't want to find
# $2 -> description of why we don't want text to exist
function should_lack() {
    if grep -i -q "$1" "$LLTEST_LOGFILE"; then
        LLTEST_RESULTS+=$'\n FAIL: '"$2";
        LLTEST_HASFAILS=true;
    else
        LLTEST_RESULTS+=$'\nPASS: '"$2";
    fi;
    return 0;
}


if [ -f "$LLTEST_SCRIPTDIR/../srcds_run" ]; then
    echo "###################################################################";
    echo $'Attemping to run server for 60 seconds to capture output';
    echo $'Command: '"$LLTEST_COMMAND";
    echo "Running as $(id)";
    echo "###################################################################";
    $LLTEST_COMMAND > "$LLTEST_LOGFILE" 2>&1 &
    pid=$!
    #kill pid NOT NEEDED IN DOCKER BUT SHOULD BE FLUSHED OUT; WOULD ALLOW USAGE OUTSIDE CONAINTER CONTEXT
    sleep 60
else
    echo "srcds_run not found!";
    echo "Test script currently only works inside of the docker container";
    exit 1;
fi;


should_have 'Server will auto-restart if there is a crash' 'Sever started executing';
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

echo "###################################################################";
echo "                          CAPTURED OUTPUT                          ";
echo "###################################################################";

cat "$LLTEST_LOGFILE";
echo $'\n';

echo "##################################################################";
echo "                           TEST RESULTS                           "
echo "##################################################################";

echo "$LLTEST_RESULTS";
echo $'\n';

if [ $LLTEST_HASFAILS = true ]; then
    echo $'\nTests has errors!';
    exit 1;
fi;

echo 'All tests passed';
exit 0;