local sensorInfo = {
	name = "GetUnscoutedPositions",
	desc = "Get positions of unscouted enemies.",
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
local SpringGetWind = Spring.GetWind
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGetUnitDefID = Spring.GetUnitDefID

local function isUnscouted(enemyId)
	-- unscouted enemies have unknown def
	return SpringGetUnitDefID(enemyId)==nil
end


-- @description return current wind statistics
return function()
	local enemies = Sensors.core.EnemyUnits()
	local positions = {}
	
	for enemyIdx=1, #enemies do
	local enemyId = enemies[enemyIdx]
		if isUnscouted(enemyId) then
		local x,y,z = SpringGetUnitPosition(enemyId)
			positions[#positions + 1] = Vec3(x,y,z)
		end
	end
	
	return positions
end