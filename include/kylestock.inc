stock void FriendIDtoSteamID(const char[] szSteam64, char[] szSteam2, int iLen)
{
    char[] szBase = "76561197960265728";
    char szSteam[18], szAccount[18];
    int iBorrow, iY, iZ, iTemp;

    strcopy(szSteam, 18, szSteam64);

    if(CharToNumber(szSteam[16]) % 2 == 1)
    {
        iY = 1;
        szSteam[16] = NumberToChar(CharToNumber(szSteam[16]) - 1);
    }
    
    for(int k = 16; k >= 0; k--)
    {
        if (iBorrow > 0)
        {
            iTemp = CharToNumber(szSteam[k]) - 1;
            
            if (iTemp >= CharToNumber(szBase[k]))
            {
                iBorrow = 0;
                szAccount[k] = NumberToChar(iTemp - CharToNumber(szBase[k]));
            }
            else
            {
                iBorrow = 1;
                szAccount[k] = NumberToChar((iTemp + 10) - CharToNumber(szBase[k]));
            }
        }
        else
        {
            if (CharToNumber(szSteam[k]) >= CharToNumber(szBase[k]))
            {
                iBorrow = 0;
                szAccount[k] = NumberToChar(CharToNumber(szSteam[k]) - CharToNumber(szBase[k]));
            }
            else
            {
                iBorrow = 1;
                szAccount[k] = NumberToChar((CharToNumber(szSteam[k]) + 10) - CharToNumber(szBase[k]));
            }
        }
    }
    
    iZ = StringToInt(szAccount);
    iZ /= 2;
    
    FormatEx(szSteam2, iLen, "STEAM_1:%d:%d", iY, iZ);
}

stock int NumberToChar(const int iNum)
{
    return '0' + ((iNum >= 0 && iNum <= 9) ? iNum : 0);
}

stock int CharToNumber(const int cNum)
{
    return (cNum >= '0' && cNum <= '9') ? (cNum - '0') : 0;
}

stock bool IsValidClient(int client)
{
    if(!(1 <= client <= MaxClients))
        return false;

    if(!IsClientInGame(client))
        return false;

    if(IsFakeClient(client))
        return false;

    return true;
}

stock void SetMenuTitleEx(Handle menu, const char[] fmt, any ...)
{
    char m_szBuffer[256];
    VFormat(m_szBuffer, 256, fmt, 3);
    Format(m_szBuffer, 256, "%s\n　", m_szBuffer);
    SetMenuTitle(menu, m_szBuffer);
}

stock bool AddMenuItemEx(Handle menu, int style, const char[] info, const char[] display, any ...)
{
    char m_szBuffer[256];
    VFormat(m_szBuffer, 256, display, 5);
    return AddMenuItem(menu, info, m_szBuffer, style);
}

stock void DrawPanelTextEx(Handle panel, const char[] fmt, any ...)
{
    char vf[256];
    VFormat(vf, 256, fmt, 3);
    DrawPanelText(panel, vf);
}