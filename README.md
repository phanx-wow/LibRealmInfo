# LibRealmInfo

World of Warcraft library for obtaining information about realms.

#### Download

* [Curse](http://wow.curseforge.com/addons/librealminfo)
* [WoWInterface](http://www.wowinterface.com/downloads/info22987)

#### Source & Issues

* [GitHub](https://github.com/phanx/wow-librealminfo)


## Usage

    name, type, language, battlegroup, region, timezone = LibStub("LibRealmInfo"):GetRealmInfo(realmID)

#### Arguments

1. `realmID` - number/string: the ID for the realm to query (strings will be converted to numbers)

#### Returns

1. `name` - string: the realm name
2. `type` - string: one of "PVE", "PVP", "RP" or "RPPVP"
3. `language` - string: the official realm language, corresponds with [GetLocale](http://wowpedia.org/API_GetLocale)() values
4. `battlegroup` - string: the battlegroup to which the realm belongs
5. `region` - string: one of "US", "EU", "CN" or "TW" (Korean realms not yet supported)
6. `timezone` - string/nil: for enUS realms, one of "PST", "MST", "CST", "EST" or "AEST"


### Notes

Realm IDs can be obtained on current 5.x live servers for the player, and the player's BattleTag and Real ID friends, using [BNGetToonInfo](http://wowpedia.org/API_BNGetToonInfo):

    _, _, _, _, realmID = BNGetToonInfo(presenceID or toonID)

or [BNGetFriendToonInfo](http://wowpedia.org/API_BNGetToonInfo):

    _, _, _, _, realmID = BNGetFriendToonInfo(friendIndex, toonIndex)

The player's own presenceID can be obtained using [BNGetInfo](http://wowpedia.org/API_BNGetInfo):

    presenceID = BNGetInfo()

These methods are only available while connected to Battle.net, and return no data on trial accounts, or on accounts for which Battle.net social features have been disabled via parental controls.

#### Obtaining realm IDs in WoW 6.x

In WoW 6.x (Warlords of Draenor) realm IDs can be obtained directly from GUIDs for all player units:

    _, realmID = strsplit(":", UnitGUID("player"))

Note that in 6.x the GUID format will change depending on the unit type; the above example will only work for player units. See [this WoWI thread](http://www.wowinterface.com/forums/showthread.php?t=49503) for more information.


## Author & Credits

Library written by [Phanx](mailto:addons@phanx.net) with data collected by [Semlar](http://www.wowinterface.com/forums/showthread.php?p=294432#post294432), [TOM_RUS](http://www.wowinterface.com/forums/showthread.php?p=294512#post294512) [Vlad](http://www.wowinterface.com/forums/showthread.php?p=294425#post294425).


## License

This is free and unencumbered software released into the public domain.

See the accompanying LICENSE file for more details.