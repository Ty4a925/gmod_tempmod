ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "#tempmod_freezeray"
ENT.Author = "Ty4a"
ENT.Category = "Temperature Mod"
ENT.Spawnable = true
ENT.PhysicsSounds = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Effect")
end