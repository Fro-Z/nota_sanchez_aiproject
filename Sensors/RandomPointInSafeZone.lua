local sensorInfo = {
	name = "RandomPointInSafeZone",
	desc = "Get random point in safe zone)",
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
return function()
	if not randomInit then
		randomInit = true
		math.randomseed( os.time() )
		math.random()
	end

	local safeArea = Sensors.core.MissionInfo()["safeArea"]
	local radius = safeArea["radius"]*0.95 --add a bit of tolerance
	
	local angle = math.random() * 2 * math.pi
	local offsetMultiplier = math.random()
	local centerOffset = Vec3(math.sin(angle), 0, math.cos(angle)):GetNormal():Mul(radius*offsetMultiplier);

	
	return safeArea["center"]:Add(centerOffset)
end