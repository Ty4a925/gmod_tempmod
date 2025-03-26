if not vFireInstalled then return end

timer.Create("TemperatureMod_vFire", 1, 0, function()
    for _, ent in pairs(vFireGetBurningEntities()) do
        if not IsValid(ent) or not ent:IsTemperatureAvaiable() then continue end

        ent:SetTemperature(ent:GetTemperature() + 7)
    end
end)