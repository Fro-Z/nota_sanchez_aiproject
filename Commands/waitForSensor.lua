function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Wait until sensor completes its calculation",
		parameterDefs = {
			{ 
				name = "sensor",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			},
			{ 
				name = "parameters",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			}
		}
	}
end


-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit

local function ClearState(self)

end

function Run(self, units, parameter)
	local sensorResult = parameter.sensor(unpack(parameter.parameters))
	
	if sensorResult["completed"]==true then
		return SUCCESS
	else
		return RUNNING
	end
end


function Reset(self)
	ClearState(self)
end
