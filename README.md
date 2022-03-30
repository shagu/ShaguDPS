# ShaguDPS

A very small and lightweight damage meter. The combat log is parsed locale-independent and should work on every 1.12 vanilla based client.
It does not have much functionality and will not gain much more features.

**Don't expect to see anything fancy here.**

![ShaguDPS](screenshot.jpg)

![ShaguDPS](screenshot2.jpg)

## Installation
1. Download **[Latest Version](https://github.com/shagu/ShaguDPS/archive/master.zip)**
2. Unpack the Zip file
3. Rename the folder "ShaguDPS-master" to "ShaguDPS"
4. Copy "ShaguDPS" into Wow-Directory\Interface\AddOns
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
