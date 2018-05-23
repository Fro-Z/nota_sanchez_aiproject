local sensorInfo = {
	name = "CircleGroup",
	desc = "Get positions for a circle formation around a unit",
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

local distFromCenter = 50;

return function()
	local positions = {}
	local step = (2*math.pi) / #units
	
	for i=1, #units do 	
		positions[#positions+1] = Vec3(math.sin(i*step), 0, math.cos(i*step)):GetNormal():Mul(distFromCenter)
	end
	
	return positions
end