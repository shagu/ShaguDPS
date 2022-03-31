# ShaguDPS

A very small and lightweight damage meter. The combat log is parsed in a locale-independent way and should work on every 1.12 (vanilla) and 2.4.3 (burning crusade) based client.

The goal is not to compete with the big players like [DPSMate](https://github.com/Geigerkind/DPSMate) or [Recount](https://www.curseforge.com/wow/addons/recount),
but instead to offer a simple damage tracker, that is fast and uses the least amount of resources as possible.

**So don't expect to see anything fancy here.**

![ShaguDPS](screenshot.jpg)

![ShaguDPS](screenshot2.jpg)

## Installation (Vanilla, 1.12)
1. Download **[Latest Version](https://github.com/shagu/ShaguDPS/archive/master.zip)**
2. Unpack the Zip file
3. Rename the folder "ShaguDPS-master" to "ShaguDPS"
4. Copy "ShaguDPS" into Wow-Directory\Interface\AddOns
5. Restart Wow

## Installation (The Burning Crusade, 2.4.3)
1. Download **[Latest Version](https://github.com/shagu/ShaguDPS/archive/master.zip)**
2. Unpack the Zip file
3. Rename the folder "ShaguDPS-master" to "ShaguDPS-tbc"
4. Copy "ShaguDPS-tbc" into Wow-Directory\Interface\AddOns
5. Restart Wow

## Commands

The following commands can be used to access the settings:
* **/shagudps**
* **/sdps**
* **/sd**

If one is already used by another addon, just pick an alternative command.
Available options are:

```
/sdps visible 1        Show main window (0 or 1)
/sdps width 180        Bar width (any number)
/sdps height 17        Bar height (any number)
/sdps bars 8           Visible Bars (any number)
/sdps trackall 0       Track all nearby units (0 or 1)
/sdps texture 2        Set the statusbar texture (1 to 4)
/sdps pfui 1           Inherit pfUI theme if available (0 or 1)
/sdps toggle           Toggle visibility of the main window
```
