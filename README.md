[<img src="https://up.jross.me/textscreens/logo-dark-slim.svg" alt="3D2D Textscreens" width="300px">](https://steamcommunity.com/sharedfiles/filedetails/?id=109643223)

[<img src="https://up.jross.me/textscreens/nodecraft-logo-light.svg" alt="Powered by Nodecraft" width="300px">](https://nodecraft.com/r/textscreens)

[![Actions Status](https://github.com/Cherry/3D2D-Textscreens/workflows/Lint/badge.svg)](https://github.com/Cherry/3D2D-Textscreens/actions)
[![Steam Workshop Subscribers](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-steam-workshop.jross.me%2F109643223)](https://steamcommunity.com/sharedfiles/filedetails/?id=109643223)
[![Crowdin](https://badges.crowdin.net/3d2d-textscreens/localized.svg)](https://crowdin.com/project/3d2d-textscreens)
> This addon can be installed via the [Steam Workshop for Garry's Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=109643223) - I do not recommend manually installing this addon via git.

## Features
* Create 3D2D text anywhere in the world
* Rotate and manipulate this text simply via your physgun
* Up to 5 lines of text
* Multiple different fonts, font sizes, and colours
* Heavily optimised
  * Full scale testing on a highly popular RP server
  * Draw distance optimisations
  * Minimal FPS hit
* Permanent text screens
  * Hold C for context menu, right click on the textscreen, and make the text screen permanent (only works for admins). This is perfect for welcome messages or rules.
* Presets
  * Define preset textscreen data (size, text, colours, etc) and save/load these for future use at any time. This is very useful to trying to replicate multiple textscreens across maps.


## User Customisation
* `ss_render_range` controls how far textscreens have to be away from you in order to render (default `1500`). Setting this to a lower number can help with lag on older machines
* `ss_render_rainbow` controls if rainbow textscreens should actually rotate their colours, or render as solid white (default enabled `1`). `0` will cause them to render as solid white, which can be beneficial for accessibility

## Server owners
* `sbox_maxtextscreens` controls the maximum amount of text screens that each player can spawn. This defaults to 1. This cvar only exists on the server, so make sure it's set via RCON, or in something like server.cfg.
* `ss_enable_rainbow` controls whether players on your server can use the rainbow effect. Set this to `0` in your `server.cfg` to prevent anyone from using rainbow effects.
* Set `ss_call_to_home 1` on your server to provide anonymous analytics including your operating system, version of the addon, and rough, anonymised geo-location. This is entirely optional and used solely to put a smile on my face.
* To install this onto your server, follow the instructions [listed here](https://wiki.garrysmod.com/page/Workshop_for_Dedicated_Servers).

### Prevent specific users/groups from using textscreens
This addon supports a `PlayerSpawnTextscreen` hook that passes the player context. If this hook returns false, the player will be prevented from spawning a textscreen. For example:
```lua
hook.Add("PlayerSpawnTextscreen", "MyCustomTextscreensSpawnFunc", function(ply)
	return ply:IsVIP()
end)
```

### Custom admin permissions
This addon supports custom permissions via the use of a `TextscreensCanAdmin` hook. When this hook isn't present, or doesn't return anything, it defaults to an `IsSuperAdmin` check. If you want to override this behaviour for your own admin permissions, create a hook that exists both server *and* client side, similar to the following:
```lua
hook.Add("TextscreensCanAdmin", "MyCustomAdminFunc", function(ply)
	return ply:SteamID() == "STEAM_0:0:43716939"
end)
```

---

Further information can be found on the [Steam Workshop for Garry's Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=109643223) or [on my website](https://jross.me/3d2d-textscreens/).

All pull requests welcomed.
