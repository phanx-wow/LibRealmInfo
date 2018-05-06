--[[--------------------------------------------------------------------
	LibRealmInfo
	World of Warcraft library for obtaining information about realms.
	Copyright 2014-2018 Phanx <addons@phanx.net>
	Zlib license. Standalone distribution strongly discouraged.
	https://github.com/phanx-wow/LibRealmInfo
	https://wow.curseforge.com/projects/librealminfo
	https://www.wowinterface.com/downloads/info22987-LibRealmInfo
----------------------------------------------------------------------]]

local MAJOR, MINOR = "LibRealmInfo", 12
assert(LibStub, MAJOR.." requires LibStub")
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local standalone = (...) == MAJOR
local realmData, connectionData
local Unpack

local function debug(...)
	if standalone then
		print("|cffff7f7f["..MAJOR.."]|r", ...)
	end
end

------------------------------------------------------------------------

local currentRegion

function lib:GetCurrentRegion()
	if currentRegion then
		return currentRegion
	end

	if Unpack then
		Unpack()
	end

	local guid = UnitGUID("player")
	if guid then
		local server = tonumber(strmatch(guid, "^Player%-(%d+)"))
		local realm = realmData[server]
		if realm then
			currentRegion = realm.region
			return currentRegion
		end
	end

	debug("GetCurrentRegion: could not identify region based on player GUID", guid)
end

------------------------------------------------------------------------

local validRegions = { US = true, EU = true, CN = true, KR = true, TW = true }

function lib:GetRealmInfo(name, region)
	debug("GetRealmInfo", name, region)
	local isString = type(name) == "string"
	if isString then
		name = strtrim(name)
	end
	if type(name) == "number" or isString and strmatch(name, "^%d+$") then
		return self:GetRealmInfoByID(name)
	end
	assert(isString and strlen(name) > 0, "Usage: GetRealmInfo(name[, region])")

	if not region or not validRegions[region] then
		region = self:GetCurrentRegion()
	end

	if Unpack then
		Unpack()
	end

	for id, realm in pairs(realmData) do
		if realm.region == region and (realm.api_name == name or realm.name == name or realm.latin_api_name == name or realm.latin_name == name) then
			return id, realm.name, realm.api_name, realm.rules, realm.locale, nil, realm.region, realm.timezone, realm.connections, realm.latin_name, realm.latin_api_name
		end
	end

	debug("No info found for realm", name, "in region", region)
end

------------------------------------------------------------------------

function lib:GetRealmInfoByID(id)
	debug("GetRealmInfoByID", id)
	id = tonumber(id)
	assert(id, "Usage: GetRealmInfoByID(id)")

	if Unpack then
		Unpack()
	end

	local realm = realmData[id]
	if realm and realm.name then
		return realm.id, realm.name, realm.api_name, realm.rules, realm.locale, nil, realm.region, realm.timezone, realm.connections, realm.latin_name, realm.latin_api_name
	end

	debug("No info found for realm ID", name)
end

------------------------------------------------------------------------

function lib:GetRealmInfoByGUID(guid)
	assert(type(guid) == "string", "Usage: GetRealmInfoByGUID(guid)")
	if not strmatch(guid, "^Player%-") then
		return debug("Unsupported GUID type", (strsplit("-", guid)))
	end
	local _, _, _, _, _, _, realm = GetPlayerInfoByGUID(guid)
	if realm == "" then
		realm = GetRealmName()
	end
	return self:GetRealmInfo(realm)
end

------------------------------------------------------------------------

function lib:GetRealmInfoByUnit(unit)
	assert(type(unit) == "string", "Usage: GetRealmInfoByUnit(unit)")
	local guid = UnitGUID(unit)
	if not guid then
		return debug("No GUID available for unit", unit)
	end
	return self:GetRealmInfoByGUID(guid)
end

------------------------------------------------------------------------

function Unpack()
	debug("Unpacking data...")

	for id, info in pairs(realmData) do
		if not strfind(info, ",") then
			-- This server doesn't belong to a specific realm
			-- but may be used to temporarily host other realms
			-- and can be used to determine the player's region.
			realmData[id] = {
				region = info,
			}
		else
			-- Normal realm server
			-- Aegwynn,PVP,enUS,US,CST
			-- Азурегос,PvE,ruRU,EU,Azuregos
			local name, rules, locale, region, timezone = strsplit(",", info)
			local latin_name
			if region ~= "US" then
				latin_name = timezone
				timezone = nil
			end
			realmData[id] = {
				id = id,
				name = name,
				api_name = (gsub(name, "[%s%-]", "")),
				rules = rules,
				locale = locale,
				region = region,
				timezone = timezone, -- only for realms in US region
				latin_name = latin_name, -- only for realms with non-Latin names
				latin_api_name = latin_name and (gsub(latin_name, "[%s%-]", "")) or nil, -- only for realms with non-Latin names
			}
		end
	end

	for i = 1, #connectionData do
		local connections = { strsplit(",", connectionData[i]) }
		for j = 1, #connections do
			local id = tonumber(connections[j])
			connections[j] = id
			realmData[id].connections = connections
		end
	end

	connectionData = nil
	Unpack = nil
	collectgarbage()

	debug("Done unpacking data.")
--[[
	local auto = { GetAutoCompleteRealms() }
	if #auto > 1 then
		local id, _, _, _, _, _, _, _, connections = lib:GetRealmInfo(GetRealmName())
		if not id then
			return
		end
		if not connections then
			print("|cffffff7fLibRealmInfo:|r Missing connected realm info for", id, GetRealmName())
			return
		end
		for i = 1, #auto do
			local name = auto[i]
			auto[name] = true
			auto[i] = nil
		end
		for i = 1, #connections do
			local _, name = GetRealmInfo(connections[i])
			if auto[name] then
				auto[name] = nil
			else
				auto[name] = connections[i]
			end
		end
		if next(auto) then
			print("|cffffff7fLibRealmInfo:|r Incomplete connected realm info for", id, GetRealmName())
			for name, id in pairs(auto) do
				print(name, id == true and "MISSING" or "INCORRECT")
			end
		end
	end
]]
end

------------------------------------------------------------------------

realmData = {
--{{ North America
[1]="Lightbringer,PvE,enUS,US,PST",
[2]="Cenarius,PvE,enUS,US,PST",
[3]="Uther,PvE,enUS,US,PST",
[4]="Kilrogg,PvE,enUS,US,PST",
[5]="Proudmoore,PvE,enUS,US,PST",
[6]="Hyjal,PvE,enUS,US,PST",
[7]="Frostwolf,PvP,enUS,US,PST",
[8]="Ner'zhul,PvP,enUS,US,PST",
[9]="Kil'jaeden,PvP,enUS,US,PST",
[10]="Blackrock,PvP,enUS,US,PST",
[11]="Tichondrius,PvP,enUS,US,PST",
[12]="Silver Hand,RP,enUS,US,PST",
[13]="Doomhammer,PvE,enUS,US,MST",
[14]="Icecrown,PvE,enUS,US,MST",
[15]="Deathwing,PvP,enUS,US,MST",
[16]="Kel'Thuzad,PvP,enUS,US,MST",
[47]="Eitrigg,PvE,enUS,US,CST",
[51]="Garona,PvE,enUS,US,CST",
[52]="Alleria,PvE,enUS,US,CST",
[53]="Hellscream,PvE,enUS,US,CST",
[54]="Blackhand,PvE,enUS,US,CST",
[55]="Whisperwind,PvE,enUS,US,CST",
[56]="Archimonde,PvP,enUS,US,CST",
[57]="Illidan,PvP,enUS,US,CST",
[58]="Stormreaver,PvP,enUS,US,CST",
[59]="Mal'Ganis,PvP,enUS,US,CST",
[60]="Stormrage,PvE,enUS,US,EST",
[61]="Zul'jin,PvE,enUS,US,EST",
[62]="Medivh,PvE,enUS,US,EST",
[63]="Durotan,PvE,enUS,US,EST",
[64]="Bloodhoof,PvE,enUS,US,EST",
[65]="Khadgar,PvE,enUS,US,EST",
[66]="Dalaran,PvE,enUS,US,EST",
[67]="Elune,PvE,enUS,US,EST",
[68]="Lothar,PvE,enUS,US,EST",
[69]="Arthas,PvP,enUS,US,EST",
[70]="Mannoroth,PvP,enUS,US,EST",
[71]="Warsong,PvP,enUS,US,EST",
[72]="Shattered Hand,PvP,enUS,US,EST",
[73]="Bleeding Hollow,PvP,enUS,US,EST",
[74]="Skullcrusher,PvP,enUS,US,EST",
[75]="Argent Dawn,RP,enUS,US,EST",
[76]="Sargeras,PvP,enUS,US,CST",
[77]="Azgalor,PvP,enUS,US,CST",
[78]="Magtheridon,PvP,enUS,US,EST",
[79]="Destromath,PvP,enUS,US,PST",
[80]="Gorgonnash,PvP,enUS,US,PST",
[81]="Dethecus,PvP,enUS,US,PST",
[82]="Spinebreaker,PvP,enUS,US,PST",
[83]="Bonechewer,PvP,enUS,US,PST",
[84]="Dragonmaw,PvP,enUS,US,PST",
[85]="Shadowsong,PvE,enUS,US,PST",
[86]="Silvermoon,PvE,enUS,US,PST",
[87]="Windrunner,PvE,enUS,US,PST",
[88]="Cenarion Circle,RP,enUS,US,PST",
[89]="Nathrezim,PvP,enUS,US,MST",
[90]="Terenas,PvE,enUS,US,MST",
[91]="Burning Blade,PvP,enUS,US,EST",
[92]="Gorefiend,PvP,enUS,US,EST",
[93]="Eredar,PvP,enUS,US,EST",
[94]="Shadowmoon,PvP,enUS,US,EST",
[95]="Lightning's Blade,PvP,enUS,US,EST",
[96]="Eonar,PvE,enUS,US,EST",
[97]="Gilneas,PvE,enUS,US,EST",
[98]="Kargath,PvE,enUS,US,EST",
[99]="Llane,PvE,enUS,US,EST",
[100]="Earthen Ring,RP,enUS,US,EST",
[101]="Laughing Skull,PvP,enUS,US,CST",
[102]="Burning Legion,PvP,enUS,US,CST",
[103]="Thunderlord,PvP,enUS,US,CST",
[104]="Malygos,PvE,enUS,US,CST",
[105]="Thunderhorn,PvE,enUS,US,CST",
[106]="Aggramar,PvE,enUS,US,CST",
[107]="Crushridge,PvP,enUS,US,PST",
[108]="Stonemaul,PvP,enUS,US,PST",
[109]="Daggerspine,PvP,enUS,US,PST",
[110]="Stormscale,PvP,enUS,US,PST",
[111]="Dunemaul,PvP,enUS,US,PST",
[112]="Boulderfist,PvP,enUS,US,PST",
[113]="Suramar,PvE,enUS,US,PST",
[114]="Dragonblight,PvE,enUS,US,PST",
[115]="Draenor,PvE,enUS,US,PST",
[116]="Uldum,PvE,enUS,US,PST",
[117]="Bronzebeard,PvE,enUS,US,PST",
[118]="Feathermoon,RP,enUS,US,PST",
[119]="Bloodscalp,PvP,enUS,US,MST",
[120]="Darkspear,PvP,enUS,US,MST",
[121]="Azjol-Nerub,PvE,enUS,US,MST",
[122]="Perenolde,PvE,enUS,US,MST",
[123]="Eldre'Thalas,PvE,enUS,US,EST",
[124]="Spirestone,PvP,enUS,US,PST",
[125]="Shadow Council,RP,enUS,US,MST",
[126]="Scarlet Crusade,RP,enUS,US,CST",
[127]="Firetree,PvP,enUS,US,EST",
[128]="Frostmane,PvP,enUS,US,CST",
[129]="Gurubashi,PvP,enUS,US,PST",
[130]="Smolderthorn,PvP,enUS,US,EST",
[131]="Skywall,PvE,enUS,US,PST",
[151]="Runetotem,PvE,enUS,US,CST",
[153]="Moonrunner,PvE,enUS,US,PST",
[154]="Detheroc,PvP,enUS,US,CST",
[155]="Kalecgos,PvP,enUS,US,PST",
[156]="Ursin,PvP,enUS,US,PST",
[157]="Dark Iron,PvP,enUS,US,PST",
[158]="Greymane,PvE,enUS,US,CST",
[159]="Wildhammer,PvP,enUS,US,CST",
[160]="Staghelm,PvE,enUS,US,CST",
[162]="Emerald Dream,PvP RP,enUS,US,CST",
[163]="Maelstrom,PvP RP,enUS,US,CST",
[164]="Twisting Nether,PvP RP,enUS,US,CST",
[1067]="Cho'gall,PvP,enUS,US,CST",
[1068]="Gul'dan,PvP,enUS,US,CST",
[1069]="Kael'thas,PvE,enUS,US,CST",
[1070]="Alexstrasza,PvE,enUS,US,CST",
[1071]="Kirin Tor,RP,enUS,US,CST",
[1072]="Ravencrest,PvE,enUS,US,CST",
[1075]="Balnazzar,PvP,enUS,US,CST",
[1128]="Azshara,PvP,enUS,US,CST",
[1129]="Agamaggan,PvP,enUS,US,CST",
[1130]="Lightninghoof,PvP RP,enUS,US,CST",
[1131]="Nazjatar,PvP,enUS,US,PST",
[1132]="Malfurion,PvE,enUS,US,CST",
[1136]="Aegwynn,PvP,enUS,US,CST",
[1137]="Akama,PvP,enUS,US,CST",
[1138]="Chromaggus,PvP,enUS,US,CST",
[1139]="Draka,PvE,enUS,US,CST",
[1140]="Drak'thul,PvE,enUS,US,CST",
[1141]="Garithos,PvP,enUS,US,CST",
[1142]="Hakkar,PvP,enUS,US,CST",
[1143]="Khaz Modan,PvE,enUS,US,CST",
[1145]="Mug'thol,PvP,enUS,US,CST",
[1146]="Korgath,PvP,enUS,US,CST",
[1147]="Kul Tiras,PvE,enUS,US,CST",
[1148]="Malorne,PvP,enUS,US,CST",
[1151]="Rexxar,PvE,enUS,US,CST",
[1154]="Thorium Brotherhood,RP,enUS,US,CST",
[1165]="Arathor,PvE,enUS,US,PST",
[1173]="Madoran,PvE,enUS,US,CST",
[1175]="Trollbane,PvE,enUS,US,EST",
[1182]="Muradin,PvE,enUS,US,CST",
[1184]="Vek'nilash,PvE,enUS,US,CST",
[1185]="Sen'jin,PvE,enUS,US,CST",
[1190]="Baelgun,PvE,enUS,US,PST",
[1258]="Duskwood,PvE,enUS,US,EST",
[1259]="Zuluhed,PvP,enUS,US,EST",
[1260]="Steamwheedle Cartel,RP,enUS,US,EST",
[1262]="Norgannon,PvE,enUS,US,EST",
[1263]="Thrall,PvE,enUS,US,EST",
[1264]="Anetheron,PvP,enUS,US,EST",
[1265]="Turalyon,PvE,enUS,US,EST",
[1266]="Haomarush,PvP,enUS,US,EST",
[1267]="Scilla,PvP,enUS,US,EST",
[1268]="Ysondre,PvP,enUS,US,EST",
[1270]="Ysera,PvE,enUS,US,EST",
[1271]="Dentarg,PvE,enUS,US,EST",
[1276]="Andorhal,PvP,enUS,US,EST",
[1277]="Executus,PvP,enUS,US,EST",
[1278]="Dalvengyr,PvP,enUS,US,EST",
[1280]="Black Dragonflight,PvP,enUS,US,EST",
[1282]="Altar of Storms,PvP,enUS,US,EST",
[1283]="Uldaman,PvE,enUS,US,EST",
[1284]="Aerie Peak,PvE,enUS,US,PST",
[1285]="Onyxia,PvP,enUS,US,PST",
[1286]="Demon Soul,PvP,enUS,US,EST",
[1287]="Gnomeregan,PvE,enUS,US,PST",
[1288]="Anvilmar,PvE,enUS,US,PST",
[1289]="The Venture Co,PvP RP,enUS,US,PST",
[1290]="Sentinels,RP,enUS,US,PST",
[1291]="Jaedenar,PvP,enUS,US,EST",
[1292]="Tanaris,PvE,enUS,US,EST",
[1293]="Alterac Mountains,PvP,enUS,US,EST",
[1294]="Undermine,PvE,enUS,US,EST",
[1295]="Lethon,PvP,enUS,US,PST",
[1296]="Blackwing Lair,PvP,enUS,US,PST",
[1297]="Arygos,PvE,enUS,US,EST",
[1342]="Echo Isles,PvE,enUS,US,PST",
[1344]="The Forgotten Coast,PvP,enUS,US,EST",
[1345]="Fenris,PvE,enUS,US,EST",
[1346]="Anub'arak,PvP,enUS,US,EST",
[1347]="Blackwater Raiders,RP,enUS,US,PST",
[1348]="Vashj,PvP,enUS,US,PST",
[1349]="Korialstrasz,PvE,enUS,US,PST",
[1350]="Misha,PvE,enUS,US,PST",
[1351]="Darrowmere,PvE,enUS,US,PST",
[1352]="Ravenholdt,PvP RP,enUS,US,EST",
[1353]="Bladefist,PvE,enUS,US,PST",
[1354]="Shu'halo,PvE,enUS,US,PST",
[1355]="Winterhoof,PvE,enUS,US,CST",
[1356]="Sisters of Elune,RP,enUS,US,CST",
[1357]="Maiev,PvP,enUS,US,PST",
[1358]="Rivendare,PvP,enUS,US,PST",
[1359]="Nordrassil,PvE,enUS,US,PST",
[1360]="Tortheldrin,PvP,enUS,US,EST",
[1361]="Cairne,PvE,enUS,US,CST",
[1362]="Drak'Tharon,PvP,enUS,US,CST",
[1363]="Antonidas,PvE,enUS,US,PST",
[1364]="Shandris,PvE,enUS,US,EST",
[1365]="Moon Guard,RP,enUS,US,CST",
[1367]="Nazgrel,PvE,enUS,US,EST",
[1368]="Hydraxis,PvE,enUS,US,CST",
[1369]="Wyrmrest Accord,RP,enUS,US,PST",
[1370]="Farstriders,RP,enUS,US,CST",
[1371]="Borean Tundra,PvE,enUS,US,CST",
[1372]="Quel'dorei,PvE,enUS,US,CST",
[1373]="Garrosh,PvE,enUS,US,EST",
[1374]="Mok'Nathal,PvE,enUS,US,CST",
[1375]="Nesingwary,PvE,enUS,US,CST",
[1377]="Drenden,PvE,enUS,US,EST",
[1425]="Drakkari,PvP,esMX,US,CST",
[1427]="Ragnaros,PvP,esMX,US,CST",
[1428]="Quel'Thalas,PvE,esMX,US,CST",
[1549]="Azuremyst,PvE,enUS,US,PST",
[1555]="Auchindoun,PvP,enUS,US,EST",
[1556]="Coilfang,PvP,enUS,US,PST",
[1557]="Shattered Halls,PvP,enUS,US,PST",
[1558]="Blood Furnace,PvP,enUS,US,CST",
[1559]="The Underbog,PvP,enUS,US,CST",
[1563]="Terokkar,PvE,enUS,US,CST",
[1564]="Blade's Edge,PvE,enUS,US,PST",
[1565]="Exodar,PvE,enUS,US,EST",
[1566]="Area 52,PvE,enUS,US,EST",
[1567]="Velen,PvE,enUS,US,PST",
[1570]="The Scryers,RP,enUS,US,PST",
[1572]="Zangarmarsh,PvE,enUS,US,MST",
[1576]="Fizzcrank,PvE,enUS,US,CST",
[1578]="Ghostlands,PvE,enUS,US,CST",
[1579]="Grizzly Hills,PvE,enUS,US,CST",
[1581]="Galakrond,PvE,enUS,US,PST",
[1582]="Dawnbringer,PvE,enUS,US,CST",
[3207]="Goldrinn,PvE,ptBR,US,BRT",
[3208]="Nemesis,PvP,ptBR,US,BRT",
[3209]="Azralon,PvP,ptBR,US,BRT",
[3210]="Tol Barad,PvP,ptBR,US,BRT",
[3234]="Gallywix,PvE,ptBR,US,BRT",
[3721]="Caelestrasz,PvE,enUS,US,AEST",
[3722]="Aman'Thul,PvE,enUS,US,AEST",
[3723]="Barthilas,PvP,enUS,US,AEST",
[3724]="Thaurissan,PvP,enUS,US,AEST",
[3725]="Frostmourne,PvP,enUS,US,AEST",
[3726]="Khaz'goroth,PvE,enUS,US,AEST",
[3733]="Dreadmaul,PvP,enUS,US,AEST",
[3734]="Nagrand,PvE,enUS,US,AEST",
[3735]="Dath'Remar,PvE,enUS,US,AEST",
[3736]="Jubei'Thos,PvP,enUS,US,AEST",
[3737]="Gundrak,PvP,enUS,US,AEST",
[3738]="Saurfang,PvE,enUS,US,AEST",
[1133]="US", -- Frostmourne / old US datacenter
[1134]="US", -- Khaz'goroth / old US datacenter
[1144]="US", -- Jubei'Thos / old US datacenter
[1149]="US", -- Gundrak / old US datacenter
[1153]="US", -- Saurfang / old US datacenter
[1168]="US", -- Blackmoore
[1169]="US", -- Naxxramas
[1171]="US", -- Theradras
[1174]="US", -- Xavius
[1418]="US", -- Aman'Thul / old US datacenter
[1419]="US", -- Barthilas / old US datacenter
[1426]="US", -- Ulduar
[1429]="US", -- Dreadmaul / old US datacenter
[1430]="US", -- Caelestrasz / old US datacenter
[1432]="US", -- Nagrand / old US datacenter
[1433]="US", -- Thaurissan / old US datacenter
[1434]="US", -- Dath'Remar / old US datacenter
[3661]="US", -- Internal Record 3661
[3675]="US", -- Internal Record 3675
[3676]="US", -- Internal Record 3676
[3677]="US", -- Internal Record 3677
[3678]="US", -- Internal Record 3678
[3683]="US", -- Internal Record 3683
[3684]="US", -- Internal Record 3684
[3685]="US", -- Internal Record 3685
[3693]="US", -- Internal Record 3693
[3694]="US", -- Internal Record 3694
[3695]="US", -- Internal Record 3695
[3697]="US", -- Internal Record 3697
[3728]="US", -- Internal Record 3697 US9
[3729]="US", -- Internal Record 3695 US9
--}}
--{{ Europe
[500]="Aggramar,PvE,enUS,EU",
[501]="Arathor,PvE,enUS,EU",
[502]="Aszune,PvE,enUS,EU",
[503]="Azjol-Nerub,PvE,enUS,EU",
[504]="Bloodhoof,PvE,enUS,EU",
[505]="Doomhammer,PvE,enUS,EU",
[506]="Draenor,PvE,enUS,EU",
[507]="Dragonblight,PvE,enUS,EU",
[508]="Emerald Dream,PvE,enUS,EU",
[509]="Garona,PvP,frFR,EU",
[510]="Vol'jin,PvE,frFR,EU",
[511]="Sunstrider,PvP,enUS,EU",
[512]="Arak-arahm,PvP,frFR,EU",
[513]="Twilight's Hammer,PvP,enUS,EU",
[515]="Zenedar,PvP,enUS,EU",
[516]="Forscherliga,RP,deDE,EU",
[517]="Medivh,PvE,frFR,EU",
[518]="Agamaggan,PvP,enUS,EU",
[519]="Al'Akir,PvP,enUS,EU",
[521]="Bladefist,PvP,enUS,EU",
[522]="Bloodscalp,PvP,enUS,EU",
[523]="Burning Blade,PvP,enUS,EU",
[524]="Burning Legion,PvP,enUS,EU",
[525]="Crushridge,PvP,enUS,EU",
[526]="Daggerspine,PvP,enUS,EU",
[527]="Deathwing,PvP,enUS,EU",
[528]="Dragonmaw,PvP,enUS,EU",
[529]="Dunemaul,PvP,enUS,EU",
[531]="Dethecus,PvP,deDE,EU",
[533]="Sinstralis,PvP,frFR,EU",
[535]="Durotan,PvE,deDE,EU",
[536]="Argent Dawn,RP,enUS,EU",
[537]="Kirin Tor,RP,frFR,EU",
[538]="Dalaran,PvE,frFR,EU",
[539]="Archimonde,PvP,frFR,EU",
[540]="Elune,PvE,frFR,EU",
[541]="Illidan,PvP,frFR,EU",
[542]="Hyjal,PvE,frFR,EU",
[543]="Kael'thas,PvP,frFR,EU",
[544]="Ner’zhul,PvP,frFR,EU,Ner'zhul",
[545]="Cho’gall,PvP,frFR,EU,Cho'gall",
[546]="Sargeras,PvP,frFR,EU",
[547]="Runetotem,PvE,enUS,EU",
[548]="Shadowsong,PvE,enUS,EU",
[549]="Silvermoon,PvE,enUS,EU",
[550]="Stormrage,PvE,enUS,EU",
[551]="Terenas,PvE,enUS,EU",
[552]="Thunderhorn,PvE,enUS,EU",
[553]="Turalyon,PvE,enUS,EU",
[554]="Ravencrest,PvP,enUS,EU",
[556]="Shattered Hand,PvP,enUS,EU",
[557]="Skullcrusher,PvP,enUS,EU",
[558]="Spinebreaker,PvP,enUS,EU",
[559]="Stormreaver,PvP,enUS,EU",
[560]="Stormscale,PvP,enUS,EU",
[561]="Earthen Ring,RP,enUS,EU",
[562]="Alexstrasza,PvE,deDE,EU",
[563]="Alleria,PvE,deDE,EU",
[564]="Antonidas,PvE,deDE,EU",
[565]="Baelgun,PvE,deDE,EU",
[566]="Blackhand,PvE,deDE,EU",
[567]="Gilneas,PvE,deDE,EU",
[568]="Kargath,PvE,deDE,EU",
[569]="Khaz'goroth,PvE,deDE,EU",
[570]="Lothar,PvE,deDE,EU",
[571]="Madmortem,PvE,deDE,EU",
[572]="Malfurion,PvE,deDE,EU",
[573]="Zuluhed,PvP,deDE,EU",
[574]="Nozdormu,PvE,deDE,EU",
[575]="Perenolde,PvE,deDE,EU",
[576]="Die Silberne Hand,RP,deDE,EU",
[577]="Aegwynn,PvP,deDE,EU",
[578]="Arthas,PvP,deDE,EU",
[579]="Azshara,PvP,deDE,EU",
[580]="Blackmoore,PvP,deDE,EU",
[581]="Blackrock,PvP,deDE,EU",
[582]="Destromath,PvP,deDE,EU",
[583]="Eredar,PvP,deDE,EU",
[584]="Frostmourne,PvP,deDE,EU",
[585]="Frostwolf,PvP,deDE,EU",
[586]="Gorgonnash,PvP,deDE,EU",
[587]="Gul'dan,PvP,deDE,EU",
[588]="Kel'Thuzad,PvP,deDE,EU",
[589]="Kil'jaeden,PvP,deDE,EU",
[590]="Mal'Ganis,PvP,deDE,EU",
[591]="Mannoroth,PvP,deDE,EU",
[592]="Zirkel des Cenarius,RP,deDE,EU",
[593]="Proudmoore,PvE,deDE,EU",
[594]="Nathrezim,PvP,deDE,EU",
[600]="Dun Morogh,PvE,deDE,EU",
[601]="Aman'thul,PvE,deDE,EU",
[602]="Sen'jin,PvE,deDE,EU",
[604]="Thrall,PvE,deDE,EU",
[605]="Theradras,PvP,deDE,EU",
[606]="Genjuros,PvP,enUS,EU",
[607]="Balnazzar,PvP,enUS,EU",
[608]="Anub'arak,PvP,deDE,EU",
[609]="Wrathbringer,PvP,deDE,EU",
[610]="Onyxia,PvP,deDE,EU",
[611]="Nera'thor,PvP,deDE,EU",
[612]="Nefarian,PvP,deDE,EU",
[613]="Kult der Verdammten,PvP RP,deDE,EU",
[614]="Das Syndikat,PvP RP,deDE,EU",
[615]="Terrordar,PvP,deDE,EU",
[616]="Krag'jin,PvP,deDE,EU",
[617]="Der Rat von Dalaran,RP,deDE,EU",
[618]="Nordrassil,PvE,enUS,EU",
[619]="Hellscream,PvE,enUS,EU",
[621]="Laughing Skull,PvP,enUS,EU",
[622]="Magtheridon,PvE,enUS,EU",
[623]="Quel'Thalas,PvE,enUS,EU",
[624]="Neptulon,PvP,enUS,EU",
[625]="Twisting Nether,PvP,enUS,EU",
[626]="Ragnaros,PvP,enUS,EU",
[627]="The Maelstrom,PvP,enUS,EU",
[628]="Sylvanas,PvP,enUS,EU",
[629]="Vashj,PvP,enUS,EU",
[630]="Bloodfeather,PvP,enUS,EU",
[631]="Darksorrow,PvP,enUS,EU",
[632]="Frostwhisper,PvP,enUS,EU",
[633]="Kor'gall,PvP,enUS,EU",
[635]="Defias Brotherhood,PvP RP,enUS,EU",
[636]="The Venture Co,PvP RP,enUS,EU",
[637]="Lightning's Blade,PvP,enUS,EU",
[638]="Haomarush,PvP,enUS,EU",
[639]="Xavius,PvP,enUS,EU",
[640]="Khaz Modan,PvE,frFR,EU",
[641]="Drek'Thar,PvE,frFR,EU",
[642]="Rashgarroth,PvP,frFR,EU",
[643]="Throk'Feroth,PvP,frFR,EU",
[644]="Conseil des Ombres,PvP RP,frFR,EU",
[645]="Varimathras,PvE,frFR,EU",
[646]="Hakkar,PvP,enUS,EU",
[647]="Les Sentinelles,RP,frFR,EU",
[1080]="Khadgar,PvE,enUS,EU",
[1081]="Bronzebeard,PvE,enUS,EU",
[1082]="Kul Tiras,PvE,enUS,EU",
[1083]="Chromaggus,PvP,enUS,EU",
[1084]="Dentarg,PvP,enUS,EU",
[1085]="Moonglade,RP,enUS,EU",
[1086]="La Croisade écarlate,PvP RP,frFR,EU",
[1087]="Executus,PvP,enUS,EU",
[1088]="Trollbane,PvP,enUS,EU",
[1089]="Mazrigos,PvE,enUS,EU",
[1090]="Talnivarr,PvP,enUS,EU",
[1091]="Emeriss,PvP,enUS,EU",
[1092]="Drak'thul,PvP,enUS,EU",
[1093]="Ahn'Qiraj,PvP,enUS,EU",
[1096]="Scarshield Legion,PvP RP,enUS,EU",
[1097]="Ysera,PvE,deDE,EU",
[1098]="Malygos,PvE,deDE,EU",
[1099]="Rexxar,PvE,deDE,EU",
[1104]="Anetheron,PvP,deDE,EU",
[1105]="Nazjatar,PvP,deDE,EU",
[1106]="Tichondrius,PvE,deDE,EU",
[1117]="Steamwheedle Cartel,RP,enUS,EU",
[1118]="Die ewige Wacht,RP,deDE,EU",
[1119]="Die Todeskrallen,PvP RP,deDE,EU",
[1121]="Die Arguswacht,PvP RP,deDE,EU",
[1122]="Uldaman,PvE,frFR,EU",
[1123]="Eitrigg,PvE,frFR,EU",
[1127]="Confrérie du Thorium,RP,frFR,EU",
[1298]="Vek'nilash,PvE,enUS,EU",
[1299]="Boulderfist,PvP,enUS,EU",
[1300]="Frostmane,PvP,enUS,EU",
[1301]="Outland,PvP,enUS,EU",
[1303]="Grim Batol,PvP,enUS,EU",
[1304]="Jaedenar,PvP,enUS,EU",
[1305]="Kazzak,PvP,enUS,EU",
[1306]="Tarren Mill,PvP,enUS,EU",
[1307]="Chamber of Aspects,PvE,enUS,EU",
[1308]="Ravenholdt,PvP RP,enUS,EU",
[1309]="Pozzo dell'Eternità,PvE,itIT,EU",
[1310]="Eonar,PvE,enUS,EU",
[1311]="Kilrogg,PvE,enUS,EU",
[1312]="Aerie Peak,PvE,enUS,EU",
[1313]="Wildhammer,PvE,enUS,EU",
[1314]="Saurfang,PvE,enUS,EU",
[1316]="Nemesis,PvP,itIT,EU",
[1317]="Darkmoon Faire,RP,enUS,EU",
[1318]="Vek'lor,PvP,deDE,EU",
[1319]="Mug'thol,PvP,deDE,EU",
[1320]="Taerar,PvP,deDE,EU",
[1321]="Dalvengyr,PvP,deDE,EU",
[1322]="Rajaxx,PvP,deDE,EU",
[1323]="Ulduar,PvE,deDE,EU",
[1324]="Malorne,PvE,deDE,EU",
[1326]="Der Abyssische Rat,PvP RP,deDE,EU",
[1327]="Der Mithrilorden,RP,deDE,EU",
[1328]="Tirion,PvE,deDE,EU",
[1330]="Ambossar,PvE,deDE,EU",
[1331]="Suramar,PvE,frFR,EU",
[1332]="Krasus,PvE,frFR,EU",
[1333]="Die Nachtwache,RP,deDE,EU",
[1334]="Arathi,PvP,frFR,EU",
[1335]="Ysondre,PvP,frFR,EU",
[1336]="Eldre'Thalas,PvP,frFR,EU",
[1337]="Culte de la Rive noire,PvP RP,frFR,EU",
[1378]="Dun Modr,PvP,esES,EU",
[1379]="Zul'jin,PvP,esES,EU",
[1380]="Uldum,PvP,esES,EU",
[1381]="C'Thun,PvP,esES,EU",
[1382]="Sanguino,PvP,esES,EU",
[1383]="Shen'dralar,PvP,esES,EU",
[1384]="Tyrande,PvE,esES,EU",
[1385]="Exodar,PvE,esES,EU",
[1386]="Minahonda,PvE,esES,EU",
[1387]="Los Errantes,PvE,esES,EU",
[1388]="Lightbringer,PvE,enUS,EU",
[1389]="Darkspear,PvE,enUS,EU",
[1391]="Alonsus,PvE,enUS,EU",
[1392]="Burning Steppes,PvP,enUS,EU",
[1393]="Bronze Dragonflight,PvE,enUS,EU",
[1394]="Anachronos,PvE,enUS,EU",
[1395]="Colinas Pardas,PvE,esES,EU",
[1400]="Un'Goro,PvE,deDE,EU",
[1401]="Garrosh,PvE,deDE,EU",
[1404]="Area 52,PvE,deDE,EU",
[1405]="Todeswache,RP,deDE,EU",
[1406]="Arygos,PvE,deDE,EU",
[1407]="Teldrassil,PvE,deDE,EU",
[1408]="Norgannon,PvE,deDE,EU",
[1409]="Lordaeron,PvE,deDE,EU",
[1413]="Aggra,PvP,ptBR,PvP,EU",
[1415]="Terokkar,PvE,enUS,EU",
[1416]="Blade's Edge,PvE,enUS,EU",
[1417]="Azuremyst,PvE,enUS,EU",
[1587]="Hellfire,PvE,enUS,EU",
[1588]="Ghostlands,PvE,enUS,EU",
[1589]="Nagrand,PvE,enUS,EU",
[1595]="The Sha'tar,RP,enUS,EU",
[1596]="Karazhan,PvP,enUS,EU",
[1597]="Auchindoun,PvP,enUS,EU",
[1598]="Shattered Halls,PvP,enUS,EU",
[1602]="Гордунни,PvP,ruRU,EU,Gordunni",
[1603]="Король-лич,PvP,ruRU,EU,Lich King",
[1604]="Свежеватель Душ,PvP,ruRU,EU,Soulflayer",
[1605]="Страж Смерти,PvP,ruRU,EU,Deathguard",
[1606]="Sporeggar,PvP RP,enUS,EU",
[1607]="Nethersturm,PvE,deDE,EU",
[1608]="Shattrath,PvE,deDE,EU",
[1609]="Подземье,PvP,ruRU,EU,Deepholm",
[1610]="Седогрив,PvP,ruRU,EU,Greymane",
[1611]="Festung der Stürme,PvP,deDE,EU",
[1612]="Echsenkessel,PvP,deDE,EU",
[1613]="Blutkessel,PvP,deDE,EU",
[1614]="Галакронд,PvE,ruRU,EU,Galakrond",
[1615]="Ревущий фьорд,PvP,ruRU,EU,Howling Fjord",
[1616]="Разувий,PvP,ruRU,EU,Razuvious",
[1617]="Ткач Смерти,PvP,ruRU,EU,Deathweaver",
[1618]="Die Aldor,RP,deDE,EU",
[1619]="Das Konsortium,PvP RP,deDE,EU",
[1620]="Chants éternels,PvE,frFR,EU",
[1621]="Marécage de Zangar,PvE,frFR,EU",
[1622]="Temple noir,PvP,frFR,EU",
[1623]="Дракономор,PvE,ruRU,EU,Fordragon",
[1624]="Naxxramas,PvP,frFR,EU",
[1625]="Борейская тундра,PvE,ruRU,EU,Borean Tundra",
[1626]="Les Clairvoyants,RP,frFR,EU",
[1922]="Азурегос,PvE,ruRU,EU,Azuregos",
[1923]="Ясеневый лес,PvP,ruRU,EU,Ashenvale",
[1924]="Пиратская бухта,PvP,ruRU,EU,Booty Bay",
[1925]="Вечная Песня,PvE,ruRU,EU,Eversong",
[1926]="Термоштепсель,PvP,ruRU,EU,Thermaplugg",
[1927]="Гром,PvP,ruRU,EU,Grom",
[1928]="Голдринн,PvE,ruRU,EU,Goldrinn",
[1929]="Черный Шрам,PvP,ruRU,EU,Blackscar",
[1315]="EU", -- Caduta dei Draghi
[1325]="EU", -- Grizzlyhügel
[1329]="EU", -- Muradin
[1390]="EU", -- GM Test realm 2
[1402]="EU", -- Menethil
[1403]="EU", -- Gnomeregan
[2073]="EU", -- Winterhuf
[2074]="EU", -- Schwarznarbe
[3391]="EU", -- Cerchio del Sangue
[3656]="EU", -- Internal Record 3656
[3657]="EU", -- Internal Record 3657
[3660]="EU", -- Internal Record 3660
[3666]="EU", -- Internal Record 3666
[3674]="EU", -- Internal Record 3674
[3679]="EU", -- Internal Record 3679
[3680]="EU", -- Internal Record 3680
[3681]="EU", -- Internal Record 3681
[3682]="EU", -- Internal Record 3682
[3686]="EU", -- Internal Record 3686
[3687]="EU", -- Internal Record 3687
[3690]="EU", -- Internal Record 3690
[3691]="EU", -- Internal Record 3691
[3692]="EU", -- Internal Record 3692
[3696]="EU", -- Internal Record 3696
[3702]="EU", -- Internal Record 3702
[3703]="EU", -- Internal Record 3703
[3713]="EU", -- Internal Record 3713
[3714]="EU", -- Internal Record 3714
--}}
--{{ Korea
[201]="불타는 군단,PvE,koKR,KR,Burning Legion",
[205]="아즈샤라,PvP,koKR,KR,Azshara",
[207]="달라란,PvP,koKR,KR,Dalaran",
[210]="듀로탄,PvP,koKR,KR,Durotan",
[211]="노르간논,PvP,koKR,KR,Norgannon",
[212]="가로나,PvP,koKR,KR,Garona",
[214]="윈드러너,PvE,koKR,KR,Windrunner",
[215]="굴단,PvP,koKR,KR,Gul'dan",
[258]="알렉스트라자,PvP,koKR,KR,Alexstrasza",
[264]="말퓨리온,PvP,koKR,KR,Malfurion",
[293]="헬스크림,PvP,koKR,KR,Hellscream",
[2079]="와일드해머,PvE,koKR,KR,Wildhammer",
[2106]="렉사르,PvE,koKR,KR,Rexxar",
[2107]="하이잘,PvP,koKR,KR,Hyjal",
[2108]="데스윙,PvP,koKR,KR,Deathwing",
[2110]="세나리우스,PvP,koKR,KR,Cenarius",
[2111]="스톰레이지,PvE,koKR,KR,Stormrage",
[2116]="줄진,PvP,koKR,KR,Zul'jin",
--}}
--{{ China
[700]="阿格拉玛,PVP,zhCN,CN",
[703]="艾苏恩,PVP,zhCN,CN",
[704]="安威玛尔,PVP,zhCN,CN",
[705]="奥达曼,PVP,zhCN,CN",
[706]="奥蕾莉亚,PVE,zhCN,CN",
[707]="白银之手,PVE,zhCN,CN",
[708]="暴风祭坛,PVP,zhCN,CN",
[709]="藏宝海湾,PVP,zhCN,CN",
[710]="尘风峡谷,PVP,zhCN,CN",
[711]="达纳斯,PVP,zhCN,CN",
[712]="迪托马斯,PVP,zhCN,CN",
[714]="国王之谷,PVP,zhCN,CN",
[715]="黑龙军团,PVP,zhCN,CN",
[716]="黑石尖塔,PVP,zhCN,CN",
[717]="红龙军团,PVP,zhCN,CN",
[718]="回音山,PVE,zhCN,CN",
[719]="基尔罗格,PVP,zhCN,CN",
[720]="卡德罗斯,PVP,zhCN,CN",
[721]="卡扎克,PVP,zhCN,CN",
[723]="库德兰,PVP,zhCN,CN",
[725]="蓝龙军团,PVP,zhCN,CN",
[726]="雷霆之王,PVP,zhCN,CN",
[727]="烈焰峰,PVP,zhCN,CN",
[729]="罗宁,PVP,zhCN,CN",
[730]="洛萨,PVP,zhCN,CN",
[731]="玛多兰,PVE,zhCN,CN",
[732]="玛瑟里顿,PVP,zhCN,CN",
[734]="奈萨里奥,PVP,zhCN,CN",
[736]="诺莫瑞根,PVP,zhCN,CN",
[737]="普瑞斯托,PVE,zhCN,CN",
[738]="燃烧平原,PVP,zhCN,CN",
[739]="萨格拉斯,PVP,zhCN,CN",
[740]="山丘之王,PVP,zhCN,CN",
[741]="死亡之翼,PVP,zhCN,CN",
[742]="索拉丁,PVP,zhCN,CN",
[744]="铜龙军团,PVP,zhCN,CN",
[745]="图拉扬,PVE,zhCN,CN",
[746]="伊瑟拉,PVE,zhCN,CN",
[748]="阿迦玛甘,PVP,zhCN,CN",
[749]="阿克蒙德,PVP,zhCN,CN",
[750]="埃加洛尔,PVP,zhCN,CN",
[751]="埃苏雷格,PVP,zhCN,CN",
[753]="艾萨拉,PVP,zhCN,CN",
[754]="艾森娜,PVE,zhCN,CN",
[755]="爱斯特纳,PVP,zhCN,CN",
[756]="暗影之月,PVP,zhCN,CN",
[757]="奥拉基尔,PVP,zhCN,CN",
[758]="冰霜之刃,PVP,zhCN,CN",
[760]="达斯雷玛,PVP,zhCN,CN",
[761]="地狱咆哮,PVP,zhCN,CN",
[762]="地狱之石,PVP,zhCN,CN",
[764]="风暴之怒,PVP,zhCN,CN",
[765]="风行者,PVP,zhCN,CN",
[766]="弗塞雷迦,PVP,zhCN,CN",
[767]="戈古纳斯,PVP,zhCN,CN",
[768]="海加尔,PVP,zhCN,CN",
[769]="毁灭之锤,PVP,zhCN,CN",
[770]="火焰之树,PVP,zhCN,CN",
[771]="卡德加,PVP,zhCN,CN",
[772]="拉文凯斯,PVP,zhCN,CN",
[773]="玛法里奥,PVP,zhCN,CN",
[774]="麦维影歌,PVP,zhCN,CN",
[775]="梅尔加尼,PVP,zhCN,CN",
[776]="梦境之树,PVE,zhCN,CN",
[778]="耐普图隆,PVP,zhCN,CN",
[780]="轻风之语,PVE,zhCN,CN",
[781]="夏维安,PVP,zhCN,CN",
[782]="塞纳里奥,PVE,zhCN,CN",
[784]="闪电之刃,PVP,zhCN,CN",
[786]="石爪峰,PVP,zhCN,CN",
[787]="泰兰德,PVE,zhCN,CN",
[788]="屠魔山谷,PVP,zhCN,CN",
[790]="伊利丹,PVP,zhCN,CN",
[791]="月光林地,PVE,zhCN,CN",
[792]="月神殿,PVE,zhCN,CN",
[793]="战歌,PVP,zhCN,CN",
[794]="主宰之剑,PVP,zhCN,CN",
[797]="埃德萨拉,PVP,zhCN,CN",
[799]="血环,PVP,zhCN,CN",
[800]="布莱克摩,PVP,zhCN,CN",
[802]="杜隆坦,PVP,zhCN,CN",
[803]="符文图腾,PVP,zhCN,CN",
[804]="鬼雾峰,PVP,zhCN,CN",
[805]="黑暗之矛,PVP,zhCN,CN",
[806]="红龙女王,PVP,zhCN,CN",
[807]="红云台地,PVP,zhCN,CN",
[808]="黄金之路,PVE,zhCN,CN",
[810]="火羽山,PVP,zhCN,CN",
[812]="迦罗娜,PVP,zhCN,CN",
[814]="凯恩血蹄,PVP,zhCN,CN",
[815]="狂风峭壁,PVP,zhCN,CN",
[816]="雷斧堡垒,PVP,zhCN,CN",
[817]="雷克萨,PVP,zhCN,CN",
[818]="雷霆号角,PVP,zhCN,CN",
[822]="玛里苟斯,PVP,zhCN,CN",
[825]="纳沙塔尔,PVP,zhCN,CN",
[826]="诺兹多姆,PVE,zhCN,CN",
[827]="普罗德摩,PVP,zhCN,CN",
[828]="千针石林,PVP,zhCN,CN",
[829]="燃烧之刃,PVP,zhCN,CN",
[830]="萨尔,PVP,zhCN,CN",
[833]="圣火神殿,PVP,zhCN,CN",
[835]="甜水绿洲,PVP,zhCN,CN",
[838]="熊猫酒仙,PVP,zhCN,CN",
[839]="血牙魔王,PVP,zhCN,CN",
[840]="勇士岛,PVP,zhCN,CN",
[841]="羽月,PVE,zhCN,CN",
[842]="蜘蛛王国,PVP,zhCN,CN",
[843]="自由之风,PVP,zhCN,CN",
[844]="阿尔萨斯,PVP,zhCN,CN",
[845]="阿拉索,PVP,zhCN,CN",
[846]="埃雷达尔,PVP,zhCN,CN",
[847]="艾欧纳尔,PVP,zhCN,CN",
[849]="暗影议会,PVP,zhCN,CN",
[850]="奥特兰克,PVP,zhCN,CN",
[851]="巴尔古恩,PVP,zhCN,CN",
[852]="冰风岗,PVP,zhCN,CN",
[855]="达隆米尔,PVP,zhCN,CN",
[856]="耳语海岸,PVE,zhCN,CN",
[857]="古尔丹,PVP,zhCN,CN",
[858]="寒冰皇冠,PVP,zhCN,CN",
[859]="基尔加丹,PVP,zhCN,CN",
[860]="激流堡,PVP,zhCN,CN",
[861]="巨龙之吼,PVP,zhCN,CN",
[863]="凯尔萨斯,PVP,zhCN,CN",
[864]="克尔苏加德,PVP,zhCN,CN",
[865]="拉格纳洛斯,PVP,zhCN,CN",
[867]="利刃之拳,PVP,zhCN,CN",
[869]="玛诺洛斯,PVP,zhCN,CN",
[870]="麦迪文,PVE,zhCN,CN",
[872]="耐奥祖,PVP,zhCN,CN",
[874]="瑞文戴尔,PVP,zhCN,CN",
[876]="霜狼,PVP,zhCN,CN",
[877]="霜之哀伤,PVE,zhCN,CN",
[878]="斯坦索姆,PVP,zhCN,CN",
[882]="提瑞斯法,PVP,zhCN,CN",
[883]="通灵学院,PVP,zhCN,CN",
[885]="希尔瓦娜斯,PVP,zhCN,CN",
[886]="血色十字军,PVP,zhCN,CN",
[887]="遗忘海岸,PVE,zhCN,CN",
[888]="银松森林,PVE,zhCN,CN",
[889]="银月,PVE,zhCN,CN",
[890]="鹰巢山,PVP,zhCN,CN",
[891]="影牙要塞,PVP,zhCN,CN",
[915]="狂热之刃,PVP,zhCN,CN",
[916]="卡珊德拉,PVP,zhCN,CN",
[917]="迅捷微风,PVP,zhCN,CN",
[918]="守护之剑,PVP,zhCN,CN",
[920]="斩魔者,PVP,zhCN,CN",
[921]="布兰卡德,PVP,zhCN,CN",
[922]="世界之树,PVE,zhCN,CN",
[924]="恶魔之翼,PVP,zhCN,CN",
[925]="万色星辰,PVE,zhCN,CN",
[926]="激流之傲,PVP,zhCN,CN",
[927]="加兹鲁维,PVP,zhCN,CN",
[928]="水晶之刺,PVP,zhCN,CN",
[929]="苏塔恩,PVP,zhCN,CN",
[930]="大地之怒,PVP,zhCN,CN",
[931]="雏龙之翼,PVP,zhCN,CN",
[932]="黑暗魅影,PVP,zhCN,CN",
[933]="踏梦者,PVP,zhCN,CN",
[936]="浸毒之骨,PVP,zhCN,CN",
[938]="密林游侠,PVP,zhCN,CN",
[940]="伊森利恩,PVP,zhCN,CN",
[941]="神圣之歌,PVE,zhCN,CN",
[943]="暮色森林,PVP,zhCN,CN",
[944]="元素之力,PVP,zhCN,CN",
[946]="日落沼泽,PVP,zhCN,CN",
[949]="芬里斯,PVP,zhCN,CN",
[951]="伊萨里奥斯,PVP,zhCN,CN",
[952]="安多哈尔,PVP,zhCN,CN",
[953]="风暴之眼,PVP,zhCN,CN",
[954]="提尔之手,PVP,zhCN,CN",
[956]="永夜港,PVE,zhCN,CN",
[959]="朵丹尼尔,PVP,zhCN,CN",
[960]="法拉希姆,PVP,zhCN,CN",
[962]="金色平原,rppvp,zhCN,CN",
[1198]="安其拉,PVP,zhCN,CN",
[1199]="安纳塞隆,PVP,zhCN,CN",
[1200]="阿努巴拉克,PVP,zhCN,CN",
[1201]="阿拉希,PVP,zhCN,CN",
[1202]="瓦里玛萨斯,PVE,zhCN,CN",
[1203]="巴纳扎尔,PVP,zhCN,CN",
[1204]="黑手军团,PVP,zhCN,CN",
[1205]="血羽,PVP,zhCN,CN",
[1206]="燃烧军团,PVP,zhCN,CN",
[1207]="克洛玛古斯,PVP,zhCN,CN",
[1208]="破碎岭,PVP,zhCN,CN",
[1209]="克苏恩,PVP,zhCN,CN",
[1210]="阿纳克洛斯,PVP,zhCN,CN",
[1211]="雷霆之怒,PVP,zhCN,CN",
[1212]="桑德兰,PVP,zhCN,CN",
[1213]="黑翼之巢,PVP,zhCN,CN",
[1214]="德拉诺,PVP,zhCN,CN",
[1215]="龙骨平原,PVP,zhCN,CN",
[1216]="卡拉赞,PVP,zhCN,CN",
[1221]="熔火之心,PVP,zhCN,CN",
[1222]="格瑞姆巴托,PVP,zhCN,CN",
[1223]="古拉巴什,PVP,zhCN,CN",
[1224]="哈卡,PVP,zhCN,CN",
[1225]="海克泰尔,PVP,zhCN,CN",
[1226]="库尔提拉斯,PVP,zhCN,CN",
[1227]="洛丹伦,PVP,zhCN,CN",
[1228]="奈法利安,PVP,zhCN,CN",
[1229]="奎尔萨拉斯,PVP,zhCN,CN",
[1230]="拉贾克斯,PVP,zhCN,CN",
[1231]="拉文霍德,PVP,zhCN,CN",
[1232]="森金,PVP,zhCN,CN",
[1233]="范达尔鹿盔,PVP,zhCN,CN",
[1234]="泰拉尔,PVP,zhCN,CN",
[1235]="瓦拉斯塔兹,PVP,zhCN,CN",
[1236]="永恒之井,PVP,zhCN,CN",
[1237]="海达希亚,PVE,zhCN,CN",
[1238]="萨菲隆,PVP,zhCN,CN",
[1239]="纳克萨玛斯,PVP,zhCN,CN",
[1240]="无尽之海,PVP,zhCN,CN",
[1241]="莱索恩,PVP,zhCN,CN",
[1482]="阿卡玛,PVP,zhCN,CN",
[1483]="阿扎达斯,PVP,zhCN,CN",
[1484]="灰谷,PVP,zhCN,CN",
[1485]="艾维娜,PVE,zhCN,CN",
[1486]="巴瑟拉斯,PVP,zhCN,CN",
[1487]="血顶,PVP,zhCN,CN",
[1488]="恐怖图腾,PVP,zhCN,CN",
[1489]="古加尔,PVP,zhCN,CN",
[1490]="达文格尔,PVP,zhCN,CN",
[1491]="黑铁,PVP,zhCN,CN",
[1492]="恶魔之魂,PVP,zhCN,CN",
[1493]="迪瑟洛克,PVP,zhCN,CN",
[1494]="丹莫德,PVP,zhCN,CN",
[1495]="艾莫莉丝,PVP,zhCN,CN",
[1496]="埃克索图斯,PVP,zhCN,CN",
[1497]="菲拉斯,PVP,zhCN,CN",
[1498]="加基森,PVP,zhCN,CN",
[1499]="加里索斯,PVP,zhCN,CN",
[1500]="格雷迈恩,PVP,zhCN,CN",
[1501]="布莱恩,PVE,zhCN,CN",
[1502]="伊莫塔尔,PVP,zhCN,CN",
[1503]="大漩涡,PVP,zhCN,CN",
[1504]="诺森德,PVP,zhCN,CN",
[1505]="奥妮克希亚,PVP,zhCN,CN",
[1506]="奥斯里安,PVP,zhCN,CN",
[1507]="外域,PVP,zhCN,CN",
[1508]="天空之墙,PVP,zhCN,CN",
[1509]="风暴之鳞,PVP,zhCN,CN",
[1510]="荆棘谷,PVP,zhCN,CN",
[1511]="逐日者,PVE,zhCN,CN",
[1512]="塔纳利斯,PVP,zhCN,CN",
[1513]="瑟莱德丝,PVP,zhCN,CN",
[1514]="塞拉赞恩,PVP,zhCN,CN",
[1515]="托塞德林,PVP,zhCN,CN",
[1516]="黑暗虚空,PVP,zhCN,CN",
[1517]="安戈洛,PVP,zhCN,CN",
[1519]="祖尔金,PVP,zhCN,CN",
[1657]="冰川之拳,PVP,zhCN,CN",
[1658]="刺骨利刃,PVP,zhCN,CN",
[1659]="深渊之巢,PVP,zhCN,CN",
[1662]="火烟之谷,PVP,zhCN,CN",
[1663]="伊兰尼库斯,PVP,zhCN,CN",
[1664]="火喉,PVP,zhCN,CN",
[1667]="迦玛兰,PVP,zhCN,CN",
[1668]="金度,PVP,zhCN,CN",
[1670]="巫妖之王,PVP,zhCN,CN",
[1672]="米奈希尔,PVP,zhCN,CN",
[1676]="幽暗沼泽,PVP,zhCN,CN",
[1681]="烈焰荆棘,PVP,zhCN,CN",
[1682]="夺灵者,PVP,zhCN,CN",
[1685]="石锤,PVP,zhCN,CN",
[1687]="塞拉摩,PVP,zhCN,CN",
[1692]="厄祖玛特,PVP,zhCN,CN",
[1693]="冬泉谷,PVP,zhCN,CN",
[1694]="伊森德雷,PVP,zhCN,CN",
[1695]="扎拉赞恩,PVP,zhCN,CN",
[1696]="亚雷戈斯,PVE,zhCN,CN",
[1793]="深渊之喉,PVP,zhCN,CN",
[1794]="凤凰之神,PVP,zhCN,CN",
[1795]="阿古斯,PVP,zhCN,CN",
[1798]="鲜血熔炉,PVP,zhCN,CN",
[1801]="黑暗之门,PVP,zhCN,CN",
[1802]="死亡熔炉,PVP,zhCN,CN",
[1803]="无底海渊,PVP,zhCN,CN",
[1807]="格鲁尔,PVP,zhCN,CN",
[1808]="哈兰,PVP,zhCN,CN",
[1809]="军团要塞,PVP,zhCN,CN",
[1810]="麦姆,PVP,zhCN,CN",
[1812]="艾露恩,PVE,zhCN,CN",
[1813]="穆戈尔,PVP,zhCN,CN",
[1815]="摩摩尔,PVP,zhCN,CN",
[1817]="试炼之环,PVP,zhCN,CN",
[1819]="希雷诺斯,PVP,zhCN,CN",
[1820]="塞泰克,PVP,zhCN,CN",
[1821]="暗影迷宫,PVP,zhCN,CN",
[1823]="托尔巴拉德,PVP,zhCN,CN",
[1824]="太阳之井,PVP,zhCN,CN",
[1827]="末日祷告祭坛,PVP,zhCN,CN",
[1828]="范克里夫,PVP,zhCN,CN",
[1829]="瓦丝琪,PVP,zhCN,CN",
[1830]="祖阿曼,PVP,zhCN,CN",
[1832]="翡翠梦境,PVE,zhCN,CN",
[1931]="阿比迪斯,PVP,zhCN,CN",
[1932]="阿曼尼,PVP,zhCN,CN",
[1933]="安苏,PVP,zhCN,CN",
[1934]="生态船,PVP,zhCN,CN",
[1935]="阿斯塔洛,PVP,zhCN,CN",
[1936]="白骨荒野,PVP,zhCN,CN",
[1937]="布鲁塔卢斯,PVP,zhCN,CN",
[1938]="达尔坎,PVP,zhCN,CN",
[1939]="末日行者,PVP,zhCN,CN",
[1940]="达基萨斯,PVP,zhCN,CN",
[1941]="熵魔,PVP,zhCN,CN",
[1942]="能源舰,PVP,zhCN,CN",
[1943]="菲米丝,PVP,zhCN,CN",
[1944]="加尔,PVP,zhCN,CN",
[1945]="迦顿,PVP,zhCN,CN",
[1946]="血吼,PVP,zhCN,CN",
[1947]="戈提克,PVP,zhCN,CN",
[1948]="盖斯,PVP,zhCN,CN",
[1949]="壁炉谷,PVP,zhCN,CN",
[1950]="贫瘠之地,PVE,zhCN,CN",
[1955]="霍格,PVP,zhCN,CN",
[1965]="奎尔丹纳斯,PVP,zhCN,CN",
[1969]="萨洛拉丝,PVP,zhCN,CN",
[1970]="沙怒,PVP,zhCN,CN",
[1971]="嚎风峡湾,PVP,zhCN,CN",
[2118]="迦拉克隆,PVE,zhCN,CN",
[2120]="奥尔加隆,PVP,zhCN,CN",
[2121]="安格博达,PVP,zhCN,CN",
[2122]="安加萨,PVP,zhCN,CN",
[2123]="织亡者,PVP,zhCN,CN",
[2124]="亡语者,PVP,zhCN,CN",
[2125]="达克萨隆,PVP,zhCN,CN",
[2126]="黑锋哨站,PVP,zhCN,CN",
[2127]="古达克,PVP,zhCN,CN",
[2129]="洛肯,PVP,zhCN,CN",
[2130]="玛洛加尔,PVP,zhCN,CN",
[2131]="莫德雷萨,PVP,zhCN,CN",
[2132]="萨塔里奥,PVP,zhCN,CN",
[2133]="影之哀伤,PVP,zhCN,CN",
[2134]="风暴峭壁,PVP,zhCN,CN",
[2135]="远古海滩,PVP,zhCN,CN",
[2137]="冬拥湖,PVP,zhCN,CN",
--}}
--{{ Taiwan
[963]="暗影之月,PvE,zhTW,TW,Shadowmoon",
[964]="尖石,PvP,zhTW,TW,Spirestone",
[965]="雷鱗,PvP,zhTW,TW,Stormscale",
[966]="巨龍之喉,PvP,zhTW,TW,Dragonmaw",
[977]="冰霜之刺,PvP,zhTW,TW,Frostmane",
[978]="日落沼澤,PvP,zhTW,TW,Sundown Marsh",
[979]="地獄吼,PvP,zhTW,TW,Hellscream",
[980]="天空之牆,PvE,zhTW,TW,Skywall",
[982]="世界之樹,PvE,zhTW,TW,World Tree",
[985]="水晶之刺,PvP,zhTW,TW,Crystalpine Stinger",
[999]="狂熱之刃,PvP,zhTW,TW,Zealot Blade",
[1001]="冰風崗哨,PvP,zhTW,TW,Chillwind Point",
[1006]="米奈希爾,PvP,zhTW,TW,Menethil",
[1023]="屠魔山谷,PvP,zhTW,TW,Demon Fall Canyon",
[1033]="語風,PvE,zhTW,TW,Whisperwind",
[1037]="血之谷,PvP,zhTW,TW,Bleeding Hollow",
[1038]="亞雷戈斯,PvE,zhTW,TW,Arygos",
[1043]="夜空之歌,PvP,zhTW,TW,Nightsong",
[1046]="聖光之願,PvE,zhTW,TW,Light's Hope",
[1048]="銀翼要塞,PvP,zhTW,TW,Silverwing Hold",
[1049]="憤怒使者,PvP,zhTW,TW,Wrathbringer",
[1054]="阿薩斯,PvP,zhTW,TW,Arthas",
[1056]="眾星之子,PvE,zhTW,TW,Quel'dorei",
[1057]="寒冰皇冠,PvP,zhTW,TW,Icecrown",
[2075]="雲蛟衛,PvE,zhTW,TW,Order of the Cloud Serpent",
--}}
}

------------------------------------------------------------------------

connectionData = {
--{{ North America
	-- http://us.battle.net/wow/en/blog/11393305
	"1136,83,109,129,1142", -- Aegwynn, Bonechewer, Daggerspine, Gurubashi, Hakkar
	"1129,56,1291,1559", -- Agamaggan, Archimonde, Jaedenar, The Underbog
	"106,1576", -- Aggramar, Fizzcrank
	"1137,84,1145", -- Akama, Dragonmaw, Mug'thol
	"1070,1563", -- Alexstrasza, Terokkar
	"52,65", -- Alleria, Khadgar
	"1282,1264,78,1268", -- Altar of Storms, Anetheron, Magtheridon, Ysondre
	"1293,1075,80,1344,71", -- Alterac Mountains, Balnazzar, Gorgonnash, The Forgotten Coast, Warsong
	"1276,1267,156,1259", -- Andorhal, Scilla, Ursin, Zuluhed
	"1363,116", -- Antonidas, Uldum
	"1346,1138,107,1141,130", -- Anub'arak, Chromaggus, Crushridge, Garithos, Nathrezim, Smolderthorn
	"1288,1294", -- Anvilmar, Undermine
	"1165,1377", -- Arathor, Drenden
	"75,1570", -- Argent Dawn, The Scryers
	"1297,99", -- Arygos, Llane
	"1555,1067,101", -- Auchindoun, Cho'gall, Laughing Skull
	"77,1128,79,103", -- Azgalor, Azshara, Destromath, Thunderlord
	"121,1143", -- Azjol-Nerub, Khaz Modan
	"1549,160", -- Azuremyst, Staghelm
	"1190,13", -- Baelgun, Doomhammer
	"1280,1068,74", -- Black Dragonflight, Gul'dan, Skullcrusher
	"54,1581", -- Blackhand, Galakrond
	"1347,125", -- Blackwater Raiders, Shadow Council
	"1296,81,154,1266,1295", -- Blackwing Lair, Dethecus, Detheroc, Haomarush, Lethon
	"1353,1147", -- Bladefist, Kul Tiras
	"1564,105", -- Blade's Edge, Thunderhorn
	"1558,70,1131", -- Blood Furnace, Mannoroth, Nazjatar
	"64,1258", -- Bloodhoof, Duskwood
	"119,112,111,1357,108", -- Bloodscalp, Boulderfist, Dunemaul, Maiev, Stonemaul
	"1371,85", -- Borean Tundra, Shadowsong
	"117,1364", -- Bronzebeard, Shandris
	"91,95,1285", -- Burning Blade, Lightning's Blade, Onyxia
	"1430,1432", -- Caelestrasz, Nagrand
	"1361,122", -- Cairne, Perenolde
	"88,1356", -- Cenarion Circle, Sisters of Elune
	"1556,1278,157,1286,72", -- Coilfang, Dalvengyr, Dark Iron, Demon Soul, Shattered Hand
	"1351,87", -- Darrowmere, Windrunner
	"1434,1134", -- Dath'Remar, Khaz'goroth
	"1582,1173", -- Dawnbringer, Madoran
	"15,1277,155,1557", -- Deathwing, Executus, Kalecgos, Shattered Halls
	"1271,55", -- Dentarg, Whisperwind
	"115,1342", -- Draenor, Echo Isles
	"114,1345", -- Dragonblight, Fenris
	"1139,113", -- Draka, Suramar
	"1362,127,1148,1358,124,110", -- Drak'Tharon, Firetree, Malorne, Rivendare, Spirestone, Stormscale
	"1140,131", -- Drak'thul, Skywall
	"1429,1433", -- Dreadmaul, Thaurissan
	"63,1270", -- Durotan, Ysera
	"58,1354", -- Eitrigg, Shu'halo
	"123,1349", -- Eldre'Thalas, Korialstrasz
	"67,97", -- Elune, Gilneas
	"96,1567", -- Eonar, Velen
	"93,92,82,159", -- Eredar, Gorefiend, Spinebreaker, Wildhammer
	"1565,62", -- Exodar, Medivh
	"1370,12,1154", -- Farstriders, Silver Hand, Thorium Brotherhood
	"118,126", -- Feathermoon, Scarlet Crusade
	"128,8,1360", -- Frostmane, Ner'zhul, Tortheldrin
	"7,1348", -- Frostwolf, Vashj
	"1578,1069", -- Ghostlands, Kael'thas
	"1287,153", -- Gnomeregan, Moonrunner
	"158,1292", -- Greymane, Tanaris
	"1579,68", -- Grizzly Hills, Lothar
	"1149,1144", -- Gundrak, Jubei'Thos
	"53,1572", -- Hellscream, Zangarmarsh
	"1368,90", -- Hydraxis, Terenas
	"14,104", -- Icecrown, Malygos
	"98,1262", -- Kargath, Norgannon
	"4,1355", -- Kilrogg, Winterhoof
	"1071,1290,1260", -- Kirin Tor, Sentinels, Steamwheedle Cartel
	"1130,163,1289", -- Lightninghoof, Maelstrom, The Venture Co
	"1132,1175", -- Malfurion, Trollbane
	"1350,1151", -- Misha, Rexxar
	"1374,86", -- Mok'Nathal, Silvermoon
	"1182,1359", -- Muradin, Nordrassil
	"1367,1375,1184", -- Nazgrel, Nesingwary, Vek'nilash
	"1372,1185", -- Quel'dorei, Sen'jin
	"1072,1283", -- Ravencrest, Uldaman
	"1352,164", -- Ravenholdt, Twisting Nether
	"151,3", -- Runetotem, Uther
--}}
--{{ Europe
	-- Current:  http://eu.battle.net/wow/en/forum/topic/8715582685
	-- Upcoming: http://eu.battle.net/wow/en/forum/topic/9582578502

	-- English
	-- PVE
	"1082,1391,1394", -- Kul Tiras / Alonsus / Anachronos
	"1081,1312", -- Bronzebeard / Aerie Peak
	"1416,1298,1310", -- Blade's Edge / Vek'nilash / Eonar
	"1313,552", -- Wildhammer / Thunderhorn
	"1311,547,1589", -- Kilrogg / Runetotem / Nagrand
	"500,619", -- Aggramar / Hellscream
	"1587,501", -- Hellfire / Arathor
	"633,630,1087,1392,556", -- Kor’gall / Bloodfeather / Executus / Burning Steppes / Shattered Hand
	"503,623", -- Azjol-Nerub / Quel'Thalas
	"1588,507", -- Ghostlands / Dragonblight
	"1389,1415,1314", -- Darkspear / Terokkar / Saurfang
	"502,548", -- Aszune / Shadowsong
	"1080,504", -- Khadgar / Bloodhoof
	"1393,618", -- Bronze Dragonflight / Nordrassil
	"1388,1089", -- Lightbringer / Mazrigos
	"1417,550", -- Azuremyst / Stormrage
	"505,553", -- Doomhammer / Turalyon
	"508,551", -- Emerald Dream / Terenas
	-- PVP
	"1598,607,1093,1088,1090,1083,1299,526,621,511", -- Shattered Halls / Balnazzar / Ahn'Qiraj / Trollbane / Talnivarr / Chromaggus / Boulderfist / Daggerspine / Laughing Skull / Sunstrider
	"1091,518,646,525,522,513", -- Emeriss / Agamaggan / Hakkar / Crushridge / Bloodscalp / Twilight's Hammer
	"1303,1413", -- Grim Batol / Aggra
	"1596,637,527,627", -- Karazhan / Lightning’s Blade / Deathwing / The Maelstrom
	"1597,529,1304", -- Auchindoun / Dunemaul / Jaedenar
	"528,558,638,629,559", -- Dragonmaw / Spinebreaker / Haomarush / Vashj / Stormreaver
	"515,521,632", -- Zenedar / Bladefist / Frostwhisper
	"639,557,519", -- Xavius / Skullcrusher / Al'Akir
	"631,606,624", -- Darksorrow / Genjuros / Neptulon
	"1092,523", -- Drak’thul / Burning Blade
	"1084,1306", -- Dentarg / Tarren Mill
	-- RP
	"1085,1595,1117", -- Moonglade / The Sha'tar / Steamwheedle Cartel
	"1317,561", -- Darkmoon Faire / Earthen Ring
	-- RP PVP
	"1096,1308,636,1606,635", -- Scarshield Legion / Ravenholdt / The Venture Co / Sporeggar / Defias Brotherhood

	-- French
	-- PVE
	"1620,510", -- Chants éternels / Vol'jin
	"540,645", -- Elune / Varimathras
	"1621,538", -- Marécage de Zangar / Dalaran
	"1123,1332", -- Eitrigg / Krasus
	"1331,517", -- Suramar / Medivh
	"1122,641", -- Uldaman / Drek'Thar
	-- PvE
	"1620,510", -- Chants éternels / Vol'jin
	"540,645", -- Elune / Varimathras
	"1621,538", -- Marécage de Zangar / Dalaran
	"1123,1332", -- Eitrigg / Krasus
	"1331,517", -- Suramar / Medivh
	"1122,641", -- Uldaman / Drek'Thar
	-- PvP
	"512,643,642,543", -- Arak-arahm / Throk'Feroth / Rashgarroth / Kael'Thas
	"1624,1334,1622,541", -- Naxxramas / Arathi / Temple noir / Illidan
	"546,509,544", -- Sargeras / Garona / Ner'zhul
	"1336,545,533", -- Eldre'Thalas / Cho'gall / Sinstralis
	-- RP
	"1127,1626,647", -- Confrérie du Thorium / Les Clairvoyants / Les Sentinelles
	-- RP PvP
	"1086,1337,644", -- La Croisade écarlate / Culte de la Rive noire / Conseil des Ombres

	-- German
	-- PVE
	"567,1323", -- Gilneas / Ulduar
	"1401,1608,574", -- Garrosh / Shattrath / Nozdormu
	"1607,562", -- Nethersturm / Alexstrasza
	"1400,1404,602", -- Un'GoroArea 52 / Sen'jin
	"1330,568", -- Ambossar / Kargath
	"1097,1324", -- Ysera / Malorne
	"1098,572", -- Malygos / Malfurion
	"1106,1409", -- Tichondrius / Lordaeron
	"1406,569", -- Arygos / Khaz'goroth
	"1407,575", -- Teldrassil / Perenolde
	"535,1328", -- Durotan / Tirion
	"570,565", -- Lothar / Baelgun
	"1408,600", -- Norgannon / Dun Morogh
	"1099,563", -- Rexxar / Alleria
	"593,571", -- Proudmoore / Madmortem
	-- PVP
	"1105,1321,584,573,608", -- Nazjatar / Dalvengyr / Frostmourne / Zuluhed / Anub'arak
	"578,1318,1613,588,609", -- Arthas / Vek'lor / Blutkessel / Kel'Thuzad / Wrathbringer
	"531,615,1319,605,610", -- Dethecus / Terrordar / Mug'thol / Theradras / Onyxia
	"1612,1320,590", -- Echsenkessel / Taerar / Mal'Ganis
	"1104,1611,1322,587,594,589", -- Anetheron / Festung der Stürme / Rajaxx / Gul'dan / Nathrezim / Kil'jaeden
	"612,611,591,582,586", -- Nefarian / Nera'thor / Mannoroth / Destromath / Gorgonnash
	"579,616", -- Azshara / Krag'jin
	-- RP
	"1118,576", -- Die ewige Wacht / Die Silberne Hand
	"1405,592", -- Todeswache / Zirkel des Cenarius
	"1327,617", -- Der Mithrilorden / Der Rat von Dalaran
	"516,1333", -- Die Nachtwache / Forscherliga
	-- RP PVP
	"1121,1119,614,1326,613,1619", -- Die Arguswacht / Die Todeskrallen / Das Syndikat / Der abyssische Rat / Kult der Verdammten / Das Konsortium

	-- Spanish
	-- PVE
	"1385,1386", -- Exodar / Minahonda
	"1395,1384,1387", -- Colinas Pardas / Tyrande / Los Errantes
	-- PVP
	"1379,1382,1383,1380", -- Zul'jin / Sanguino / Shen'dralar / Uldum

	-- Russian
	-- PVP
	"1924,1617", -- Booty Bay (RU) / Deathweaver (RU)
	"1609,1616", -- Deepholm (RU) / Razuvious (RU)
	"1927,1926", -- Grom (RU) / Thermaplugg (RU)
	"1603,1610", -- Lich King (RU) / Greymane (RU)
--}}
--{{ Korea
	-- https://github.com/phanx-wow/LibRealmInfo/issues/8
	-- PVE
	"201,2111", -- 불타는 군단 / 스톰레이지
	"2106,2079,214", -- 렉사르 / 와일드해머 / 윈드러너
	-- PVP
	"258,2108", -- 알렉스트라자 / 데스윙
	"2110,207,264,211", -- 세나리우스 / 달라란 / 말퓨리온 / 노르간논
	"212,215,2116", -- 가로나 / 굴단 / 줄진
--}}
--{{ Taiwan
	-- inferred by GUID sniffing, needs confirmation by GetAutoCompleteRealms
	"3663,982,1038",
	"963,1056,1033",
	"964,1001,1057",
	"966,1043,965",
	"978,1023",
	"980,1046",
	"985,1049",
	"999,979,1054",
--}}
}

------------------------------------------------------------------------

if standalone then
	LRI_RealmData = realmData
	LRI_ConnectionData = connectionData
end
