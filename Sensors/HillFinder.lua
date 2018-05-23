local sensorInfo = {
	name = "HillFinder",
	desc = "Get hills on the map (assumes rectangular hills)",
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

local hillTreshold = 180;
local gridStep = 40;


function isHill(x, y)
	return Spring.GetGroundHeight(x,y) > hillTreshold

end

-- Get table of hill centers, assuming rectangular hills
function getHillCenters(hills, hillMap)
	local hillCenters = {}
	local hillId = 1

	for key, value in pairs(hills) do
		local posX = value[1]
		local posY = value[2]
		
		local sizeX = 0;
		local sizeY = 0;
		while hillMap[posX+sizeX][posY] do
			sizeX = sizeX + gridStep
		end
		
		while hillMap[posX][posY+sizeY] do
			sizeY = sizeY + gridStep
		end
		
		hillCenters[hillId] = {x = posX + sizeX/2,z = posY + sizeY/2, sizeX = sizeX, sizeZ=sizeY}
		hillId = hillId + 1
	end
	
	return hillCenters;
end



-- @description return current wind statistics
return function()
	local hillMap = {}
	local nextHillId = 1
	local hills = {}
		
	for posX=0, Game.mapSizeX, gridStep do
		hillMap[posX] = {}
		for posY=0, Game.mapSizeZ, gridStep do
			if isHill(posX, posY) then
				-- Get hillID from adjacent tiles or create a new one
				if posX-gridStep>0 and isHill(posX-gridStep,posY) then
					hillMap[posX][posY] = hillMap[posX-gridStep][posY]
				elseif posY-gridStep>0 and isHill(posX, posY-gridStep) then
					hillMap[posX][posY] = hillMap[posX][posY - gridStep]
				elseif posY-gridStep>0 and posX-gridStep>0 and isHill(posX-gridStep, posY-gridStep) then
					hillMap[posX][posY] = hillMap[posX-gridStep][posY - gridStep]
				else
					hillMap[posY][posY] = nextHillId;
					hills[nextHillId] = {posX, posY}
					nextHillId = nextHillId + 1			
				end
			end
		
			hillMap[posX][posY] = isHill(posX, posY)
		end
	
	end
	
	if(Script.LuaUI("HillFinderDebug_update")) then
		Script.LuaUI.HillFinderDebug_update(hillMap, gridStep, hills)
	end
	
	return getHillCenters(hills, hillMap)
end