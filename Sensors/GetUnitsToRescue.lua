local sensorInfo = {
	name = "GetUnitsToRescue",
	desc = "Get units to rescue (Box of Death or LLT outside the safe zone)",
	author = "Luis",
	date = "2017-05-16",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGetGroundHeight = Spring.GetGroundHeight
local safeZoneCenter = Sensors.core.MissionInfo()["safeArea"]["center"]
local safeZoneRadius = Sensors.core.MissionInfo()["safeArea"]["radius"]

local function GetUnitPositionVector(unitId)
	local x,y,z = SpringGetUnitPosition(unitId)
	return Vec3(x,y,z)
end

local function isInsideTheSafeZone(unitId)
	local unitPos = GetUnitPositionVector(unitId)
	unitPos["y"] = SpringGetGroundHeight(unitPos["x"], unitPos["z"])
	
	return unitPos:Distance(safeZoneCenter) < safeZoneRadius
end

-- @description return current wind statistics
return function(unitId)
	local teamId = Spring.GetUnitTeam(unitId)
	local unfiltered = Spring.GetTeamUnitsByDefs(teamId, {UnitDefNames["armbox"].id, UnitDefNames["armllt"].id} )

	
	-- filter out any units inside the safe zone
	local filtered = {}
	
	for i=1,#unfiltered do 
		if not isInsideTheSafeZone(unfiltered[i]) then
			filtered[#filtered+1]=unfiltered[i]
		end
	end

	return filtered
end