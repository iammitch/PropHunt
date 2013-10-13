--[[
	shared.lua - Shared Component
	-----------------------------------------------------
	This is the shared component of your gamemode, a lot of the game variables
	can be changed from here.
]]

include( "config.lua" )
include( "shared_player.lua" )

include( "player_class.lua" )
include( "player_extension.lua" )
include( "class_default.lua" )
include( "player_colours.lua" )

fretta_voting = CreateConVar( "fretta_voting", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Allow/Dissallow voting" )

GM.Name		= "Prop Hunt"
GM.Author	= "Kow@lski (Original by AMT) (Modified by Mitch)"
GM.Email	= "mitchell@bitswit.ch"

// Help info
GM.Help = [[Prop Hunt is a twist on the classic backyard game Hide and Seek.

As a Prop you have ]]..GetConVar("HUNTER_BLINDLOCK_TIME"):GetInt()..[[ seconds to replicate an existing prop on the map and then find a good hiding spot. Press [E] to replicate the prop you are looking at. Your health is scaled based on the size of the prop you replicate.

As a Hunter you will be blindfolded for the first ]]..GetConVar("HUNTER_BLINDLOCK_TIME"):GetInt()..[[ seconds of the round while the Props hide. When your blindfold is taken off, you will need to find props controlled by players and kill them. Damaging non-player props will lower your health significantly. However, killing a Prop will increase your health by ]]..GetConVar("HUNTER_KILL_BONUS"):GetInt()..[[ points.

Both teams can press [F3] to play a taunt sound.]]

GM.AllowAutoTeam = true				-- Allow auto-assign?
GM.AllowSpectating = true			-- Allow people to spectate during the game?
GM.SecondsBetweenTeamSwitches = 10	-- The minimum time between each team change?
GM.VotingDelay = 5					-- Delay between end of game, and vote. if you want to display any extra screens before the vote pops up
GM.ShowTeamName = true				-- Show the team name on the HUD

GM.NoPlayerSuicide = false			-- Set to true if players should not be allowed to commit suicide.
GM.NoPlayerDamage = false			-- Set to true if players should not be able to damage each other.
GM.NoPlayerSelfDamage = false		-- Allow players to hurt themselves?
GM.NoPlayerTeamDamage = true		-- Allow team-members to hurt each other?
GM.NoPlayerPlayerDamage = false 	-- Allow players to hurt each other?
GM.NoNonPlayerPlayerDamage = false 	-- Allow damage from non players (physics, fire etc)
GM.NoPlayerFootsteps = false		-- When true, all players have silent footsteps
GM.PlayerCanNoClip = false			-- When true, players can use noclip without sv_cheats
GM.TakeFragOnSuicide = true			-- -1 frag on suicide

GM.MaximumDeathLength = 0			-- Player will repspawn if death length > this (can be 0 to disable)
GM.MinimumDeathLength = 2			-- Player has to be dead for at least this long
GM.AutomaticTeamBalance = false     -- Teams will be periodically balanced 
GM.ForceJoinBalancedTeams = true	-- Players won't be allowed to join a team if it has more players than another team
GM.RealisticFallDamage = false		-- Set to true if you want realistic fall damage instead of the fix 10 damage.
GM.AddFragsToTeamScore = false		-- Adds player's individual kills to team score (must be team based)

GM.RoundPreStartTime = 5			-- Preperation time before a round starts
GM.RoundPostLength = 8				-- Seconds to show the 'x team won!' screen at the end of a round
GM.RoundEndsWhenOneTeamAlive = true	-- CS Style rules

GM.DeathLingerTime = 4				-- The time between you dying and it going into spectator mode, 0 disables

GM.SelectColor = false				-- Can players modify the colour of their name? (ie.. no teams)

GM.PlayerRingSize = 48              -- How big are the colored rings under the player's feet (if they are enabled) ?
GM.HudSkin = "SimpleSkin"			-- The Derma skin to use for the HUD components
GM.DeathNoticeDefaultColor = Color( 255, 128, 0 ); -- Default colour for entity kills
GM.DeathNoticeTextColor = color_white; -- colour for text ie. "died", "killed"

GM.ValidSpectatorModes = { OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING } // The spectator modes that are allowed
GM.ValidSpectatorEntities = { "player" }	-- Entities we can spectate, players being the obvious default choice.

GM.AddFragsToTeamScore		= true
GM.CanOnlySpectateOwnTeam 	= true
GM.Data 					= {}
GM.EnableFreezeCam			= true
GM.GameLength				= GAME_TIME
GM.NoAutomaticSpawning		= true
GM.NoNonPlayerPlayerDamage	= true
GM.NoPlayerPlayerDamage 	= true
GM.RoundBased				= true
GM.RoundLimit				= ROUNDS_PER_MAP
GM.RoundLength 				= ROUND_TIME
GM.RoundPreStartTime		= 0
GM.SelectModel				= false
GM.SuicideString			= "couldn't take the pressure and committed suicide."
GM.TeamBased 				= true

DeriveGamemode("base")

function GM:InGamemodeVote()
	return GetGlobalBool( "InGamemodeVote", false )
end

--[[
   Name: gamemode:TeamHasEnoughPlayers( Number teamid )
   Desc: Return true if the team has too many players.
		 Useful for when forced auto-assign is on.
]]
function GM:TeamHasEnoughPlayers( teamid )

	local PlayerCount = team.NumPlayers( teamid )

	-- Don't let them join a team if it has more players than another team
	if ( GAMEMODE.ForceJoinBalancedTeams ) then
	
		for id, tm in pairs( team.GetAllTeams() ) do
			if ( id > 0 && id < 1000 && team.NumPlayers( id ) < PlayerCount && team.Joinable(id) ) then return true end
		end
		
	end

	return false
	
end

--[[
   Name: gamemode:PlayerCanJoinTeam( Player ply, Number teamid )
   Desc: Are we allowed to join a team? Return true if so.
]]
function GM:PlayerCanJoinTeam( ply, teamid )

	if ( SERVER && !self.BaseClass:PlayerCanJoinTeam( ply, teamid ) ) then 
		return false 
	end

	if ( GAMEMODE:TeamHasEnoughPlayers( teamid ) ) then
		ply:ChatPrint( "That team is full!" )
		ply:SendLua("GAMEMODE:ShowTeam()")
		return false
	end
	
	return true
	
end

--[[
   Name: gamemode:Move( Player ply, CMoveData mv )
   Desc: Setup Move, this also calls the player's class move
		 function.
]]
function GM:Move( ply, mv )

	if ( ply:CallClassFunction( "Move", mv ) ) then return true end

end

--[[
   Name: gamemode:KeyPress( Player ply, Number key )
   Desc: Player presses a key, this also calls the player's class
		 OnKeyPress function.
]]
function GM:KeyPress( ply, key )

	if ( ply:CallClassFunction( "OnKeyPress", key ) ) then return true end

end

--[[
   Name: gamemode:KeyRelease( Player ply, Number key )
   Desc: Player releases a key, this also calls the player's class
		 OnKeyRelease function.
]]
function GM:KeyRelease( ply, key )

	if ( ply:CallClassFunction( "OnKeyRelease", key ) ) then return true end

end

--[[
   Name: gamemode:PlayerFootstep( Player ply, Vector pos, Number foot, String sound, Float volume, CReceipientFilter rf )
   Desc: Player's feet makes a sound, this also calls the player's class Footstep function.
		 If you want to disable all footsteps set GM.NoPlayerFootsteps to true.
		 If you want to disable footsteps on a class, set Class.DisableFootsteps to true.
]]
function GM:PlayerFootstep( ply, pos, foot, sound, volume, rf ) 

	if( GAMEMODE.NoPlayerFootsteps || !ply:Alive() || ply:Team() == TEAM_SPECTATOR || ply:IsObserver() ) then
		return true;
	end
	
	local Class = ply:GetPlayerClass();
	if( !Class ) then return end
	
	if( Class.DisableFootsteps ) then // rather than using a hook, we can just do this to override the function instead.
		return true;
	end
	
	if( Class.Footstep ) then
		return Class:Footstep( ply, pos, foot, sound, volume, rf ); // Call footstep function in class, you can use this to make custom footstep sounds
	end
	
end

--[[
   Name: gamemode:CalcView( Player ply, Vector origin, Angles angles, Number fov )
   Desc: Calculates the players view. Also calls the players class
		 CalcView function, as well as GetViewModelPosition and CalcView
		 on the current weapon. Returns a table.
]]
function GM:CalcView( ply, origin, angles, fov )

	local view = ply:CallClassFunction( "CalcView", origin, angles, fov ) or { ["origin"] = origin, ["angles"] = angles, ["fov"] = fov };
	
	origin = view.origin or origin
	angles = view.angles or angles
	fov = view.fov or fov
		
	local wep = ply:GetActiveWeapon()
	if ( IsValid( wep ) ) then
	
		local func = wep.GetViewModelPosition
		if ( func ) then view.vm_origin,  view.vm_angles = func( wep, origin*1, angles*1 ) end
		
		local func = wep.CalcView
		if ( func ) then view.origin, view.angles, view.fov = func( wep, ply, origin*1, angles*1, fov ) end
	
	end

	return view
	
end

--[[
   Name: gamemode:GetTimeLimit()
   Desc: Returns the time limit of a game in seconds, so you could
		 make it use a cvar instead. Return -1 for unlimited.
		 Unlimited length games can be changed using vote for
		 change.
]]
function GM:GetTimeLimit()

	if( GAMEMODE.GameLength > 0 ) then
		return GAMEMODE.GameLength * 60;
	end
	
	return -1;
	
end

--[[
   Name: gamemode:GetGameTimeLeft()
   Desc: Get the remaining time in seconds.
]]
function GM:GetGameTimeLeft()

	local EndTime = GAMEMODE:GetTimeLimit();
	if ( EndTime == -1 ) then return -1 end
	
	return EndTime - CurTime()

end

--[[
   Name: gamemode:PlayerNoClip( player, bool )
   Desc: Player pressed the noclip key, return true if
		  the player is allowed to noclip, false to block
]]
function GM:PlayerNoClip( pl, on )
	
	// Allow noclip if we're in single player or have cheats enabled
	if ( GAMEMODE.PlayerCanNoClip || game.SinglePlayer() || GetConVar( "sv_cheats" ):GetBool() ) then return true end
	
	// Don't if it's not.
	return false
	
end

-- This function includes /yourgamemode/player_class/*.lua
-- And AddCSLuaFile's each of those files.
-- You need to call it in your derived shared.lua IF you have files in that folder
-- and want to include them!
function IncludePlayerClasses()

	local Folder = string.Replace( GM.Folder, "gamemodes/", "" );

	for c,d in pairs(file.Find(Folder.."/gamemode/player_class/*.lua", "LUA")) do
		include( Folder.."/gamemode/player_class/"..d )
		AddCSLuaFile( Folder.."/gamemode/player_class/"..d )
	end

end

IncludePlayerClasses()		

function util.ToMinutesSeconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

    return string.format("%02d:%02d", minutes, math.floor(seconds))
end

function util.ToMinutesSecondsMilliseconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

	local milliseconds = math.floor(seconds % 1 * 100)

    return string.format("%02d:%02d.%02d", minutes, math.floor(seconds), milliseconds)
end

function timer.SimpleEx(delay, action, ...)
	if ... == nil then
		timer.Simple(delay, action)
	else
		local a, b, c, d, e, f, g, h, i, j, k = ...
		timer.Simple(delay, function() action(a, b, c, d, e, f, g, h, i, j, k) end)
	end
end

function timer.CreateEx(timername, delay, repeats, action, ...)
	if ... == nil then
		timer.Create(timername, delay, repeats, action)
	else
		local a, b, c, d, e, f, g, h, i, j, k = ...
		timer.Create(timername, delay, repeats, function() action(a, b, c, d, e, f, g, h, i, j, k) end)
	end
end

function GM:CreateTeams()
	if !GAMEMODE.TeamBased then
		return
	end
	
	TEAM_HUNTERS = 1
	team.SetUp(TEAM_HUNTERS, "Hunters", Color(150, 205, 255, 255))
	team.SetSpawnPoint(TEAM_HUNTERS, {"info_player_counterterrorist", "info_player_combine", "info_player_deathmatch", "info_player_axis"})
	team.SetClass(TEAM_HUNTERS, {"Hunter"})

	TEAM_PROPS = 2
	team.SetUp(TEAM_PROPS, "Props", Color(255, 60, 60, 255))
	team.SetSpawnPoint(TEAM_PROPS, {"info_player_terrorist", "info_player_rebel", "info_player_deathmatch", "info_player_allies"})
	team.SetClass(TEAM_PROPS, {"Prop"})
end