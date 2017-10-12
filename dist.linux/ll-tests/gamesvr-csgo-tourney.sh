#!/bin/bash

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
logfile="$scriptdir/gamesvr-csgo-tourney.log"

echo $'\n\n{{ TESTING CSGO TOURNEY SERVER }}';

if [ -f "$scriptdir/../srcds_run" ]; then
    echo $'\tAttemping to run server for 60 seconds to capture output';
    command="$scriptdir/../srcds_run -game csgo +game_type 0 +game_mode 1 -console -usercon +map de_nuke +sv_lan 1"
    $command > "$logfile" 2>&1 &
    pid=$!
    sleep 60
    #kill $pid NOT NEEDED IN DOCKER BUT SHOULD BE FLUSHED OUT; WOULD ALLOW USAGE OUTSIDE CONAINTER CONTEXT
else
    #command="$scriptdir/../srcds_run -game csgo +game_type 0 +game_mode 1 -console -usercon +map de_nuke +sv_lan 1"
    echo "srcds_run not found!";
    echo "This script only works inside of the docker container";
    exit 1;
fi

#      ____                _           ______             __
#     / __ ) ___   ____ _ (_)____     /_  __/___   _____ / /_ _____
#    / __  |/ _ \ / __ `// // __ \     / /  / _ \ / ___// __// ___/
#   / /_/ //  __// /_/ // // / / /    / /  /  __/(__  )/ /_ (__  )
#  /_____/ \___/ \__, //_//_/ /_/    /_/   \___//____/ \__//____/
#               /____/

if ! grep -i -q "Server will auto-restart if there is a crash" "$logfile"; then
    echo $'\tFAIL: Server did start to execute';
    exit 1;
else
    echo $'\tPASS: Server started executing';
fi;

if grep -i -q "Server restart in 10 seconds" "$logfile"; then
    echo $'\tFAIL: Server is boot-looping';
    exit 1;
else
    echo $'\tPASS: Server is not boot looping';
fi;

if grep -i -q "Running the dedicated server as root" "$logfile"; then
    echo $'\tFAIL: Server ran under root account';
    exit 1;
else
    echo $'\tPASS: Server did not run under user root';
fi;

if ! grep -i -q "Game.dll loaded for \"Counter-Strike: Global Offensive\"" "$logfile"; then
    echo $'\tFAIL: Server did not load csgo';
    exit 1;
else
    echo $'\tPASS: Server loaded gametype csgo';
fi;

if ! grep -i -q "[SM/MM Information]" "$logfile"; then
    echo $'\tFAIL: Meta Mod and/or Source Mod are not loading';
    exit 1;
else
    echo $'\tPASS: MetaMod and Source Mod are loaded';
fi;

if ! grep -i -q "\[warmod.smx\] Current Map" "$logfile"; then
    echo $'\tFAIL: warmod is not bootstrapped';
    exit 1;
else
    echo $'\tPASS: warmod is bootstrapped';
fi;

if ! grep -i -q "Server is hibernating" "$logfile"; then
    echo $'\tFAIL: Server did not hibernate';
    exit 1;
else
    echo $'\tPASS: Server succesfully hibernated';
fi;

if ! grep -i -q "Server logging enabled." "$logfile"; then
    echo $'\tFAIL: Server logging is not enabled';
    exit 1;
else
    echo $'\tPASS: Server logging is enabled';
fi;

if ! grep -i -q "Server logging data to file logs/" "$logfile"; then
    echo $'\tFAIL: Server logging is not outputing to files';
    exit 1;
else
    echo $'\tPASS: Server logging is outputting to files';
fi;

if ! grep -i -q "WarMod \[BFG\] WarmUp Config Loaded" "$logfile"; then
    echo $'\tFAIL: WarMod is not loading configs';
    exit 1;
else
    echo $'\tPASS: WarMod loaded config files';
fi;

if ! grep -i -q "======================BEGIN SERVER STATUS======================" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS did not run';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS ran';
fi;

if grep -i -q "<Error>" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS reporting an error';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS not reporting errors';
fi;

if ! grep -i -q "\"Server Status-LL MOD\"" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS not finding plug in: Server Status';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS found plug in: Server Status';
fi;

if ! grep -i -q "\"\[BFG\] WarMod\"" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS not finding plug in: WarMod';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS found plug in: WarMod';
fi;

if ! grep -i -q "\"Log Connections - LL Mod\"" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS not finding plug in: LL Mod Log Connections';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS found plug in: LL Mod Log Connections';
fi;

if ! grep -i -q "\"Admin File Reader\"" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS not finding plug in: Admin File Reader';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS found plug in: Admin File Reader';
fi;

if ! grep -i -q "\"Basic Info Triggers\"" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS not finding plug in: Basic Info Triggers';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS found plug in: Basic Info Triggers';
fi;

if ! grep -i -q "\"Basic Comm Control\"" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS not finding plug in: Basic Comm Control';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS found plug in: Basic Comm Control';
fi;

if ! grep -i -q "\"Anti-Flood\"" "$logfile"; then
    echo $'\tFAIL: LL SERVER STATUS not finding plug in: Anti-Flood';
    exit 1;
else
    echo $'\tPASS: LL SERVER STATUS found plug in: Anti-Flood';
fi;

echo $'{{ ALL TESTS PASSED}}\n\n';

exit 0;
