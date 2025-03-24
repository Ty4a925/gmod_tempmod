local meta = FindMetaTable("Entity")

local normtemp = CreateConVar("tempmod_normal_temperature", "20", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Normal temperature for objects")
local damageprops = CreateConVar("tempmod_damageprops", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Damage props by temperature")
local tempfordamage = CreateConVar("tempmod_tempfordamage", "100", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "If the temperature is equal to this number then the prop will break")
local tempspread = CreateConVar("tempmod_tempspread", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Temperature spread")
local spreadvalue = CreateConVar("tempmod_tempspread_value", "0.10", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Temperature spread value")
local tempdecrease = CreateConVar("tempmod_tempdecrease_value", "1.0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Temperature decrease value")
local increasevalue = CreateConVar("tempmod_tempincrease_value", "5.0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Temperature increase value")
local decreasetime = CreateConVar("tempmod_tempdecrease_updatetime", "1.0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Temperature increase value")
local spreadtime = CreateConVar("tempmod_tempspread_updatetime", "1.0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Temperature increase value")

local function IsMetalObject(ent)
    if not IsValid(ent) then return false end
    local entmat = ent:GetMaterialType()
    return entmat == MAT_VENT or entmat == MAT_METAL
end

local function UpdateTemperatureMaterial(ent)
    if not IsValid(ent) then return end
    local entmat = ent:GetMaterialType()
    local temp = ent:GetTemperature()

    if temp >= 1000 then
        if IsMetalObject(ent) then
            ent:SetMaterial("temperaturemod/metal/metalwhite.vtf")
        end
    elseif ent:GetMaterial() == "temperaturemod/metal/metalwhite.vtf" then
        ent:SetMaterial("")
    end
end

local function UpdateTemperatureColor(ent)
    if not IsValid(ent) or not ent.GetMaterialType then return end
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

function meta:SetTemperature(num)
    if not IsValid(self) then return end
    self:SetNW2Int("Temperature", num)

    if not self.GetMaterialType then return end
    local entmat = self:GetMaterialType()
    local temp = self:GetTemperature()

    if damageprops:GetBool() and temp >= tempfordamage:GetInt() then
        self:TakeDamage(math.min(self:Health() - 15, 0))
    end

    if not vFireInstalled then
        if entmat == MAT_WOOD and temp >= 300 and self:WaterLevel() < 2 then
            self:Ignite(60 * temp)
        end
    end

    UpdateTemperatureMaterial(self)
    UpdateTemperatureColor(self)
end

hook.Add("PlayerSpawnedProp", "PropTemperatureSpawn", function(pl, mdl, ent)
    if ent:IsTemperatureAvaiable() then
        ent:SetTemperature(normtemp:GetInt())
        if ent:GetMaterialType() == MAT_METAL then ent:SetNW2Bool("IsMetalObject",true) end
    end
end)

local LastUpdate = CurTime()
local LastDamageTime = CurTime()
local LastSpreadUpdate = CurTime()

if SERVER then
    hook.Add("Think", "PropTemperatureLogic", function()
        local curTime = CurTime()

        if not LastUpdate or curTime - LastUpdate > decreasetime:GetInt() and tempdecrease:GetInt() > 0 then
            for _, ent in ents.Iterator() do
                if ent:IsTemperatureAvaiable() then
                    local temp = ent:GetTemperature()

                    local num = 0
                    if ent:WaterLevel() > 2 then num = 10 else num = 1 end
                    
                    if temp > normtemp:GetInt() then
                        ent:SetTemperature(temp - tempdecrease:GetInt()*num)
                    end
                    LastUpdate = curTime + decreasetime:GetInt()
                end
            end
        end

        if tempspread:GetBool() then
            if not LastSpreadUpdate or curTime - LastSpreadUpdate > spreadtime:GetInt() then
                for _, ent in ents.Iterator() do
                    if ent:IsTemperatureAvaiable() then
                        local entities = ents.FindInSphere(ent:GetPos(), 75 )
                        for _, nearbyEnt in ipairs(entities) do
                            if nearbyEnt:IsTemperatureAvaiable() and nearbyEnt ~= ent then
                                local temp1 = ent:GetTemperature()
                                local temp2 = nearbyEnt:GetTemperature()
                                local temp3 = temp1 - temp2

                                if temp3 ~= 0 then
                                    local spreadvalue = GetConVarNumber("tempmod_tempspread_value")
                                    local amount = temp3 * spreadvalue/2
                                    ent:SetTemperature(temp1 - amount)
                                    nearbyEnt:SetTemperature(temp2 + amount)
                                end
                            end
                        end
                    end
                end
                LastSpreadUpdate = curTime + spreadtime:GetInt()
            end
        end

        if not LastDamageTime or curTime - LastDamageTime > 1 then
            for _, ply in player.Iterator() do
                if IsValid(ply) then
                    if ply:Health() > 0 then
                        local entities = ents.FindInSphere(ply:GetPos(),65)

                        for _, ent in ipairs(entities) do
                            if IsValid(ent) and ent:IsTemperatureAvaiable() and ent:GetTemperature() >= 50 then
                                local dmg = DamageInfo()
                                dmg:SetDamage((ent:GetTemperature() - 50) / 10)
                                dmg:SetAttacker(ent)
                                dmg:SetInflictor(ent)
                                dmg:SetDamageType(DMG_BURN)

                                ply:TakeDamageInfo(dmg)

                                LastDamageTime = curTime + 1
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
end

hook.Add("EntityTakeDamage", "TemperatureByDamage", function(target, dmginfo)
    if not IsValid(target) or not target:IsTemperatureAvaiable() then return end

    local damagetype = dmginfo:GetDamageType()
    local damage = dmginfo:GetDamage()

    if damagetype == DMG_BURN then
        target:SetTemperature(target:GetTemperature() + damage * 0.5)
    elseif damagetype == DMG_BLAST then
        target:SetTemperature(target:GetTemperature() + math.min(damage, 100))
    end
end)

concommand.Add("set_temp", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end

    local ent = tr.Entity
    if IsValid(ent) and ent:IsTemperatureAvaiable() then
        local temp = tonumber(args[1])
        if temp then
            ent:SetTemperature(temp)
        end
    end
end)

concommand.Add("get_temp", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end

    local ent = tr.Entity
    if IsValid(ent) and ent:IsTemperatureAvaiable() then
        local temp = ent:GetTemperature()
        ply:ChatPrint(ent:GetClass() .. " Temperature")
        ply:ChatPrint("- " .. temp .. " Celsius")
        ply:ChatPrint("- " .. tostring(temp * 9 / 5 + 32) .. " Fahrenheit")
    end
end)
