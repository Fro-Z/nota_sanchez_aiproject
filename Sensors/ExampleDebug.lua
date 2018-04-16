local sensorInfo = {
	name = "ExampleDebug",
	desc = "Sends data to example debug widget",
	author = "PepeAmpere",
	date = "2018-04-16",
	license = "MIT",
}

-- get madatory module operators
VFS.Include("modules.lua") -- modules table
VFS.Include(modules.attach.data.path .. modules.attach.data.head) -- attach lib module

-- get other madatory dependencies
attach.Module(modules, "message") -- communication backend load

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- @description return current wind statistics
return function()
	if #units > 0 then
		local unitID = units[1]
		local x,y,z = Spring.GetUnitPosition(unitID)
		if (Script.LuaUI('exampleDebug_update')) then
			Script.LuaUI.exampleDebug_update(
				unitID, -- key
				{	-- data
					startPos = Vec3(x,y,z), 
					endPos = Vec3(x,y,z) + Vec3(0,0,100)
				}
			)
		end
		return {	-- data
					startPos = Vec3(x,y,z), 
					endPos = Vec3(x,y,z) + Vec3(0,0,100)
				}
	end
end