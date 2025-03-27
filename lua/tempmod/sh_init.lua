local meta = FindMetaTable("Entity")

function meta:IsTemperatureAvaiable()
    return self:GetClass() == "prop_physics"
end

if SERVER then
    function meta:GetTemperature()
        return self:GetTable().Temperature or 0
    end
else
    function meta:GetTemperature()
        return self:GetNW2Int("Temperature", 0)
    end
end