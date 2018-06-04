function getInfo()
	return {
		onNoUnits = FAILURE, -- instant success
		tooltip = "Load units at position",
		parameterDefs = {
			{ 
				name = "transporter",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			},
			{ 
				name = "unit",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			},
		}
	}
end

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit
local SpringGetUnitTransporter = Spring.GetUnitTransporter

local function ClearState(self)

end

function Run(self, units, parameter)
	local unitId = parameter.transporter
	SpringGiveOrderToUnit(unitId, CMD.LOAD_UNITS, {parameter.unit}, {})

	if SpringGetUnitTransporter(parameter.unit)==unitId then
		return SUCCESS
	else
		return RUNNING
	end
end


function Reset(self)
	ClearState(self)
end
