// Send the required lua files to the client
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "shared_player.lua" )
AddCSLuaFile( "config.lua" )
AddCSLuaFile( 'skin.lua' )
AddCSLuaFile( 'player_class.lua' )
AddCSLuaFile( 'class_default.lua' )
AddCSLuaFile( 'player_extension.lua' )
AddCSLuaFile( 'vgui/vgui_hudlayout.lua' )
AddCSLuaFile( 'vgui/vgui_hudelement.lua' )
AddCSLuaFile( 'vgui/vgui_hudbase.lua' )
AddCSLuaFile( 'vgui/vgui_hudcommon.lua' )
AddCSLuaFile( 'vgui/vgui_gamenotice.lua' )
AddCSLuaFile( 'vgui/vgui_scoreboard.lua' )
AddCSLuaFile( 'vgui/vgui_scoreboard_team.lua' )
AddCSLuaFile( 'vgui/vgui_scoreboard_small.lua' )
AddCSLuaFile( 'vgui/vgui_vote.lua' )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_halo.lua" )
AddCSLuaFile( "cl_init_fretta.lua" )
AddCSLuaFile( 'cl_hud.lua' )
AddCSLuaFile( 'cl_deathnotice.lua' )
AddCSLuaFile( 'cl_scores.lua' )
AddCSLuaFile( 'cl_notify.lua' )
AddCSLuaFile( 'cl_splashscreen.lua' )
AddCSLuaFile( 'cl_selectscreen.lua' )
AddCSLuaFile( 'cl_gmchanger.lua' )
AddCSLuaFile( 'cl_help.lua' )
AddCSLuaFile( 'player_colours.lua' )

include( "init_fretta.lua" )
include( "shared.lua" )
include( "sv_gmchanger.lua" )
include( "sv_spectator.lua" )
include( "round_controller.lua" )
include( "utility.lua" )

// If there is a mapfile send it to the client (sometimes servers want to change settings for certain maps)
if file.Exists("../gamemodes/prop_hunt/gamemode/maps/"..game.GetMap()..".lua", "LUA") then
	AddCSLuaFile("maps/"..game.GetMap()..".lua")
end

// Server only constants
EXPLOITABLE_DOORS = {
	"func_door",
	"prop_door_rotating", 
	"func_door_rotating"
}
USABLE_PROP_ENTITIES = {
	"prop_physics",
	"prop_physics_multiplayer"
}

REGIONS = {}

function DefineRegion(name,x1,y1,z1,x2,y2,z2)
	print("Defining region '"..name.."'...")
	n = name
	v1 = Vector(x1,y1,z1)
	v2 = Vector(x2,y2,z2)
	REGIONS[n] = {
		point_1 = v1,
		point_2 = v2,
		templates = {}
	}
end

function DefineRegionTemplate(name, data)

	if REGIONS[name] == nil then
		print("Unknown region '" .. name .."', skipping this template.")
		return
	end

	table.insert(REGIONS[name].templates, data)

end

function ClearRegion(region)
	for _, ent in pairs(ents.FindInBox(region.point_1, region.point_2)) do
		mName = ent:GetModel()
		if mName != nil and ( string.match ( mName, "prop" ) or string.match ( mName, "gibs" ) ) then
			ent:Remove()
		end
	end
end

function GenerateRegion(data)
	for _, ent_template in pairs(data) do
		ent = ents.Create("prop_physics")
		ent:SetModel(ent_template[1])
		ent:SetPos(Vector(ent_template[2], ent_template[3], ent_template[4]))
		ent:SetAngles(Angle(ent_template[5], ent_template[6], ent_template[7]))
		ent:Spawn()
	end
end

if file.Exists("map_data/"..game.GetMap()..".lua", "GAME") then
	include("map_data/"..game.GetMap()..".lua")
end

// Send the required resources to the client
--[[
Removed from this vesrion.
for _, taunt in pairs(HUNTER_TAUNTS) do resource.AddFile("sound/"..taunt) end
for _, taunt in pairs(PROP_TAUNTS) do resource.AddFile("sound/"..taunt) end
]]

// Called alot
function GM:CheckPlayerDeathRoundEnd()
	if !GAMEMODE.RoundBased || !GAMEMODE:InRound() then 
		return
	end

	local Teams = GAMEMODE:GetTeamAliveCounts()

	if table.Count(Teams) == 0 then
		GAMEMODE:RoundEndWithResult(1001, "Draw, everyone loses!")
		return
	end

	if table.Count(Teams) == 1 then
		local TeamID = table.GetFirstKey(Teams)
		GAMEMODE:RoundEndWithResult(TeamID, team.GetName(1).." win!")
		return
	end
end


// Called when an entity takes damage
function EntityTakeDamage(ent, dmginfo)
    local att = dmginfo:GetAttacker()
	if GAMEMODE:InRound() && ent && ent:GetClass() != "ph_prop" && !ent:IsPlayer() && att && att:IsPlayer() && att:Team() == TEAM_HUNTERS && att:Alive() then
		att:SetHealth(att:Health() - GetConVar("HUNTER_FIRE_PENALTY"):GetInt())
		if att:Health() <= 0 then
			MsgAll(att:Name() .. " felt guilty for hurting so many innocent props and committed suicide\n")
			att:Kill()
		end
	end
end
hook.Add("EntityTakeDamage", "PH_EntityTakeDamage", EntityTakeDamage)


// Called when player tries to pickup a weapon
function GM:PlayerCanPickupWeapon(pl, ent)
 	if pl:Team() != TEAM_HUNTERS then
		return false
	end
	
	return true
end


// Called when player needs a model
function GM:PlayerSetModel(pl)
	local player_model = "models/Gibs/Antlion_gib_small_3.mdl"
	
	if pl:Team() == TEAM_HUNTERS then
		player_model = "models/player/combine_super_soldier.mdl"
	end
	
	util.PrecacheModel(player_model)
	pl:SetModel(player_model)
end


// Called when a player tries to use an object
function GM:PlayerUse(pl, ent)
	if !pl:Alive() || pl:Team() == TEAM_SPECTATOR then return false end
	
	if pl:Team() == TEAM_PROPS && pl:IsOnGround() && !pl:Crouching() && table.HasValue(USABLE_PROP_ENTITIES, ent:GetClass()) && ent:GetModel() then
		if table.HasValue(BANNED_PROP_MODELS, ent:GetModel()) then
			pl:ChatPrint("That prop has been banned by the server.")
		elseif ent:GetPhysicsObject():IsValid() && pl.ph_prop:GetModel() != ent:GetModel() then
			local ent_health = math.Clamp(ent:GetPhysicsObject():GetVolume() / 250, 1, 200)
			local new_health = math.Clamp((pl.ph_prop.health / pl.ph_prop.max_health) * ent_health, 1, 200)
			local per = pl.ph_prop.health / pl.ph_prop.max_health
			pl.ph_prop.health = new_health
			
			pl.ph_prop.max_health = ent_health
			pl.ph_prop:SetModel(ent:GetModel())
			pl.ph_prop:SetSkin(ent:GetSkin())
			pl.ph_prop:SetSolid(SOLID_BSP)
			pl.ph_prop:SetPos(pl:GetPos() - Vector(0, 0, ent:OBBMins().z))
			pl.ph_prop:SetAngles(pl:GetAngles())
			
			local hullxymax = math.Round(math.Max(ent:OBBMaxs().x, ent:OBBMaxs().y))
			local hullxymin = hullxymax * -1
			local hullz = math.Round(ent:OBBMaxs().z)
			
			pl:SetHull(Vector(hullxymin, hullxymin, 0), Vector(hullxymax, hullxymax, hullz))
			pl:SetHullDuck(Vector(hullxymin, hullxymin, 0), Vector(hullxymax, hullxymax, hullz))
			pl:SetHealth(new_health)
			
			umsg.Start("SetHull", pl)
				umsg.Long(hullxymax)
				umsg.Long(hullz)
				umsg.Short(new_health)
			umsg.End()
		end
	end
	
	// Prevent the door exploit
	if table.HasValue(EXPLOITABLE_DOORS, ent:GetClass()) && pl.last_door_time && pl.last_door_time + 1 > CurTime() then
		return false
	end
	
	pl.last_door_time = CurTime()
	return true
end


// Called when player presses [F3]. Plays a taunt for their team
function GM:ShowSpare1(pl)
	--[[
	if GAMEMODE:InRound() && pl:Alive() && (pl:Team() == TEAM_HUNTERS || pl:Team() == TEAM_PROPS) && pl.last_taunt_time + TAUNT_DELAY <= CurTime() && #PROP_TAUNTS > 1 && #HUNTER_TAUNTS > 1 then
		repeat
			if pl:Team() == TEAM_HUNTERS then
				rand_taunt = table.Random(HUNTER_TAUNTS)
			else
				rand_taunt = table.Random(PROP_TAUNTS)
			end
		until rand_taunt != pl.last_taunt
		
		pl.last_taunt_time = CurTime()
		pl.last_taunt = rand_taunt
		
		pl:EmitSound(rand_taunt, 100)
	end	
	]]
end

function GM:KeyPress( ply, bind )
	if ply:Team() == TEAM_PROPS and bind == IN_DUCK then
		ply.ignore_rotation = !ply.ignore_rotation
		print(ply:GetName() .. " toggled prop rotation lock!")
		if ply.ignore_rotation then
			ply:ChatPrint("Prop Rotation Lock: ENABLED")
		else
			ply:ChatPrint("Prop Rotation Lock: DISABLED")
		end
	end
end


// Called when the gamemode is initialized
function Initialize()
	game.ConsoleCommand("mp_flashlight 0\n")
end
hook.Add("Initialize", "PH_Initialize", Initialize)


// Called when a player leaves
function PlayerDisconnected(pl)
	pl:RemoveProp()
end
hook.Add("PlayerDisconnected", "PH_PlayerDisconnected", PlayerDisconnected)


// Called when the players spawns
function PlayerSpawn(pl)
	pl:Blind(false)
	pl:RemoveProp()
	pl:SetColor( Color(255, 255, 255, 255))
	pl:SetRenderMode( RENDERMODE_TRANSALPHA )
	pl:UnLock()
	pl:ResetHull()
	pl.last_taunt_time = 0
	
	umsg.Start("ResetHull", pl)
	umsg.End()
	
	pl:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
end
hook.Add("PlayerSpawn", "PH_PlayerSpawn", PlayerSpawn)


// Removes all weapons on a map
function RemoveWeaponsAndItems()
	for _, wep in pairs(ents.FindByClass("weapon_*")) do
		wep:Remove()
	end
	
	for _, item in pairs(ents.FindByClass("item_*")) do
		item:Remove()
	end
end
hook.Add("InitPostEntity", "PH_RemoveWeaponsAndItems", RemoveWeaponsAndItems)


// Called when round ends
function RoundEnd()
	for _, pl in pairs(team.GetPlayers(TEAM_HUNTERS)) do
		pl:Blind(false)
		pl:UnLock()
	end
end
hook.Add("RoundEnd", "PH_RoundEnd", RoundEnd)


// This is called when the round time ends (props win)
function GM:RoundTimerEnd()
	if !GAMEMODE:InRound() then
		end
	return
   
	GAMEMODE:RoundEndWithResult(TEAM_PROPS, "Props win!")
end

function PropPlacement( )
	for name, data in pairs(REGIONS) do
		ClearRegion(data)
		GenerateRegion(table.Random(data.templates))
	end
end

// Called before start of round
function GM:OnPreRoundStart(num)

	game.CleanUpMap()

	PropPlacement ( )

	if GetGlobalInt("RoundNumber") != 1 && (SWAP_TEAMS_EVERY_ROUND == 1 || ((team.GetScore(TEAM_PROPS) + team.GetScore(TEAM_HUNTERS)) > 0 || SWAP_TEAMS_POINTS_ZERO==1)) then
		for _, pl in pairs(player.GetAll()) do
			if pl:Team() == TEAM_PROPS || pl:Team() == TEAM_HUNTERS then
				if pl:Team() == TEAM_PROPS then
					pl:SetTeam(TEAM_HUNTERS)
				else
					pl:SetTeam(TEAM_PROPS)
				end
				
				pl:ChatPrint("Teams have been swapped!")
			end
		end
	end
	
	UTIL_StripAllPlayers()
	UTIL_SpawnAllPlayers()
	UTIL_FreezeAllPlayers()
end