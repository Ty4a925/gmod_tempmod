AddCSLuaFile("tempmod/cl_init.lua")
AddCSLuaFile("tempmod/sh_init.lua")
include("tempmod/sh_init.lua")

if SERVER then
    resource.AddWorkshop("3259220540")
    include("tempmod/sv_init.lua")
else
    include("tempmod/cl_init.lua")
end

AddCSLuaFile("tempmod/modules/cl_halo.lua")
AddCSLuaFile("tempmod/modules/cl_utilities.lua")

if SERVER then
    include("tempmod/modules/sv_vfire.lua")
else
    include("tempmod/modules/cl_halo.lua")
    include("tempmod/modules/cl_utilities.lua")
end
