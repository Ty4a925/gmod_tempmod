TOOL.Category = "Temperature Mod"
TOOL.Name = "#tool.tempchanger.name"
TOOL.ClientConVar["temperature"] = "200"
TOOL.Information = {
    {name = "left"},
    {name = "reload"}
}

local normal_temp = GetConVar("tempmod_normal_temperature")

function TOOL:LeftClick(trace)
    local ent = trace.Entity

    if IsValid(ent) and ent:IsTemperatureAvaiable() then
        if CLIENT then return true end
        ent:SetTemperature(self:GetClientNumber("temperature"))

        return true
    end

    return false
end

function TOOL:RightClick()
    return false
end

function TOOL:Reload(trace)
    local ent = trace.Entity

    if IsValid(ent) then
        if CLIENT then return true end
        ent:SetTemperature(normal_temp:GetInt())

        return true
    end

    return false
end

local color_box = Color(40, 40, 40, 200)

function TOOL:DrawHUD()
    local ent = LocalPlayer():GetEyeTrace().Entity

    if IsValid(ent) and ent:IsTemperatureAvaiable() then
        local temp = ent:GetTemperature()
        local scrW, scrH = ScrW(), ScrH()

        draw.RoundedBox(2, scrW / 2 - 80, scrH / 2 + 30, scrW / 2 - 800, scrH / 2 - 475, color_box)
        draw.SimpleText(temp .. "°C", "Trebuchet24", scrW / 2, scrH / 2 + 50, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(temp * 9 / 5 + 32) .. "°F", "Trebuchet18", scrW / 2 - 70, scrH / 2 + 70, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(temp + 273) .. "°K", "Trebuchet18", scrW / 2 - 70, scrH / 2 + 85, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

function TOOL.BuildCPanel(cpanel)
    cpanel:NumSlider("#tool.tempchanger.smalldesc", "tempchanger_temperature", -50000, 50000, 0)
end