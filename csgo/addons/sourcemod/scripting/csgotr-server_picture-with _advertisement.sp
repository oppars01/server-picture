#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <multicolors>
#include <overlays>

#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Server Picture", 
	author = "oppa", 
	description = "It allows us to show the picture you want on the screen throughout the round.", 
	version = "1.0", 
	url = "csgo-turkiye.com"
};

Handle h_client_status = null;
ConVar cv_picture = null;
char s_picture[ PLATFORM_MAX_PATH ];
int b_client_status [ MAXPLAYERS+1 ] = {true, ...};

public void OnPluginStart() 
{
    cv_picture = CreateConVar("sm_server_picture_name", "models/csgo-turkiye_com/plugin/server_picture/csgo-turkiye-picture", "Picture Filename");
    AutoExecConfig(true, "server_picture","CSGO_Turkiye");
    GetConVarString(cv_picture, s_picture, sizeof(s_picture));
    HookConVarChange(cv_picture, OnCvarChanged);
    h_client_status = RegClientCookie("server_picture_user_status", "Server Picture User Status", CookieAccess_Private);
    RegConsoleCmd("sm_serverpicture", Server_Picture, "Discord User Register");
    LoadTranslations("csgo_tr-server_picture.phrases.txt");
    for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i)) b_client_status[ i ] = queryCookie(i);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}

public void OnMapStart(){
    PrecacheDecalAnyDownload(s_picture);
}

public void OnClientPostAdminCheck(int client)
{
	b_client_status[ client ] = queryCookie(client);
}

public bool queryCookie(int client){
	char value[2];
	GetClientCookie(client, h_client_status, value, sizeof(value));
	if (StrEqual(value, "1", true) || StrEqual(value, "", true))return true;
	return false;
}

public int OnCvarChanged(Handle convar, const char[] oldVal, const char[] newVal)
{
    if(convar == cv_picture) strcopy(s_picture, sizeof(s_picture), newVal);
}

public Action Server_Picture(int client, int args)
{
    if(client != 0){
        if(IsValidClient(client)){
            b_client_status[ client ] = !queryCookie(client);
            if(b_client_status[ client ]){
                SetClientCookie(client, h_client_status, "1");
                ShowOverlay(client, s_picture, 0.0);
            }else{
                SetClientCookie(client, h_client_status, "0");
                CreateTimer(0.0, DeleteOverlay, GetClientUserId(client));
            }
            CPrintToChat(client,"{orange} Bu eklenti {darkblue}csgo-turkiye.com {orange}tarafından ücretsiz olarak paylaşılmıştır.");
            CPrintToChat(client, "%t", "Change Client Status");
        }
    }else{
        PrintToServer("%t", "Console Message");
    }
    return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client)){
        if(b_client_status[ client ])ShowOverlay(client, s_picture, 0.0);
        CPrintToChat(client, "%t", "Show Picture");
    }
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))return false;
	return IsClientInGame(client);
}