#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>

#pragma semicolon		1
#pragma newdecls		required

#define MXPLYR			MAXPLAYERS+1

int iProPlayer[ MXPLYR ];

public Plugin myinfo = {
	name = "WepAlphanator",
	author = "Assyrian/Nergal",
	description = "makes weapons transparent",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_vm", CommandSetWepAlpha, "Weapon Alpha");
	RegConsoleCmd("sm_pro", CommandSetWepAlpha, "Weapon Alpha");
	RegConsoleCmd("sm_angles", CommandInfo, "Weapon Angles");
	RegAdminCmd("sm_advm", CommandSetAdminWepAlpha, ADMFLAG_SLAY, "Admin Weapon Alpha");
	RegAdminCmd("sm_adpro", CommandSetAdminWepAlpha, ADMFLAG_SLAY, "Admin Weapon Alpha");

	HookEvent("player_spawn", EventResupply);
	HookEvent("post_inventory_application", EventResupply);

	for ( int i=MaxClients ; i ; --i ) {
		if ( !IsValidClient(i) )
			continue;
		OnClientPutInServer(i);
	}
}
public void OnClientPutInServer( int client )
{
	iProPlayer[ client ] = -1;
}

public Action CommandInfo(int client, int args)
{
	float flVector[3]; GetClientEyeAngles(client, flVector);
	CPrintToChat(client, "{green}Your Eye Angles: x:%f, y:%f, z:%f", flVector[0], flVector[1], flVector[2]);

	GetClientEyePosition(client, flVector);
	CPrintToChat(client, "{green}Your Eye Position: x:%f, y:%f, z:%f", flVector[0], flVector[1], flVector[2]);

	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", flVector);
	CPrintToChat(client, "{green}Your Absolute Origin from Property Vector: x:%f, y:%f, z:%f", flVector[0], flVector[1], flVector[2]);

	GetEntPropVector(client, Prop_Send, "m_vecMaxs", flVector);
	CPrintToChat(client, "{green}Your Vector Max Size: x:%f, y:%f, z:%f", flVector[0], flVector[1], flVector[2]);

	GetEntPropVector(client, Prop_Send, "m_vecMins", flVector);
	CPrintToChat(client, "{green}Your Vector Min Size: x:%f, y:%f, z:%f", flVector[0], flVector[1], flVector[2]);

	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", flVector);
	CPrintToChat(client, "{green}Your Absolute Angle Rotation: x:%f, y:%f, z:%f", flVector[0], flVector[1], flVector[2]);

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", flVector);
	CPrintToChat(client, "{green}Your Velocity: x:%f, y:%f, z:%f", flVector[0], flVector[1], flVector[2]);

	return Plugin_Continue;
}
public Action CommandSetWepAlpha(int client, int args)
{
	if (args < 1) {
		ReplyToCommand(client, "[Alpha Weps] Usage: !vm <0-255>");
		return Plugin_Handled;
	}
	char number[8]; GetCmdArg(1, number, sizeof(number));

	int maxalpha = StringToInt(number);
	iProPlayer[ client ] = maxalpha;

	SetWeaponInvis(client, maxalpha);
	CPrintToChat(client, "{green}You've Turned Your Weapon Transparent!");

	return Plugin_Continue;
}
public Action CommandSetAdminWepAlpha(int client, int args)
{
	if (args < 2) {
		ReplyToCommand(client, "[Alpha Weps] Usage: !advm <target> <0-255>");
		return Plugin_Handled;
	}
	char szTargetname[64]; GetCmdArg(1, szTargetname, sizeof(szTargetname));
	char szNum[64]; GetCmdArg(2, szNum, sizeof(szNum));

	int maxalpha = StringToInt(szNum);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS+1], target_count;
	bool tn_is_ml;
	if ( (target_count = ProcessTargetString(szTargetname, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i=0; i < target_count; i++) {
		if ( IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i]) )
		{
			SetWeaponInvis(target_list[i], maxalpha);
			CPrintToChat(target_list[i], "{unusual}Your Weapon Is Transparent!");
		}
	}
	return Plugin_Handled;
}
public Action EventResupply(Event event, const char[] name, bool dontBroadcast)
{
	int i = GetClientOfUserId( event.GetInt("userid") );
	if ( IsValidClient(i) ) {
		if ( iProPlayer[ i ] != -1 ) {
			SetWeaponInvis( i, iProPlayer[ i ] );
			CreateTimer(2.0, LateAlpha, i);
		}
	}
	return Plugin_Continue;
}
stock void Clamp(int& value, int max, int min=0)
{
	if (value > max)
		value = max;
	else if (value < min)
		value = min;
}
stock void SetWeaponInvis(int client, int& alpha)
{
	for (int i=0; i<5; i++) {
		int entity = GetPlayerWeaponSlot(client, i); 
		if ( IsValidEdict(entity) && IsValidEntity(entity) )
		{
			Clamp(alpha, 255);
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR); 
			SetEntityRenderColor(entity, 150, 150, 150, alpha); 
		}
	}
}
stock bool IsValidClient(int client, bool replaycheck = true)
{
	if ( client <= 0 || client > MaxClients)
		return false;
	if ( !IsClientInGame(client) )
		return false;
	if ( GetEntProp(client, Prop_Send, "m_bIsCoaching") )
		return false;
	if ( replaycheck )
		if ( IsClientSourceTV(client) || IsClientReplay(client) )
			return false;
	return true;
}

public Action LateAlpha(Handle hTimer, any client)
{
	SetWeaponInvis( client, iProPlayer[ client ] );
	return Plugin_Continue;
}
