-- get madatory module operators
VFS.Include("modules.lua") -- modules table
VFS.Include(modules.attach.data.path .. modules.attach.data.head) -- attach lib module

-- get other madatory dependencies
attach.Module(modules, "message") -- communication backend load

function getInfo()
    return {
        period = 0 -- no caching
    }
end

-- @description return current wind statistics
return function()
    message.SendRules({
        subject = "manualMissionEnd",
        data = {},
    })
end