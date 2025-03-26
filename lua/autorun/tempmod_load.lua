AddCSLuaFile("tempmod/sh_init.lua")
include("tempmod/sh_init.lua")

if SERVER then
    resource.AddWorkshop("3259220540")
    include("tempmod/sv_init.lua")
else
    CreateClientConVar("tempmod_glow_max", "5", true, false, "Maximum of glow hot objects")
    CreateClientConVar("tempmod_glow_enabled", "1", true, false, "Maximum of glow hot objects")
end

AddCSLuaFile("tempmod/modules/cl_halo.lua")
AddCSLuaFile("tempmod/modules/cl_utilities.lua")

if SERVER then
    include("tempmod/modules/sv_vfire.lua")
else
    include("tempmod/modules/cl_halo.lua")
    include("tempmod/modules/cl_utilities.lua")
end
