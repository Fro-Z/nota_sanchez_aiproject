local sensorInfo = {
	name = "GetUnitContinent",
	desc = "EXPERIMENTAL! Get continent of the unit",
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
local SpringGetGroundHeight = Spring.GetGroundHeight

local hillTreshold = 10;
local gridStep = 50;
local mapSizeX = Game.mapSizeX;
local mapSizeZ = Game.mapSizeZ;


function isHill(x, y)
	return SpringGetGroundHeight(x,y) > hillTreshold
end

function isMarked(hillMap, x, y)
	return hillMap[x] ~= nil and hillMap[x][y]~= nil
end

-- Mark current position as a hill with hillId if it is a hill
function markIfHill(hillMap, posX, posY, hillId, nextCenters)
	if hillMap[posX] ~= nil and hillMap[posX][posY]==0 then	
		hillMap[posX][posY] = hillId
		nextCenters[#nextCenters+1] = {x=posX, y=posY}
	end
end

-- TODO remove
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Mark all neighboring hills with the same id
function markNeighbours(hillMap, posX, posY)
	local localId = hillMap[posX][posY]
	local nextCenters = {{x=posX, y=posY}}
	local currentIdx = 1
	
	-- use iteration instead of a recursion to avoid stack overflow
	while nextCenters[currentIdx]~=nil do
		posX = nextCenters[currentIdx]["x"]
		posY = nextCenters[currentIdx]["y"]
	
		-- Top row
		markIfHill(hillMap, posX-gridStep, posY+gridStep, localId, nextCenters)
		markIfHill(hillMap, posX, posY+gridStep, localId, nextCenters)
		markIfHill(hillMap, posX+gridStep, posY+gridStep, localId, nextCenters)
				
		-- Center row
		markIfHill(hillMap, posX-gridStep, posY, localId, nextCenters)
		markIfHill(hillMap, posX+gridStep, posY, localId, nextCenters)

		-- Bottom row
		markIfHill(hillMap, posX-gridStep, posY-gridStep, localId, nextCenters)
		markIfHill(hillMap, posX, posY-gridStep, localId, nextCenters)
		markIfHill(hillMap, posX+gridStep, posY-gridStep, localId, nextCenters)

		currentIdx=currentIdx+1;

	end
end

-- Generate hill map to be used for unit reachability
function generateHillMap()
	local hillMap = {}
	local nextHillId = 1;
		
	for posX=0, mapSizeX, gridStep do
		for posY=0, mapSizeZ, gridStep do
			if isHill(posX, posY) then
				if hillMap[posX] == nil then
					hillMap[posX]={}
				end			
				hillMap[posX][posY] = 0;						
			end
		end
	end
	
	
	local nextHillId = 1;
	for posX=0, mapSizeX, gridStep do
		for posY=0, mapSizeZ, gridStep do
			if hillMap[posX][posY]~=nil and hillMap[posX][posY] == 0 then
				hillMap[posX][posY] = nextHillId
				nextHillId = nextHillId + 1
				markNeighbours(hillMap, posX, posY)
			end
		end
	end
	
	return hillMap;
end


-- Round to nearest multiple, assuming positive integers
function roundToMultiple(value, multiple)
	local remainder = value % multiple;
	if(remainder>multiple/2) then
		return value + (multiple-remainder) -- round ups
	else
		return value - remainder
	end
end

-- @description return current wind statistics
return function(unitId)	
	if global.hillMap == nil then
		global.hillMap = generateHillMap()
	end
	
	local x,y,z = Spring.GetUnitPosition(unitId);
	x = roundToMultiple(x, gridStep);
	z = roundToMultiple(z, gridStep);
	
	if isMarked(global.hillMap, x, z) then
		return global.hillMap[x][z]
	else
		return nil
	end
end