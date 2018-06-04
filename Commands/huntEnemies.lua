function getInfo()
	return {
		onNoUnits = FAILURE, -- instant success
		tooltip = "Hunt reachable enemies",
		parameterDefs = {}
	}
end

-- constants
local THRESHOLD_STEP = 25
local THRESHOLD_DEFAULT = 10

local hillTreshold = 1;
local gridStep = 40;
local mapSizeX = Game.mapSizeX;
local mapSizeZ = Game.mapSizeZ;

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit
local SpringGetGroundHeight = Spring.GetGroundHeight
local SpringIsUnitInLos = Spring.IsUnitInLos
local SpringGetUnitDefID = Spring.GetUnitDefID


local function ClearState(self)
	self.threshold = {}
	self.lastUnitPosition = {}
	self.unitTargets = {}
	self.unitTabooLists = {}
	self.hillMap = {}
end

local function tableContains(tbl, value)
	for k,v in ipairs(tbl) do
		if v==value then
			return true
		end
	end
	
	return false
end

local function tableAddNext(tbl, value)
	tbl[#tbl]=value
end

local function areOnTheSameHill(unit1, unit2)
	return Sensors.nota_sanchez_aiproject.GetUnitContinent(unit1) == Sensors.nota_sanchez_aiproject.GetUnitContinent(unit2)
end

local function isOnLand(unitId)
	local x,y,z = SpringGetUnitPosition(unitId)
	return SpringGetGroundHeight(x,z) > 1
end

local function getAvailableTargets(unitId, tabooList, hillMap)
	local enemyUnitIds = Sensors.core.EnemyUnits()
	local availableTargets = {}
	
	-- Add all reachable enemy units as targets
	for enemyIdx=1, #enemyUnitIds do
		local enemyId = enemyUnitIds[enemyIdx]
	
		-- Target is avaiblable if not taboo and is on the same hill
		if (not (tabooList[unitId] ~= nil and tableContains(tabooList, enemyId)))
		and areOnTheSameHill(unitId, enemyId) and isOnLand(enemyId) then
			availableTargets[#availableTargets+1] = enemyId
		end
		
	end
	return availableTargets
end



-- Get nearest enemy to point (by air distance)
local function getNearest(enemyIds, point)
	local nearestDistance = nil;
	local nearestEnemy = nil;
	
	for enemyIdx=1,#enemyIds do
		local enemyId = enemyIds[enemyIdx]
		local enemyX, enemyY, enemyZ = Spring.GetUnitPosition(enemyId)
		local distance = Vec3(enemyX,enemyY,enemyZ):Distance(point)
		
		if nearestDistance==nil or distance < nearestDistance then
			nearestDistance = distance
			nearestEnemy = enemyId
		end
	end

	return nearestEnemy
end

local function isUnscouted(enemyId)
	-- unscouted enemies have unknown def
	return SpringGetUnitDefID(enemyId)==nil
end

-- Has unit a valid target to seek (does not mean it is reachable)
function hasValidTarget(unitId, unitTargetsUnit)
	local enemyUnits = Sensors.core.EnemyUnits()
	local targetId = unitTargetsUnit[unitId]
	return targetId ~= nil and tableContains(enemyUnits, targetId)
end



function Run(self, units, parameter)
	-- init
	if self.threshold == nil then
		self.threshold = {}
		self.unitTargets = {} --targets as a Vec3
		self.unitTargetsUnit = {} --targets as unitId
		self.lastUnitPosition = {}
		self.unitTabooList = {}
	end

	local anyUnitCanReachEnemy = false
	-- assign target to each unit
	for unitIdx=1, #units do
		local unitId = units[unitIdx]
		
		-- update only units without a valid target
		if not hasValidTarget(unitId, self.unitTargetsUnit) then
			local unitX,unitY,unitZ = Spring.GetUnitPosition(unitId)
			local unitPos = Vec3(unitX,unitY,unitZ)
			
			-- init taboo list for unit
			if self.unitTabooList[unitId] == nil then
				self.unitTabooList[unitId] = {}
			end
			
			-- Find a target for unit
			local targets = getAvailableTargets(unitId, self.unitTabooList[unitId], self.hillMap)
			if #targets>0 then
				local targetEnemyId = getNearest(targets, unitPos)
				
				local enemyX,enemyY,enemyZ = Spring.GetUnitPosition(targetEnemyId)
				self.unitTargets[unitId] = Vec3(enemyX,enemyY,enemyZ)
				self.unitTargetsUnit[unitId] = targetEnemyId
				anyUnitCanReachEnemy = true
				self.threshold[unitId] = TRESHOLD_DEFAULT
				self.lastUnitPosition[unitId] = Vec3(0,0,0)
			end
				
		else
			anyUnitCanReachEnemy = true
		
		end
	end
	
		
	-- threshold of success
	for unitIdx=1, #units do
		local unitId = units[unitIdx]
		local pointX, pointY, pointZ = SpringGetUnitPosition(unitId)
		local unitPos = Vec3(pointX, pointY, pointZ)
		if unitPos:Distance(self.lastUnitPosition[unitId]) < 5 then 
			self.threshold[unitId] = self.threshold[unitId] + THRESHOLD_STEP 
		else
			self.threshold[unitId] = THRESHOLD_DEFAULT
		end
		self.lastUnitPosition[unitId] = unitPos
	end
	
	-- check for succesfully reaching destination or killing the enemy
	for unitIdx=1, #units do
	local unitId = units[unitIdx]
		if self.unitTargets[unitId]~=nil then	
			local isUnitCloseToDestination = self.lastUnitPosition[unitId]:Distance(self.unitTargets[unitId]) < self.threshold[unitId]
			
			-- ideally we would want the unit killed, but it is possible the unit might become stuck somewhere
			-- then the treshold will make it chase somethink else
			if isUnitCloseToDestination or not hasValidTarget(unitId, self.unitTargetsUnit) then
				tableAddNext(self.unitTabooList[unitId], self.unitTargetsUnit[unitId]) -- Add to taboo list so that this unit wont attempt the same target again
				self.unitTargets[unitId] = nil -- new target will be found next iteration	
				self.unitTargetsUnit[unitId] = nil				
			end
		end
	end


	if (anyUnitCanReachEnemy) then
		for unitIdx=1, #units do
			local unitId = units[unitIdx]
			if self.unitTargets[unitId] ~= nil then
				SpringGiveOrderToUnit(unitId, CMD.FIGHT , self.unitTargets[unitId]:AsSpringVector(), {})
			end
		end
		return RUNNING
	else
		return SUCCESS
		
	end
end


function Reset(self)
	ClearState(self)
end
