function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Scatter units into positions",
		parameterDefs = {
			{ 
				name = "positions",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			},
			{ 
				name = "fight",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "false",
			}
		}
	}
end

-- constants
local THRESHOLD_STEP = 25
local THRESHOLD_DEFAULT = 0

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit

local function ClearState(self)
	self.threshold = {}
	self.lastUnitPosition = {}
end

function Run(self, units, parameter)
	local positions = parameter.positions -- table of Vec3
	local fight = parameter.fight -- boolean
	
	-- init
	if self.threshold == nil then
		self.threshold = {}
	end
	
	if self.lastUnitPosition == nil then
		self.lastUnitPosition = {}
	end
	
	-- assign target to each unit
	local unitTargets = {}
	local nextPositionIdx = 1
	for unitIdx=1, #units do
	local unitId = units[unitIdx]
		local x = positions[nextPositionIdx % #positions + 1]["x"]
		local z = positions[nextPositionIdx % #positions + 1]["z"]
		nextPositionIdx = nextPositionIdx + 1
		
		unitTargets[unitId] = Vec3(x, Spring.GetGroundHeight(x,z), z)
		if self.threshold[unitId] == nil then
			self.threshold[unitId] = TRESHOLD_DEFAULT
		end
		
		if self.lastUnitPosition[unitId] == nil then
			self.lastUnitPosition[unitId] = Vec3(0,0,0)
		end
	end
		
	
	-- pick the spring command implementing the move
	local cmdID = CMD.MOVE
	if (fight) then cmdID = CMD.FIGHT end

	-- threshold of success
	for unitIdx=1, #units do
		local unitId = units[unitIdx]
		local pointX, pointY, pointZ = SpringGetUnitPosition(unitId)
		local unitPos = Vec3(pointX, pointY, pointZ)
		if (unitPos == self.lastUnitPosition[unitId]) then 
			self.threshold[unitId] = self.threshold[unitId] + THRESHOLD_STEP 
		else
			self.threshold[unitId] = THRESHOLD_DEFAULT
		end
		self.lastUnitPosition[unitId] = unitPos
	end
	
	-- check for success
	local allUnitsOnTarget = true;
	for unitIdx=1, #units do
	local unitId = units[unitIdx]
		if(self.lastUnitPosition[unitId]:Distance(unitTargets[unitId]) > self.threshold[unitId]) then
			allUnitsOnTarget = false
		else
			-- are there any more targets
			if nextPositionIdx <= #positions then
				local x = positions[nextPositionIdx]["x"];
				local z = positions[nextPositionIdx]["z"];
				nextPositionIdx = nextPositionIdx +1
				
				unitTargets[unitId] = Vec3(x, Spring.GetGroundHeight(x,z), z)
				self.threshold[unitId] = TRESHOLD_DEFAULT
				allUnitsOnTarget = false
			end
		end
	end


	if (allUnitsOnTarget and nextPositionIdx > #positions) then
		return SUCCESS
	else
		for unitIdx=1, #units do
			local unitId = units[unitIdx]
			SpringGiveOrderToUnit(unitId, cmdID, unitTargets[unitId]:AsSpringVector(), {})
		end
		
		return RUNNING
	end
end


function Reset(self)
	ClearState(self)
end
