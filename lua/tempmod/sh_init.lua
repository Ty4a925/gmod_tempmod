local meta = FindMetaTable("Entity")

function meta:IsTemperatureAvaiable()
    return self:GetClass() == "prop_physics"
end

function meta:GetTemperature(fallback)
    return self:GetNW2Int("Temperature", fallback)
end