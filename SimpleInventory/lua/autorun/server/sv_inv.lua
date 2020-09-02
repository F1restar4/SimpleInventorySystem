// Simple inventory system 
// Written by Alex (steam:76561198081540869) (Github:F1restar4)

include("sv_invsql.lua")
util.AddNetworkString("SMPLInventoryLoad")
util.AddNetworkString("SMPLInventoryEquip")
util.AddNetworkString("SMPLInventorySwap")
util.AddNetworkString("SMPLInventoryNotify")
util.AddNetworkString("SMPLInventoryDestroy")
util.AddNetworkString("SMPLInventoryDrop") 

local function InvNotify(ply, str)
	net.Start("SMPLInventoryNotify")
		net.WriteString(str)
	net.Send(ply)
end

local function GetModel(class)
	local ent = ents.Create(class)
	ent:SetPos(Vector(0,0,0))
	ent:Spawn()
	local model = ent:GetModel()
	ent:Remove()
	return model
end

local function GetModels(data)
	local out = {}
	for k, v in pairs(data) do
		if k == "ID"  or  v == "NULL" or out[v] != nil then continue end
		out[v] = GetModel(v)
	end
	return out
end

local function LoadInventory(ply)
	local Data = ReturnTable(ply)
	local ModelData = GetModels(Data)
	net.Start("SMPLInventoryLoad")
		net.WriteTable(Data)
		net.WriteTable(ModelData)
	net.Send(ply)
end

net.Receive("SMPLInventorySwap", function(len, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	local slot1, slot2 = net.ReadUInt(4), net.ReadUInt(4)
	SwapSlots(ply, slot1 ,slot2)
	LoadInventory(ply)
end)

net.Receive("SMPLInventoryEquip", function(len, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end 
	local slot = net.ReadUInt(4)
	local SlotData = ReturnSingle(ply, slot)
	if SlotData == "NULL" || ply:Give(SlotData) == "NULL" then InvNotify(ply, "Weapon invalid or already equipped") return end
	UpdateSlot(ply, slot, "NULL")
	LoadInventory(ply)
end)

net.Receive("SMPLInventoryDestroy", function(len, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	local slot = net.ReadUInt(4)
	local SlotData = ReturnSingle(ply, slot)
	if SlotData == "NULL" then InvNotify(ply, "Hey, stop trying to poke holes in here. Actually, keep doing it, but, like, tell me if you find something please.") return end
	UpdateSlot(ply, slot, "NULL")
	LoadInventory(ply)
end)

net.Receive("SMPLInventoryDrop", function(len, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	local slot = net.ReadUInt(4) 
	local SlotData = ReturnSingle(ply, slot)
	if SlotData == "NULL" then InvNotify(ply, "ur bones") return end
	
	local trace = {}
	trace.start = ply:GetShootPos()
	trace.endpos = trace.start + ply:GetAimVector() * 50
	trace.filter = {ply}
	local tr = util.TraceLine(trace)
	
	local model = GetModel(SlotData)
	local wep = ents.Create("spawned_weapon")
	wep:SetModel(model)
	wep:SetWeaponClass(SlotData)
	wep:SetPos(tr.HitPos)
	wep:Spawn()
	
	UpdateSlot(ply, slot, "NULL")
	LoadInventory(ply) 
end)

hook.Add("PlayerInitialSpawn", "InventoryPlayerCreation", function(ply)
	timer.Simple(1, function()
		CreateNewUser(ply)
		LoadInventory(ply)
	end)
end)

hook.Add("PlayerPickupDarkRPWeapon", "PreventDefaultPickup", function(ply, ent, wep)
	if not AddItem(ply, ent:GetWeaponClass()) then InvNotify(ply, "No Space in Inventory!") return true end
	ent:DecreaseAmount()
	LoadInventory(ply)
	return true
end)