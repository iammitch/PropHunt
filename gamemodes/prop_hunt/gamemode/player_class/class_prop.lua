// Create new class
local CLASS = {}


// Some settings for the class
CLASS.DisplayName			= "Prop"
CLASS.WalkSpeed 			= 250
CLASS.CrouchedWalkSpeed 	= 0.2
CLASS.RunSpeed				= 250
CLASS.DuckSpeed				= 0.2
CLASS.DrawTeamRing			= false


-- Called by spawn and sets loadout
function CLASS:Loadout(pl)
	-- Props don't get anything
end


-- Called when player spawns with this class
function CLASS:OnSpawn(pl)
	pl:SetColor( Color(255, 255, 255, 0))
	
	pl.ph_prop = ents.Create("ph_prop")
	pl.ph_prop:SetPos(pl:GetPos())
	pl.ph_prop:SetAngles(pl:GetAngles())
	pl.ph_prop:Spawn()
	pl.ph_prop:SetSolid(SOLID_BBOX)
	pl.ph_prop:SetParent(pl)
	pl.ph_prop:SetOwner(pl)
	
	pl.ph_prop.max_health = 100

	pl.ignore_rotation = false

end


// Called when a player dies with this class
function CLASS:OnDeath(pl, attacker, dmginfo)
	pl:RemoveProp()
end

function CLASS:Move(pl, mv)
	if pl.ph_prop == nil then
		return
	end
	if !pl.ignore_rotation then
		local ang = mv:GetAngles()
		local newAng = Angle(0, ang.y, 0)
		pl.ph_prop:SetAngles(newAng)
	end
end

// Register
player_class.Register("Prop", CLASS)