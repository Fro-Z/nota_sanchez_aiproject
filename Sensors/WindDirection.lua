local sensorInfo = {
	name = "WindDirection",
	desc = "Return data of actual wind.",
	author = "PepeAmpere",
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

-- @description return current wind statistics
return function()
	local dirX, dirY, dirZ, strength, normDirX, normDirY, normDirZ = SpringGetWind()
	return {
		dirX = dirX,
		dirY = dirY,
		dirZ = dirZ,
		strength = strength,
		normDirX = normDirX,
		normDirY = normDirY,
		normDirZ = normDirZ,
	}
end