function getInfo()
	return {
		onNoUnits = FAILURE, -- instant success
		tooltip = "Unload units at position",
		parameterDefs = {
			{ 
				name = "transporter",
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
local SpringGetUnitIsTransporting = Spring.GetUnitIsTransporting
local SpringGetGroundHeight = Spring.GetGroundHeight


local function ClearState(self)

end


function Run(self, units, parameter)
	local unitId = parameter.transporter
	
	local x,y,z = SpringGetUnitPosition(unitId)
	y = SpringGetGroundHeight(x,z)
	
	SpringGiveOrderToUnit(unitId, CMD.UNLOAD_UNITS, {x,y,z,50}, {})

	if #SpringGetUnitIsTransporting(unitId)==0 then
		return SUCCESS
	else
		return RUNNING
	end
end


function Reset(self)
	ClearState(self)
end
