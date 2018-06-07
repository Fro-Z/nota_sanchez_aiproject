local sensorInfo = {
	name = "GetRandomMapPositions",
	desc = "Get random positions on the map",
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


local wasInitialized = false
-- @description return current wind statistics
return function(count)
	if wasInitialized==false then
		wasInitialized = true
		math.randomseed(os.time())
		math.random()
	end

	local positions = {}
	
	for i=1, count do
		local x = math.random(Game.mapSizeX)
		local z = math.random(Game.mapSizeZ)
		local y = Spring.GetGroundHeight(x,z)
		positions[#positions+1] = Vec3(x,y,z)
	end
	
	return positions
end