// Simple inventory system 
// Written by Alex (steam:76561198081540869) (Github:F1restar4)

local draw = draw
local net = net
local math = math
local Color = Color
local vgui = vgui

local Inventory = Inventory or {}
local ModelData = ModelData or {}
local InventoryMenu 
local waitingForLoad = false

local function CreateNewInv()
	if IsValid(InventoryMenu) then 
		InventoryMenu.List:UpdateInventory(Inventory) 
		InventoryMenu:Show()  
		return 
	end
	
	local InventoryMenuBack = vgui.Create("DPanel")
	InventoryMenuBack:SetSize(410, 205)
	InventoryMenuBack:Center()
	InventoryMenuBack.Paint = function(self, w, h)
		draw.RoundedBox(10, 0, 0, w, h, Color(0,0,0,170))
	end
	InventoryMenu = vgui.Create( "DFrame")
	InventoryMenu.Back = InventoryMenuBack
	InventoryMenu:SetSize(405, 200)
	InventoryMenu:SetTitle("Inventory")
	InventoryMenu:Center()
	InventoryMenu:MakePopup()
	InventoryMenu.btnClose.DoClick = function(self) self:GetParent():Hide() end
	InventoryMenu.OnRemove = function(self) waitingForLoad = false self.Back:Remove() end
	function InventoryMenu:Hide()
		self:SetVisible(false)
		self.Back:Hide()
	end
	
	function InventoryMenu:Show()
		self:SetVisible(true)
		self.Back:Show()
	end
	
	
	function InventoryMenu:Paint(w, h)
		draw.RoundedBox(10, 0, 0, w, h, Color(100, 100, 100, 200))
	end
	
	InventoryMenu.OnKeyCodePressed = function(self, key)
		local helpBind = input.GetKeyCode(input.LookupBinding("gm_showhelp", true))
		if key == helpBind then self:Hide() end
	end

	local List = vgui.Create("DIconLayout", InventoryMenu)
	InventoryMenu.List = List
	List:Dock( FILL )
	List:SetSpaceY(5)
	List:SetSpaceX(5)
	List.Inventory = Inventory
	
	List.UpdateInventory = function(self, NewInventory)
		self:Clear()
		self.Inventory = NewInventory or self.Inventory
		for k, v in pairs(self.Inventory) do
			if k == "ID" then continue end
			local Item = self:Add("DPanel")
			Item:SetSize(75, 75)
			Item.Slot = k
			Item.Paint = function(self, w, h)
				draw.RoundedBox(10, 0, 0, w, h, Color(150, 150, 150, 220))
			end
			Item:Receiver("Inventory", function( self, tab, isdropped)
				if not isdropped then return end
				local target = tab[1].Slot
				net.Start("SMPLInventorySwap")
					net.WriteUInt(self.Slot, 4)
					net.WriteUInt(target, 4)
				net.SendToServer()
				waitingForLoad = true
			end)

			if v == "NULL" then continue end
		
			local content = vgui.Create("DModelPanel", Item)
			content:Dock(FILL)
			content:SetModel(ModelData[v])
			content.Slot = k
			content.Ent = v
			content:SetToolTip(v)
			local mn, mx = content.Entity:GetRenderBounds()
			local size = 0
			size = math.max( size, math.abs( mn.x ) + math.abs( mx.x ) )
			size = math.max( size, math.abs( mn.y ) + math.abs( mx.y ) )
			size = math.max( size, math.abs( mn.z ) + math.abs( mx.z ) )
			content:SetFOV(45)
			content:SetCamPos( Vector( size, size, size ) )
			content:SetLookAt( ( mn + mx ) * 0.5 )
			function content:LayoutEntity( Entity ) return end
		
			content.DoRightClick = function(self)
				local menu = DermaMenu()
				menu:AddOption("Equip", function() 
					net.Start("SMPLInventoryEquip")
						net.WriteUInt(self.Slot, 4)
					net.SendToServer()
					waitingForLoad = true
					InventoryMenu:Hide()
				end)
				menu:AddOption("Drop", function()
					net.Start("SMPLInventoryDrop")
						net.WriteUInt(self.Slot, 4)
					net.SendToServer()
					waitingForLoad = true
				end)
				menu:AddOption("Destroy", function()
					net.Start("SMPLInventoryDestroy")
						net.WriteUInt(self.Slot, 4)
					net.SendToServer()
					waitingForLoad = true
				end)
			
				menu:Open()
			
			end
		
			content:Droppable("Inventory")
			content:Receiver("Inventory", function( self, tab, isdropped)
				if not isdropped then return end
				local target = tab[1].Slot			
				net.Start("SMPLInventorySwap")
					net.WriteUInt(self.Slot, 4)
					net.WriteUInt(target, 4)
				net.SendToServer()
				waitingForLoad = true
			end)

		end
	end
	List:UpdateInventory(Inventory)
	InventoryMenu.List = List
	
end

net.Receive("SMPLInventoryLoad", function()
	local first = false
	if table.Count(Inventory) <= 0 then first = true end
	
	local tab = net.ReadTable()
	local models = net.ReadTable()
	Inventory = tab
	ModelData = models
	if waitingForLoad then InventoryMenu.List:UpdateInventory(Inventory) waitingForLoad = false end
	if first && table.Count(Inventory) > 0 then chat.AddText(Color(0,255,255), "[Inventory Sys] ", Color(255,255,255), "Inventory loaded successfully") end
end) 

hook.Add("ShowHelp", "SMPLInventoryOpen", function(ply)
	CreateNewInv()
end)


net.Receive("SMPLInventoryNotify", function()
	chat.AddText(Color(0,255,255), "[Inventory Sys] ", Color(255,255,255), net.ReadString())
end)
