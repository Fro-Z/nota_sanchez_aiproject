local sensorInfo = {
	name = "GetSafePath",
	desc = "Get safe path between two points if it exists, calculating between multiple calls",
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

local gridStep = 50;
local mapSizeX = Game.mapSizeX;
local mapSizeZ = Game.mapSizeZ;
local lastEnemyUnit = nil; --last enemy unit that caused a point to be unsafe (speeds up calculation of adjacent tiles)
local dangerRangeForUnknownUnit = 500
local maxNodesPerStep = 500;
local mayWaypointsGeneratedPerStep = 3000; --setting this too low makes the generation take too long, but reduces freezes

-- speedups
local SpringGetWind = Spring.GetWind
local SpringGetUnitDefID = Spring.GetUnitDefID
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGetGroundHeight = Spring.GetGroundHeight

local waypointMap
local savedStates = {}

local wpNextGenPosX = 0;
local wpGenFinished = false

local function getDangerRange(unitId)
-- anti air kbot
-- anti aircraft machine gun
-- kobra anti air flak gun
-- AK infantry kbot
-- pulverizer anti-air missile tower

	local defId = Spring.GetUnitDefID(unitId)
	if(defId==nil) then
		global.defIdNilCount = global.defIdNilCount + 1
		return dangerRangeForUnknownUnit;
	end
	
	local def = UnitDefs[defId]
	return def.maxWeaponRange * 1.1
end

-- Is waypoint safe for travel (out of range of enemy fire, or sufficiently low in altitude)
local function isPointSafe(posX, posZ)
	local groundHeight = SpringGetGroundHeight(posX, posZ)
	-- We can fly safely below the mountains
	if groundHeight < 100 then
		return true
	end


-- try to fail on the last unit that failed
	if  lastEnemyUnit~=nil then
		local x,y,z = SpringGetUnitPosition(lastEnemyUnit)
		if Vec3(posX, y, posZ):Distance(Vec3(x,y,z)) < getDangerRange(lastEnemyUnit) then
				return false
		end
	end
	
	global.defIdNilCount = 0

	local enemies = Sensors.core.EnemyUnits()
	
	for enemyIdx=1,#enemies do
		local enemyId = enemies[enemyIdx]
		local x,y,z = SpringGetUnitPosition(enemyId)
		
		local distToEnemy = Vec3(posX, y, posZ):Distance(Vec3(x,y,z))
		if distToEnemy < getDangerRange(enemyId) then
			lastEnemyUnit = enemyId
			return false
		end
		
	end
	
	return true
end

local function generateWaypoints()
	local wpRemainingThisCycle = mayWaypointsGeneratedPerStep;
	
	for posX=wpNextGenPosX, mapSizeX, gridStep do
		if waypointMap[posX]==nil then waypointMap[posX] = {} end
		
		for posY=0, mapSizeZ, gridStep do
			wpRemainingThisCycle = wpRemainingThisCycle - 1
			
			if isPointSafe(posX, posY) then			
				waypointMap[posX][posY] = true
			end			
		end
		
		-- End now and continue next time, but do at least the whole column
		if wpRemainingThisCycle<=0 then
				wpNextGenPosX = posX + gridStep			
				local ptsNow = (mapSizeZ/gridStep)*(posX/gridStep)
				local ptsTotal = (mapSizeX/gridStep)*(mapSizeZ/gridStep)
				Spring.Echo("Generating safe waypoints "..(ptsNow/ptsTotal)*100 .."%")
				return false
		end
	end
	
	wpGenFinished = true
	Spring.Echo("Safe waypoints generated")
	return true
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

function isWaypointSafe(posX, posY)
	return waypointMap[posX] ~= nil and waypointMap[posX][posY]==true
end


function isNodeOpen(x, y, openNodes)
	return openNodes[x]~=nil and openNodes[x][y]~=nil
end

-- Open node if it is safe
local function addIfSafe(x, y, nodesToExpand, openNodes, predecessors, from)
	if isWaypointSafe(x, y) and not isNodeOpen(x, y, openNodes) then
		nodesToExpand[#nodesToExpand+1] = {x=x, y=y}
		
		if predecessors[x]==nil then predecessors[x]={} end
		predecessors[x][y] = from
		if openNodes[x]==nil then openNodes[x]={} end
		openNodes[x][y]=true
	end
end

-- Expand waypoint node
local function expand(currentWp, nodesToExpand, openNodes, predecessors)
	local x = currentWp["x"]
	local y = currentWp["y"]
	
	-- Top
	addIfSafe(x-gridStep, y+gridStep, nodesToExpand, openNodes, predecessors, currentWp)
	addIfSafe(x, y+gridStep, nodesToExpand, openNodes, predecessors, currentWp)
	addIfSafe(x+gridStep, y+gridStep, nodesToExpand, openNodes, predecessors, currentWp)
	
	-- Center
	addIfSafe(x-gridStep, y, nodesToExpand, openNodes, predecessors, currentWp)
	addIfSafe(x+gridStep, y, nodesToExpand, openNodes, predecessors, currentWp)
	
	-- Bottom
	addIfSafe(x-gridStep, y-gridStep, nodesToExpand, openNodes, predecessors, currentWp)
	addIfSafe(x, y-gridStep, nodesToExpand, openNodes, predecessors, currentWp)
	addIfSafe(x+gridStep, y-gridStep, nodesToExpand, openNodes, predecessors, currentWp)

end

-- Reconstruct path form a predecessor table
local function reconstructPath(waypoint, predecessors, pathState, to)
	local path = {}

	-- Load last saved state if it exists
	if pathState["path"] ~= nil then
		path = pathState["path"]
		waypoint = pathState["waypoint"]
	end

	local nodeLimitRemaining = maxNodesPerStep;
	while waypoint ~= nil and nodeLimitRemaining>0 do
		nodeLimitRemaining = nodeLimitRemaining-1
		
		local x = waypoint["x"]
		local y = waypoint["y"]
		path[#path+1]=waypoint
		if predecessors[x]~=nil then 
			waypoint = predecessors[x][y]
		else
			waypoint = nil
		end	
	end
	
	-- Ended because node limit ran out, save our work and continue next time
	if nodeLimitRemaining<=0 and waypoint~=nil then
		pathState["waypoint"] = waypoint
		pathState["path"] = path
		return {completed = false, result = nil}
	end
	
	-- Reverse the path so that it goes in the correct order
	local reversedPath = {}
	for i=1,#path do
		local x = path[i]["x"]
		local y = path[i]["y"]
		reversedPath[#path-i+1] = Vec3(x, 0, y)
	end
	
	-- Move to the target point that does not lie on the grid
	reversedPath[#reversedPath+1]=to
	
	return {completed=true, result = reversedPath}
end

-- Save current BFS search state so that it can be loaded next time
local function saveState(fromX, fromY, toX, toY, currentWp, predecessors, openNodes, nodesToExpand, currentIdx, pathState)
	if savedStates[fromX]==nil then savedStates[fromX] = {} end
	if savedStates[fromX][fromY]==nil then savedStates[fromX][fromY] = {} end
	if savedStates[fromX][fromY][toX]==nil then savedStates[fromX][fromY][toX] = {} end
	
	savedStates[fromX][fromY][toX][toY] = {currentWp = currentWp, predecessors = predecessors, openNodes = openNodes, nodesToExpand=nodesToExpand, currentIdx=currentIdx, pathState=pathState}
end

local function getSavedState(fromX, fromY, toX, toY)
	return savedStates[fromX][fromY][toX][toY]
end

-- Is there a saved state for this search
local function hasSavedState(fromX, fromY, toX, toY)
	return savedStates[fromX]~=nil and savedStates[fromX][fromY]~=nil and savedStates[fromX][fromY][toX]~=nil and savedStates[fromX][fromY][toX][toY]~=nil
end

-- Find a safe path between two Vec3 positions
function findPath(from, to)
	local fromX = roundToMultiple(from["x"], gridStep)
	local fromY = roundToMultiple(from["z"], gridStep)
	
	local toX = roundToMultiple(to["x"], gridStep)
	local toY = roundToMultiple(to["z"], gridStep)
	
	if (not isWaypointSafe(fromX, fromY)) then
		Spring.Echo("Start fail")
		return {completed=true, result = nil}
	end
	
	if  (not isWaypointSafe(toX, toY)) then
		Spring.Echo("End fail")
		return {completed=true, result = nil}
	end
	
	local currentWp = {x=fromX, y=fromY}
	local predecessors = {}
	local openNodes = {}
	local nodesToExpand = {}	
	local currentIdx = 1
	local pathState = {}
	
	addIfSafe(fromX, fromY, nodesToExpand, openNodes, predecessors, nil)
	
	-- Load saved state
	if hasSavedState(fromX, fromY, toX, toY) then
		local state = getSavedState(fromX, fromY, toX, toY)
		currentWp = state["currentWp"]
		predecessors = state["predecessors"]
		openNodes = state["openNodes"]
		nodesToExpand = state["nodesToExpand"]
		currentIdx = state["currentIdx"]
		pathState = state["pathState"]
	else
		saveState(fromX, fromY, toX, toY, currentWp, predecessors, openNodes, nodesToExpand, currentIdx, pathState)
	end
	
	
	-- Found the target wp
		if 	currentWp["x"] == toX and currentWp["y"]==toY then
			return reconstructPath(currentWp, predecessors, pathState, to)
		end
	
	local nodeLimitRemaining = maxNodesPerStep;
	-- BFS over safe nodes
	while currentIdx<= #nodesToExpand and nodeLimitRemaining>0 do
		nodeLimitRemaining = nodeLimitRemaining-1;
		
		currentWp = nodesToExpand[currentIdx]
		currentIdx = currentIdx + 1
	
		-- Found the target wp
		if 	currentWp["x"] == toX and currentWp["y"]==toY then
			saveState(fromX, fromY, toX, toY, currentWp, predecessors, openNodes, nodesToExpand, currentIdx, pathState)
			return reconstructPath(currentWp, predecessors, pathState, to)
		end
		expand(currentWp, nodesToExpand, openNodes, predecessors)		
	end

	-- Ended because node limit ran out, save our work and continue next time
	if nodeLimitRemaining<=0 and currentIdx<=#nodesToExpand then
		saveState(fromX, fromY, toX, toY, currentWp, predecessors, openNodes, nodesToExpand, currentIdx, pathState)
		return {completed=false, result=nil}
	end
	
	Spring.Echo("Searched " .. #nodesToExpand .. "nodes")
	
	return {completed=true, result=nil};
end

function regenerateWaypoints()
		waypointMap = {}
		savedStates = {}
		wpNextGenPosX = 0;
		wpGenFinished = false
end

-- @description return safe path between points or null if there is none
return function(from, to)
	if waypointMap==nil then
		regenerateWaypoints()
	end
	
	if not wpGenFinished then
		generateWaypoints()
		return {completed=false, result=nil}
	end
	
	return findPath(from, to)
end

