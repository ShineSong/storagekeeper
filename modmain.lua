GLOBAL.CHEATS_ENABLED = true
GLOBAL.require( 'debugkeys' )

local require = GLOBAL.require
local storagekeeper=require('storagecluster')()

storagekeeper.searchradius=GetModConfigData("radius")
print("Cluster Radius : ",storagekeeper.searchradius)
local function StorageServerPostInit(inst)
	storagekeeper:registerStorage(inst)
	inst:ListenForEvent("onbuilt",function()
		storagekeeper.storageDirty=true
		storagekeeper:rebuildAdjacencyLists()
		end)
	if inst.components.workable ~= nil then
		local oldOnfinish=inst.components.workable.onfinish
			onhammered=function(inst, worker)
			oldOnfinish(inst,worker)
			storagekeeper:deregisterStorage(inst)
			storagekeeper.storageDirty=true
			storagekeeper:rebuildAdjacencyLists()
		end
		inst.components.workable:SetOnFinishCallback(onhammered)
	end
	-- inst:ListenForEvent("itemget",function(inst,in_slot,item,src_pos)
	-- 	if not storagekeeper.isRunning then
	-- 		local player=inst.components.container.opener
	-- 		if player then
	-- 			storagekeeper:StorageArrange(player,true)
	-- 		end
	-- 	end
	-- 	end)
	inst:ListenForEvent("SignPlus_IsEditing_Dirty", function(inst)
		storagekeeper.labelDirty=true
		end)
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
end
