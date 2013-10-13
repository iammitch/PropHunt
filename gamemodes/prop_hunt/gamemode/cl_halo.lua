--[[

	File: cl_halo.lua
	Author: Mitch

	Description: Clientside file that deals with drawing a halo around fellow Hunters.

]]

local PH_HALO_ENABLED = true
local PH_HALO_COLOUR = Color( 0, 100, 255 )
local PH_HALO_IGNORE_Z = true

hook.Add( "PreDrawHalos", "AddHalos", function()

	local localPly = LocalPlayer()

	if PH_HALO_ENABLED == false or localPly:Team() != TEAM_HUNTERS then
		return
	end

	-- Find all players who are on the hunter team, and add them to the list.
	ents = {}
	for _, ply in pairs(player.GetAll()) do
		if ply:Alive() and ply:Team() == TEAM_HUNTERS && ply != localPly then
			table.insert(ents, ply)
		end
	end

	-- Add the halo
	halo.Add( ents, PH_HALO_COLOUR, 5, 5, 2, true, PH_HALO_IGNORE_Z )

end )