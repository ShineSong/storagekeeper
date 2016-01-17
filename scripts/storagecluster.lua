local foods=require('preparedfoods')
--- Find value in table,return the first index of v
--
-- @param t table
-- @param v values to find
-- @return idx of v in t,if not found return nil.
function table.find(t, v) -- find element index of v in t
  for i, _v in ipairs(t) do
    if _v == v then
      return i
    end
  end
  return nil
end
--- Clear the table
--
-- @param t
function table.clear(t)
    for k,v in pairs(t) do
      t[k] = nil
    end
end
--- Clone table in superficial copy
--
-- @param t
local function cloneTable(t)
  local rtn = {}
  for k, v in pairs(t) do rtn[k] = v end
  return rtn
end

-- Class of StorageCluster
local StorageCluster = Class(function(self)
	self.managedClusters={}
	self.adjaceList={}
	self.groupClusters={}
	self.storageDirty=true
	self.labelDirty=true
	self.searchradius=nil
	self.maxDepth=0
	end)
--constant of the class
StorageCluster.prefabFilter={
	treasurechest={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox"},
	largechest={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox"},
	cellar={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox"},
	dragonflychest={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox"},
	pandoraschest={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox"},
	skullchest={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox"},
	minotaurchest={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox"},
	bluebox={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox"},
	icebox={"icebox","largeicebox","freezer","deep_freezer"},
	largeicebox={"icebox","largeicebox","freezer","deep_freezer"},
	freezer={"icebox","largeicebox","freezer","deep_freezer"},
	deep_freezer={"icebox","largeicebox","freezer","deep_freezer"},
	}
StorageCluster.supportContainer={"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox","icebox","largeicebox","freezer","deep_freezer"}
StorageCluster.BagEnum={Equip=1,Tool=2,ResNatu=3,ResArti=4,ResHunt=5,Food=6,Meal=7,Misc=8,Pipe=9}
StorageCluster.resNatural={
	"cutgrass",
	"cutreeds",
	"log",
	"rocks",
	"flint",
	"goldnugget",
	"twigs",
	"nitre",
	"poop",
	"charcoal",
	"ash",
	"nightmarefuel",
	"boneshard",
	"dug_grass",
	"dug_berrybush",
	"dug_marsh_bush",
	"dug_sapling",
	"fireflies",
	"moonrocknugget",
	"foliage",
	"mandrake",
	}
StorageCluster.resArtificial={
	"rope",
	"cutstone",
	"papyrus",
	"boards",
	"gears",
	"transistor",
	"reviver",
	"bandage",
	"healingsalve",
	"lifeinjector",
	"compass",
	"heatrock",
	"wall_hay_item",
	"wall_wood_item",
	"wall_stone_item",
	"wall_moonrock_item",
	"turf_road",
	"turf_woodfloor",
	"turf_checkerfloor",
	"turf_carpetfloor",
	"turf_dragonfly",
	"waterballoon",
	"bedroll_straw",
	"bernie_inactive",
	}
StorageCluster.resHunt={
	"silk",
	"spidereggsack",
	"spidergland",
	"houndstooth",
	"batwing",
	"livinglog",
	"pigskin",
	"stinger",
	"trunk_summer",
	"trunk_winter",
	"beardhair",
	"bearger_fur",
	"beefalowool",
	"feather_crow",
	"feather_robin",
	"feather_robin_winter",
	"rottenegg",
	"furtuft",
	"goose_feather",
	"honeycomb",
	"lightninggoathorn",
	"deerclops_eyeball",
	"dragon_scales",
	"manrabbit_tail",
	"minotaurhorn",
	"mosquitosack",
	"slurper_pelt",
	"slurtle_shellpieces",
	"steelwool",
	"tentaclespots",
	"thulecite",
	"thulecite_pieces",	
	}

--- Register container to keeper after it init
--
-- @param inst the container
function StorageCluster:registerStorage(inst)
	print("Register Storage ",inst)
	self:buildAdjacencyList(inst)
	self.managedClusters[inst]={
		content={},
		container=inst.components.container,
		payload=0,
		capacity=inst.components.container.numslots,
		}
end

--- Deregister container from keeper
--
-- @param inst the container
function StorageCluster:deregisterStorage(inst)
	self.managedClusters[inst]=nil
end
--- Find nearby container and build adjacency List
--
-- @param inst center container
function StorageCluster:buildAdjacencyList(inst)
	inst:DoTaskInTime(0, function()
	    local x,y,z = inst.Transform:GetWorldPosition()
	    local nearby=TheSim:FindEntities(x,y,z, self.searchradius,{"structure"})
	    local validNearby={}
	    for _,v in pairs(nearby) do
	    	if table.contains(self.prefabFilter[inst.prefab],v.prefab) then
	    		table.insert(validNearby,v)
	    	end
	    end
	    self.adjaceList[inst]=validNearby
    end)
end
--- Rebuild adjacency lists for all managered storage when some are changed
function StorageCluster:rebuildAdjacencyLists()
	print("Rebuild Adjacency Lists")
	table.clear(self.adjaceList)
	for k,_ in pairs(self.managedClusters) do
		self:buildAdjacencyList(k)
	end
end
--- build adjacency set for single container by recursion
--
-- @param inst container
-- @param old_set already in set
-- @return new set in this level
function StorageCluster:buildAdjacencySet(inst,old_set)
	local new_set={}
	old_set=old_set or {}
	for _,v in pairs(self.adjaceList[inst]) do
		if not table.contains(old_set,v) then
			table.insert(new_set,v)
			table.insert(old_set,v)
		end
	end
	for _,v in pairs(new_set) do
		old_set=self:buildAdjacencySet(v,old_set)
	end
	return old_set
end
--- Build Group Clusters table and storage info when it's dirty
function StorageCluster:buildGroupClusters()
	if self.storageDirty then
		print("Rebuild Group Clusters")
		table.clear(self.groupClusters)
		for k,v in pairs(self.managedClusters) do
			local adjset=nil
			-- Find the same group's set
			for _,v in pairs(self.groupClusters) do
				if table.contains(v,k) then
					adjset=v
					break
				end
			end
			self.groupClusters[k]=adjset or self:buildAdjacencySet(k)
		end
		self.storageDirty=false
	end

	local _maxDepth=nil
	for k,v in pairs(self.managedClusters) do
		if k.components.signdata and self.labelDirty then
			local content=v.content
			table.clear(content)
			local label=k.components.signdata.data.str
			local tokens=label:split(',')
			for _,v in ipairs(tokens) do
				if table.containskey(self.BagEnum,v) then
					table.insert(content,self.BagEnum[v])
				end
			end
			_maxDepth=_maxDepth or 0
			local size=table.getn(content)
			_maxDepth= size > _maxDepth and size or _maxDepth
		end
		v.payload=0
	end
	self.maxDepth= _maxDepth or self.maxDepth
	self.labelDirty=false
end

--- Sort and merge through the bag and return the bag
--
-- @param bag
-- @return sorted and merged bag
function StorageCluster:sortBag(bag)
	table.sort(bag,function(a,b)
		return a.name < b.name
	end)
	--merge stackable items
	local k =1
	local totalCount=#bag
	while k < totalCount do
		local a=bag[k]
		local b=bag[k+1]
		if a.name == b.name and a.components.stackable ~= nil then
			if not a.components.stackable:IsFull() then
				local maxstack_a=a.components.stackable.maxsize
				local cur_stacksize_a=a.components.stackable.stacksize
				local cur_stacksize_b=b.components.stackable.stacksize
				local perish_time_a = nil
                local perish_time_b = nil
                if a.components.perishable ~= nil then
                    perish_time_a = a.components.perishable.perishremainingtime
                    perish_time_b = b.components.perishable.perishremainingtime
                end
                local add_a=0
                if cur_stacksize_a + cur_stacksize_b > maxstack_a then
                	add_a=maxstack_a-cur_stacksize_a
                else
                	add_a=cur_stacksize_b
                end
                local new_a=cur_stacksize_a+add_a
                local new_b=cur_stacksize_b-add_a
                a.components.stackable.stacksize=new_a
                b.components.stackable.stacksize=new_b
                if a.components.perishable ~= nil then
                	--average the perish time
                	a.components.perishable.perishremainingtime=(cur_stacksize_a*perish_time_a+add_a*perish_time_b)/new_a
                end
                if new_b == 0 then
                	table.remove(bag,k+1)
                	totalCount=totalCount-1
                else
                	b.components.stackable.stacksize=new_b
            	end
            	if new_a < maxstack_a then
            	--Let next a = current a to fill the stack
            		k=k-1
            	end
			end
		end
		k=k+1
	end
	return bag
end

--- Detect the type of the item,we have some predefined classes.
-- 
-- @param inst item
function StorageCluster:itemType(inst)
	if inst.components.edible and inst.components.perishable then
		if table.containskey(foods,inst.prefab) then
			return self.BagEnum.Meal
		else
			return self.BagEnum.Food
		end
	elseif inst.components.equippable then
		if inst.components.tool then
			return self.BagEnum.Tool -- Tool
		else
			return self.BagEnum.Equip -- Equip
		end
	elseif not inst.prefab then
		print("No prefab?!")
		for k,v in pairs(inst) do
			print(k,v)
		end
		return self.BagEnum.Misc
	elseif table.contains(self.resNatural,inst.prefab) then
		return self.BagEnum.ResNatu -- Natural Resource
	elseif table.contains(self.resArtificial,inst.prefab) then
		return self.BagEnum.ResArti -- Artificial Resource
	elseif table.contains(self.resHunt,inst.prefab) then
		return self.BagEnum.ResHunt -- Hunt Resource
	else
		return self.BagEnum.Misc -- Miscellaneous
	end
end
--- Find the best slot in the storage cluster for an item. 
--
-- @param groupStorages table of container to search for
-- @param integralSlotsCount integral of slotsnum in groupStorages
-- @param index index of your wares
-- @return container,slot
function StorageCluster:getNextAvailableStorageSlot(groupStorages,integralSlotsCount,index)
	for k,v in pairs(integralSlotsCount) do
		if index<v then
			-- can be insert this storage
			local storage=groupStorages[k-1]
			local firstIndex=integralSlotsCount[k-1]
			local slot=index-firstIndex+1
			return storage.components.container,slot
		end
	end
	print("ALL FULL? Pls report this bug.")
end

--- Fill Cluster with current bag
--
-- @param cluster
-- @param bag
function StorageCluster:fillClusterWithBag(cluster,bag)
	for _,v in ipairs(cluster) do
		local _bagsize=table.getn(bag)
		local _storInfo=self.managedClusters[v]
		local _contResid=_storInfo.capacity - _storInfo.payload
		local amountToMove=_contResid > _bagsize and _bagsize or _contResid
		for i=1,amountToMove do
			local itemObj=bag[1]
			v.components.container:GiveItem(itemObj,_storInfo.payload+i)
			table.remove(bag,1)
		end
		_storInfo.payload=_storInfo.payload+amountToMove
	end
end

--- Arrange the items in cluster which contains current opened container
--
-- @param player
function StorageCluster:StorageArrange(player)
	local open_chest=nil
	
	if player == nil then
		return
	end
	
	--find supported container the player opened
	if player.components.inventory ~= nil then
        for k,v in pairs(player.components.inventory.opencontainers) do
        	if table.contains(self.supportContainer,k.prefab) then
        		open_chest=k
        		break
        	end
        end
    end
    
	if open_chest == nil then
		return
	end
	self:buildGroupClusters()
	local groupStorages = cloneTable(self.groupClusters[open_chest])
	if groupStorages == nil then
		return
	end
	-- share lock : not arrange occupied chest
	for i=#groupStorages,1,-1 do
		local v=groupStorages[i].components.container
		if v:IsOpen() and not v:IsOpenedBy(player) then
			table.remove(groupStorages,i)
		else
			v.onopenfn(groupStorages[i])
		end
	end

	local bags={}
	for _,v in pairs(self.BagEnum) do
		bags[v]={}
	end

	for _,s in pairs(groupStorages) do
		local storage=s.components.container
		for _,item in pairs(storage.slots) do
			-- Figure out what kind of item we're dealing with.
			local cid=self:itemType(item)
			table.insert(bags[cid],item)
			-- Detach the item from the player's inventory.
			storage:RemoveItem(item, true)
		end
	end
	for k,v in pairs(bags) do 
		bags[k]=self:sortBag(v)
	end
	-- Fill containers typed with label layer by layer.
	for d=1,self.maxDepth do
		-- Find storages in current depth
		local clusterAtDepth={}
		for _,k in pairs(groupStorages) do
			local v=self.managedClusters[k]
			local t=v.content[d]
			if t and v.payload ~= v.capacity then
				if not table.containskey(clusterAtDepth,t) then clusterAtDepth[t]={} end
				local storageSameType=clusterAtDepth[t]
				table.insert(storageSameType,k)
			end
		end

		-- Fill containers with content type
		for t,c in pairs(clusterAtDepth) do
			--If contains opened chest ,promote it's priority.
			if table.contains(c,open_chest) then
				RemoveByValue(c,open_chest)
				table.insert(c,1,open_chest)
			end	
			self:fillClusterWithBag(c,bags[t])
		end
	end
	
	local residualOfItems=0
	for _,v in ipairs(bags) do
		residualOfItems=residualOfItems+table.getn(v)
	end

	if residualOfItems > 0 then
		-- Fill items remain in bags to spare space. Pipe type with lowest priority
		local spareContainer={}
		for _,k in pairs(groupStorages) do
			local v=self.managedClusters[k]
			if v.payload < v.capacity and table.contains(v.content,self.BagEnum.Pipe) then
				table.insert(spareContainer,k)
			else
				table.insert(spareContainer,1,k)
			end
		end
		--If opened chest without pipe type ,promote it's priority.
		if table.contains(spareContainer,open_chest) and
			not table.contains(self.managedClusters[open_chest].content,self.BagEnum.Pipe) then
			RemoveByValue(spareContainer,open_chest)
			table.insert(spareContainer,1,open_chest)
		end	

		for k,v in pairs(bags) do
			self:fillClusterWithBag(spareContainer,v)
		end
	end

	for _,v in pairs(groupStorages) do
		if v ~= open_chest then
			v.components.container.onclosefn(v)
		end
	end
end

return StorageCluster