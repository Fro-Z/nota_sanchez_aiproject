local sensorInfo = {
	name = "Filter table",
	desc = "Filter data from the first table, removing any that exist in the second table",
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

-- speedups
local SpringGetWind = Spring.GetWind

local function tableContains(tbl, value)
	if tbl==nil then return false end

	for k,v in ipairs(tbl) do
		if v==value then
			return true
		end
	end
	
	return false
end

return function(data, filter)
	local filtered = {}
	
	for i=1,#data do
		if not tableContains(filter, data[i]) then
		filtered[#filtered+1]=data[i]
		end
	end
	
	return filtered
end