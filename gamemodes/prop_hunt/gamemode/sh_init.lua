// Include the required lua files
include("sh_player.lua")


// Include the configuration for this map
if file.Exists("../gamemodes/prop_hunt/gamemode/maps/"..game.GetMap()..".lua", "LUA") || file.Exists("../lua_temp/prop_hunt/gamemode/maps/"..game.GetMap()..".lua", "LUA") then
	include("maps/"..game.GetMap()..".lua")
end


// Fretta!
IncludePlayerClasses()


// Fretta configuration



// Called on gamemdoe initialization to create teams