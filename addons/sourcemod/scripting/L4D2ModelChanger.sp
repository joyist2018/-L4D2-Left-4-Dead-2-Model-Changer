/*
1.9.2
Fixed api called returning Entity reference instead of Entity index.

1.9.3
Common infected model changing nolonger random it will cycle though they 1-34

1.9.4
Updated IsInfectedThirdPerson

1.9.5
Fixed some mistakes with code.
Saved some returns to varables instead of finding it again.
Optmized code somemore.

1.9.6
Added Deathmodel animations.
*/



#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
//#include <lmc_modelchanger>
#pragma semicolon 1

#define MAX_FRAMECHECK 20

#define PLUGIN_VERSION "1.9.6"

#define ZOMBIECLASS_SMOKER		1
#define ZOMBIECLASS_BOOMER		2
#define ZOMBIECLASS_HUNTER		3
#define ZOMBIECLASS_SPITTER		4
#define ZOMBIECLASS_JOCKEY		5
#define ZOMBIECLASS_CHARGER		6
#define ZOMBIECLASS_TANK		8

#define Witch_Normal			"models/infected/witch.mdl"
#define Witch_Bride				"models/infected/witch_bride.mdl"

#define Infected_TankNorm		"models/infected/hulk.mdl"
#define Infected_TankSac		"models/infected/hulk_dlc3.mdl"
#define Infected_Boomer			"models/infected/boomer.mdl"
#define Infected_Boomette		"models/infected/boomette.mdl"
#define Infected_Hunter			"models/infected/hunter.mdl"
#define Infected_Smoker			"models/infected/smoker.mdl"
#define MODEL_NICK 				"models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE			"models/survivors/survivor_producer.mdl"
#define MODEL_COACH				"models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS				"models/survivors/survivor_mechanic.mdl"
#define MODEL_BILL				"models/survivors/survivor_namvet.mdl"
#define MODEL_ZOEY				"models/survivors/survivor_teenangst.mdl"
#define MODEL_ZOEYLIGHT			"models/survivors/survivor_teenangst_light.mdl"
#define MODEL_FRANCIS			"models/survivors/survivor_biker.mdl"
#define MODEL_FRANCISLIGHT		"models/survivors/survivor_biker_light.mdl"
#define MODEL_LOUIS				"models/survivors/survivor_manager.mdl"
#define NPC_Pilot				"models/npcs/rescue_pilot_01.mdl"

#define Infected_RiotCop		"models/infected/common_male_riot.mdl"
#define Infected_Mudder			"models/infected/common_male_mud.mdl"
#define Infected_Ceda			"models/infected/common_male_ceda.mdl"
#define Infected_Clown			"models/infected/common_male_clown.mdl"
#define Infected_Jimmy			"models/infected/common_male_jimmy.mdl"
#define Infected_Fallen			"models/infected/common_male_fallen_survivor.mdl"

#define Infected_Common1		"models/infected/common_male_tshirt_cargos.mdl"
#define Infected_Common2		"models/infected/common_male_tankTop_jeans.mdl"
#define Infected_Common3		"models/infected/common_male_dressShirt_jeans.mdl"
#define Infected_Common4		"models/infected/common_female_tankTop_jeans.mdl"
#define Infected_Common5		"models/infected/common_female_tshirt_skirt.mdl"
#define Infected_Common6		"models/infected/common_male_roadcrew.mdl"
#define Infected_Common7		"models/infected/common_male_tankTop_overalls.mdl"
#define Infected_Common8		"models/infected/common_male_tankTop_jeans_rain.mdl"
#define Infected_Common9		"models/infected/common_female_tankTop_jeans_rain.mdl"
#define Infected_Common10		"models/infected/common_male_roadcrew_rain.mdl"
#define Infected_Common11		"models/infected/common_male_tshirt_cargos_swamp.mdl"
#define Infected_Common12		"models/infected/common_male_tankTop_overalls_swamp.mdl"
#define Infected_Common13		"models/infected/common_female_tshirt_skirt_swamp.mdl"
#define Infected_Common14		"models/infected/common_male_formal.mdl"
#define Infected_Common15		"models/infected/common_female_formal.mdl"
#define Infected_Common16		"models/infected/common_military_male01.mdl"
#define Infected_Common17		"models/infected/common_police_male01.mdl"
#define Infected_Common18		"models/infected/common_male_baggagehandler_01.mdl"
#define Infected_Common19		"models/infected/common_tsaagent_male01.mdl"
#define Infected_Common20		"models/infected/common_shadertest.mdl"
#define Infected_Common21		"models/infected/common_female_nurse01.mdl"
#define Infected_Common22		"models/infected/common_surgeon_male01.mdl"
#define Infected_Common23		"models/infected/common_worker_male01.mdl"
#define Infected_Common24		"models/infected/common_morph_test.mdl"
#define Infected_Common25		"models/infected/common_male_biker.mdl"
#define Infected_Common26		"models/infected/common_female01.mdl"
#define Infected_Common27		"models/infected/common_male01.mdl"
#define Infected_Common28		"models/infected/common_male_suit.mdl"
#define Infected_Common29		"models/infected/common_patient_male01_l4d2.mdl"
#define Infected_Common30		"models/infected/common_male_polo_jeans.mdl"
#define Infected_Common31		"models/infected/common_female_rural01.mdl"
#define Infected_Common32		"models/infected/common_male_rural01.mdl"
#define Infected_Common33		"models/infected/common_male_pilot.mdl"
#define Infected_Common34		"models/infected/common_test.mdl"


static iHiddenOwner[2048+1] = {0, ...};
static iHiddenEntity[2048+1] = {0, ...};
static iHiddenEntityRef[2048+1];
static iHiddenIndex[MAXPLAYERS+1] = {0, ...};
static bool:bThirdPerson[MAXPLAYERS+1] = {false, ...};
static iSavedModel[MAXPLAYERS+1] = {0, ...};
static bool:bAutoApplyMsg[MAXPLAYERS+1];//1.4
static bool:bAutoBlockedMsg[MAXPLAYERS+1][9];//1.4
static bool:bIsIncapped[MAXPLAYERS+1] = {false, ...};

static Handle:hCvar_AdminOnlyModel = INVALID_HANDLE;
static bool:g_bAdminOnly = false;

static Handle:hCvar_AllowTank = INVALID_HANDLE;
static Handle:hCvar_AllowHunter = INVALID_HANDLE;
static Handle:hCvar_AllowSmoker = INVALID_HANDLE;
static Handle:hCvar_AllowBoomer = INVALID_HANDLE;
static Handle:hCvar_AllowSurvivors = INVALID_HANDLE;
static Handle:hCvar_AiChanceSurvivor = INVALID_HANDLE;
static Handle:hCvar_AiChanceInfected = INVALID_HANDLE;
static Handle:hCvar_TankModel = INVALID_HANDLE;
static Handle:hCvar_HideDeathModel = INVALID_HANDLE;
static Handle:hCvar_HideBotsModel = INVALID_HANDLE;
static bool:g_bAllowTank = false;
static bool:g_bAllowHunter = false;
static bool:g_bAllowSmoker = false;
static bool:g_bAllowBoomer = false;
static bool:g_bAllowSurvivors = false;
static bool:g_bTankModel = false;
static bool:g_bHideBotsModel;
static g_iHideDeathModel;
static g_iAiChanceSurvivor = 50;
static g_iAiChanceInfected = 50;

static Handle:hCookie_LmcCookie = INVALID_HANDLE;

static Handle:hCvar_AnnounceDelay = INVALID_HANDLE;
static Handle:hCvar_AnnounceMode = INVALID_HANDLE;
static Float:g_fAnnounceDelay = 7.0;
static g_iAnnounceMode = 3;

static bool:bHideDeathModel = false;

new Handle:g_hOnClientModelApplied = INVALID_HANDLE;
new Handle:g_hOnClientModelAppliedPre = INVALID_HANDLE;
new Handle:g_hOnClientModelBlocked = INVALID_HANDLE;
new Handle:g_hOnClientModelChanged = INVALID_HANDLE;
new Handle:g_hOnClientModelDestroyed = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("L4D2ModelChanger");
	CreateNative("LMC_GetClientOverlayModel", GetOverlayModel);
	CreateNative("LMC_SetClientOverlayModel", SetOverlayModel);
	CreateNative("LMC_SetEntityOverlayModel", SetEntityOverlayModel);
	CreateNative("LMC_GetEntityOverlayModel", GetEntityOverlayModel);
	CreateNative("LMC_HideClientOverlayModel", HideOverlayModel);
	
	g_hOnClientModelApplied = CreateGlobalForward("LMC_OnClientModelApplied", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);
	g_hOnClientModelAppliedPre = CreateGlobalForward("LMC_OnClientModelAppliedPre", ET_Event, Param_Cell, Param_CellByRef);
	g_hOnClientModelBlocked  = CreateGlobalForward("LMC_OnClientModelSelected", ET_Event, Param_Cell, Param_String);
	g_hOnClientModelChanged  = CreateGlobalForward("LMC_OnClientModelChanged", ET_Event, Param_Cell, Param_Cell, Param_String);
	g_hOnClientModelDestroyed  = CreateGlobalForward("LMC_OnClientModelDestroyed", ET_Event, Param_Cell, Param_Cell);
	
	return APLRes_Success;
}

public Plugin:myinfo =
{
	name = "Left 4 Dead 2 Model Changer",
	author = "Lux",
	description = "Left 4 Dead Model Changer for Survivors and Infected",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2449184#post2449184"
};

#define ENABLE_AUTOEXEC true

public OnPluginStart()
{
	RegConsoleCmd("sm_lmc", ShowMenu, "Brings up a menu to select a client's model");
	
	CreateConVar("l4d2modelchanger_version", PLUGIN_VERSION, "Left 4 Dead Model Changer", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	hCvar_AdminOnlyModel = CreateConVar("lmc_adminonly", "0", "Allow admins to only change models? (1 = true) NOTE: this will disable announcement to player who join.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_AllowTank = CreateConVar("lmc_allowtank", "0", "Allow Tanks to have custom model? (1 = true)",FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_AllowHunter = CreateConVar("lmc_allowhunter", "1", "Allow Hunters to have custom model? (1 = true)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_AllowSmoker = CreateConVar("lmc_allowsmoker", "1", "Allow Smoker to have custom model? (1 = true)",FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_AllowBoomer = CreateConVar("lmc_allowboomer", "1", "Allow Boomer to have custom model? (1 = true)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_AllowSurvivors = CreateConVar("lmc_allowSurvivors", "1", "Allow Survivors to have custom model? (1 = true)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_AnnounceDelay = CreateConVar("lmc_announcedelay", "15.0", "Delay On which a message is displayed for !lmc command", FCVAR_NOTIFY, true, 1.0, true, 360.0);
	hCvar_AnnounceMode = CreateConVar("lmc_announcemode", "1", "Display Mode for !lmc command (0 = off, 1 = Print to chat, 2 = Center text, 3 = Director Hint)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	hCvar_AiChanceSurvivor = CreateConVar("lmc_ai_model_survivor", "10", "(0 = disable custom models)chance on which the AI will get a custom model", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	hCvar_AiChanceInfected = CreateConVar("lmc_ai_model_infected", "15", "(0 = disable custom models)chance on which the AI will get a custom model", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	hCvar_TankModel = CreateConVar("lmc_allow_tank_model_use", "0", "The tank model is big and don't look good on other models so i made it optional(1 = true)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_HideDeathModel = CreateConVar("lmc_hide_defib_model", "2", "(-1 to do nothing at all)(0 = But create Deathmodels) (1 = custom model death model) (2 = Custom model ragdoll and hide death model)", FCVAR_NOTIFY, true, -1.0, true, 2.0);
	hCvar_HideBotsModel = CreateConVar("lmc_spec_hide_bots", "1", "When spectating bots in firstperson hide custom model? (0 = disable will save some cpu power)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hCookie_LmcCookie = RegClientCookie("lmc_cookie", "", CookieAccess_Protected);
	
	HookConVarChange(hCvar_AdminOnlyModel, eConvarChanged);
	HookConVarChange(hCvar_AllowTank, eConvarChanged);
	HookConVarChange(hCvar_AllowHunter, eConvarChanged);
	HookConVarChange(hCvar_AllowSmoker, eConvarChanged);
	HookConVarChange(hCvar_AllowBoomer, eConvarChanged);
	HookConVarChange(hCvar_AllowSurvivors, eConvarChanged);
	HookConVarChange(hCvar_AnnounceDelay, eConvarChanged);
	HookConVarChange(hCvar_AnnounceMode, eConvarChanged);
	HookConVarChange(hCvar_AiChanceSurvivor, eConvarChanged);
	HookConVarChange(hCvar_AiChanceInfected, eConvarChanged);
	HookConVarChange(hCvar_TankModel, eConvarChanged);
	HookConVarChange(hCvar_HideDeathModel, eConvarChanged);
	HookConVarChange(hCvar_HideBotsModel, eConvarChanged);
	CvarsChanged();
	
	
	HookEvent("player_death", ePlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", ePlayerSpawn);
	HookEvent("player_team", eTeamChange);
	HookEvent("player_incapacitated", eSetColour);
	HookEvent("revive_end", eSetColour);
	
	#if ENABLE_AUTOEXEC
	AutoExecConfig(true, "L4D2ModelChanger1.9");
	#endif
}

public OnMapStart()
{
	
	PrecacheModel(Witch_Normal, true);
	PrecacheModel(Witch_Bride, true);
	PrecacheModel(Infected_RiotCop, true);
	PrecacheModel(Infected_Mudder, true);
	PrecacheModel(NPC_Pilot, true);
	PrecacheModel(Infected_Ceda, true);
	PrecacheModel(Infected_Clown, true);
	PrecacheModel(Infected_Jimmy, true);
	PrecacheModel(Infected_Fallen, true);
	PrecacheModel(Infected_TankNorm, true);
	PrecacheModel(Infected_TankSac, true);
	PrecacheModel(Infected_Boomer, true);
	PrecacheModel(Infected_Boomette, true);
	PrecacheModel(Infected_Hunter, true);
	PrecacheModel(Infected_Smoker, true);
	PrecacheModel(Infected_Common1, true);
	PrecacheModel(Infected_Common2, true);
	PrecacheModel(Infected_Common3, true);
	PrecacheModel(Infected_Common4, true);
	PrecacheModel(Infected_Common5, true);
	PrecacheModel(Infected_Common6, true);
	PrecacheModel(Infected_Common7, true);
	PrecacheModel(Infected_Common8, true);
	PrecacheModel(Infected_Common9, true);
	PrecacheModel(Infected_Common10, true);
	PrecacheModel(Infected_Common11, true);
	PrecacheModel(Infected_Common12, true);
	PrecacheModel(Infected_Common13, true);
	PrecacheModel(Infected_Common14, true);
	PrecacheModel(Infected_Common15, true);
	PrecacheModel(Infected_Common16, true);
	PrecacheModel(Infected_Common17, true);
	PrecacheModel(Infected_Common18, true);
	PrecacheModel(Infected_Common19, true);
	PrecacheModel(Infected_Common20, true);
	PrecacheModel(Infected_Common21, true);
	PrecacheModel(Infected_Common22, true);
	PrecacheModel(Infected_Common23, true);
	PrecacheModel(Infected_Common24, true);
	PrecacheModel(Infected_Common25, true);
	PrecacheModel(Infected_Common26, true);
	PrecacheModel(Infected_Common27, true);
	PrecacheModel(Infected_Common28, true);
	PrecacheModel(Infected_Common29, true);
	PrecacheModel(Infected_Common30, true);
	PrecacheModel(Infected_Common31, true);
	PrecacheModel(Infected_Common32, true);
	PrecacheModel(Infected_Common33, true);
	PrecacheModel(Infected_Common34, true);
	PrecacheModel(NPC_Pilot, true);
	PrecacheModel(MODEL_NICK, true);
	PrecacheModel(MODEL_ROCHELLE, true);
	PrecacheModel(MODEL_COACH, true);
	PrecacheModel(MODEL_ELLIS, true);
	PrecacheModel(MODEL_BILL, true);
	PrecacheModel(MODEL_ZOEY, true);
	PrecacheModel(MODEL_ZOEYLIGHT, true);
	PrecacheModel(MODEL_FRANCIS, true);
	PrecacheModel(MODEL_FRANCISLIGHT, true);
	PrecacheModel(MODEL_LOUIS, true);
	PrecacheSound("ui/menu_countdown.wav", true);
	CvarsChanged();
	
	
	/*THIRDPERSON FIX*/
	for(new i = 1; i <= MaxClients; i++)
	{
		bAutoApplyMsg[i] = true;//1.4
		for(new b = 0; b < sizeof(bAutoBlockedMsg[]); b++)//1.4
			bAutoBlockedMsg[i][b] = true;
	}
	
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_bAdminOnly = GetConVarInt(hCvar_AdminOnlyModel) > 0;
	g_bAllowTank = GetConVarInt(hCvar_AllowTank) > 0;
	g_bAllowHunter = GetConVarInt(hCvar_AllowHunter) > 0;
	g_bAllowSmoker = GetConVarInt(hCvar_AllowSmoker) > 0;
	g_bAllowBoomer = GetConVarInt(hCvar_AllowBoomer) > 0;
	g_bAllowSurvivors = GetConVarInt(hCvar_AllowSurvivors) > 0;
	g_iHideDeathModel = GetConVarInt(hCvar_HideDeathModel);
	g_bHideBotsModel = GetConVarInt(hCvar_HideBotsModel) > 0;
	g_iAiChanceSurvivor = GetConVarInt(hCvar_AiChanceSurvivor);
	g_iAiChanceInfected = GetConVarInt(hCvar_AiChanceInfected);
	g_bTankModel = GetConVarInt(hCvar_TankModel) > 0;
	g_fAnnounceDelay = GetConVarFloat(hCvar_AnnounceDelay);
	g_iAnnounceMode = GetConVarInt(hCvar_AnnounceMode);
}

//heil timocop he done this before me
static BeWitched(iClient, const String:sModel[], const bool:bBaseReattach)
{
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	new iEntity = iHiddenIndex[iClient];
	if(IsValidEntRef(iEntity) && !bBaseReattach)
	{
		SetEntityModel(iEntity, sModel);
		Call_StartForward(g_hOnClientModelChanged);
		Call_PushCell(iClient);
		Call_PushCell(EntRefToEntIndex(iEntity));
		Call_PushString(sModel);
		Call_Finish();
		return;
	}
	else if(bBaseReattach)
		AcceptEntityInput(iEntity, "Kill");
	
	
	iEntity = CreateEntityByName("prop_dynamic_ornament");
	if(iEntity < 0)
		return;
	
	DispatchKeyValue(iEntity, "model", sModel);
	
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", iClient);
	
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetAttached", iClient);
	AcceptEntityInput(iEntity, "TurnOn");
	
	SetEntityRenderMode(iClient, RENDER_NONE);
	
	iHiddenIndex[iClient] = EntIndexToEntRef(iEntity);
	iHiddenOwner[iEntity] = GetClientUserId(iClient);
	
	SetEntProp(iClient, Prop_Send, "m_nMinGPULevel", 1);
	SetEntProp(iClient, Prop_Send, "m_nMaxGPULevel", 1);
	
	Call_StartForward(g_hOnClientModelApplied);
	Call_PushCell(iClient);
	Call_PushCell(iEntity);
	Call_PushString(sModel);
	Call_PushCell(bBaseReattach);
	Call_Finish();
	
	if(IsFakeClient(iClient) && !g_bHideBotsModel)
		return;
	
	SDKHook(iEntity, SDKHook_SetTransmit, HideModel);
}

public Action:HideModel(iEntity, iClient)
{
	if(IsFakeClient(iClient))
		return Plugin_Continue;
	
	if(!IsPlayerAlive(iClient))
		if(GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 4)
			if(GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget") == GetClientOfUserId(iHiddenOwner[iEntity]))
				return Plugin_Handled;
	
	static iOwner;
	iOwner = GetClientOfUserId(iHiddenOwner[iEntity]);
	
	if(iOwner < 1 || !IsClientInGame(iOwner))
		return Plugin_Continue;
	
	switch(GetClientTeam(iOwner)) {
		case 2: {
			if(iOwner != iClient)
				return Plugin_Continue;
			
			if(!IsSurvivorThirdPerson(iClient))
				return Plugin_Handled;
		}
		case 3: {
			static bool:bIsGhost;
			bIsGhost = GetEntProp(iOwner, Prop_Send, "m_isGhost", 1) > 0;
			
			if(iOwner != iClient) {
				//Hide model for everyone else when is ghost mode exapt me
				if(bIsGhost)
					return Plugin_Handled;
			}
			else {
				// Hide my model when not in thirdperson
				if(bIsGhost)
				{
					SetEntityRenderMode(iOwner, RENDER_NONE);
				}
				if(!IsInfectedThirdPerson(iOwner))
					return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public ePlayerDeath(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	static iVictim;
	iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	static iEntity;
	
	if(iVictim > 0 && iVictim <= MaxClients && IsClientInGame(iVictim))
	{
		static iTeam;
		iTeam = GetClientTeam(iVictim);
		
		iEntity = EntRefToEntIndex(iHiddenIndex[iVictim]);
		if(iTeam == 3 && IsValidEntRef(iHiddenIndex[iVictim]))
		{
			AcceptEntityInput(iEntity, "ClearParent");
			
			SetEntProp(iEntity, Prop_Send, "m_bClientSideRagdoll", 1, 1);
			
			SetVariantString("OnUser1 !self:Kill::0.1:1");
			AcceptEntityInput(iEntity, "AddOutput");
			AcceptEntityInput(iEntity, "FireUser1");
			iHiddenIndex[iVictim] = -1;
			return;
		}
		
		if(g_iHideDeathModel == -1)
		{
			if(IsValidEntRef(iHiddenIndex[iVictim]))
				AcceptEntityInput(iEntity, "Kill");
			return;
		}
		
		static iEnt;
		if(iTeam == 2)
		{
			bHideDeathModel = true;
			iEnt = CreateEntityByName("survivor_death_model");
			bHideDeathModel = false;
			if(iEnt < 0)
				return;
			
			DispatchSpawn(iEnt);
			ActivateEntity(iEnt);
			
			SetEntProp(iEnt, Prop_Data, "m_nModelIndex", GetEntProp(iVictim, Prop_Data, "m_nModelIndex"));
			SetEntProp(iEnt, Prop_Send, "m_nCharacterType", GetEntProp(iVictim, Prop_Send, "m_survivorCharacter"));
			
			static String:sModel[31];
			GetEntPropString(iVictim, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
			switch(sModel[29])
			{
				case 'b'://nick
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 679, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 678, 2);
				}
				case 'd'://rochelle
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 686, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 685, 2);
				}
				case 'c'://coach
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 668, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 667, 2);
				}
				case 'h'://ellis
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 683, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 682, 2);
				}
				case 'v'://bill
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 771, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 770, 2);
				}
				case 'n'://zoey
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 808, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 807, 2);
				}
				case 'e'://francis
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 774, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 773, 2);
				}
				case 'a'://louis
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 771, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 770, 2);
				}
				case 'w'://adawong
				{
					if(bIsIncapped[iVictim])
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 686, 2);
					else
						SetEntProp(iEnt, Prop_Send, "m_nSequence", 687, 2);
				}
			}
			
			SetEntPropFloat(iEnt, Prop_Send, "m_flPlaybackRate", 1.0);
			SetEntProp(iEnt, Prop_Send, "m_bClientSideAnimation", 1, 1);
			
			static Float:fPos[3];
			static Float:fAng[3];
			
			GetClientAbsOrigin(iVictim, fPos);
			GetClientAbsAngles(iVictim, fAng);
			
			fPos[2]++;
			static Handle:trace;
			trace = TR_TraceRayFilterEx(fPos, Float:{90.0, 0.0, 0.0}, MASK_SHOT, RayType_Infinite, _TraceFilter);
			
			static Float:fEnd[3];
			TR_GetEndPosition(fEnd, trace); // retrieve our trace endpoint
			CloseHandle(trace);
			
			fAng[0] = 0.0;
			
			if(150 > GetVectorDistance(fPos, fEnd))//traceray is from the center not from the 4 corners of the collision box should help with deathmodels teleporting down a ledge or though a prop.
				TeleportEntity(iEnt, fEnd, fAng, NULL_VECTOR);
			else
			{
				fPos[2]--;
				TeleportEntity(iEnt, fPos, fAng, NULL_VECTOR);
			}
			
		
			
			static iWeapon;
			iWeapon = GetPlayerWeaponSlot(iVictim, 1);
			if(iWeapon > MaxClients && iWeapon <= 2048 && IsValidEntity(iWeapon))
				SDKHooks_DropWeapon(iVictim, iWeapon);
			
			if(g_iHideDeathModel < 1 && IsValidEntRef(iHiddenIndex[iVictim]))
			{
				AcceptEntityInput(iEntity, "Kill");
				iHiddenIndex[iVictim] = -1;
				return;
			}
		}
		
		if(!IsValidEntRef(iHiddenIndex[iVictim]))
			return;
		
		SetEntProp(iEntity, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(iEntity, Prop_Send, "m_iGlowType", 0);
		SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", 0);
		SetEntProp(iEntity, Prop_Send, "m_nGlowRangeMin", 0);
		
		SDKUnhook(iEntity, SDKHook_SetTransmit, HideModel);
		
		if(iTeam != 2)
			return;
		
		iHiddenIndex[iVictim] = -1;
		iHiddenOwner[iEntity] = -1;
		
		AcceptEntityInput(iEntity, "ClearParent");
		SetEntProp(iEnt, Prop_Send, "m_nMinGPULevel", 1);
		SetEntProp(iEnt, Prop_Send, "m_nMaxGPULevel", 1);
		
		if(g_iHideDeathModel == 1)
		{
			AcceptEntityInput(iEntity, "Detach");
			
			SetVariantString("!activator");
			AcceptEntityInput(iEntity, "SetParent", iEnt);
			
			SetVariantString("!activator");
			AcceptEntityInput(iEntity, "SetAttached", iEnt);
			
			SetEntityRenderMode(iEnt, RENDER_NONE);
			return;
		}
		
		SetEntProp(iEntity, Prop_Send, "m_bClientSideAnimation", 1, 1);
		SetEntProp(iEntity, Prop_Send, "m_bClientSideRagdoll", 1, 1);
		SetVariantString("OnUser1 !self:Kill::0.1:1");
		AcceptEntityInput(iEntity, "AddOutput");
		AcceptEntityInput(iEntity, "FireUser1");
		SetEntityRenderMode(iEnt, RENDER_NONE);
	}
	else
	{
		iVictim = GetEventInt(hEvent, "entityid");
		if(iVictim < MaxClients+1 || iVictim > 2048 || !IsValidEntity(iVictim))
			return;
		
		if(!IsValidEntRef(iHiddenEntity[iVictim]))
			return;
		
		iEntity = EntRefToEntIndex(iHiddenEntity[iVictim]);
		
		SetEntProp(iEntity, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(iEntity, Prop_Send, "m_iGlowType", 0);
		SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", 0);
		SetEntProp(iEntity, Prop_Send, "m_nGlowRangeMin", 0);
		
		SetEntProp(iEntity, Prop_Send, "m_bClientSideAnimation", 1, 1);
		SetEntProp(iEntity, Prop_Send, "m_bClientSideRagdoll", 1, 1);
		SetEntPropFloat(iVictim, Prop_Send, "m_flModelScale", 999.0);
		
		AcceptEntityInput(iEntity, "ClearParent");
		SetVariantString("OnUser1 !self:Kill::0.1:1");
		AcceptEntityInput(iEntity, "AddOutput");
		AcceptEntityInput(iEntity, "FireUser1");
	}
}

public ePlayerSpawn(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	if(IsValidEntRef(iHiddenIndex[iClient]))
	{
		AcceptEntityInput(iHiddenIndex[iClient], "kill");
		iHiddenIndex[iClient] = -1;
	}
	
	SetEntProp(iClient, Prop_Send, "m_nMinGPULevel", 0);
	SetEntProp(iClient, Prop_Send, "m_nMaxGPULevel", 0);
	
	static iTeam;
	iTeam = GetClientTeam(iClient);
	
	if(IsFakeClient(iClient))//1.4
		if(iTeam == 3)
	{
		switch(GetEntProp(iClient, Prop_Send, "m_zombieClass"))//1.4
		{
			case ZOMBIECLASS_SMOKER:
			{
				if(!g_bAllowSmoker)
					return;
			}
			case ZOMBIECLASS_BOOMER:
			{
				if(!g_bAllowBoomer)
					return;
			}
			case ZOMBIECLASS_HUNTER:
			{
				if(!g_bAllowHunter)
					return;
			}
			case 4, 5, 6, 7:
			return;
			case ZOMBIECLASS_TANK:
			{
				if(!g_bAllowTank)
					return;
			}
		}
	}
		else if(iTeam == 2)
			if(!g_bAllowSurvivors)
				return;
	
	if(!IsFakeClient(iClient))
	{
		if(iSavedModel[iClient] < 2)
			return;
		
		ModelIndex(iClient, iSavedModel[iClient], false);
		return;
	}
	else
		RequestFrame(NextFrame, iClient);
}

public NextFrame(any:iClient)
{
	if(!IsClientInGame(iClient) || !IsFakeClient(iClient) || !IsPlayerAlive(iClient))
		return;
	
	static iTeam;
	iTeam = GetClientTeam(iClient);
	
	if(iTeam == 2)
	{
		if(GetRandomInt(1, 100) < g_iAiChanceSurvivor)
			ModelIndex(iClient, GetRandomInt(1, 25), false);
		
		return;
	}
	else if(iTeam == 3)
	{
		if(GetRandomInt(1, 100) < g_iAiChanceInfected)
			ModelIndex(iClient, GetRandomInt(1, 25), false);
	}
}

public eSetColour(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
	
	if(!IsValidEntRef(iHiddenIndex[iClient]))
		return;
	
	SetEntityRenderMode(iClient, RENDER_NONE);
}

public eTeamChange(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
	
	new iEntity = iHiddenIndex[iClient];
	
	if(!IsValidEntRef(iEntity))
		return;
	
	AcceptEntityInput(iEntity, "kill");
	iHiddenIndex[iClient] = -1;
}


public OnClientDisconnect(iClient)
{
	//1.3
	if(AreClientCookiesCached(iClient))
	{
		decl String:sCookie[3];
		IntToString(iSavedModel[iClient], sCookie, sizeof(sCookie));
		SetClientCookie(iClient, hCookie_LmcCookie, sCookie);
	}
	bAutoApplyMsg[iClient] = true;//1.4
	for(new b = 0; b < sizeof(bAutoBlockedMsg[]); b++)//1.4
		bAutoBlockedMsg[iClient][b] = true;
	
	
	new iEntity = iHiddenIndex[iClient];
	
	iHiddenIndex[iClient] = -1;
	iSavedModel[iClient] = 0;
	
	if(!IsValidEntRef(iEntity))
		return;
	
	AcceptEntityInput(iEntity, "kill");
}

/*borrowed some code from csm*/
public Action:ShowMenu(iClient, iArgs)
{
	if(iClient == 0)
	{
		ReplyToCommand(iClient, "[LMC] Menu is in-game only.");
		return Plugin_Continue;
	}
	if(GetUserFlagBits(iClient) == 0 && g_bAdminOnly)
	{
		ReplyToCommand(iClient, "\x04[LMC] \x03Model Changer is only available to admins.");
		return Plugin_Continue;
	}
	if(!IsPlayerAlive(iClient) && bAutoBlockedMsg[iClient][8])
	{
		ReplyToCommand(iClient, "\x04[LMC] \x03Pick a Model to be Applied NextSpawn");
		bAutoBlockedMsg[iClient][8] = false;
	}
	new Handle:hMenu = CreateMenu(CharMenu);
	SetMenuTitle(hMenu, "Choose a Model");//1.4
	
	AddMenuItem(hMenu, "1", "Normal Models");
	AddMenuItem(hMenu, "15", "Random Common");
	AddMenuItem(hMenu, "2", "Witch");
	AddMenuItem(hMenu, "3", "Witch Bride");
	AddMenuItem(hMenu, "4", "Boomer");
	AddMenuItem(hMenu, "5", "Boomette");
	AddMenuItem(hMenu, "6", "Hunter");
	AddMenuItem(hMenu, "7", "Smoker");
	AddMenuItem(hMenu, "8", "Riot Cop");
	AddMenuItem(hMenu, "9", "MudMan");
	AddMenuItem(hMenu, "10", "Chopper Pilot");
	AddMenuItem(hMenu, "11", "CEDA");
	AddMenuItem(hMenu, "12", "Clown");
	AddMenuItem(hMenu, "13", "Jimmy Gibs");
	AddMenuItem(hMenu, "14", "Fallen Survivor");
	AddMenuItem(hMenu, "16", "Nick");
	AddMenuItem(hMenu, "17", "Rochelle");
	AddMenuItem(hMenu, "18", "Coach");
	AddMenuItem(hMenu, "19", "Ellis");
	AddMenuItem(hMenu, "20", "Bill");
	AddMenuItem(hMenu, "21", "Zoey");
	AddMenuItem(hMenu, "22", "Francis");
	AddMenuItem(hMenu, "23", "Louis");
	AddMenuItem(hMenu, "24", "Tank");
	AddMenuItem(hMenu, "25", "Tank DLC");
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 15);
	
	return Plugin_Continue;
}

public CharMenu(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:sItem[4];
			GetMenuItem(hMenu, param2, sItem, sizeof(sItem));
			ModelIndex(param1, StringToInt(sItem), true);
			ShowMenu(param1, 0);
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	}
}

static ModelIndex(iClient, iCaseNum, bool:bUsingMenu=false)
{
	static String:sModel[PLATFORM_MAX_PATH];
	
	new Action:iResult;
	Call_StartForward(g_hOnClientModelBlocked);
	Call_PushCell(iClient);
	Call_PushStringEx(sModel, sizeof(sModel), SM_PARAM_STRING_UTF8, SP_PARAMFLAG_BYREF);
	Call_Finish(iResult);
	
	switch(iResult)
	{
		case Plugin_Handled, Plugin_Stop:
		{
			return;
		}
		case Plugin_Changed:
		{
			if(sModel[0] != '\0')
			{
				BeWitched(iClient, sModel, false);
				return;
			}
			else
				LogError("[LMC] LMC_OnClientModelSelected forward you can't add an empty string");
		}
	}
	
	//1.4
	if(!IsFakeClient(iClient))
	{
		//1.3
		if(AreClientCookiesCached(iClient) && bUsingMenu)
		{
			decl String:sCookie[3];
			IntToString(iCaseNum, sCookie, sizeof(sCookie));
			SetClientCookie(iClient, hCookie_LmcCookie, sCookie);
		}
		iSavedModel[iClient] = iCaseNum;
		
		if(!IsPlayerAlive(iClient))
			return;
	}
	
	switch(GetClientTeam(iClient))
	{
		case 3:
		{
			switch(GetEntProp(iClient, Prop_Send, "m_zombieClass"))
			{
				case ZOMBIECLASS_SMOKER:
				{
					if(!g_bAllowSmoker)
					{//1.4
						if(IsFakeClient(iClient))
							return;
						
						
						if(!bUsingMenu && !bAutoBlockedMsg[iClient][0])
							return;
						
						PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Smoker");
						bAutoBlockedMsg[iClient][0] = false;
						return;
					}
				}
				case ZOMBIECLASS_BOOMER:
				{//1.4
					if(!g_bAllowBoomer)
					{
						if(IsFakeClient(iClient))
							return;
						
						if(!bUsingMenu && !bAutoBlockedMsg[iClient][1])
							return;
						
						PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Boomer");
						bAutoBlockedMsg[iClient][1] = false;
						return;
					}
				}
				case ZOMBIECLASS_HUNTER:
				{//1.4
					if(!g_bAllowHunter)
					{
						if(IsFakeClient(iClient))
							return;
						
						if(!bUsingMenu && !bAutoBlockedMsg[iClient][2])
							return;
						
						PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Hunter");
						bAutoBlockedMsg[iClient][2] = false;
						return;
					}
				}
				case ZOMBIECLASS_SPITTER:
				{//1.4
					if(IsFakeClient(iClient))
						return;
					
					if(!bUsingMenu && !bAutoBlockedMsg[iClient][3])
						return;
					
					PrintToChat(iClient, "\x04[LMC] \x03Models Don't Work for \x04Spitter");
					bAutoBlockedMsg[iClient][3] = false;
					return;
				}
				case ZOMBIECLASS_JOCKEY:
				{//1.4
					if(IsFakeClient(iClient))
						return;
					
					if(!bUsingMenu && !bAutoBlockedMsg[iClient][4])
						return;
					
					PrintToChat(iClient, "\x04[LMC] \x03Models Don't Work for \x04Jockey");
					bAutoBlockedMsg[iClient][4] = false;
					return;
				}
				case ZOMBIECLASS_CHARGER:
				{//1.4
					if(IsFakeClient(iClient))
						return;
					
					if(!bUsingMenu && !bAutoBlockedMsg[iClient][5])
						return;
					
					PrintToChat(iClient, "\x04[LMC] \x03Models Don't Work for \x04Charger");
					bAutoBlockedMsg[iClient][5] = false;
					return;
				}
				case ZOMBIECLASS_TANK:
				{//1.4
					if(!g_bAllowTank)
					{
						if(IsFakeClient(iClient))
							return;
						
						if(!bUsingMenu && !bAutoBlockedMsg[iClient][6])
							return;
						
						PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Tank");
						bAutoBlockedMsg[iClient][6] = false;
						return;
					}
				}
			}
		}
		case 2:
		{
			if(!g_bAllowSurvivors)
			{//1.4
				if(IsFakeClient(iClient))
					return;
				
				if(!bUsingMenu && !bAutoBlockedMsg[iClient][7])
					return;
				
				PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Survivors");
				bAutoBlockedMsg[iClient][7] = false;
				return;
			}
		}
	}
	
	static iModel;
	iModel = iCaseNum;
	new Action:iEndResult;
	Call_StartForward(g_hOnClientModelAppliedPre);
	Call_PushCell(iClient);
	Call_PushCellRef(iModel);
	Call_Finish(iEndResult);
	
	switch(iEndResult)
	{
		case Plugin_Handled, Plugin_Stop:
		{
			return;
		}
		
		case Plugin_Changed:
		{
			if(iModel < 1 || iModel > 25)
			{
				LogError("[LMC] LMC_OnClientModelAppliedPre forward Action was called with an out of bounds value iModel(%i)", iModel);
			}
			else
			{
				iCaseNum = iModel;
			}
		}
	}
	//model selection
	switch(iCaseNum)//1.4
	{
		case 1: {
			SetEntityRenderMode(iClient, RENDER_NORMAL);
			SetEntProp(iClient, Prop_Send, "m_nMinGPULevel", 0);
			SetEntProp(iClient, Prop_Send, "m_nMaxGPULevel", 0);
			
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Models will be default");
			bAutoApplyMsg[iClient] = false;
			
			new iEntity = iHiddenIndex[iClient];
			if(IsValidEntRef(iEntity))
			{
				AcceptEntityInput(iEntity, "kill");
				iHiddenIndex[iClient] = -1;
			}
			return;
		}
		case 2: {
			BeWitched(iClient, Witch_Normal, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Witch");
			bAutoApplyMsg[iClient] = false;
		}
		case 3: {
			BeWitched(iClient, Witch_Bride, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Witch Bride");
			bAutoApplyMsg[iClient] = false;
		}
		case 4: {
			BeWitched(iClient, Infected_Boomer, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Boomer");
			bAutoApplyMsg[iClient] = false;
		}
		case 5: {
			BeWitched(iClient, Infected_Boomette, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Boomette");
			bAutoApplyMsg[iClient] = false;
		}
		case 6: {
			BeWitched(iClient, Infected_Hunter, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Hunter");
			bAutoApplyMsg[iClient] = false;
		}
		case 7: {
			BeWitched(iClient, Infected_Smoker, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Smoker");
			bAutoApplyMsg[iClient] = false;
		}
		case 8: {
			BeWitched(iClient, Infected_RiotCop, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04RiotCop");
			bAutoApplyMsg[iClient] = false;
		}
		case 9: {
			BeWitched(iClient, Infected_Mudder, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04MudMen");
			bAutoApplyMsg[iClient] = false;
		}
		case 10: {
			BeWitched(iClient, NPC_Pilot, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Chopper Pilot");
			bAutoApplyMsg[iClient] = false;
		}
		case 11: {
			BeWitched(iClient, Infected_Ceda, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04CEDA Suit");
			bAutoApplyMsg[iClient] = false;
		}
		case 12: {
			BeWitched(iClient, Infected_Clown, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Clown");
			bAutoApplyMsg[iClient] = false;
		}
		case 13: {
			BeWitched(iClient, Infected_Jimmy, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Jimmy Gibs");
			bAutoApplyMsg[iClient] = false;
		}
		case 14: {
			BeWitched(iClient, Infected_Fallen, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Fallen Survivor");
			bAutoApplyMsg[iClient] = false;
		}
		case 15:
		{
			static iChoice = 1;//+1 each time amy player picks a common infected
			//maybe ill use the m_iSkin entprop for more variation but im not sure how that will effect stuff with thirdparty models with no variation comment if you do.
			
			switch(iChoice)
			{
				case 1: BeWitched(iClient, Infected_Common1, false);
				case 2: BeWitched(iClient, Infected_Common2, false);
				case 3: BeWitched(iClient, Infected_Common3, false);
				case 4: BeWitched(iClient, Infected_Common4, false);
				case 5: BeWitched(iClient, Infected_Common5, false);
				case 6: BeWitched(iClient, Infected_Common6, false);
				case 7: BeWitched(iClient, Infected_Common7, false);
				case 8: BeWitched(iClient, Infected_Common8, false);
				case 9: BeWitched(iClient, Infected_Common9, false);
				case 10: BeWitched(iClient, Infected_Common10, false);
				case 11: BeWitched(iClient, Infected_Common11, false);
				case 12: BeWitched(iClient, Infected_Common12, false);
				case 13: BeWitched(iClient, Infected_Common13, false);
				case 14: BeWitched(iClient, Infected_Common14, false);
				case 15: BeWitched(iClient, Infected_Common15, false);
				case 16: BeWitched(iClient, Infected_Common16, false);
				case 17: BeWitched(iClient, Infected_Common17, false);
				case 18: BeWitched(iClient, Infected_Common18, false);
				case 19: BeWitched(iClient, Infected_Common19, false);
				case 20: BeWitched(iClient, Infected_Common20, false);
				case 21: BeWitched(iClient, Infected_Common21, false);
				case 22: BeWitched(iClient, Infected_Common22, false);
				case 23: BeWitched(iClient, Infected_Common23, false);
				case 24: BeWitched(iClient, Infected_Common24, false);
				case 25: BeWitched(iClient, Infected_Common25, false);
				case 26: BeWitched(iClient, Infected_Common26, false);
				case 27: BeWitched(iClient, Infected_Common27, false);
				case 28: BeWitched(iClient, Infected_Common28, false);
				case 29: BeWitched(iClient, Infected_Common29, false);
				case 30: BeWitched(iClient, Infected_Common30, false);
				case 31: BeWitched(iClient, Infected_Common31, false);
				case 32: BeWitched(iClient, Infected_Common32, false);
				case 33: BeWitched(iClient, Infected_Common33, false);
				case 34: BeWitched(iClient, Infected_Common34, false);
			}
			iChoice++;
			if(iChoice > 34)
				iChoice = 1;
				
			
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Common Infected");
			bAutoApplyMsg[iClient] = false;
		}
		case 16: {
			BeWitched(iClient, MODEL_NICK, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Nick");
			bAutoApplyMsg[iClient] = false;
		}
		case 17: {
			BeWitched(iClient, MODEL_ROCHELLE, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Rochelle");
			bAutoApplyMsg[iClient] = false;
		}
		case 18: {
			BeWitched(iClient, MODEL_COACH, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Coach");
			bAutoApplyMsg[iClient] = false;
		}
		case 19: {
			BeWitched(iClient, MODEL_ELLIS, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Ellis");
			bAutoApplyMsg[iClient] = false;
		}
		case 20: {
			BeWitched(iClient, MODEL_BILL, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Bill");
			bAutoApplyMsg[iClient] = false;
		}
		case 21: {
			if(GetRandomInt(1, 100) > 50)
				BeWitched(iClient, MODEL_ZOEY, false);
			else
				BeWitched(iClient, MODEL_ZOEYLIGHT, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Zoey");
			bAutoApplyMsg[iClient] = false;
		}
		case 22: {
			if(GetRandomInt(1, 100) > 50)
				BeWitched(iClient, MODEL_FRANCIS, false);
			else
				BeWitched(iClient, MODEL_FRANCISLIGHT, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Francis");
			bAutoApplyMsg[iClient] = false;
		}
		case 23: {
			BeWitched(iClient, MODEL_LOUIS, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Louis");
			bAutoApplyMsg[iClient] = false;
		}
		case 24:
		{
			if(!g_bTankModel)
			{
				if(IsFakeClient(iClient))
					return;
				
				if(!bUsingMenu && !bAutoApplyMsg[iClient])
					return;
				
				PrintToChat(iClient, "\x04[LMC] \x03Tank Models are Disabled");
				bAutoApplyMsg[iClient] = false;
				return;
			}
			BeWitched(iClient, Infected_TankNorm, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Tank");
			bAutoApplyMsg[iClient] = false;
		}
		case 25:
		{
			if(!g_bTankModel)
			{
				if(IsFakeClient(iClient))
					return;
				
				if(!bUsingMenu && !bAutoApplyMsg[iClient])
					return;
				
				PrintToChat(iClient, "\x04[LMC] \x03Tank Models are Disabled");
				bAutoApplyMsg[iClient] = false;
				return;
			}
			BeWitched(iClient, Infected_TankSac, false);
			if(IsFakeClient(iClient))
				return;
			
			if(!bUsingMenu && !bAutoApplyMsg[iClient])
				return;
			
			PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Tank DLC");
			bAutoApplyMsg[iClient] = false;
		}
	}
	bAutoApplyMsg[iClient] = false;
}

public OnClientPostAdminCheck(iClient)
{
	if(IsFakeClient(iClient))
	{
		if(GetClientTeam(iClient) == 2)
			SDKHook(iClient, SDKHook_OnTakeDamagePost, eOnTakeDamagePost);
		
		return;
	}
	
	SDKHook(iClient, SDKHook_OnTakeDamagePost, eOnTakeDamagePost);
	
	if(g_iAnnounceMode != 0 && !g_bAdminOnly)
		CreateTimer(g_fAnnounceDelay, iClientInfo, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:iClientInfo(Handle:hTimer, any:iUserID)
{
	new iClient = GetClientOfUserId(iUserID);
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return Plugin_Stop;
	
	switch(g_iAnnounceMode)
	{
		case 1:
		{
			PrintToChat(iClient, "\x04[LMC] \x03To Change Model use chat Command \x04!lmc\x03");
			EmitSoundToClient(iClient, "ui/menu_countdown.wav");
		}
		case 2: PrintHintText(iClient, "[LMC] To Change Model use chat Command !lmc");
		case 3:
		{
			new iEntity = CreateEntityByName("env_instructor_hint");
			
			decl String:sValues[64];
			sValues[0] = '\0';
			
			FormatEx(sValues, sizeof(sValues), "hint%d", iClient);
			DispatchKeyValue(iClient, "targetname", sValues);
			DispatchKeyValue(iEntity, "hint_target", sValues);
			
			Format(sValues, sizeof(sValues), "10");
			DispatchKeyValue(iEntity, "hint_timeout", sValues);
			DispatchKeyValue(iEntity, "hint_range", "100");
			DispatchKeyValue(iEntity, "hint_icon_onscreen", "icon_tip");
			DispatchKeyValue(iEntity, "hint_caption", "[LMC] To Change Model use chat Command !lmc");
			Format(sValues, sizeof(sValues), "%i %i %i", GetRandomInt(1, 255), GetRandomInt(100, 255), GetRandomInt(1, 255));
			DispatchKeyValue(iEntity, "hint_color", sValues);
			DispatchSpawn(iEntity);
			AcceptEntityInput(iEntity, "ShowHint", iClient);
			
			Format(sValues, sizeof(sValues), "OnUser1 !self:Kill::6:1");
			SetVariantString(sValues);
			AcceptEntityInput(iEntity, "AddOutput");
			AcceptEntityInput(iEntity, "FireUser1");
		}
	}
	return Plugin_Stop;
}

//malformed model fix for the real model changing and messing up stuff like invis explot with the menu
public OnGameFrame()
{
	static iFrameskip = 0;
	static iFrameskipColour = 0;
	iFrameskip = (iFrameskip + 1) % MAX_FRAMECHECK;
	
	if(iFrameskip != 0 || !IsServerProcessing())
		return;
	
	iFrameskipColour = (iFrameskipColour + 1) % 480;
	
	if(iFrameskipColour != 0)
	{
		for(new i = 1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			static iEnt;
			if(!IsValidEntRef(iHiddenIndex[i]) && !IsValidEntRef(iHiddenEntityRef[i]))
				SetEntityRenderMode(i, RENDER_NORMAL);
			
			if(IsValidEntRef(iHiddenIndex[i]))
			{
				SetEntityRenderMode(i, RENDER_NONE);
				iEnt = EntRefToEntIndex(iHiddenIndex[i]);
				
				if(GetEntProp(iEnt, Prop_Send, "m_nGlowRange") > 0 && GetEntProp(i, Prop_Send, "m_nGlowRange") == 0)
					continue;
				if(GetEntProp(iEnt, Prop_Send, "m_iGlowType") > 0 && GetEntProp(i, Prop_Send, "m_iGlowType") == 0)
					continue;
				if(GetEntProp(iEnt, Prop_Send, "m_glowColorOverride") > 0 && GetEntProp(i, Prop_Send, "m_glowColorOverride") == 0)
					continue;
				if(GetEntProp(iEnt, Prop_Send, "m_nGlowRangeMin") > 0 && GetEntProp(i, Prop_Send, "m_nGlowRangeMin") == 0)
					continue;
				
				SetEntProp(iEnt, Prop_Send, "m_nGlowRange", GetEntProp(i, Prop_Send, "m_nGlowRange"));
				SetEntProp(iEnt, Prop_Send, "m_iGlowType", GetEntProp(i, Prop_Send, "m_iGlowType"));
				SetEntProp(iEnt, Prop_Send, "m_glowColorOverride", GetEntProp(i, Prop_Send, "m_glowColorOverride"));
				SetEntProp(iEnt, Prop_Send, "m_nGlowRangeMin", GetEntProp(i, Prop_Send, "m_nGlowRangeMin"));
			}
			
			static iModelIndex[MAXPLAYERS+1] = {0, ...};
			if(iModelIndex[i] == GetEntProp(i, Prop_Data, "m_nModelIndex", 2))
				continue;
			
			iModelIndex[i] = GetEntProp(i, Prop_Data, "m_nModelIndex", 2);
			
			if(!IsValidEntRef(iHiddenIndex[i]))
				continue;
			
			static String:sModel[PLATFORM_MAX_PATH];
			GetEntPropString(iHiddenIndex[i], Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			BeWitched(i, sModel, true);
		}
	}
	
	static iFrameSkipOther;
	iFrameSkipOther = (iFrameSkipOther + 1) % 1480;
	
	if(iFrameSkipOther != 0)
	{
		static i;
		for(i = MaxClients+1;i <= 2048;i++)
		{
			if(!IsValidEntRef(iHiddenEntityRef[i]))
				continue;
			
			if(!IsValidEntRef(iHiddenEntity[i]))
				continue;
			
			static iEnt;
			iEnt = EntRefToEntIndex(iHiddenEntity[i]);
			SetEntityRenderFx(i, RENDERFX_HOLOGRAM);
			SetEntityRenderColor(i, 0, 0, 0, 0);
			
			if(GetEntProp(iEnt, Prop_Send, "m_nGlowRange") > 0 && GetEntProp(i, Prop_Send, "m_nGlowRange") == 0)
				continue;
			if(GetEntProp(iEnt, Prop_Send, "m_iGlowType") > 0 && GetEntProp(i, Prop_Send, "m_iGlowType") == 0)
				continue;
			if(GetEntProp(iEnt, Prop_Send, "m_glowColorOverride") > 0 && GetEntProp(i, Prop_Send, "m_glowColorOverride") == 0)
				continue;
			if(GetEntProp(iEnt, Prop_Send, "m_nGlowRangeMin") > 0 && GetEntProp(i, Prop_Send, "m_nGlowRangeMin") == 0)
				continue;
			
			SetEntProp(iEnt, Prop_Send, "m_nGlowRange", GetEntProp(i, Prop_Send, "m_nGlowRange"));
			SetEntProp(iEnt, Prop_Send, "m_iGlowType", GetEntProp(i, Prop_Send, "m_iGlowType"));
			SetEntProp(iEnt, Prop_Send, "m_glowColorOverride", GetEntProp(i, Prop_Send, "m_glowColorOverride"));
			SetEntProp(iEnt, Prop_Send, "m_nGlowRangeMin", GetEntProp(i, Prop_Send, "m_nGlowRangeMin"));
		}
	}
}

static bool:IsValidEntRef(iEntRef)
{
	return (iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE);
}
static bool:IsSurvivorThirdPerson(iClient)
{
	if(bThirdPerson[iClient])
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_hViewEntity") > 0)
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
		return true;
	if(GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 1)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if(GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0)
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
		return true;
	switch(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction"))
	{
		case 1:
		{
			static iTarget;
			iTarget = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");
			
			if(iTarget == GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner"))
				return true;
			else if(iTarget != iClient)
				return true;
		}
		case 4, 6, 7, 8, 9, 10:
		return true;
	}
	
	static String:sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	switch(sModel[29])
	{
		case 'b'://nick
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 626, 625, 624, 623, 622, 621, 661, 662, 664, 665, 666, 667, 668, 670, 671, 672, 673, 674, 620, 680, 616:
				return true;
			}
		}
		case 'd'://rochelle
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 625, 616:
				return true;
			}
		}
		case 'c'://coach
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 656, 622, 623, 624, 625, 626, 663, 662, 661, 660, 659, 658, 657, 654, 653, 652, 651, 621, 620, 669, 615:
				return true;
			}
		}
		case 'h'://ellis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 625, 675, 626, 627, 628, 629, 630, 631, 678, 677, 676, 575, 674, 673, 672, 671, 670, 669, 668, 667, 666, 665, 684, 621:
				return true;
			}
		}
		case 'v'://bill
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753, 676, 675, 761, 758, 757, 756, 755, 754, 527, 772, 762, 522:
				return true;
			}
		}
		case 'n'://zoey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 537, 819, 823, 824, 538, 539, 540, 541, 542, 543, 813, 828, 825, 822, 821, 820, 818, 817, 816, 815, 814, 536, 809, 572:
				return true;
			}
		}
		case 'e'://francis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 532, 533, 534, 535, 536, 537, 769, 768, 767, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 531, 530, 775, 525:
				return true;
			}
		}
		case 'a'://louis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 529, 530, 531, 532, 533, 534, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 755, 754, 753, 527, 772, 528, 522:
				return true;
			}
		}
		case 'w'://adawong
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 625, 616:
				return true;
			}
		}
	}
	
	return false;
}
static bool:IsInfectedThirdPerson(iClient)
{
	if(bThirdPerson[iClient])
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_hViewEntity") > 0)
		return true;
	
	switch(GetEntProp(iClient, Prop_Send, "m_zombieClass"))
	{
		case 1://smoker
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 30, 31, 32, 36, 37, 38, 39:
				return true;
			}
		}
		case 2://boomer
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 30, 31, 32, 33:
				return true;
			}
		}
		case 3://hunter
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 38, 39, 40, 41, 42, 43, 45, 46, 47, 48, 49:
				return true;
			}
		}
		case 4://spitter
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 17, 18, 19, 20:
				return true;
			}
		}
		case 5://jockey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 8 , 15, 16, 17, 18:
				return true;
			}
		}
		case 6://charger
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 5, 27, 28, 29, 31, 32, 33, 34, 35, 39, 40, 41, 42:
				return true;
			}
		}
		case 8://tank
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 28, 29, 30, 31, 49, 50, 51, 73, 74, 75, 76 ,77:
				return true;
			}
		}
	}
	
	return false;
}

public GetOverlayModel(Handle:plugin, numParams)
{
	if(numParams < 1)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	new iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_PARAM, "Client index out of bounds %i", iClient);
	
	if(!IsValidEntRef(iHiddenIndex[iClient]))
		return -1;
	
	return EntRefToEntIndex(iHiddenIndex[iClient]);
}

public HideOverlayModel(Handle:plugin, numParams)
{
	if(numParams < 2)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	new iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_PARAM, "Client index out of bounds %i", iClient);
	
	if(!IsValidEntRef(iHiddenIndex[iClient]))
		return false;
	
	new iEntity = EntRefToEntIndex(iHiddenIndex[iClient]);
	
	new bool:bHide = GetNativeCell(2);
	if(bHide)
	{
		SetEntityRenderMode(iEntity, RENDER_NONE);
		return true;
	}
	else
	{
		SetEntityRenderMode(iEntity, RENDER_NORMAL);
		return true;
	}
}

public SetOverlayModel(Handle:plugin, numParams)
{
	if(numParams < 2)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	new iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_PARAM, "Client index out of bounds %i", iClient);
	
	new String:sModel[PLATFORM_MAX_PATH];
	
	GetNativeString(2, sModel, sizeof(sModel));
	
	if(sModel[0] == '\0')
		ThrowNativeError(SP_ERROR_PARAM, "Error Empty String");
	
	BeWitched(iClient, sModel, false);
	return EntRefToEntIndex(iHiddenIndex[iClient]);
}

public SetEntityOverlayModel(Handle:plugin, numParams)
{
	if(numParams < 2)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	new iEntity = GetNativeCell(1);
	if(iEntity < 1 || iEntity > 2048)
		ThrowNativeError(SP_ERROR_PARAM, "Entity index out of bounds %i", iEntity);
	
	static String:sModel[PLATFORM_MAX_PATH];
	GetNativeString(2, sModel, sizeof(sModel));
	
	if(sModel[0] == '\0')
		ThrowNativeError(SP_ERROR_PARAM, "Error Empty String");
	
	BeWitchOther(iEntity, sModel);
	return EntRefToEntIndex(iHiddenEntityRef[iEntity]);
}

public GetEntityOverlayModel(Handle:plugin, numParams)
{
	if(numParams < 1)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	new iEntity = GetNativeCell(1);
	if(iEntity < MaxClients+1 || iEntity > 2048+1)
		ThrowNativeError(SP_ERROR_PARAM, "Entity index out of bounds %i", iEntity);
	
	if(!IsValidEntRef(iHiddenEntityRef[iEntity]))
		return -1;
	
	if(!IsValidEntRef(iHiddenEntity[iEntity]))
		return -1;
	
	return EntRefToEntIndex(iHiddenEntity[iEntity]);
}


public OnEntityDestroyed(iEntity)
{
	if(!IsServerProcessing() || iEntity < MaxClients+1 || iEntity > 2048)
		return;
	
	static String:sClassname[64];
	GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
	if(sClassname[0] != 'p' || !StrEqual(sClassname, "prop_dynamic_ornament", false))
		return;
	
	static iClient;
	iClient = GetClientOfUserId(iHiddenOwner[iEntity]);
	
	if(iClient < 1)
		return;
	
	iHiddenOwner[iEntity] = -1;//1.7.3
	
	if(!IsValidEntRef(iHiddenIndex[iClient]))
		return;
	
	Call_StartForward(g_hOnClientModelDestroyed);
	Call_PushCell(iClient);
	Call_PushCell(EntRefToEntIndex(iHiddenIndex[iClient]));//now returns entity index 
	Call_Finish();
}

public OnEntityCreated(iEntity, const String:sClassname[])
{
	if(g_iHideDeathModel == -1 || bHideDeathModel ||!IsServerProcessing())
		return;
	
	if(sClassname[0] != 's' || !StrEqual(sClassname, "survivor_death_model", false))
		return;
	
	SDKHook(iEntity, SDKHook_SpawnPost, SpawnPost);
}

public SpawnPost(iEntity)
{
	SDKUnhook(iEntity, SDKHook_SpawnPost, SpawnPost);
	
	if(!IsValidEntity(iEntity))
		return;
	
	AcceptEntityInput(iEntity, "Kill");
}

static BeWitchOther(iEntity, const String:sModel[])
{
	if(iEntity < 1 || iEntity > 2048)
		return;
	
	if(IsValidEntRef(iHiddenEntity[iEntity]))
	{
		SetEntityModel(iHiddenEntity[iEntity], sModel);
		return;
	}
	
	static iEnt;
	iEnt = CreateEntityByName("prop_dynamic_ornament");
	if(iEnt < 0)
		return;
	
	DispatchKeyValue(iEnt, "model", sModel);
	
	DispatchSpawn(iEnt);
	ActivateEntity(iEnt);
	
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", iEntity);
	
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetAttached", iEntity);
	AcceptEntityInput(iEnt, "TurnOn");
	
	iHiddenEntity[iEntity] = EntIndexToEntRef(iEnt);
	iHiddenEntityRef[iEntity] = EntIndexToEntRef(iEntity);
	SetEntityRenderFx(iEntity, RENDERFX_HOLOGRAM);
	SetEntityRenderColor(iEntity, 0, 0, 0, 0);
	SetEntProp(iEntity, Prop_Send, "m_nMinGPULevel", 1);
	SetEntProp(iEntity, Prop_Send, "m_nMaxGPULevel", 1);
	
	/*
	SetEntProp(iEnt, Prop_Send, "m_nGlowRange", GetEntProp(i, Prop_Send, "m_nGlowRange"));
	SetEntProp(iEnt, Prop_Send, "m_iGlowType", GetEntProp(i, Prop_Send, "m_iGlowType"));
	SetEntProp(iEnt, Prop_Send, "m_glowColorOverride", GetEntProp(i, Prop_Send, "m_glowColorOverride"));
	SetEntProp(iEnt, Prop_Send, "m_nGlowRangeMin", GetEntProp(i, Prop_Send, "m_nGlowRangeMin"));
	*/
}

public bool:_TraceFilter(iEntity, contentsMask)
{
	static String:sClassName[32];
	GetEntityClassname(iEntity, sClassName, sizeof(sClassName));
	
	if(sClassName[0] != 'i' || !StrEqual(sClassName, "infected", false))
	{
		return false;
	}
	else if(sClassName[0] != 'w' || !StrEqual(sClassName, "witch", false))
	{
		return false;
	}
	else if(StrContains(sClassName, "weapon_", false) == 0)
	{
		return false;
	}
	else if(iEntity > 0 && iEntity <= MaxClients)
	{
		return false;
	}
	return true;
	
}

public TP_OnThirdPersonChanged(iClient, bool:bIsThirdPerson)
{
	bThirdPerson[iClient] = bIsThirdPerson;
}

public OnClientCookiesCached(iClient)
{	
	decl String:sCookie[3];
	GetClientCookie(iClient, hCookie_LmcCookie, sCookie, sizeof(sCookie));
	if(StrEqual(sCookie, "\0", false))
		return;
	
	iSavedModel[iClient] = StringToInt(sCookie);
	
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	if(IsValidEntRef(iHiddenIndex[iClient]))
		return;
	
	ModelIndex(iClient, iSavedModel[iClient], false);
}


public eOnTakeDamagePost(iVictim, iAttacker, iInflictor, Float:fDamage, iDamagetype)
{
	if(!IsClientInGame(iVictim) || GetClientTeam(iVictim) != 2 || !IsPlayerAlive(iVictim))
		return;
	
	bIsIncapped[iVictim] = bool:GetEntProp(iVictim, Prop_Send, "m_isIncapacitated", 1);
}