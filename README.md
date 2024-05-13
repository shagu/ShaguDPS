## Pepo changes
Significantly improved performance by separating the event listeners along with other changes.  Additionally if you are on damage or dps mode it will ignore heal events and vice versa so you can't see healing for a fight after the fact.

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
/sdps pastel 0         Use pastel colors (0 or 1)
/sdps backdrop 1       Show window backdrop and border (0 or 1)
/sdps toggle           Toggle visibility of the main window
```

## Combat Log Range

ShaguDPS relies fully on the combat log and does not have any sort of raid-syncing between players.
That means, thing you see are limited by the maximum range your combat log can display. The game defaults are set to 40 yards.
If you want to increase that range, you can run the following command in order to set it to 200:

    /run for _,n in pairs({"Party", "PartyPet", "FriendlyPlayers", "FriendlyPlayersPets", "HostilePlayers", "HostilePlayersPets", "Creature" }) do SetCVar("CombatLogRange"..n, 200) end

Alternatively you can set it manually in your Config.wtf:

    SET CombatLogRangeParty "200"
    SET CombatLogRangePartyPet "200"
    SET CombatLogRangeFriendlyPlayers "200"
    SET CombatLogRangeFriendlyPlayersPets "200"
    SET CombatLogRangeHostilePlayers "200"
    SET CombatLogRangeHostilePlayersPets "200"
    SET CombatLogRangeCreature "200"

You should keep in mind that some unitframe-addons rely on the combat log range to be set exactly to "40".
Increasing the range, can break the 40y range checks of those, and others might simply reset it back to "40".
