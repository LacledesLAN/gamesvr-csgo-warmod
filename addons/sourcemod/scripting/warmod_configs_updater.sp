#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <updater>

/* Plugin info */
#define UPDATE_URL				"http://warmod.bitbucket.org/wm_cfg_updater.txt"
#define WM_VERSION				"0.3.3.7"
#define WM_DESCRIPTION			"Updates Warmod configs with updatecfgs command"

public Plugin:myinfo = {
	name = "[BFG] WarMod Config Updater",
	author = "Versatile_BFG",
	description = WM_DESCRIPTION,
	version = WM_VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	//auto update
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	RegAdminCmd("updatecfgs", UpdateCFGs, ADMFLAG_CUSTOM1, "Updates configs with the latest format");
	
	CreateConVar("wm_cfg_version_notify", WM_VERSION, WM_DESCRIPTION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/* Config Updating */

public Action:UpdateCFGs(client, args)
{
	if (LibraryExists("warmod"))
	{
		UpdateRuleSet_Global();
	}
	else
	{
		LogError("[WarMod Config Updater] Plug-in Warmod.smx required to create updated configs");
	}
	return Plugin_Handled;
}

static UpdateRuleSet_Global()
{
	ServerCommand("exec warmod/ruleset_global.cfg");
	
	decl String:dirName[PLATFORM_MAX_PATH];
	Format(dirName, sizeof(dirName), "cfg/warmod");
	if (!DirExists(dirName))
		CreateDirectory(dirName, 751);
	
	decl String:cfgFile[PLATFORM_MAX_PATH];
	decl String:convarString[PLATFORM_MAX_PATH];
	Format(cfgFile, sizeof(cfgFile), "cfg/warmod/ruleset_global.cfg");
	
	DeleteFile(cfgFile);
	
	
	new Handle:file = OpenFile(cfgFile, "w");

	WriteFileLine(file, "// WarMod [BFG] - Global Ruleset Config");
	WriteFileLine(file, "// Updated via [BFG] WarMod Config Updater for Warmod v%s", WM_VERSION);
	WriteFileLine(file, "// This config is executed by all other rulesets");
	WriteFileLine(file, "// It holds the majority of commands, so that each ruleset can use a base configuration");
	WriteFileLine(file, "//Remove prac commands");
	WriteFileLine(file, "");
	WriteFileLine(file, "sv_infinite_ammo				\"0\"	//Players active weapon will never run out of ammo. If set to 2 then player has infinite total ammo but still has to reload the weapon");
	WriteFileLine(file, "sv_showimpacts				\"0\"	//Shows client (red) and server (blue) bullet impact point (1=both, 2=client-only, 3=server-only)");
	WriteFileLine(file, "sv_cheats				\"0\"	//Allow cheats on server (cheat console commands not hacks)");
	WriteFileLine(file, "");
	WriteFileLine(file, "// WarMod Configs");
	WriteFileLine(file, "");
	GetConVarString(FindConVar("wm_reset_config"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_reset_config				\"%s\"	//Sets the config to load at the end/reset of a match", convarString);
	WriteFileLine(file, "");
	WriteFileLine(file, "// WarMod Multiplayer");
	WriteFileLine(file, "");
	WriteFileLine(file, "wm_active				\"%i\"	//Enable or disable WarMod as active", GetConVarInt(FindConVar("wm_active")));
	WriteFileLine(file, "wm_max_players				\"%i\"	//Sets the maximum players allowed on both teams combined, others will be forced to spectator (0 = unlimited)", GetConVarInt(FindConVar("wm_max_players")));
	WriteFileLine(file, "wm_round_money				\"%i\"	//Enable or disable a client's team mates money to be displayed at the start of a round (to him only)", GetConVarInt(FindConVar("wm_round_money")));
	WriteFileLine(file, "wm_min_ready				\"%i\"	//Sets the minimum required ready players to Live on 3", GetConVarInt(FindConVar("wm_min_ready")));
	WriteFileLine(file, "wm_ingame_scores			\"%i\"	//Enable or disable ingame scores to be showed at the end of each round", GetConVarInt(FindConVar("wm_ingame_scores")));
	WriteFileLine(file, "wm_lock_teams				\"%i\"	//Enable or disable locked teams when a match is running", GetConVarInt(FindConVar("wm_lock_teams")));
	WriteFileLine(file, "tv_enable					\"%i\"	//GOTV enabled?", GetConVarInt(FindConVar("tv_enable")));
	WriteFileLine(file, "wm_auto_record				\"%i\"	//Enable or disable auto SourceTV demo record on Live on 3", GetConVarInt(FindConVar("wm_auto_record")));
	WriteFileLine(file, "");
	WriteFileLine(file, "//WarMod Knife");
	WriteFileLine(file, "wm_auto_knife				\"%i\"	//Enable or disable the knife round before going live", GetConVarInt(FindConVar("wm_auto_knife")));
	WriteFileLine(file, "wm_knife_hegrenade			\"%i\"	//Enable or disable giving a player a hegrenade on Knife on 3", GetConVarInt(FindConVar("wm_knife_hegrenade")));
	WriteFileLine(file, "wm_knife_flashbang			\"%i\"	//Sets how many flashbangs to give a player on Knife on 3", GetConVarInt(FindConVar("wm_knife_flashbang")));
	WriteFileLine(file, "wm_knife_smokegrenade			\"%i\"	//Enable or disable giving a player a smokegrenade on Knife on 3", GetConVarInt(FindConVar("wm_knife_smokegrenade")));
	WriteFileLine(file, "wm_knife_zeus				\"%i\"	//Enable or disable giving a player a zeus on Knife on 3", GetConVarInt(FindConVar("wm_knife_zeus")));
	WriteFileLine(file, "wm_knife_armor				\"%i\"	//Enable or disable giving a player Armor on Knife on 3", GetConVarInt(FindConVar("wm_knife_armor")));
	WriteFileLine(file, "wm_knife_helmet				\"%i\"	//Enable or disable giving a player a Helmet on Knife on 3 [requires armor active]", GetConVarInt(FindConVar("wm_knife_helmet")));
	WriteFileLine(file, "");
	WriteFileLine(file, "//WarMod Pause");
	WriteFileLine(file, "");
	WriteFileLine(file, "sv_pausable				\"%i\"	//Is the server pausable.", GetConVarInt(FindConVar("sv_pausable")));
	WriteFileLine(file, "wm_pause_confirm			\"%i\"	//Wait for other team to confirm pause: 0 = off, 1 = on", GetConVarInt(FindConVar("wm_pause_confirm")));
	WriteFileLine(file, "wm_unpause_confirm			\"%i\"	//Wait for other team to confirm unpause: 0 = off, 1 = on", GetConVarInt(FindConVar("wm_unpause_confirm")));
	WriteFileLine(file, "wm_auto_unpause				\"%i\"	//Sets auto unpause: 0 = off, 1 = on", GetConVarInt(FindConVar("wm_auto_unpause")));
	WriteFileLine(file, "wm_auto_unpause_delay			\"%i\"	//Sets the seconds to wait before auto unpause", GetConVarInt(FindConVar("wm_auto_unpause_delay")));
	WriteFileLine(file, "wm_pause_limit				\"%i\"	//Sets max pause count per team per half", GetConVarInt(FindConVar("wm_pause_limit")));
	WriteFileLine(file, "");
	WriteFileLine(file, "// WarMod Warmup");
	WriteFileLine(file, "wm_warmup_respawn			\"%i\"	//Enable or disable the respawning of players in warmup", GetConVarInt(FindConVar("wm_warmup_respawn")));
	WriteFileLine(file, "wm_block_warm_up_grenades		\"%i\"	//Enable or disable grenade blocking in warmup", GetConVarInt(FindConVar("wm_block_warm_up_grenades")));
	WriteFileLine(file, "");
	WriteFileLine(file, "// WarMod Misc");
	WriteFileLine(file, "");
	WriteFileLine(file, "wm_show_info				\"%i\"	//Enable or disable the display of the Ready System to players", GetConVarInt(FindConVar("wm_show_info")));
	WriteFileLine(file, "wm_rcon_only				\"%i\"	//Enable or disable admin commands to be only executed via RCON or console", GetConVarInt(FindConVar("wm_rcon_only")));
	WriteFileLine(file, "wm_require_names			\"%i\"	//Enable or disable the requirement of set team names for lo3", GetConVarInt(FindConVar("wm_require_names")));
	WriteFileLine(file, "wm_random_team_names			\"%i\"	//Enable or disable the random set of a pro team name for the match", GetConVarInt(FindConVar("wm_random_team_names")));
	WriteFileLine(file, "wm_auto_ready				\"%i\"	//Enable or disable the ready system being automatically enabled on map change", GetConVarInt(FindConVar("wm_auto_ready")));
	WriteFileLine(file, "");
	WriteFileLine(file, "// WarMod Ban");
	WriteFileLine(file, "");
	WriteFileLine(file, "wm_ban_on_disconnect		\"%i\"	//Enable or disable players banned on disconnect if match is live", GetConVarInt(FindConVar("wm_ban_on_disconnect")));
	WriteFileLine(file, "");
	WriteFileLine(file, "// Warmod Veto");
	WriteFileLine(file, "");
	WriteFileLine(file, "wm_veto					\"%i\"	//Veto Style: 0 = off, 1 = Bo1, 2 = Bo2, 3 = Bo3", GetConVarInt(FindConVar("wm_veto")));
	WriteFileLine(file, "wm_veto_bo3				\"%i\"	//Veto Style: 0 = Normal, 1 = New", GetConVarInt(FindConVar("wm_veto_bo3")));
	WriteFileLine(file, "wm_veto_random				\"%i\"	//After the vetoing is done, will a map be picked at random?", GetConVarInt(FindConVar("wm_veto_random")));
	GetConVarString(FindConVar("wm_pugsetup_maplist_file"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_pugsetup_maplist_file			\"%s\"	//Maplist to read from. The file path is relative to the sourcemod directory.", convarString);
	WriteFileLine(file, "wm_pugsetup_randomize_maps		\"%i\"	//When maps are shown in the map vote/veto, should their order be randomized?", GetConVarInt(FindConVar("wm_pugsetup_randomize_maps")));
	WriteFileLine(file, "");
	WriteFileLine(file, "exec gamemode_competitive_server.cfg", false);// no newline at the end
	CloseHandle(file);
	
	UpdateRuleSet_MR15();
}

static UpdateRuleSet_MR15()
{
	ServerCommand("exec warmod/ruleset_mr15.cfg");
	decl String:cfgFile[PLATFORM_MAX_PATH];
	Format(cfgFile, sizeof(cfgFile), "cfg/warmod/ruleset_mr15.cfg");
	
	DeleteFile(cfgFile);
	new Handle:file = OpenFile(cfgFile, "w");

	WriteFileLine(file, "// WarMod [BFG] - MR15 Ruleset Config");
	WriteFileLine(file, "// Updated via [BFG] WarMod Config Updater for Warmod v%s", WM_VERSION);
	WriteFileLine(file, "// Exec default config");
	WriteFileLine(file, "exec warmod/ruleset_global.cfg");
	WriteFileLine(file, "");
	WriteFileLine(file, "// Change MR15 commands");
	WriteFileLine(file, "wm_match_config		\"warmod/ruleset_mr15.cfg\"		//Sets the match config to load on Live on 3");
	WriteFileLine(file, "mp_maxrounds		\"30\"		//max number of rounds to play before server changes maps");
	WriteFileLine(file, "mp_overtime_enable		\"0\"		//If a match ends in a tie, use overtime rules to determine winner");
	WriteFileLine(file, "mp_overtime_maxrounds		\"%i\"		//When overtime is enabled play additional rounds to determine winner", GetConVarInt(FindConVar("mp_overtime_maxrounds")));
	WriteFileLine(file, "mp_overtime_startmoney		\"%i\"		//Money assigned to all players at start of every overtime half", GetConVarInt(FindConVar("mp_overtime_startmoney")));
	WriteFileLine(file, "mp_startmoney		\"800\"			//amount of money each player gets when they reset");
	WriteFileLine(file, "mp_roundtime		\"1.75\"		//How many minutes each round takes");
	WriteFileLine(file, "mp_roundtime_defuse		\"1.75\"		//How many minutes each round of Bomb Defuse takes. If 0 then use mp_roundtime instead");
	WriteFileLine(file, "wm_round_money		\"1\"		//Enable or disable a client's team mates money to be displayed at the start of a round (to him only)");
	WriteFileLine(file, "");
	WriteFileLine(file, "say WarMod [BFG] MR15 Match Config Loaded", false); // no newline at the end
	CloseHandle(file);
	
	UpdateRuleSet_MR15_OT();
}

static UpdateRuleSet_MR15_OT()
{
	ServerCommand("exec warmod/ruleset_mr15_ot.cfg");
	
	decl String:cfgFile[PLATFORM_MAX_PATH];
	Format(cfgFile, sizeof(cfgFile), "cfg/warmod/ruleset_mr15_ot.cfg");
	
	DeleteFile(cfgFile);
	new Handle:file = OpenFile(cfgFile, "w");

	WriteFileLine(file, "// WarMod [BFG] - MR15 OT Ruleset Config");
	WriteFileLine(file, "// Updated via [BFG] WarMod Config Updater for Warmod v%s", WM_VERSION);
	WriteFileLine(file, "// Exec default config");
	WriteFileLine(file, "exec warmod/ruleset_global.cfg");
	WriteFileLine(file, "");
	WriteFileLine(file, "// Change MR15 commands");
	WriteFileLine(file, "wm_match_config		\"warmod/ruleset_mr15_ot.cfg\"		//Sets the match config to load on Live on 3");
	WriteFileLine(file, "mp_maxrounds		\"30\"		//max number of rounds to play before server changes maps");
	WriteFileLine(file, "mp_match_can_clinch		\"1\"		//Can a team clinch and end the match by being so far ahead that the other team has no way to catching up?");
	WriteFileLine(file, "mp_overtime_enable		\"1\"		//If a match ends in a tie, use overtime rules to determine winner");
	WriteFileLine(file, "mp_overtime_maxrounds		\"%i\"		//When overtime is enabled play additional rounds to determine winner", GetConVarInt(FindConVar("mp_overtime_maxrounds")));
	WriteFileLine(file, "mp_overtime_startmoney 		\"%i\"		//Money assigned to all players at start of every overtime half", GetConVarInt(FindConVar("mp_overtime_startmoney")));
	WriteFileLine(file, "mp_startmoney		\"800\"		//amount of money each player gets when they reset");
	WriteFileLine(file, "mp_roundtime		\"1.75\"		//How many minutes each round takes");
	WriteFileLine(file, "mp_roundtime_defuse		\"1.75\"		//How many minutes each round of Bomb Defuse takes. If 0 then use mp_roundtime instead");
	WriteFileLine(file, "wm_round_money		\"1\"		//Enable or disable a client's team mates money to be displayed at the start of a round (to him only)");
	WriteFileLine(file, "");
	WriteFileLine(file, "say WarMod [BFG] MR15 With OverTime Config Loaded", false);// no newline at the end
	CloseHandle(file);
	
	UpdateRuleSet_MR12();
}

static UpdateRuleSet_MR12()
{
	ServerCommand("exec warmod/ruleset_mr12.cfg");
	
	decl String:cfgFile[PLATFORM_MAX_PATH];
	Format(cfgFile, sizeof(cfgFile), "cfg/warmod/ruleset_mr12.cfg");
	
	DeleteFile(cfgFile);
	new Handle:file = OpenFile(cfgFile, "w");

	WriteFileLine(file, "// WarMod [BFG] - MR12 Ruleset Config");
	WriteFileLine(file, "// Updated via [BFG] WarMod Config Updater for Warmod v%s", WM_VERSION);
	WriteFileLine(file, "// Exec default config");
	WriteFileLine(file, "exec warmod/ruleset_global.cfg");
	WriteFileLine(file, "");
	WriteFileLine(file, "// Change MR15 commands");
	WriteFileLine(file, "wm_match_config		\"warmod/ruleset_mr12.cfg\"		//Sets the match config to load on Live on 3");
	WriteFileLine(file, "mp_maxrounds		\"24\"		//max number of rounds to play before server changes maps");
	WriteFileLine(file, "mp_overtime_enable		\"%i\"		//If a match ends in a tie, use overtime rules to determine winner", GetConVarInt(FindConVar("mp_overtime_enable")));
	WriteFileLine(file, "mp_overtime_maxrounds		\"%i\"		//When overtime is enabled play additional rounds to determine winner", GetConVarInt(FindConVar("mp_overtime_maxrounds")));
	WriteFileLine(file, "mp_overtime_startmoney		\"%i\"		//Money assigned to all players at start of every overtime half", GetConVarInt(FindConVar("mp_overtime_startmoney")));
	WriteFileLine(file, "mp_startmoney		\"16000\"		//amount of money each player gets when they reset");
	WriteFileLine(file, "mp_roundtime		\"1.34\"		//How many minutes each round takes");
	WriteFileLine(file, "mp_roundtime_defuse		\"1.34\"		//How many minutes each round of Bomb Defuse takes. If 0 then use mp_roundtime instead");
	WriteFileLine(file, "wm_round_money		\"1\"		//Enable or disable a client's team mates money to be displayed at the start of a round (to him only)");
	WriteFileLine(file, "");
	WriteFileLine(file, "say WarMod [BFG] MR12 Config Loaded", false);// no newline at the end
	CloseHandle(file);
	
	UpdateRuleSet_MR9();
}

static UpdateRuleSet_MR9()
{
	ServerCommand("exec warmod/ruleset_mr9.cfg");
	
	decl String:cfgFile[PLATFORM_MAX_PATH];
	Format(cfgFile, sizeof(cfgFile), "cfg/warmod/ruleset_mr9.cfg");
	
	DeleteFile(cfgFile);
	new Handle:file = OpenFile(cfgFile, "w");

	WriteFileLine(file, "// WarMod [BFG] - MR9 Ruleset Config");
	WriteFileLine(file, "// Updated via [BFG] WarMod Config Updater for Warmod v%s", WM_VERSION);
	WriteFileLine(file, "// Exec default config");
	WriteFileLine(file, "exec warmod/ruleset_global.cfg");
	WriteFileLine(file, "");
	WriteFileLine(file, "// Change MR15 commands");
	WriteFileLine(file, "wm_match_config		\"warmod/ruleset_mr9.cfg\"		//Sets the match config to load on Live on 3");
	WriteFileLine(file, "mp_maxrounds		\"18\"		//max number of rounds to play before server changes maps");
	WriteFileLine(file, "mp_overtime_enable		\"%i\"		//If a match ends in a tie, use overtime rules to determine winner", GetConVarInt(FindConVar("mp_overtime_enable")));
	WriteFileLine(file, "mp_overtime_maxrounds		\"%i\"		//When overtime is enabled play additional rounds to determine winner", GetConVarInt(FindConVar("mp_overtime_maxrounds")));
	WriteFileLine(file, "mp_overtime_startmoney		\"%i\"		//Money assigned to all players at start of every overtime half", GetConVarInt(FindConVar("mp_overtime_startmoney")));
	WriteFileLine(file, "mp_startmoney		\"16000\"		//amount of money each player gets when they reset");
	WriteFileLine(file, "mp_roundtime		\"1.34\"		//How many minutes each round takes");
	WriteFileLine(file, "mp_roundtime_defuse		\"1.34\"		//How many minutes each round of Bomb Defuse takes. If 0 then use mp_roundtime instead");
	WriteFileLine(file, "wm_round_money		\"1\"		//Enable or disable a client's team mates money to be displayed at the start of a round (to him only)");
	WriteFileLine(file, "");
	WriteFileLine(file, "say WarMod [BFG] MR9 Config Loaded", false);// no newline at the end
	CloseHandle(file);
	
	UpdateOn_Map_Load();
}

static UpdateOn_Map_Load()
{
	ServerCommand("exec warmod/on_map_load.cfg");
	
	decl String:cfgFile[PLATFORM_MAX_PATH];
	decl String:convarString[PLATFORM_MAX_PATH];
	Format(cfgFile, sizeof(cfgFile), "cfg/warmod/on_map_load.cfg");
	DeleteFile(cfgFile);
	new Handle:file = OpenFile(cfgFile, "w");

	WriteFileLine(file, "// WarMod [BFG] - On Map Load Config");
	WriteFileLine(file, "// Updated via [BFG] WarMod Config Updater for Warmod v%s", WM_VERSION);
	WriteFileLine(file, "// This config file is executed on every map change, including when the server first starts");
	WriteFileLine(file, "// Note: Plugins have been loaded by now");
	WriteFileLine(file, "");
	WriteFileLine(file, "//WarMod Updater");
	WriteFileLine(file, "");
	if (LibraryExists("updater"))
	{
		WriteFileLine(file, "sm_updater 			\"%i\"		//Determines update functionality. (1 = Notify, 2 = Download, 3 = Include source code)", GetConVarInt(FindConVar("sm_updater")));
	}
	else
	{
		WriteFileLine(file, "sm_updater 			\"2\"		//Determines update functionality. (1 = Notify, 2 = Download, 3 = Include source code)");
	}
	WriteFileLine(file, "");
	WriteFileLine(file, "//WarMod");
	WriteFileLine(file, "wm_warmod_safemode		\"%i\"		//This disables features that usually break on a CS:GO update", GetConVarInt(FindConVar("sm_deadtalk")));
	GetConVarString(FindConVar("wm_match_config"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_match_config			\"%s\"	//Sets the match config to load on Live on 3", convarString);
	WriteFileLine(file, "");
	WriteFileLine(file, "// WarMod Stats");
	WriteFileLine(file, "");
	GetConVarString(FindConVar("wm_save_dir"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_save_dir			\"%s\"	//Directory to store SourceTV demos and WarMod logs", convarString);
	WriteFileLine(file, "wm_prefix_logs			\"%i\"		//Enable or disable the prefixing of \"_\" to uncompleted match SourceTV demos and WarMod logs", GetConVarInt(FindConVar("wm_prefix_logs")));
	WriteFileLine(file, "wm_stats_enabled			\"%i\"		//Enable or disable statistical logging", GetConVarInt(FindConVar("wm_stats_enabled")));
	WriteFileLine(file, "wm_stats_method			\"%i\"		//Sets the stats logging method: 0 = UDP stream/server logs, 1 = WarMod logs, 2 = both", GetConVarInt(FindConVar("wm_stats_method")));
	WriteFileLine(file, "wm_stats_trace			\"%i\"		//Enable or disable updating all player positions, every wm_stats_trace_delay seconds", GetConVarInt(FindConVar("wm_stats_trace")));
	WriteFileLine(file, "wm_stats_trace_delay		\"%i\"		//The ammount of time between sending player position updates", GetConVarInt(FindConVar("wm_stats_trace_delay")));
	GetConVarString(FindConVar("mp_teamname_1"), convarString, sizeof(convarString));
	WriteFileLine(file, "mp_teamname_1 			\"%s\"	//A non-empty string overrides the first team's name", convarString);
	GetConVarString(FindConVar("mp_teamname_2"), convarString, sizeof(convarString));
	WriteFileLine(file, "mp_teamname_2 			\"%s\"		//A non-empty string overrides the second team's name", convarString);
	GetConVarString(FindConVar("mp_teamlogo_1"), convarString, sizeof(convarString));
	WriteFileLine(file, "mp_teamlogo_1 			\"%s\"		//Enter a team's shorthand image name to display their logo", convarString);
	GetConVarString(FindConVar("mp_teamlogo_2"), convarString, sizeof(convarString));
	WriteFileLine(file, "mp_teamlogo_2 			\"%s\"		//Enter a team's shorthand image name to display their logo", convarString);
	GetConVarString(FindConVar("wm_competition"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_competition			\"%s\"	//Name of host for a competition. eg. ESEA, Cybergamer, CEVO, ESL", convarString);
	GetConVarString(FindConVar("wm_event"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_event			\"%s\"		//Name of event. eg. Season #, ODC #, Ladder", convarString);
	GetConVarString(FindConVar("wm_chat_prefix"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_chat_prefix			\"%s\"	//Change the chat prefix. Default is WarMod_BFG", convarString);
	WriteFileLine(file, "");
	if (LibraryExists("warmod_stats"))
	{
		WriteFileLine(file, "// Stats Site");
		WriteFileLine(file, "");
		GetConVarString(FindConVar("wm_site_location"), convarString, sizeof(convarString));
		WriteFileLine(file, "wm_site_location			\"%s\"		//Location of where the demo is uploaded for download. Do not have '/' at end of string. eg. www.warmod.com", convarString);
		GetConVarString(FindConVar("wm_demo_location"), convarString, sizeof(convarString));
		WriteFileLine(file, "wm_demo_location			\"%s\"		//Location of where the demo is uploaded for download. eg. www.warmod.com/demos/", convarString);
		GetConVarString(FindConVar("wm_forums_location"), convarString, sizeof(convarString));
		WriteFileLine(file, "wm_forums_location			\"%s\"		//Location of where the community forums are. eg. www.warmod.com/forums/", convarString);
		WriteFileLine(file, "");
	}
	WriteFileLine(file, "// FTP Upload");
	WriteFileLine(file, "");
	WriteFileLine(file, "wm_autodemoupload_enable				\"%i\"			//Automatically upload demos when finished recording.", GetConVarInt(FindConVar("wm_autodemoupload_enable")));
	WriteFileLine(file, "wm_autodemoupload_bzip2				\"%i\"			//Compression level. If set > 0 demos will be compressed before uploading. (Requires bzip2 extension.)", GetConVarInt(FindConVar("wm_autodemoupload_bzip2")));
	WriteFileLine(file, "wm_autodemoupload_delete				\"%i\"			//Delete the demo (and the bz2) if upload was successful.", GetConVarInt(FindConVar("wm_autodemoupload_delete")));
	GetConVarString(FindConVar("wm_autodemoupload_ftptargetdemo"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_autodemoupload_ftptargetdemo			\"%s\"		//The ftp target to use for demo uploads.", convarString);
	GetConVarString(FindConVar("wm_autodemoupload_ftptargetlog"), convarString, sizeof(convarString));
	WriteFileLine(file, "wm_autodemoupload_ftptargetlog			\"%s\"		//The ftp target to use for log uploads.", convarString);
	if (LibraryExists("warmod_stats"))
	{
		GetConVarString(FindConVar("wm_autodemoupload_ftptargetstats"), convarString, sizeof(convarString));
		WriteFileLine(file, "wm_autodemoupload_ftptargetstats			\"%s\"		//The ftp target to use for stats site uploads.", convarString);
	}
	WriteFileLine(file, "wm_autodemoupload_completed			\"%i\"			//Only upload demos when match is completed.", GetConVarInt(FindConVar("wm_autodemoupload_completed")));
	WriteFileLine(file, "");
	WriteFileLine(file, "// Voice Communications");
	WriteFileLine(file, "");
	if (LibraryExists("basecomm"))
	{
		WriteFileLine(file, "sm_deadtalk					\"%i\"			//Controls how dead communicate. 0 - Off. 1 - Dead players ignore teams. 2 - Dead players talk to living teammates.", GetConVarInt(FindConVar("sm_deadtalk")));
	}
	else
	{
		WriteFileLine(file, "sm_deadtalk					\"0\"			//Controls how dead communicate. 0 - Off. 1 - Dead players ignore teams. 2 - Dead players talk to living teammates.");
	}
	WriteFileLine(file, "");
	WriteFileLine(file, "exec warmod/ruleset_warmup.cfg", false);// no newline at the end
	CloseHandle(file);
}