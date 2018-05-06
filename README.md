LibRealmInfo
===============

Library to provide information about realms.

* [Download on CurseForge](https://wow.curseforge.com/projects/librealminfo)
* [Download on WoWInterface](https://www.wowinterface.com/downloads/info22987-LibRealmInfo.html)
* [Source Code on GitHub](https://github.com/phanx-wow/LibRealmInfo)
* [Issue Tracker on GitHub](https://github.com/phanx-wow/LibRealmInfo/issues)


Documentation
----------------

* [API functions](https://github.com/phanx-wow/LibRealmInfo/wiki/API)
* [Adding LibRealmInfo to your addon](https://github.com/Phanx/LibRealmInfo/wiki/Embedding)


Caveats
----------

If you only need to know the names of realms connected to the player's current realm, you should just use [GetAutoCompleteRealms](http://wowpedia.org/API_GetAutoCompleteRealms) instead of this library.

If you only need to know which region (US, Europe, etc.) the player is currently in, you can try [GetCurrentRegion](http://wowpedia.org/API_GetCurrentRegion), but you should be aware that this function may return incorrect values for players whose game clients have connected to multiple regions.

Note that the realm IDs contained in the GUIDs of player characters on connected realms identify the server currently hosting the connected realm group, which may not be the realm that character actually belongs to. Pass the GUID to [GetPlayerInfoByGUID](http://wowpedia.org/API_GetPlayerInfoByGUID) to get the character's real realm name, or use the `GetRealmInfoByGUID` or `GetRealmInfoByUnit` methods provided by LibRealmInfo.

LibRealmInfo is currently missing information about connected realms in the Chinese region, and the information it does provide about Chinese realms may be incomplete or outdated. The Battle.net Developer API doesn't provide data about Chinese realms, so the Chinese realm data in LibRealmInfo was compiled manually, and has not been updated since 2014. If you can provide updated data, please open an issue or pull request!
