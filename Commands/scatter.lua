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
	
	
	-- validation
	if (#positions > #units) then
		Logger.warn("scatter", "Your position list [" .. #positions .. "] is bigger than number of units [" .. #units .. "] in this group.") 
		return FAILURE
	end
	
	-- assign target to each unit
	local unitTargets = {}
	for unitIdx=1, #units do
		local x = positions[(unitIdx % #positions)+1]["x"];
		local z = positions[(unitIdx % #positions)+1]["z"];
		unitTargets[unitIdx] = Vec3(x, Spring.GetGroundHeight(x,z), z)
		if self.threshold[unitIdx] == nil then
			self.threshold[unitIdx] = TRESHOLD_DEFAULT
		end
		
		if self.lastUnitPosition[unitIdx] == nil then
			self.lastUnitPosition[unitIdx] = Vec3(0,0,0)
		end
	end
		
	
	-- pick the spring command implementing the move
	local cmdID = CMD.MOVE
	if (fight) then cmdID = CMD.FIGHT end

	-- threshold of success
	for unitIdx=1, #units do
		local pointX, pointY, pointZ = SpringGetUnitPosition(units[unitIdx])
		local unitPos = Vec3(pointX, pointY, pointZ)
		if (unitPos == self.lastUnitPosition[unitIdx]) then 
			self.threshold[unitIdx] = self.threshold[unitIdx] + THRESHOLD_STEP 
		else
			self.threshold[unitIdx] = THRESHOLD_DEFAULT
		end
		self.lastUnitPosition[unitIdx] = unitPos
	end
	
	-- check for success
	local allUnitsOnTarget = true;
	for unitIdx=1, #units do
		if(self.lastUnitPosition[unitIdx]:Distance(unitTargets[unitIdx]) > self.threshold[unitIdx]) then
			allUnitsOnTarget = false
		end
	end


	if (allUnitsOnTarget) then
		return SUCCESS
	else
		for unitIdx=1, #units do
			SpringGiveOrderToUnit(units[unitIdx], cmdID, unitTargets[unitIdx]:AsSpringVector(), {})
		end
		
		return RUNNING
	end
end


function Reset(self)
	ClearState(self)
end
