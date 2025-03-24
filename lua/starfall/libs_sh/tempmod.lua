local checkluatype = SF.CheckLuaType
local registerprivilege = SF.Permissions.registerPrivilege

registerprivilege("entities.setTemperature", "Set Temperature", "Allows the user to change the temperature of an entity", { entities = {} })

return function(instance)

local getent
local ents_methods, ent_meta = instance.Types.Entity.Methods, instance.Types.Entity
local checkpermission = instance.player ~= SF.Superuser and SF.Permissions.check or function() end

instance:AddHook("initialize", function()
	getent = ent_meta.GetEntity
end)

--- Returns whether an entity can have a temperature.
-- @shared
-- @return boolean True if available, false if not
function ents_methods:isTemperatureAvaiable()
    return getent(self):IsTemperatureAvaiable()
end

--- Gets the temperature of an entity.
-- @shared
-- @return number Temperature of the entity
function ents_methods:getTemperature()
    return getent(self):GetTemperature()
end

if SERVER then
    --- Sets the temperature of the entity.
	-- @server
	-- @param number newtemperature New temperature value.
	function ents_methods:setTemperature(val)
		local ent = getent(self)
		checkluatype(val, TYPE_NUMBER)
        checkpermission(instance, ent, "entities.setTemperature")

		if not ent:IsTemperatureAvaiable() then 
			SF.Throw("Temperature is not available on this entity!", 2)
		else
			ent:SetTemperature(ent)
		end
	end
end

end