local tempmod_glow_enabled = GetConVar("tempmod_glow_enabled")
local tempmod_glow_max = GetConVar("tempmod_glow_max")

local color_red = Color(255, 0, 0)
local color_yellow = Color(255, 250, 0)

hook.Add("PreDrawHalos", "AddHotMetalHalos", function()
    if not tempmod_glow_enabled:GetBool() then return end

    local hotEntities = {}
    local count = 0

    for _, ent in ipairs(ents.FindByClass("prop_physics")) do
        if not ent:GetNW2Bool("IsMetalObject") then continue end

        local temperature = ent:GetTemperature()

        if temperature >= 999 then
            count = count + 1

            if count > tempmod_glow_max:GetInt() then break end

            table.insert(hotEntities, ent)

            if temperature < 3000 then
                halo.Add(hotEntities, color_red, 0.0025 * temperature, 0.0025 * temperature, 5, true, false)
                halo.Add(hotEntities, color_yellow, 2, 2, 4, true, false)
            else
                halo.Add(hotEntities, color_red, 5, 5, 5, true, false)
                halo.Add(hotEntities, color_yellow, 2, 2, 4, true, false)
            end
        end
    end
end)