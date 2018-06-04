function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Scatter units into positions",
		parameterDefs = {
			{ 
				name = "pathPositions",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			},
			{ 
				name = "reverse",
				variableType = "expression",
				componentType = "checkBox",
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


local function GetUnitPositionVector(unitId)
	local x,y,z = Spring.GetUnitPosition(unitId)
	return Vec3(x,y,z)
end

local function ClearState(self)
	self.threshold = {}
	self.initiated = {}
	self.lastUnitPosition = {}
	self.finished = {}
end

local function getTarget(targetId, path, reversePath)
	if reversePath==true then
		return path[#path - targetId + 1]
	else
		return path[targetId]
	end
end

function Run(self, units, parameter)
	local path = parameter.pathPositions
	
	if self.initiated == nil then
		ClearState(self)
	end
		
	local anyUnitsTraveling = false
	for unitIdx=1, #units do
		local unitId = units[unitIdx]

		-- Init once per unit
		if self.initiated[unitId] == nil and self.finished[unitId]~=true then
			self.initiated[unitId] = true
			
			-- Queue move orders
			for targetId = 1, #path do
				local target = getTarget(targetId, path, parameter.reverse)
				SpringGiveOrderToUnit(unitId, CMD.MOVE, path[targetId]:AsSpringVector(), {"shift"})
			end	
		end
		
		-- Increase threshold of success if not moving
		local unitPos = GetUnitPositionVector(unitId)
		unitPos["y"] = 0
		if (unitPos == self.lastUnitPosition[unitId]) then 
			self.threshold[unitId] = self.threshold[unitId] + THRESHOLD_STEP 
		else
			self.threshold[unitId] = THRESHOLD_DEFAULT
		end
		self.lastUnitPosition[unitId] = unitPos
		
		-- Reached the end
		if(unitPos:Distance(getTarget(#path, path, parameter.reverse)) < self.threshold[unitId]) then
			self.finished[unitId] = true
		else
			anyUnitsTraveling = true
		end
	end
	
	if anyUnitsTraveling then
		return RUNNING 
	else
		return SUCCESS
	end
end


function Reset(self)
	ClearState(self)
end
