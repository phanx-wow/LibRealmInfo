# LibRealmInfo

World of Warcraft library for obtaining information about realms.


## Download

* [Curse](http://www.curse.com/addons/wow/librealminfo)
* [WoWInterface](http://www.wowinterface.com/downloads/info)


## Source & Issues

* [GitHub](https://github.com/phanx/wow-librealminfo)


## Usage

	name, type, language, region = LibStub("LibRealmInfo"):GetRealmInfo(realmID)

### Arguments

1. `realmID` - number: the ID for the realm to query

### Returns

1. `name` - string: the name of the realm
2. `type` - string: one of "PVE", "PVP", "RP" or "RPPVP"
3. `language` - string: the official language of the realm, corresponds with GetLocale() values
4. `region` - string: one of "US" or "EU" (other regions not yet supported)
5. `subregion` - string/nil: an additional descriptor if other than what's indicated by the language and region, currently only "Oceanic" for US/Oceanic realms

### Notes

Realm IDs can be obtained on current 5.x live servers through Battle.net using [BNGetToonInfo](http://wowpedia.org/API_BNGetToonInfo):

	_, _, _, _, realmID = BNGetToonInfo(presenceID or toonID)

or [BNGetFriendToonInfo](http://wowpedia.org/API_BNGetToonInfo):

	_, _, _, _, realmID = BNGetFriendToonInfo(friendIndex, toonIndex)

The player's own presenceID can be obtained using [BNGetInfo](http://wowpedia.org/API_BNGetInfo):

	presenceID = BNGetInfo()

In WoW 6.x (Warlords of Draenor) realm IDs can be obtained directly from GUIDs:

	_, realmID = strsplit(":", UnitGUID("player"))

Note that in 6.x the GUID format will change depending on the unit type; the above example will only work for player units. See [this WoWI thread](http://www.wowinterface.com/forums/showthread.php?t=49503) for more information.


## Author & Credits

Written by [Phanx](mailto:addons@phanx.net) with data collected by
[Vlad](http://www.wowinterface.com/forums/showthread.php?p=294425#post294425)
and [Semlar](http://www.wowinterface.com/forums/showthread.php?p=294432#post294432).


## License

This is free and unencumbered software released into the public domain.

See the accompanying LICENSE file for more details.