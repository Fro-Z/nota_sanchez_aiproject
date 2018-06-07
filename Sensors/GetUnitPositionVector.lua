local sensorInfo = {
	name = "GetUnitPositionVector",
	desc = "Get position of the unit as a vector",
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

local randomInit = false
-- @description return random point in safe zone
return function(unitId)
	local x,y,z = Spring.GetUnitPosition(unitId)
	
	return Vec3(x,y,z)
end