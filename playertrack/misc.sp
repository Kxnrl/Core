void LoadTranstion()
{
	char m_szPath[128];
	BuildPath(Path_SM, m_szPath, 128, "translations/cg.core.phrases.txt");
	if(FileSize(m_szPath) != TRANSDATASIZE)
	{
		DeleteFile(m_szPath);
		TranslationToFile(m_szPath);
		Handle kv = CreateKeyValues("Phrases", "", "");
		FileToKeyValues(kv, m_szPath);
		KeyValuesToFile(kv, m_szPath);
		CloseHandle(kv);
		LogToFileEx(g_szLogFile, "TranslationToFile: %s    size: %d    version: %s", m_szPath, FileSize(m_szPath), PLUGIN_VERSION);
	}
	LoadTranslations("cg.core.phrases");
}

void SettingAdver()
{
	//创建Kv
	Handle kv = CreateKeyValues("ServerAdvertisement", "", "");
	char FILE_PATH[256];
	BuildPath(Path_SM, FILE_PATH, 256, "configs/ServerAdvertisement.cfg");
	
	//创建Key
	if(KvJumpToKey(kv, "Settings", true))
	{
		KvSetString(kv, "enable", "1");
		KvSetFloat(kv, "Delay_between_messages", 30.0);
		KvSetString(kv, "Advertisement_tag", "[{blue}CG{default}] ^");
		KvSetString(kv, "Time_Format", "%H:%M:%S");
		KvGoBack(kv);
		KvRewind(kv);
		KeyValuesToFile(kv, FILE_PATH);
	}

	CloseHandle(kv);
	kv = INVALID_HANDLE;

	if(0 < g_iServerId)
	{
		char m_szQuery[128];
		Format(m_szQuery, 128, "SELECT * FROM playertrack_adv WHERE sid = '%i' OR sid = '0'", g_iServerId);
		MySQL_Query(g_hDB_csgo, SQLCallback_GetAdvData, m_szQuery, _, DBPrio_High);
	}
}

void SetClientVIP(int client, int type)
{
	//设置VIP(Allow API)
	g_eClient[client][iVipType] = type;
	
	char m_szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

	//看看这个VIP是不是OP? 并且补起各个权限和权重
	if(GetUserAdmin(client) == INVALID_ADMIN_ID && FindAdminByIdentity(AUTHMETHOD_STEAM, m_szAuth) == INVALID_ADMIN_ID)
	{
		AdminId adm = CreateAdmin(g_eClient[client][szDiscuzName]);
		
		BindAdminIdentity(adm, AUTHMETHOD_STEAM, m_szAuth);
		
		SetAdminFlag(adm, Admin_Reservation, true);
		SetAdminFlag(adm, Admin_Generic, true);
		SetAdminFlag(adm, Admin_Custom2, true);
		
		if(type == 3)
		{
			SetAdminFlag(adm, Admin_Custom5, true);
			SetAdminFlag(adm, Admin_Custom6, true);
			SetAdminImmunityLevel(adm, 9);
		}
		else if(type == 2)
		{
			SetAdminFlag(adm, Admin_Custom6, true);
			SetAdminImmunityLevel(adm, 8);
		}
		else if(type == 1)
		{
			SetAdminImmunityLevel(adm, 5);
		}
		
		RunAdminCacheChecks(client);
	}
	else
	{
		AdminId adm = GetUserAdmin(client);
		AdminId admid = FindAdminByIdentity(AUTHMETHOD_STEAM, m_szAuth);
		
		if(adm == admid)
		{
			if(!GetAdminFlag(adm, Admin_Reservation))
				SetAdminFlag(adm, Admin_Reservation, true);
			
			if(!GetAdminFlag(adm, Admin_Generic))
				SetAdminFlag(adm, Admin_Generic, true);
		
			if(!GetAdminFlag(adm, Admin_Custom2))
				SetAdminFlag(adm, Admin_Custom2, true);
			
			if(GetAdminImmunityLevel(adm) < 5)
				SetAdminImmunityLevel(adm, 5);

			if(type == 3)
			{
				if(!GetAdminFlag(adm, Admin_Custom5))
					SetAdminFlag(adm, Admin_Custom5, true);
				
				if(!GetAdminFlag(adm, Admin_Custom6))
					SetAdminFlag(adm, Admin_Custom6, true);
				
				if(GetAdminImmunityLevel(adm) < 9)
					SetAdminImmunityLevel(adm, 9);
			}
			else if(type == 2)
			{
				if(!GetAdminFlag(adm, Admin_Custom6))
					SetAdminFlag(adm, Admin_Custom6, true);
				
				if(GetAdminImmunityLevel(adm) < 8)
					SetAdminImmunityLevel(adm, 8);
			}
		}
		
	}
	
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		RunAdminCacheChecks(client);
	}

	OnClientVipChecked(client);
}

void GetClientFlags(int client)
{
	//先获得客户flags
	int flags = GetUserFlagBits(client);
	
	//取得32位ID
	char m_szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

	//Main判定
	if(StrEqual(m_szAuth, "STEAM_1:1:44083262"))
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "CG玩家");
	}
	//狗管理权限为 CVAR
	else if(flags & ADMFLAG_CONVARS)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "管理员");
	}
	//狗OP权限为 CHANGEMAP
	else if(flags & ADMFLAG_CHANGEMAP)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "服务器OP");
	}
	//永久VIP权限为 Custom5
	else if(flags & ADMFLAG_CUSTOM5)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "永久VIP");
	}
	//年费VIP权限为 Custom6
	else if(flags & ADMFLAG_CUSTOM6)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "年费VIP");
	}
	//月费VIP权限为 Custom2
	else if(flags & ADMFLAG_CUSTOM2)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "月费VIP");
	}
	//以上都不是则为普通玩家
	else
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "CG玩家");
	}
}

void PrintConsoleInfo(int client)
{
	int timeleft;
	GetMapTimeLeft(timeleft);
	
	if(timeleft <= 30)
		return;

	char szTimeleft[32], szMap[128], szHostname[128];
	Format(szTimeleft, 32, "%d:%02d", timeleft / 60, timeleft % 60);
	GetCurrentMap(szMap, 128);
	GetConVarString(FindConVar("hostname"), szHostname, 128);

	PrintToConsole(client, "-----------------------------------------------------------------------------------------------");
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "                                     欢迎来到[CG]游戏社区                                      ");	
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "当前服务器:  %s   -   Tickrate: %i.0", szHostname, RoundToNearest(1.0 / GetTickInterval()));
	PrintToConsole(client, " ");
	PrintToConsole(client, "论坛地址: https://csgogamers.com  官方QQ群: 107421770  官方YY: 435773");
	PrintToConsole(client, "当前地图: %s   剩余时间: %s", szMap, szTimeleft);
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "服务器基础命令:");
	PrintToConsole(client, "商店相关： !store [打开商店]  !credits [显示余额]      !inv       [查看库存]");
	PrintToConsole(client, "地图相关： !rtv   [滚动投票]  !revote  [重新选择]      !nominate  [预定地图]");
	PrintToConsole(client, "娱乐相关： !music [点歌菜单]  !stop    [停止地图音乐]  !musicstop [停止点播歌曲]");
	PrintToConsole(client, "其他命令： !sign  [每日签到]  !hide    [屏蔽足迹霓虹]  !tp/!seeme [第三人称视角]");
	PrintToConsole(client, "玩家认证： !rz    [查询认证]");
	PrintToConsole(client, "搞基系统： !cp    [功能菜单]");
	PrintToConsole(client, "势力系统： !faith [功能菜单]  !fhelp   [帮助菜单]");
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "-----------------------------------------------------------------------------------------------");		
	PrintToConsole(client, "                                                                                               ");
}

public int MenuHandler_CGMainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(strcmp(info, "store") == 0)
			FakeClientCommand(client, "sm_store");
		else if(strcmp(info, "faith") == 0)
			FakeClientCommand(client, "sm_force");
		else if(strcmp(info, "lily") == 0)
			FakeClientCommand(client, "sm_lily");
		else if(strcmp(info, "music") == 0)
			FakeClientCommand(client, "sm_music");
		else if(strcmp(info, "sign") == 0)
			FakeClientCommand(client, "sm_sign");
		else if(strcmp(info, "vip") == 0)
			FakeClientCommand(client, "sm_vip");
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void BuildListenerMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_Listener);
	SetMenuTitleEx(menu, "[CG]  %t", "signature title");

	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%t", "signature now you can type");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%t", "signature color codes");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%t", "signature example");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%t", "signature input preview", g_eClient[client][szNewSignature]);
	
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "preview", "%t", "signature item preview");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "ok", "%t", "signature item ok");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 120);
	
	if(g_eClient[client][hListener] != INVALID_HANDLE)
	{
		KillTimer(g_eClient[client][hListener]);
		g_eClient[client][hListener] = INVALID_HANDLE;
	}

	g_eClient[client][bListener] = true;
	g_eClient[client][hListener] = CreateTimer(120.0, Timer_ListenerTimeout, GetClientUserId(client));
}

public int MenuHandler_Listener(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		g_eClient[client][bListener] = false;
		if(g_eClient[client][hListener] != INVALID_HANDLE)
		{
			KillTimer(g_eClient[client][hListener]);
			g_eClient[client][hListener] = INVALID_HANDLE;
		}
		
		if(StrEqual(info, "preview"))
		{
			char m_szPreview[256];
			strcopy(m_szPreview, 256, g_eClient[client][szNewSignature]);
			ReplaceString(m_szPreview, 512, "{白}", "\x01");
			ReplaceString(m_szPreview, 512, "{红}", "\x02");
			ReplaceString(m_szPreview, 512, "{粉}", "\x03");
			ReplaceString(m_szPreview, 512, "{绿}", "\x04");
			ReplaceString(m_szPreview, 512, "{黄}", "\x05");
			ReplaceString(m_szPreview, 512, "{亮绿}", "\x06");
			ReplaceString(m_szPreview, 512, "{亮红}", "\x07");
			ReplaceString(m_szPreview, 512, "{灰}", "\x08");
			ReplaceString(m_szPreview, 512, "{褐}", "\x09");
			ReplaceString(m_szPreview, 512, "{橙}", "\x10");
			ReplaceString(m_szPreview, 512, "{紫}", "\x0E");
			ReplaceString(m_szPreview, 512, "{亮蓝}", "\x0B");
			ReplaceString(m_szPreview, 512, "{蓝}", "\x0C");
			tPrintToChat(client, "签名预览: %s", m_szPreview);
			BuildListenerMenu(client);
		}
		if(StrEqual(info, "ok"))
		{
			if(!OnAPIStoreSetCredits(client, -500, "设置签名", true))
			{
				tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "signature you have not enough credits");
				return;
			}
			
			char auth[32], eSignature[512], m_szQuery[1024];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			SQL_EscapeString(g_hDB_csgo, g_eClient[client][szNewSignature], eSignature, 512);
			Format(m_szQuery, 512, "UPDATE `playertrack_player` SET signature = '%s' WHERE id = '%d' and steamid = '%s'", eSignature, CG_GetPlayerID(client), auth);
			CG_SaveDatabase(m_szQuery);
			tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "signature set successful");
			strcopy(g_eClient[client][szSignature], 256, g_eClient[client][szNewSignature]);
			ReplaceString(g_eClient[client][szNewSignature], 512, "{白}", "\x01");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{红}", "\x02");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{粉}", "\x03");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{绿}", "\x04");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{黄}", "\x05");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{亮绿}", "\x06");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{亮红}", "\x07");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{灰}", "\x08");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{褐}", "\x09");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{橙}", "\x10");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{紫}", "\x0E");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{亮蓝}", "\x0B");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{蓝}", "\x0C");
			tPrintToChat(client, "%t: %s", "signature yours", g_eClient[client][szNewSignature]);
		}
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Timer_ListenerTimeout(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		g_eClient[client][bListener] = false;
		g_eClient[client][hListener] = INVALID_HANDLE;
	}
}