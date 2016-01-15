-- GLOBAL.CHEATS_ENABLED = true
-- GLOBAL.require( 'debugkeys' )

local require = GLOBAL.require
local storagekeeper=require('storagecluster')()

storagekeeper.searchradius=GetModConfigData("radius")

local function StorageServerPostInit(inst)
	storagekeeper:buildAdjacencyList(inst)
	table.insert(storagekeeper.managedStorages,inst)
	inst:ListenForEvent("onbuilt",function()
		storagekeeper:reBuildAdjacencyLists()
		end)
	inst:ListenForEvent("onopen",function(inst)
		local player=inst.components.container.opener
		storagekeeper.directionOfConvey[player].firstSort=true
		end)
	if inst.components.workable ~= nil then
		local oldOnfinish=inst.components.workable.onfinish
			onhammered=function(inst, worker)
			oldOnfinish(inst,worker)
			local itoremove=table.find(storagekeeper.managedStorages,inst)
			table.remove(storagekeeper.managedStorages,itoremove)	
			storagekeeper:reBuildAdjacencyLists()
		end
		inst.components.workable:SetOnFinishCallback(onhammered)
	end
end

--- Inventory must be sorted server-side, so listen for a RPC.
AddModRPCHandler(modname, "dsiRemoteStorageArrange", function(player,modVersion)
	if modVersion ~= GLOBAL.KnownModIndex:GetModInfo(modname).version then
		print("Client Version:",modVersion,"not compatible with Server:",GLOBAL.KnownModIndex:GetModInfo(modname).version)
		if player.components.talker then
			player.components.talker:Say("I Need Update Storage Keeper")
		end
		return
	end
	storagekeeper:StorageArrange(player)
	print("Storage Sort called by ",player,chest)
	end)

--- Press "[KeyBind]" to sort your inventory.
GLOBAL.TheInput:AddKeyDownHandler(GetModConfigData("keybind"), function()
	if not GLOBAL.ThePlayer then
		print("Not ThePlayer")
		return
	end
	if GLOBAL.ThePlayer.HUD:IsConsoleScreenOpen() or GLOBAL.ThePlayer.HUD:IsChatInputScreenOpen() then
		return
	end
	local modVersion       = GLOBAL.KnownModIndex:GetModInfo(modname).version

	SendModRPCToServer(MOD_RPC[modname]["dsiRemoteStorageArrange"], modVersion)
end)

if GLOBAL.TheNet:GetIsServer() then
	for _,v in ipairs(storagekeeper.supportContainer) do
		AddPrefabPostInit(v,StorageServerPostInit)
	end
	AddPlayerPostInit(function(player)
		if player then
			print("Register player : ",player)
			storagekeeper.directionOfConvey[player] = {firstSort=true,direction=0}
		else
			print("Error on player :",player)
		end
	end)
end