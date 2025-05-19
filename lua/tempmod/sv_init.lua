local meta = FindMetaTable("Entity")

local flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}
local normtemp = CreateConVar("tempmod_normal_temperature", "20", flags, "Normal temperature for objects")
local damageprops = CreateConVar("tempmod_damageprops", "1", flags, "Damage props by temperature")
local tempfordamage = CreateConVar("tempmod_tempfordamage", "100", flags, "If the temperature is equal to this number then the prop will break")
local tempspread = CreateConVar("tempmod_tempspread", "1", flags, "Temperature spread")
local spreadvalue = CreateConVar("tempmod_tempspread_value", "0.1", flags, "Temperature spread value")
local tempdecrease = CreateConVar("tempmod_tempdecrease_value", "1", flags, "Temperature decrease value")
local decreasetime = CreateConVar("tempmod_tempdecrease_updatetime", "1", flags, "Temperature increase value")
local spreadtime = CreateConVar("tempmod_tempspread_updatetime", "1", flags, "Temperature increase value")

local function IsMetalObject(ent)
    local material = ent:GetMaterialType()
    return material == MAT_VENT or material == MAT_METAL
end

local function UpdateTemperatureMaterial(ent)
    if ent:GetTemperature() >= 1000 then
        if IsMetalObject(ent) then
            ent:SetMaterial("temperaturemod/metal/metalwhite.vtf")
        end
    elseif ent:GetMaterial() == "temperaturemod/metal/metalwhite.vtf" then
        ent:SetMaterial("")
    end
end

local function UpdateTemperatureColor(ent)
    local entmat = ent:GetMaterialType()
    local temp = ent:GetTemperature()

    if temp >= 100 and temp < 1000 then
        if IsMetalObject(ent) then
            local color = math.Clamp((temp - 100) / 1000, 0, 1) * 255
            ent:SetColor(Color(255, 255 - color, 255 - color))
        elseif entmat == MAT_WOOD or entmat == MAT_PLASTIC then
            local color = math.Clamp((temp - 100) / 300, 0, 1) * 255
            ent:SetColor(Color(255 - color, 255 - color, 255 - color))
        end
    elseif temp >= 1000 then
        if IsMetalObject(ent) then
            ent:SetColor(color_white)
        end
    end
end

duplicator.RegisterEntityModifier("Tempmod_Temperature", function(ply, ent, data)
    if ent:IsTemperatureAvaiable() and data.Temperature and data.Temperature == data.Temperature then
        ent:SetTemperature(data.Temperature)
    end
end)

function meta:SetTemperature(num)
    self:SetNW2Int("Temperature", num)

    if damageprops:GetBool() and num >= tempfordamage:GetInt() then
        self:TakeDamage(math.min(self:Health() - 15, 0))
    end

    if not vFireInstalled then
        local material = self:GetMaterialType()

        if material == MAT_WOOD and num >= 300 and self:WaterLevel() < 2 then
            self:Ignite(60 * num)
        end
    end

    UpdateTemperatureMaterial(self)
    UpdateTemperatureColor(self)

    --Duplictor/saves support
    duplicator.StoreEntityModifier(self, "Tempmod_Temperature", {Temperature = num})
end

hook.Add("OnEntityCreated", "PropTemperatureSpawn", function(ent)
    if ent:IsValid() and ent:IsTemperatureAvaiable() then
        timer.Simple(0, function()
            if ent:IsValid() then
                if ent:GetMaterialType() == MAT_METAL then
                    ent:SetNW2Bool("IsMetalObject", true)
                end

                if not ent:GetTemperature(false) then
                    ent:SetTemperature(normtemp:GetInt())
                end
            end
        end)
    end
end)

timer.Create("TemperatureMod_Decrease", decreasetime:GetInt(), 0, function()
    for _, ent in ipairs(ents.FindByClass("prop_physics")) do
        if ent:IsTemperatureAvaiable() then
            local temp = ent:GetTemperature()

            if temp > normtemp:GetInt() then
                local decreasetemp = math.max(ent:WaterLevel() >= 1 and temp * 0.25 or 1, 1)

                if decreasetemp > 100 then
                    local effect = EffectData()
                    effect:SetOrigin(ent:GetPos())
                    effect:SetScale(5)
                    util.Effect("hot_metal", effect)
                end

                ent:SetTemperature(temp - tempdecrease:GetInt() * decreasetemp)
            end
        end
    end
end)

timer.Create("TemperatureMod_Spread", spreadtime:GetInt(), 0, function()
    if not tempspread:GetBool() then return end

    for _, ent in ipairs(ents.FindByClass("prop_physics")) do
        for _, nearent in ipairs(ents.FindInSphere(ent:GetPos(), 75)) do
            if nearent:IsTemperatureAvaiable() and nearent ~= ent then
                local temp1 = ent:GetTemperature()
                local temp2 = nearent:GetTemperature()
                if temp1 == temp2 then continue end

                local temp3 = temp1 - temp2

                if temp3 ~= 0 then
                    local amount = temp3 * spreadvalue:GetFloat() / 2
                    ent:SetTemperature(temp1 - amount)
                    nearent:SetTemperature(temp2 + amount)
                end
            end
        end
    end
end)

timer.Create("TeamperatureMod_Damage", 1, 0, function()
    for _, ply in player.Iterator() do
        if not ply:Alive() then continue end

        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 65)) do
            if ent:IsTemperatureAvaiable() and ent:GetTemperature() >= 75 then
                local dmg = DamageInfo()
                dmg:SetDamage((ent:GetTemperature() - 50) / 10)
                dmg:SetAttacker(ent)
                dmg:SetInflictor(ent)
                dmg:SetDamageType(DMG_BURN)
                ply:TakeDamageInfo(dmg)
            end
        end
    end
end)

hook.Add("EntityTakeDamage", "TemperatureByDamage", function(target, dmginfo)
    if not target:IsTemperatureAvaiable() then
        local damagetype = dmginfo:GetDamageType()

        if damagetype == DMG_BURN or damagetype == DMG_BLAST then
            target:SetTemperature(target:GetTemperature() + dmginfo:GetDamage() * 0.5)
        end
    end
end)

concommand.Add("set_temp", function(ply, cmd, args)
    local ent = ply:GetEyeTrace().Entity

    if IsValid(ent) and ent:IsTemperatureAvaiable() then
        local temp = tonumber(args[1])

        if temp then
            ent:SetTemperature(temp)
        end
    end
end)

concommand.Add("get_temp", function(ply, cmd, args)
    local ent = ply:GetEyeTrace().Entity

    if IsValid(ent) and ent:IsTemperatureAvaiable() then
        local temp = ent:GetTemperature()
        ply:ChatPrint(ent:GetClass() .. " Temperature")
        ply:ChatPrint("- " .. temp .. " Celsius")
        ply:ChatPrint("- " .. math.floor(temp * 9 / 5 + 32) .. " Fahrenheit")
    end
end)
