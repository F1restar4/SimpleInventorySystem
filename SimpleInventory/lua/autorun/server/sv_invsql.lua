// Simple inventory system 
// Written by Alex (steam:76561198081540869) (Github:F1restar4)

local function errCheck(In)
	if In == false then return true end
	return false
end

local function CreateTable()
	if sql.TableExists("SMPL_Inventory") then return false end
	local out = sql.Query("CREATE TABLE SMPL_Inventory(ID TEXT PRIMARY KEY, '1' TEXT, '2' TEXT, '3' TEXT, '4' TEXT, '5' TEXT, '6' TEXT, '7' TEXT, '8' TEXT, '9' TEXT, '10' TEXT)" ) 
	if errCheck(out) then return false, sql.LastError() end
	return true
end

local function CheckUserExists(ply)
	if not sql.TableExists("SMPL_Inventory") then CreateTable() return false end
	if sql.Query("Select * FROM SMPL_Inventory WHERE ID='"..ply:SteamID64().."'") then return true end
	return false
end

function CreateNewUser(ply)
	if CheckUserExists(ply) then return true end
	if sql.Query("INSERT INTO SMPL_Inventory(ID) VALUES( '"..ply:SteamID64().."')") then return true end
	return false
end


function UpdateSlot(ply, slot, entry)
	if not CheckUserExists(ply) then CreateNewUser(ply) end
	local out = sql.Query("UPDATE SMPL_Inventory SET '"..slot.."'='"..entry.."' WHERE ID='"..ply:SteamID64().."'")
	if errCheck(out) then return false, sql.LastError() end
	return true
end


local function fixTable(tab)
	local out = {}
	local id = tab.ID
	for k, v in pairs(tab) do
		if k == "ID" then continue end
		out[tonumber(k)] = v
	end
	out["ID"] = id
	return out 
end 

function ReturnTable(ply)
	if not CheckUserExists(ply) then CreateNewUser(ply) end
	local Out = sql.Query("SELECT * FROM SMPL_Inventory WHERE ID='"..ply:SteamID64().."'")
	if errCheck(Out) then return false, sql.LastError() end
	return fixTable(Out[1])
end

local function FindNext(ply)
	local tab = ReturnTable(ply)
	for k, v in pairs(tab) do
		if k == "ID" then break end
		if v == "NULL" then return k end
	end
	return false
end

function AddItem(ply, item)
	local Slot = FindNext(ply)
	if not Slot then return false end
	return UpdateSlot(ply, Slot, item)
end

local function ReturnAll()
	local Out = sql.Query("SELECT * FROM SMPL_Inventory")
	if errCheck(Out) then return false, sql.LastError() end
	return Out
end

function ReturnSingle(ply, slot)
	if not CheckUserExists(ply) then CreateNewUser(ply) end

	local Out = ReturnTable(ply)
	if errCheck(Out) then return false, sql.LastError() end
	return(Out[slot])
end

function SwapSlots(ply, slot1, slot2)
	if not CheckUserExists(ply) then CreateNewUser(ply) end
	local tab = ReturnTable(ply)
	local out = sql.Query("UPDATE SMPL_Inventory SET '"..slot2.."'='"..tab[slot1].."', '"..slot1.."'='"..tab[slot2].."' WHERE ID='"..ply:SteamID64().."'") 
	if errCheck(Out) then return false, sql.LastError() end
	return ReturnTable(ply)
end

CreateTable()

