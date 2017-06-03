#pragma semicolon 1
//Comment out this line if you want to use this on something other than tf2
#define ADVERT_SOURCE2009

#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <steamtools>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN
#if defined ADVERT_SOURCE2009
#include <morecolors_ads>
#else
#include <colors_ads>
#endif
#include <regex>
#include <smlib>
#include <extended_adverts>

#define PLUGIN_VERSION "1.2.9"

#if defined ADVERT_SOURCE2009
#define UPDATE_URL "http://dl.dropbox.com/u/83581539/update-tf2.txt"
#else
#define UPDATE_URL "http://dl.dropbox.com/u/83581539/update-nontf2.txt"
#endif

new Handle:g_hPluginEnabled = INVALID_HANDLE;
new Handle:g_hAdvertDelay = INVALID_HANDLE;
new Handle:g_hAdvertFile = INVALID_HANDLE;
new Handle:g_hAdvertisements = INVALID_HANDLE;
new Handle:g_hAdvertTimer = INVALID_HANDLE;
//new Handle:g_hDynamicTagRegex = INVALID_HANDLE;
new Handle:g_hExitPanel = INVALID_HANDLE;
new Handle:g_hExtraTopColorsPath = INVALID_HANDLE;
#if defined ADVERT_SOURCE2009
new Handle:g_hExtraChatColorsPath = INVALID_HANDLE;
new String:g_strExtraChatColorsPath[PLATFORM_MAX_PATH];
#endif

new Handle:g_hCenterAd[MAXPLAYERS + 1];

new Handle:g_hTopColorTrie = INVALID_HANDLE;

new Handle:g_hForwardPreReplace,
	Handle:g_hForwardPreClientReplace,
	Handle:g_hForwardPostAdvert;
#if defined ADVERT_SOURCE2009	
new	Handle:g_hForwardPreAddChatColor,
	Handle:g_hForwardPostAddChatColor;
#endif
new	Handle:g_hForwardPreAddTopColor,
	Handle:g_hForwardPostAddTopColor,
	Handle:g_hForwardPreAddAdvert,
	Handle:g_hForwardPostAddAdvert,
	Handle:g_hForwardPreDeleteAdvert,
	Handle:g_hForwardPostDeleteAdvert;

new bool:g_bPluginEnabled,
	bool:g_bExitPanel,
	bool:g_bUseSteamTools;

new Float:g_fAdvertDelay;


new bool:g_bTickrate = true;
new g_iTickrate;
new g_iFrames = 0;
new Float:g_fTime;
new String:g_strConfigPath[PLATFORM_MAX_PATH];
new String:g_strExtraTopColorsPath[PLATFORM_MAX_PATH];

static const String:g_tagRawText[11][24] = 
{
	"",
	"{IP}",
	"{FULL_IP}",
	"{PORT}",
	"{CURRENTMAP}",
	"{NEXTMAP}",
	"{TICKRATE}",
	"{SERVER_TIME}",
	"{SERVER_TIME24}",
	"{SERVER_DATE}",
	"{TIMELEFT}"
};

static const String:g_clientRawText[7][32] =
{
	"",
	"{CLIENT_NAME}",
	"{CLIENT_STEAMID}",
	"{CLIENT_IP}",
	"{CLIENT_FULLIP}",
	"{CLIENT_CONNECTION_TIME}",
	"{CLIENT_MAPTIME}"
};

static const String:g_strConVarBoolText[2][5] =
{
	"OFF",
	"ON"
};

static const String:g_strKeyValueKeyList[4][8] =
{
	"type",
	"text",
	"flags",
	"noflags"
};

public Plugin:myinfo = 
{
	name        = "Extended Advertisements",
	author      = "Mini",
	description = "Extended advertisement system for Source 2009 Games' new color abilities for developers",
	version     = PLUGIN_VERSION,
	url         = "http://forums.alliedmods.net/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("adv_adverts");
	MarkNativeAsOptional("Steam_GetPublicIP");
	MarkNativeAsOptional("Updater_AddPlugin");
	MarkNativeAsOptional("Updater_RemovePlugin");
	CreateNative("AddExtraTopColor", Native_AddTopColorToTrie);
	CreateNative("Client_CanViewAds", Native_CanViewAdvert);
	CreateNative("AddAdvert", Native_AddAdvert);
	CreateNative("ShowAdvert", Native_ShowAdvert);
	CreateNative("ReloadAdverts", Native_ReloadAds);
	CreateNative("DeleteAdvert", Native_DeleteAdvert);
	CreateNative("AdvertExists", Native_AdvertExists);
	#if defined ADVERT_SOURCE2009
	CreateNative("AddExtraChatColor", Native_AddChatColorToTrie);
	#endif
	return APLRes_Success;
}

public Native_AdvertExists(Handle:plugin, numParams)
{
	new ml = 128;
	decl String:id[ml];
	GetNativeString(1, id, ml);
	KvSavePosition(g_hAdvertisements);
	if (KvJumpToKey(g_hAdvertisements, id))
	{
		KvRewind(g_hAdvertisements);
		return true;
	}
	return false;
}

public Native_DeleteAdvert(Handle:plugin, numParams)
{
	new ml = 128;
	decl String:id[ml];
	GetNativeString(1, id, ml);
	
	new Action:returnVal = Plugin_Continue;
	Call_StartForward(g_hForwardPreDeleteAdvert);
	Call_PushStringEx(id, ml, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(ml);
	Call_Finish(_:returnVal);
	
	if (returnVal != Plugin_Continue)
		return false;
	
	KvSavePosition(g_hAdvertisements);
	if (KvJumpToKey(g_hAdvertisements, id))
	{
		KvDeleteThis(g_hAdvertisements);
		KvRewind(g_hAdvertisements);
		Call_StartForward(g_hForwardPostDeleteAdvert);
		Call_PushString(id);
		Call_Finish();
		return true;
	}
	return false;
}
public Native_ReloadAds(Handle:plugin, numParams)
{
	new bool:ads = GetNativeCell(1),
		bool:tsay = GetNativeCell(2);
#if defined ADVERT_SOURCE2009	
	new bool:chat = GetNativeCell(3);
#endif
	if (ads)
	{
		if (g_hAdvertisements != INVALID_HANDLE)
			CloseHandle(g_hAdvertisements);
		parseAdvertisements();
	}
	if (tsay)
	{
		if (g_hTopColorTrie != INVALID_HANDLE)
			ClearTrie(g_hTopColorTrie);
		initTopColorTrie();
		parseExtraTopColors();
	}
#if defined ADVERT_SOURCE2009
	if (chat)
	{
		parseExtraChatColors();
	}
#endif
}

public Native_ShowAdvert(Handle:plugin, numParams)
{
	new maxlength = 128;
	decl String:advertId[maxlength];
	GetNativeString(1, advertId, maxlength);
	new bool:order = GetNativeCell(2);
	if (order)
		KvSavePosition(g_hAdvertisements);
	if (strcmp(advertId, NULL_STRING, false) != 0)
	{
		if (!KvJumpToKey(g_hAdvertisements, advertId))
			return false;
	}
	AdvertisementTimer(g_hAdvertTimer);
	if (order)
		KvRewind(g_hAdvertisements);
	return true;
}

public Native_AddAdvert(Handle:plugin, numParams)
{
	new advertId_ml = 128;
	decl String:advertId[advertId_ml];
	GetNativeString(1, advertId, advertId_ml);
	new advertText_ml = 1024, advertType_ml = 128;
	decl String:advertText[advertText_ml], String:advertType[advertType_ml];
	GetNativeString(3, advertText, advertText_ml);
	GetNativeString(2, advertType, advertType_ml);
	new flagBits = GetNativeCell(4);
	new noFlagBits = GetNativeCell(5);
	new bool:jumpTo = GetNativeCell(6);
	new bool:replace = GetNativeCell(7);
	
	new Action:returnVal = Plugin_Continue;
	
	Call_StartForward(g_hForwardPreAddAdvert);
	Call_PushStringEx(advertId, advertId_ml, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(advertId_ml);
	Call_PushStringEx(advertType, advertType_ml, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(advertType_ml);
	Call_PushStringEx(advertText, advertText_ml, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(advertText_ml);
	Call_PushCellRef(flagBits);
	Call_PushCellRef(noFlagBits);
	Call_PushCellRef(jumpTo);
	Call_PushCellRef(replace);
	Call_Finish(_:returnVal);
	
	if (returnVal != Plugin_Continue)
		return false;
	
	new bool:advertExists = AdvertExists(advertId);
	
	if (!jumpTo || (!replace && advertExists))
		KvSavePosition(g_hAdvertisements);
	
	if (replace && advertExists)
	{
		KvJumpToKey(g_hAdvertisements, advertId);
		KvDeleteThis(g_hAdvertisements);
	}
	else if (!replace && advertExists)
	{
		KvRewind(g_hAdvertisements);
		return false;
	}
	
	KvJumpToKey(g_hAdvertisements, advertId, true);
	
	KvSetString(g_hAdvertisements, g_strKeyValueKeyList[0], advertType);
	KvSetString(g_hAdvertisements, g_strKeyValueKeyList[1], advertText);
	KvSetNum(g_hAdvertisements, g_strKeyValueKeyList[2], flagBits);
	KvSetNum(g_hAdvertisements, g_strKeyValueKeyList[3], noFlagBits);
	
	if (!jumpTo)
		KvRewind(g_hAdvertisements);
	
	Call_StartForward(g_hForwardPostAddAdvert);
	Call_PushString(advertId);
	Call_PushString(advertType);
	Call_PushString(advertText);
	Call_PushCell(flagBits);
	Call_PushCell(noFlagBits);
	Call_PushCell(jumpTo);
	Call_PushCell(replace);
	Call_Finish();
	
	return true;
}

public Native_AddTopColorToTrie(Handle:plugin, numParams)
{
	new colorName_maxLength = 256;
	decl String:colorName[colorName_maxLength];
	GetNativeString(1, colorName, colorName_maxLength);
	new red = GetNativeCell(2),
		blue = GetNativeCell(3),
		green = GetNativeCell(4),
		alpha = GetNativeCell(5);
	new bool:replace = GetNativeCell(6);
	
	new Action:fReturn = Plugin_Continue;
	Call_StartForward(g_hForwardPreAddTopColor);
	Call_PushStringEx(colorName, colorName_maxLength, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(colorName_maxLength);
	Call_PushCellRef(red);
	Call_PushCellRef(green);
	Call_PushCellRef(blue);
	Call_PushCellRef(alpha);
	Call_PushCellRef(replace);
	Call_Finish(_:fReturn);
	
	if (fReturn != Plugin_Continue)
	{
		return false;
	}
	
	new color[4];
	color[0] = red;
	color[1] = blue;
	color[2] = green;
	color[3] = alpha;
	
	new returnVal = SetTrieArray(g_hTopColorTrie, colorName, color, 4, replace);
	
	Call_StartForward(g_hForwardPostAddTopColor);
	Call_PushString(colorName);
	Call_PushCell(red);
	Call_PushCell(green);
	Call_PushCell(blue);
	Call_PushCell(alpha);
	Call_PushCell(replace);
	Call_Finish();
	
	return returnVal;
}

#if defined ADVERT_SOURCE2009
public Native_AddChatColorToTrie(Handle:plugin, numParams)
{
	new colorName_maxLength = 256;
	decl String:colorName[colorName_maxLength];
	GetNativeString(1, colorName, colorName_maxLength);
	new hex = GetNativeCell(2);
	
	new Action:callReturn = Plugin_Continue;
	Call_StartForward(g_hForwardPreAddChatColor);
	Call_PushStringEx(colorName, colorName_maxLength, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(colorName_maxLength);
	Call_PushCellRef(hex);
	Call_Finish(_:callReturn);
	
	if (callReturn != Plugin_Continue)
		return false;
	
	new bool:returnVal = CAddColor(colorName, hex);
	
	Call_StartForward(g_hForwardPostAddChatColor);
	Call_PushString(colorName);
	Call_PushCell(hex);
	Call_Finish();
	
	return returnVal;
}
#endif

public OnPluginStart()
{
	CreateConVar("extended_advertisements_version", PLUGIN_VERSION, "Display advertisements", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	#if defined ADVERT_SOURCE2009
	if (!IsGameCompatible())
		SetFailState("[Extended Advertisements] You are running a version of this plugin that is incompatible with your game.");
	#endif
	g_hPluginEnabled = CreateConVar("sm_extended_advertisements_enabled", "1", "Is plugin enabled?", 0, true, 0.0, true, 1.0);
	g_hAdvertDelay = CreateConVar("sm_extended_advertisements_delay", "30.0", "The delay time between each advertisement");
	g_hAdvertFile = CreateConVar("sm_extended_advertisements_file", "configs/extended_advertisements.txt", "What is the file directory of the advertisements file");
	g_hExitPanel = CreateConVar("sm_extended_advertisements_exitmenu", "1", "In \"M\" type menus, can clients close the menu with the press of any button?");
	g_hExtraTopColorsPath = CreateConVar("sm_extended_advertisement_extratopcolors_file", "configs/extra_top_colors.txt", "What is the directory of the \"Extra Top Colors\" config?");
	#if defined ADVERT_SOURCE2009
	g_hExtraChatColorsPath = CreateConVar("sm_extended_advertisements_extrachatcolors_file", "configs/extra_chat_colors.txt", "What is the directory of the \"Extra Chat Colors\" config?");
	#endif
	
	HookConVarChange(g_hPluginEnabled, OnEnableChange);
	HookConVarChange(g_hAdvertDelay, OnAdvertDelayChange);
	HookConVarChange(g_hAdvertFile, OnAdvertFileChange);
	HookConVarChange(g_hExitPanel, OnExitChange);
	HookConVarChange(g_hExtraTopColorsPath, OnExtraTopColorsPathChange);
	#if defined ADVERT_SOURCE2009
	HookConVarChange(g_hExtraChatColorsPath, OnExtraChatColorsPathChange);
	#endif
	
	InitiConfiguration();

	
	LoadTranslations("extended_advertisements.phrases");
	
	
	RegAdminCmd("sm_reloadads", Command_ReloadAds, ADMFLAG_RCON);
	RegAdminCmd("sm_showad", Command_ShowAd, ADMFLAG_RCON);
	RegAdminCmd("sm_addadvert", Command_AddAdvert, ADMFLAG_RCON);
	RegAdminCmd("sm_deladd", Command_DeleteAdvert, ADMFLAG_RCON);
	
	
	AutoExecConfig();
	
	g_hForwardPreReplace = CreateGlobalForward("OnAdvertPreReplace", ET_Hook, Param_String, Param_String, Param_String, Param_CellByRef);
	g_hForwardPostAdvert = CreateGlobalForward("OnPostAdvertisementShown", ET_Ignore, Param_String, Param_String, Param_String, Param_Cell);
	g_hForwardPreClientReplace = CreateGlobalForward("OnAdvertPreClientReplace", ET_Single, Param_Cell, Param_String, Param_String, Param_String, Param_CellByRef);
#if defined ADVERT_SOURCE2009	
	g_hForwardPreAddChatColor = CreateGlobalForward("OnAddChatColorPre", ET_Hook, Param_String, Param_Cell, Param_CellByRef);
	g_hForwardPostAddChatColor = CreateGlobalForward("OnAddChatColorPost", ET_Ignore, Param_String, Param_Cell);
#endif
	g_hForwardPreAddTopColor = CreateGlobalForward("OnAddTopColorPre", ET_Hook, Param_String, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef);
	g_hForwardPostAddTopColor = CreateGlobalForward("OnAddTopColorPost", ET_Ignore, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardPreAddAdvert = CreateGlobalForward("OnAddAdvertPre", ET_Hook, Param_String, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef);
	g_hForwardPostAddAdvert = CreateGlobalForward("OnAddAdvertPost", ET_Ignore, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardPreDeleteAdvert = CreateGlobalForward("OnPreDeleteAdvert", ET_Hook, Param_String, Param_Cell);
	g_hForwardPostDeleteAdvert = CreateGlobalForward("OnPostDeleteAdvert", ET_Ignore, Param_String);
	
	//g_hDynamicTagRegex = CompileRegex("\\{([Cc][Oo][Nn][Vv][Aa][Rr](_[Bb][Oo][Oo][Ll])?):[A-Za-z0-9_!@#$%^&*()\\-~`+=]{1,}\\}");
	
	g_bUseSteamTools = (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "Steam_GetPublicIP") == FeatureStatus_Available);
	
	if (LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);
}

#if defined ADVERT_SOURCE2009
stock bool:IsGameCompatible()
{
	/*new sdkversion = GuessSDKVersion();
	if (SOURCE_SDK_EPISODE2VALVE <= sdkversion < SOURCE_SDK_LEFT4DEAD || sdkversion >= SOURCE_SDK_CSGO)*/
	if (SOURCE_SDK_EPISODE2VALVE <= GuessSDKVersion() < SOURCE_SDK_LEFT4DEAD)
		return true;
	return false;
}
#endif

// [SM] Usage: sm_deladvert <Advert Id>
public Action:Command_DeleteAdvert(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%t %t", "Advert_Tag", "Del_Usage");
		return Plugin_Handled;
	}
	decl String:arg[256];
	GetCmdArgString(arg, sizeof(arg));
	StripQuotes(arg);
	if (DeleteAdvert(arg))
		ReplyToCommand(client, "%t %t", "Advert_Tag", "Del_Success", arg);
	else
		ReplyToCommand(client, "%t %t", "Advert_Tag", "Del_Fail", arg);
	return Plugin_Handled;
}

// [SM] Usage: sm_addadvert <Advert Id> <Advert Type> <Advert Text> [Flags] [NoFlags]
public Action:Command_AddAdvert(client, args)
{
	decl String:arg[5][256];
	switch (args)
	{
		case 5:
		{
			for (new i = 0; i <= args; i++)
			{
				GetCmdArg(i, arg[i], sizeof(arg[]));
			}
			new flagBits = ReadFlagString(arg[3]),
				noFlagBits = ReadFlagString(arg[4]);
			
			if (AddAdvert(arg[0], arg[1], arg[2], flagBits, noFlagBits))
				ReplyToCommand(client, "%t %t", "Advert_Tag", "Add_Success", arg[0]);
			else
				ReplyToCommand(client, "%t %t", "Advert_Tag", "Add_Fail", arg[0]);
		}
		case 4:
		{
			for (new i = 0; i <= args; i++)
			{
				GetCmdArg(i, arg[i], sizeof(arg[]));
			}
			new flagBits = ReadFlagString(arg[3]);
			
			if (AddAdvert(arg[0], arg[1], arg[2], flagBits))
				ReplyToCommand(client, "%t %t", "Advert_Tag", "Add_Success", arg[0]);
			else
				ReplyToCommand(client, "%t %t", "Advert_Tag", "Add_Fail", arg[0]);
		}
		case 3:
		{
			for (new i = 0; i <= args; i++)
			{
				GetCmdArg(i, arg[i], sizeof(arg[]));
			}
			
			if (AddAdvert(arg[0], arg[1], arg[2]))
				ReplyToCommand(client, "%t %t", "Advert_Tag", "Add_Success", arg[0]);
			else
				ReplyToCommand(client, "%t %t", "Advert_Tag", "Add_Fail", arg[0]);
		}
		default:
		{
			ReplyToCommand(client, "%t %t", "Advert_Tag", "Add_Usage");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

/**
 * 
 * Format Time
 * Note: Credit goes to GameME, this was a mere copy and paste
 * 
 */

stock format_time(timestamp, String: formatted_time[192]) 
{ 
	Format(formatted_time, 192, "%dd %02d:%02d:%02dh", 
			timestamp / 86400, 
			timestamp / 3600 % 24, 
			timestamp / 60 % 60, 
			timestamp % 60 
		); 
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL);
	
	g_bUseSteamTools = (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "Steam_GetPublicIP") == FeatureStatus_Available);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "updater"))
		Updater_RemovePlugin();
	
	g_bUseSteamTools = (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "Steam_GetPublicIP") == FeatureStatus_Available);
}

public OnGameFrame() 
{
	if (g_bTickrate) 
	{
		g_iFrames++;
		
		new Float:fTime = GetEngineTime();
		if (fTime >= g_fTime) 
		{
			if (g_iFrames == g_iTickrate) 
			{
				g_bTickrate = false;
			} 
			else 
			{
				g_iTickrate = g_iFrames;
				g_iFrames   = 0;    
				g_fTime     = fTime + 1.0;
			}
		}
	}
}

public OnConfigsExecuted()
{
	InitiConfiguration();
	#if defined ADVERT_SOURCE2009
	parseExtraChatColors();
	#endif
	parseExtraTopColors();
	parseAdvertisements();
	if (!g_bPluginEnabled)
	{
		if (g_hAdvertTimer != INVALID_HANDLE)
		{
			KillTimer(g_hAdvertTimer);
			g_hAdvertTimer = INVALID_HANDLE;
		}
	}
	else
	{
		if (g_hAdvertTimer != INVALID_HANDLE)
		{
			KillTimer(g_hAdvertTimer);
			g_hAdvertTimer = INVALID_HANDLE;
		}
		g_hAdvertTimer = CreateTimer(g_fAdvertDelay, AdvertisementTimer, _, TIMER_REPEAT);
	}
}

public OnMapStart()
{
	if (!g_bPluginEnabled)
	{
		if (g_hAdvertTimer != INVALID_HANDLE)
		{
			KillTimer(g_hAdvertTimer);
			g_hAdvertTimer = INVALID_HANDLE;
		}
	}
	else
	{
		if (g_hAdvertTimer != INVALID_HANDLE)
		{
			KillTimer(g_hAdvertTimer);
			g_hAdvertTimer = INVALID_HANDLE;
		}
		g_hAdvertTimer = CreateTimer(g_fAdvertDelay, AdvertisementTimer, _, TIMER_REPEAT);
	}
}

public OnMapEnd()
{
	if (g_hAdvertTimer != INVALID_HANDLE)
	{
		KillTimer(g_hAdvertTimer);
		g_hAdvertTimer = INVALID_HANDLE;
	}
}

stock InitiConfiguration()
{
	g_bPluginEnabled = GetConVarBool(g_hPluginEnabled);
	g_fAdvertDelay = GetConVarFloat(g_hAdvertDelay);
	g_bExitPanel = GetConVarBool(g_hExitPanel);
	
	decl String:advertPath[PLATFORM_MAX_PATH];
	GetConVarString(g_hAdvertFile, advertPath, sizeof(advertPath));
	BuildPath(Path_SM, g_strConfigPath, sizeof(g_strConfigPath), advertPath);
	
	GetConVarString(g_hExtraTopColorsPath, advertPath, sizeof(advertPath));
	BuildPath(Path_SM, g_strExtraTopColorsPath, sizeof(g_strExtraTopColorsPath), advertPath);
	
	#if defined ADVERT_SOURCE2009
	GetConVarString(g_hExtraChatColorsPath, advertPath, sizeof(advertPath));
	BuildPath(Path_SM, g_strExtraChatColorsPath, sizeof(g_strExtraChatColorsPath), advertPath);
	#endif
	initTopColorTrie();
}

public OnExtraTopColorsPathChange(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	BuildPath(Path_SM, g_strExtraTopColorsPath, sizeof(g_strExtraTopColorsPath), newValue);
	if (g_hTopColorTrie != INVALID_HANDLE)
		ClearTrie(g_hTopColorTrie);
	parseExtraTopColors();
}

public OnExitChange(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	g_bExitPanel = StringToInt(newValue) ? true : false;
}

#if defined ADVERT_SOURCE2009
public OnExtraChatColorsPathChange(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	BuildPath(Path_SM, g_strExtraChatColorsPath, sizeof(g_strExtraChatColorsPath), newValue);
	parseExtraChatColors();
}
#endif
public OnEnableChange(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	new bool:newVal = StringToInt(newValue) ? true : false,
		bool:oldVal = StringToInt(oldValue) ? true : false;
	g_bPluginEnabled = newVal;
	if (newVal != oldVal)
	{
		if (!newVal)
		{
			if (g_hAdvertTimer != INVALID_HANDLE)
			{
				KillTimer(g_hAdvertTimer);
				g_hAdvertTimer = INVALID_HANDLE;
			}
		}
		else
		{
			if (g_hAdvertTimer != INVALID_HANDLE)
			{
				KillTimer(g_hAdvertTimer);
				g_hAdvertTimer = INVALID_HANDLE;
			}
			g_hAdvertTimer = CreateTimer(g_fAdvertDelay, AdvertisementTimer, _, TIMER_REPEAT);
		}
	}
}

public OnAdvertDelayChange(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	g_fAdvertDelay = StringToFloat(newValue);
	
	if (!g_bPluginEnabled)
	{
		if (g_hAdvertTimer != INVALID_HANDLE)
		{
			KillTimer(g_hAdvertTimer);
			g_hAdvertTimer = INVALID_HANDLE;
		}
	}
	else
	{
		if (g_hAdvertTimer != INVALID_HANDLE)
		{
			KillTimer(g_hAdvertTimer);
			g_hAdvertTimer = INVALID_HANDLE;
		}
		g_hAdvertTimer = CreateTimer(g_fAdvertDelay, AdvertisementTimer, _, TIMER_REPEAT);
	}
}

public OnAdvertFileChange(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	BuildPath(Path_SM, g_strConfigPath, sizeof(g_strConfigPath), newValue);
	if (g_hAdvertisements != INVALID_HANDLE)
	{
		CloseHandle(g_hAdvertisements);
		g_hAdvertisements = INVALID_HANDLE;
	}
	parseAdvertisements();
}

public Action:AdvertisementTimer(Handle:advertTimer)
{
	if (g_bPluginEnabled)
	{
		decl String:sFlags[32], String:sText[256], String:sType[6], String:sBuffer[256], String:sBuffer2[256], String:sectionName[128];
		new flagBits = -1,
			noFlagBits = -1;
		
		KvGetSectionName(g_hAdvertisements, sectionName, sizeof(sectionName));
		KvGetString(g_hAdvertisements, g_strKeyValueKeyList[0],  sType,  sizeof(sType), "none");
		KvGetString(g_hAdvertisements, g_strKeyValueKeyList[1],  sText,  sizeof(sText), "none");
		KvGetString(g_hAdvertisements, g_strKeyValueKeyList[2], sFlags, sizeof(sFlags), "none");
		if (!StrEqual(sFlags, "none"))
			flagBits = ReadFlagString(sFlags);
		KvGetString(g_hAdvertisements, g_strKeyValueKeyList[3], sFlags, sizeof(sFlags), "none");
		if (!StrEqual(sFlags, "none"))
			noFlagBits = ReadFlagString(sFlags);
		
		if (!KvGotoNextKey(g_hAdvertisements)) 
		{
			KvRewind(g_hAdvertisements);
			KvGotoFirstSubKey(g_hAdvertisements);
		}
			
		new Action:forwardReturn = Plugin_Continue,
			bool:forwardBool = true;

		if (StrContains(sText, "\\n") != -1)
		{
			Format(sFlags, sizeof(sFlags), "%c", 13);
			ReplaceString(sText, sizeof(sText), "\\n", sFlags);
		}

		Call_StartForward(g_hForwardPreReplace);
		Call_PushString(sectionName);
		Call_PushStringEx(sType, sizeof(sType), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(sText, sizeof(sText), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(flagBits);
		Call_Finish(_:forwardReturn);
		
		if (forwardReturn != Plugin_Continue)
			return Plugin_Continue;
		
		ReplaceAdText(sText, sText, sizeof(sText));
		strcopy(sBuffer, sizeof(sBuffer), sText);
		
		if (StrContains(sType, "C", false) != -1) 
		{
			String_RemoveExtraTags(sBuffer, sizeof(sBuffer));
			LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH)
			{
				Call_StartForward(g_hForwardPreClientReplace);
				Call_PushCell(client);
				Call_PushString(sectionName);
				Call_PushString(sType);
				Call_PushStringEx(sBuffer, sizeof(sBuffer), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(flagBits);
				Call_Finish(_:forwardBool);
				
				if (forwardBool && Client_CanViewAds(client, flagBits, noFlagBits))
				{
					ReplaceClientText(client, sBuffer, sBuffer2, sizeof(sBuffer2));
					PrintCenterText(client, sBuffer2);	
					new Handle:hCenterAd;
					g_hCenterAd[client] = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					WritePackCell(hCenterAd,   client);
					WritePackString(hCenterAd, sBuffer2);
					
				}
			}
		}
		
		strcopy(sBuffer, sizeof(sBuffer), sText);
		forwardBool = true;
		if (StrContains(sType, "H", false) != -1) 
		{
			String_RemoveExtraTags(sBuffer, sizeof(sBuffer));
			LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH)
			{
				Call_StartForward(g_hForwardPreClientReplace);
				Call_PushCell(client);
				Call_PushString(sectionName);
				Call_PushString(sType);
				Call_PushStringEx(sBuffer, sizeof(sBuffer), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(flagBits);
				Call_Finish(_:forwardBool);
				
				if (forwardBool && Client_CanViewAds(client, flagBits, noFlagBits))
				{
					ReplaceClientText(client, sBuffer, sBuffer2, sizeof(sBuffer2));
					PrintHintText(client, sBuffer2);
				}
			}
		}
		
		strcopy(sBuffer, sizeof(sBuffer), sText);
		forwardBool = true;
		if (StrContains(sType, "M", false) != -1) 
		{
			new Handle:hPl = CreatePanel();
			DrawPanelText(hPl, sBuffer);
			SetPanelCurrentKey(hPl, 10);
			
			String_RemoveExtraTags(sBuffer, sizeof(sBuffer));
			LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH)
			{
				Call_StartForward(g_hForwardPreClientReplace);
				Call_PushCell(client);
				Call_PushString(sectionName);
				Call_PushString(sType);
				Call_PushStringEx(sBuffer, sizeof(sBuffer), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(flagBits);
				Call_Finish(_:forwardBool);
				
				if (forwardBool && Client_CanViewAds(client, flagBits, noFlagBits))
				{
					ReplaceClientText(client, sBuffer, sBuffer2, sizeof(sBuffer2));
					SendPanelToClient(hPl, client, Handler_DoNothing, 10);
				}
			}
			
			CloseHandle(hPl);
		}
		
		strcopy(sBuffer, sizeof(sBuffer), sText);
		forwardBool = true;
		if (StrContains(sType, "S", false) != -1) 
		{
			String_RemoveExtraTags(sBuffer, sizeof(sBuffer), true);
			LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH)
			{
				Call_StartForward(g_hForwardPreClientReplace);
				Call_PushCell(client);
				Call_PushString(sectionName);
				Call_PushString(sType);
				Call_PushStringEx(sBuffer, sizeof(sBuffer), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(flagBits);
				Call_Finish(_:forwardBool);

				if (forwardBool && Client_CanViewAds(client, flagBits, noFlagBits))
				{
					ReplaceClientText(client, sBuffer, sBuffer2, sizeof(sBuffer2));
					CPrintToChatEx(client, client, sBuffer2);
				}
			}
		}
		
		strcopy(sBuffer, sizeof(sBuffer), sText);
		forwardBool = true;
		if (StrContains(sType, "T", false) != -1) 
		{
			// Credits go to Dr. Mckay
			decl String:part[256], String:find[32];
			new value[4], first, last;
			new index = 0;
			first = FindCharInString(sBuffer[index], '{');
			last = FindCharInString(sBuffer[index], '}');
			if (first != -1 && last != -1) 
			{
				first++;
				last--;
				for (new j = 0; j <= last - first + 1; j++) 
				{
					if (j == last - first + 1) 
					{
						part[j] = 0;
						break;
					}
					part[j] = sBuffer[index + first + j];
				}
				index += last + 2;
				String_ToLower(part, part, sizeof(part));
				if (g_hTopColorTrie == INVALID_HANDLE)
				{
					initTopColorTrie();
					parseExtraTopColors();
				}
				if (GetTrieArray(g_hTopColorTrie, part, value, 4)) 
				{
					Format(find, sizeof(find), "{%s}", part);
					ReplaceString(sBuffer, sizeof(sBuffer), find, "", false);
				}
			}
			else
			{
				GetTrieArray(g_hTopColorTrie, "white", value, 4);
			}
			
			String_RemoveExtraTags(sBuffer, sizeof(sBuffer));
			
			
			LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH)
			{
				Call_StartForward(g_hForwardPreClientReplace);
				Call_PushCell(client);
				Call_PushString(sectionName);
				Call_PushString(sType);
				Call_PushStringEx(sBuffer, sizeof(sBuffer), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(flagBits);
				Call_Finish(_:forwardBool);
				
				if (forwardBool && Client_CanViewAds(client, flagBits, noFlagBits))
				{
					new Handle:hKv = CreateKeyValues("Stuff", "title", sBuffer2);
					KvSetColor(hKv, "color", value[0], value[1], value[2], value[3]);
					KvSetNum(hKv,   "level", 1);
					KvSetNum(hKv,   "time",  10);
					ReplaceClientText(client, sBuffer, sBuffer2, sizeof(sBuffer2));
					CreateDialog(client, hKv, DialogType_Msg);
					if (hKv != INVALID_HANDLE)
						CloseHandle(hKv);
				}				
			}
		}
		Call_StartForward(g_hForwardPostAdvert);
		Call_PushString(sectionName);
		Call_PushString(sType);
		Call_PushString(sText);
		Call_PushCell(flagBits);
		Call_Finish();
	}
	return Plugin_Continue;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) 
{
	if (g_bExitPanel)
	{
		switch (action)
		{
			case MenuAction_Select:
			{
				CloseHandle(menu);
			}
			case MenuAction_End:
			{
				CloseHandle(menu);
			}
		}
	}
}

public Action:Timer_CenterAd(Handle:timer, Handle:pack) 
{
	decl String:sText[256];
	static iCount = 0;
	
	ResetPack(pack);
	new iClient = ReadPackCell(pack);
	ReadPackString(pack, sText, sizeof(sText));
	
	if (IsClientInGame(iClient) && ++iCount < 5) 
	{
		PrintCenterText(iClient, sText);
		
		return Plugin_Continue;
	}
	
	else 
	{
		iCount = 0;
		g_hCenterAd[iClient] = INVALID_HANDLE;
		
		return Plugin_Stop;
	}
}

public Action:Command_ShowAd(client, args)
{
	if (args > 0)
	{
		decl String:arg[256];
		GetCmdArgString(arg, sizeof(arg));
		StripQuotes(arg);
		if (!ShowAdvert(arg))
		{
			ReplyToCommand(client, "%t %t", "Advert_Tag", "ShowAd_NotFound");
			return Plugin_Handled;
		}
	}
	else
		ShowAdvert();
	return Plugin_Handled;
}

public Action:Command_ReloadAds(client, args)
{
	if (g_bPluginEnabled)
	{
		#if defined ADVERT_SOURCE2009
		parseExtraChatColors();
		#endif
		if (g_hTopColorTrie != INVALID_HANDLE)
			ClearTrie(g_hTopColorTrie);
		initTopColorTrie();
		parseExtraTopColors();
		if (g_hAdvertisements != INVALID_HANDLE)
			CloseHandle(g_hAdvertisements);
		parseAdvertisements();
		ReplyToCommand(client, "%t %t", "Advert_Tag", "Config_Reloaded");
	}
	return Plugin_Handled;
}

stock parseAdvertisements()
{
	if (g_bPluginEnabled)
	{
		g_hAdvertisements = CreateKeyValues("Advertisements");
		
		if (FileExists(g_strConfigPath)) 
		{
			//new Handle:kv = CreateKeyValues("Advertisements");
			FileToKeyValues(g_hAdvertisements, g_strConfigPath);
			/*KvGotoFirstSubKey(kv);
			decl String:sBuffer[5][256];
			do
			{
				KvGetSectionName(kv, sBuffer[4], sizeof(sBuffer[]));
				for (new i = 0; i < sizeof(g_strKeyValueKeyList); i++)
				{
					KvGetString(kv, g_strKeyValueKeyList[i], sBuffer[i], sizeof(sBuffer[]), "none");
				}
				new flags = -1, noflags = -1;
				
				if (!StrEqual(sBuffer[2], "none"))
					flags = ReadFlagString(sBuffer[2]);
				if (!StrEqual(sBuffer[3], "none"))
					noflags = ReadFlagString(sBuffer[3]);
				
				AddAdvert(sBuffer[4], sBuffer[0], sBuffer[1], flags, noflags, false, true);
			}
			while (KvGotoNextKey(kv));
			CloseHandle(kv);*/
		} 
		else 
		{
			SetFailState("Advertisement file \"%s\" was not found.", g_strConfigPath);
		}
	}
}

stock ReplaceAdText(const String:inputText[], String:outputText[], outputText_maxLength)
{
	strcopy(outputText, outputText_maxLength, inputText);
	decl String:part[256], String:replace[128];
	new first, last;
	new index = 0, charIndex;
	new Handle:conVarFound;
	for (new i = 0; i < 100; i++) 
	{
		first = FindCharInString(outputText[index], '{');
		last = FindCharInString(outputText[index], '}');
		if (first != -1 || last != -1)
		{
			for (new j = 0; j <= last - first + 1; j++) 
			{
				if (j == last - first + 1) 
				{
					part[j] = 0;
					break;
				}
				part[j] = outputText[index + first + j];
			}
			index += last + 1;
			
			charIndex = StrContains(part, "{CONVAR:", false);
			if (charIndex == 0)
			{
				strcopy(replace, sizeof(replace), part);
				ReplaceString(replace, sizeof(replace), "{CONVAR:", "", false);
				ReplaceString(replace, sizeof(replace), "}", "", false);
				conVarFound = FindConVar(replace);
				if (conVarFound != INVALID_HANDLE)
				{
					GetConVarString(conVarFound, replace, sizeof(replace));
					ReplaceString(outputText, outputText_maxLength, part, replace, false);
				}
				else
					ReplaceString(outputText, outputText_maxLength, part, "", false);
			}
			else
			{
				charIndex = StrContains(part, "{CONVAR_BOOL:", false);
				if (charIndex == 0)
				{
					strcopy(replace, sizeof(replace), part);
					ReplaceString(replace, sizeof(replace), "{CONVAR_BOOL:", "", false);
					ReplaceString(replace, sizeof(replace), "}", "", false);
					conVarFound = FindConVar(replace);
					if (conVarFound != INVALID_HANDLE)
					{
						new int = GetConVarInt(conVarFound);
						if (int == 1 || int == 0)
							ReplaceString(outputText, outputText_maxLength, part, g_strConVarBoolText[int], false);
						else
							ReplaceString(outputText, outputText_maxLength, part, "", false);
					}
					else
						ReplaceString(outputText, outputText_maxLength, part, "", false);
				}
			}
			
			/*if (MatchRegex(g_hDynamicTagRegex, part) > 0)
			{
				strcopy(replace, sizeof(replace), part);
				new Handle:conVarFound = INVALID_HANDLE;
				if (StrContains(replace, "CONVAR_BOOL", false) != -1)
				{
					ReplaceString(replace, sizeof(replace), "{CONVAR_BOOL:", "", false);
					ReplaceString(replace, sizeof(replace), "}", "", false);
					conVarFound = FindConVar(replace);
					if (conVarFound != INVALID_HANDLE)
					{
						new conVarValue = GetConVarInt(conVarFound);
						if (conVarValue == 0 || conVarValue == 1)
							strcopy(replace, sizeof(replace), g_strConVarBoolText[conVarValue]);
						else
							replace = "";
					}
					else
						replace = "";
				}
				else
				{
					ReplaceString(replace, sizeof(replace), "{CONVAR:", "", false);
					ReplaceString(replace, sizeof(replace), "}", "", false);
					conVarFound = FindConVar(replace);
					if (conVarFound != INVALID_HANDLE)
						GetConVarString(conVarFound, replace, sizeof(replace));
					else
						replace = "";
				}
				ReplaceString(outputText, outputText_maxLength, part, replace);
			}*/
		}
		else
			break;
	}
	
	new i = 1;
	decl String:strTemp[256];
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		GetServerIP(strTemp, sizeof(strTemp));
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		GetServerIP(strTemp, sizeof(strTemp), true);
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		Format(strTemp, sizeof(strTemp), "%i", Server_GetPort());
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		GetCurrentMap(strTemp, sizeof(strTemp));
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		GetNextMap(strTemp, sizeof(strTemp));
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		IntToString(g_iTickrate, strTemp, sizeof(strTemp));
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		FormatTime(strTemp, sizeof(strTemp), "%I:%M:%S%p");
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		FormatTime(strTemp, sizeof(strTemp), "%H:%M:%S");
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		FormatTime(strTemp, sizeof(strTemp), "%x");
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	i++;
	if (StrContains(outputText, g_tagRawText[i], false) != -1)
	{
		new iMins, iSecs, iTimeLeft;
			
		if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0) 
		{
			iMins = iTimeLeft / 60;
			iSecs = iTimeLeft % 60;
		}
		
		Format(strTemp, sizeof(strTemp), "%d:%02d", iMins, iSecs);
		ReplaceString(outputText, outputText_maxLength, g_tagRawText[i], strTemp, false);
	}
	strTemp[0] = '\0';
}

stock ReplaceClientText(client, const String:inputText[], String:outputText[], outputText_maxLength)
{
	
	if (Client_IsValid(client))
	{
		strcopy(outputText, outputText_maxLength, inputText);
		new i = 1;
		decl String:strTemp[256];
		if (StrContains(outputText, g_clientRawText[i], false) != -1)
		{
			GetClientName(client, strTemp, sizeof(strTemp));\
			ReplaceString(outputText, outputText_maxLength, g_clientRawText[i], strTemp, false);
		}
		i++;
		if (StrContains(outputText, g_clientRawText[i], false) != -1)
		{
			GetClientAuthString(client, strTemp, sizeof(strTemp));
			ReplaceString(outputText, outputText_maxLength, g_clientRawText[i], strTemp, false);
		}
		i++;
		if (StrContains(outputText, g_clientRawText[i], false) != -1)
		{
			GetClientIP(client, strTemp, sizeof(strTemp));
			ReplaceString(outputText, outputText_maxLength, g_clientRawText[i], strTemp, false);
		}
		i++;
		if (StrContains(outputText, g_clientRawText[i], false) != -1)
		{
			GetClientIP(client, strTemp, sizeof(strTemp), false);
			ReplaceString(outputText, outputText_maxLength, g_clientRawText[i], strTemp, false);
		}
		i++;
		if (StrContains(outputText, g_clientRawText[i], false) != -1)
		{
			Format(strTemp, sizeof(strTemp), "%d", GetClientTime(client));
			ReplaceString(outputText, outputText_maxLength, g_clientRawText[i], strTemp, false);
		}
		i++;
		if (StrContains(outputText, g_clientRawText[i], false) != -1)
		{
			Format(strTemp, sizeof(strTemp), "%d", Client_GetMapTime(client));
			ReplaceString(outputText, outputText_maxLength, g_clientRawText[i], strTemp, false);
		}
		strTemp[0] = '\0';
	}
	return;
}

stock GetServerIP(String:ipAddress[], serverIP_maxLength, bool:fullIp = false)
{
	Server_GetIPNumString(ipAddress, serverIP_maxLength, g_bUseSteamTools);
	if (fullIp)
	{
		new serverPublicPort = Server_GetPort();
		Format(ipAddress, serverIP_maxLength, "%s:%i", ipAddress, serverPublicPort);
	}
}

public Native_CanViewAdvert(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new clientFlagBits = GetNativeCell(2);
	new noFlagBits = GetNativeCell(3);
	if (clientFlagBits == -1 && noFlagBits == -1)
		return true;
	if (CheckCommandAccess(client, "extended_adverts", ADMFLAG_ROOT))
		return true;
	if ((clientFlagBits == -1 || CheckCommandAccess(client, "extended_advert", clientFlagBits)) && (noFlagBits == -1 || !CheckCommandAccess(client, "extended_notview", noFlagBits)))
		return true;
	return false;
}

#if defined ADVERT_SOURCE2009
stock parseExtraChatColors()
{
	if (g_bPluginEnabled)
	{
		if (FileExists(g_strExtraChatColorsPath)) 
		{
			new Handle:keyValues = CreateKeyValues("Extra Chat Colors");
			FileToKeyValues(keyValues, g_strExtraChatColorsPath);
			KvGotoFirstSubKey(keyValues);
			decl String:colorName[128], hex;
			do
			{
				KvGetSectionName(keyValues, colorName, sizeof(colorName));
				hex = KvGetNum(keyValues, "hex", 0);
				if (hex != 0)
					CAddColor(colorName, hex);
			}
			while (KvGotoNextKey(keyValues));
			KvRewind(keyValues);
		}
	}
}
#endif

stock parseExtraTopColors()
{
	if (g_bPluginEnabled)
	{
		if (FileExists(g_strExtraTopColorsPath)) 
		{
			new Handle:keyValues = CreateKeyValues("Extra Top Colors");
			FileToKeyValues(keyValues, g_strExtraTopColorsPath);
			KvGotoFirstSubKey(keyValues);
			decl String:colorName[128], red, green, blue, alpha;
			do
			{
				KvGetSectionName(keyValues, colorName, sizeof(colorName));
				String_ToLower(colorName, colorName, sizeof(colorName));
				red = KvGetNum(keyValues, "red");
				green = KvGetNum(keyValues, "green");
				blue = KvGetNum(keyValues, "blue");
				alpha = KvGetNum(keyValues, "alpha", 255);
				new rgba[4];
				rgba[0] = red;
				rgba[1] = green;
				rgba[2] = blue;
				rgba[3] = alpha;
				SetTrieArray(g_hTopColorTrie, colorName, rgba, 4);
			}
			while (KvGotoNextKey(keyValues));
			KvRewind(keyValues);
		}
	}
}

stock initTopColorTrie()
{
	g_hTopColorTrie = CreateTrie();
	SetTrieArray(g_hTopColorTrie, "white", {255, 255, 255, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "red", {255, 0, 0, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "green", {0, 255, 0, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "blue", {0, 0, 255, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "yellow", {255, 255, 0, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "purple", {255, 0, 255, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "cyan", {0, 255, 255, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "orange", {255, 128, 0, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "pink", {255, 0, 128, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "olive", {128, 255, 0, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "lime", {0, 255, 128, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "violet", {128, 0, 255, 255}, 4);
	SetTrieArray(g_hTopColorTrie, "lightblue", {0, 128, 255, 255}, 4);
}

stock removeTopColors(String:input[], maxlength, bool:ignoreChat = true)
{
	decl String:part[256], String:find[32];
	new value[4], first, last;
	new index = 0;
	new bool:result = false;
	for (new i = 0; i < 100; i++) 
	{
		result = false;
		first = FindCharInString(input[index], '{');
		last = FindCharInString(input[index], '}');
		if (first == -1 || last == -1) 
		{
			return;
		}
		first++;
		last--;
		for (new j = 0; j <= last - first + 1; j++) 
		{
			if(j == last - first + 1) 
			{
				part[j] = 0;
				break;
			}
			part[j] = input[index + first + j];
		}
		index += last + 2;
		String_ToLower(part, part, sizeof(part));
		#if defined ADVERT_SOURCE2009
		new value_ex;
		if (ignoreChat && (GetTrieValue(CTrie, part, value_ex) || !strcmp(part, "default", false) || !strcmp(part, "teamcolor", false)))
			result = true;
		#else
		if (ignoreChat)
		{
			decl String:colorTag[64];
			for (new x = 0; x < sizeof(CTag); x++)
			{
				Format(colorTag, sizeof(colorTag), "{%s}", CTag[x]);
				if (StrContains(part, colorTag, false) != -1)
					result = true;
			}
		}
		#endif
		if (g_hTopColorTrie == INVALID_HANDLE)
		{
			initTopColorTrie();
			parseExtraTopColors();
		}
		if (GetTrieArray(g_hTopColorTrie, part, value, 4) && !result) 
		{
			Format(find, sizeof(find), "{%s}", part);
			ReplaceString(input, maxlength, find, "", false);
		}
	}
}

stock String_RemoveExtraTags(String:inputString[], inputString_maxLength, bool:ignoreChat = false, bool:ignoreTop = false, bool:ignoreRawTag = false)
{
	/*if (!ignoreChat)
		CRemoveTags(inputString, inputString_maxLength);
	if (!ignoreTop)
		removeTopColors(inputString, inputString_maxLength, ignoreChat);
	if (!ignoreRawTag)
	{
		for (new i = 1; i < sizeof(g_tagRawText); i++)
		{
			if (StrContains(inputString, g_tagRawText[i], false) != -1)
				ReplaceString(inputString, inputString_maxLength, g_tagRawText[i], "", false);
		}
	}*/
}

/** 
 * 
 * Modified version of SMLIB's Server_GetIPString
 * 
 */

stock Server_GetIPNumString(String:ipBuffer[], ipBuffer_maxLength, bool:useSteamTools)
{
	new ip;
	switch (useSteamTools)
	{
		case true:
		{
			new octets[4];
			Steam_GetPublicIP(octets);
			ip =
				octets[0] << 24	|
				octets[1] << 16	|
				octets[2] << 8	|
				octets[3];
			LongToIP(ip, ipBuffer, ipBuffer_maxLength);
		}
		case false:
		{
			new Handle:conVarHostIP = INVALID_HANDLE;
			if (conVarHostIP == INVALID_HANDLE)
				conVarHostIP = FindConVar("hostip");
			ip = GetConVarInt(conVarHostIP);
			LongToIP(ip, ipBuffer, ipBuffer_maxLength);
		}
	}
}

public OnPluginEnd()
{
	CloseHandle(g_hAdvertisements);
	CloseHandle(g_hTopColorTrie);
}
