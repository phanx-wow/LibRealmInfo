LibRealmInfo
===============

World of Warcraft library for obtaining information about realms.

* **Download:** [Curse](http://wow.curseforge.com/addons/librealminfo)
* **Download:** [WoWInterface](http://www.wowinterface.com/downloads/info22987-LibRealmInfo.html)  
* **Source & Issues:** [GitHub](https://github.com/Phanx/LibRealmInfo)
* **API Documentation:** [GitHub Wiki](https://github.com/Phanx/LibRealmInfo/wiki)


Usage
--------

#### GetRealmInfo

`LibStub("LibRealmInfo"):GetRealmInfo(realmID)`  
=> name, apiName, rules, locale, battlegroup, region, timezone, connected, latinName

#### GetRealmInfoByName

`LibStub("LibRealmInfo"):GetRealmInfoByName(name, region)`  
=> realmID, name, apiName, rules, locale, battlegroup, region, timezone, connected, latinName

#### GetRealmInfoByUnit

`LibStub("LibRealmInfo"):GetRealmInfoByUnit(unit)`  
=> realmID, name, apiName, rules, locale, battlegroup, region, timezone, connected, latinName

See the [API documentation](https://github.com/Phanx/LibRealmInfo/wiki) on GitHub for more details!


To Do
--------

#### Data for Korean realms?

If you have an active Korean account, please see [this forum post](http://www.wowinterface.com/forums/showthread.php?p=294425#post294425). If you don't know how to run the script provided there, you can just post the whole HTML source of the relevant page (right-click > view source > save, then attach the file to your post).


License
----------

This is free and unencumbered software released into the public domain.

See the accompanying LICENSE file for more details.