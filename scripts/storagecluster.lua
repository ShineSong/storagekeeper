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
	self.managedStorages={}
	self.adjaceList={}
	self.groupClusters={}
	self.directionOfConvey={}
	self.dirty=true
	self.searchradius=nil
	end)
--constant of the class
StorageCluster.prefabFilter={
		treasurechest = {"treasurechest","largechest","cellar"},
		largechest = {"treasurechest","largechest","cellar"},
		cellar = {"treasurechest","largechest","cellar"},
		icebox= {"icebox","largeicebox"},
		largeicebox={"icebox","largeicebox"}
	}
StorageCluster.supportContainer={"treasurechest","largechest","cellar","icebox","largeicebox"}
--- Find nearby container and build adjacency List
--
-- @param inst center container
function StorageCluster:buildAdjacencyList(inst)
	inst:DoTaskInTime(0, function()
        local x,y,z = inst.Transform:GetWorldPosition()
        local nearby=TheSim:FindEntities(x,y,z, self.searchradius)
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
function StorageCluster:reBuildAdjacencyLists()
	table.clear(self.adjaceList)
	for _,v in pairs(self.managedStorages) do
		self:buildAdjacencyList(v)
	end
	self.dirty=true
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
--- Build Group Clusters table when it's dirty
function StorageCluster:buildGroupClusters()
	if self.dirty then
		table.clear(self.groupClusters)
		for _,v in pairs(self.managedStorages) do
			self.groupClusters[v]=self:buildAdjacencySet(v)
		end
		self.dirty=false
	end
end

--- Sort and merge through the bag and return the bag
--
-- @param bag
-- @return sorted and merged bag
function StorageCluster:sortBag(bag)
	table.sort(bag.contents,function(a,b)
		-- Sort by name then value.
		if bag.sortBy == 'name' then
			if a.obj.name ~= b.obj.name then
				return a.obj.name < b.obj.name
			end
			return a.value > b.value

		-- Sort by value then name.
		else
			if a.value ~= b.value then
				return a.value > b.value
			end
			return a.obj.name < b.obj.name
		end
	end)
	--merge stackable items
	local k =1
	local totalCount=#bag.contents
	while k < totalCount do
		local a=bag.contents[k]
		local b=bag.contents[k+1]
		if a.obj.name == b.obj.name and a.obj.components.stackable ~= nil then
			if not a.obj.components.stackable:IsFull() then
				local maxstack_a=a.obj.components.stackable.maxsize
				local cur_stacksize_a=a.obj.components.stackable.stacksize
				local cur_stacksize_b=b.obj.components.stackable.stacksize
				local perish_time_a = nil
                local perish_time_b = nil
                if a.obj.components.perishable ~= nil then
                    perish_time_a = a.obj.components.perishable.perishremainingtime
                    perish_time_b = b.obj.components.perishable.perishremainingtime
                end
                local add_a=0
                if cur_stacksize_a + cur_stacksize_b > maxstack_a then
                	add_a=maxstack_a-cur_stacksize_a
                else
                	add_a=cur_stacksize_b
                end
                local new_a=cur_stacksize_a+add_a
                local new_b=cur_stacksize_b-add_a
                a.obj.components.stackable.stacksize=new_a
                b.obj.components.stackable.stacksize=new_b
                if a.obj.components.perishable ~= nil then
                	--average the perish time
                	a.obj.components.perishable.perishremainingtime=(cur_stacksize_a*perish_time_a+add_a*perish_time_b)/new_a
                end
                if new_b == 0 then
                	table.remove(bag.contents,k+1)
                	totalCount=totalCount-1
                else
                	b.obj.components.stackable.stacksize=new_b
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
--- Does the item provide armour?
--
-- @param inst InventoryItem object
-- @return bool
function StorageCluster:itemIsArmour(inst)
	return inst.components.armor ~= nil
end

--- Is the item a food for the current player?
--
-- @param inst InventoryItem object
-- @return bool
function StorageCluster:itemIsFood(inst)
	local itemIsGear = inst.components.edible and inst.components.edible.foodtype == FOODTYPE.GEARS
	return inst.components.edible and (inst.components.perishable or itemIsGear)
end

--- Is the item a light?
--
-- @param inst InventoryItem object
-- @return bool
function StorageCluster:itemIsLight(inst)
	return inst.components.lighter and inst.components.fueled
end

--- Is the item a priority resource?
-- These items were manually selected from a frequency analysis of recipe components in the game
-- as of 10th March 2015. The idea is that the player will care most about having a quantity of
-- these items (because they are used commonly in item recipes), so let's sort them together.
--
-- @param inst InventoryItem object
-- @return bool
function StorageCluster:itemIsResource(inst)
	-- Highest frequency to lowest fequency
	local items = {
		"Twigs",
		"Nightmare Fuel",
		"Rope",
		"Gold Nugget",
		"Boards",
		"Silk",
		"Papyrus",
		"Cut Grass",
		"Thulecite",
		"Cut Stone",
		"Flint",
		"Log",
		"Living Log",
		"Pig Skin",
		"Thulecite Fragments",
		"Rocks",
		"Nitre",
	}

	for i = 1, #items do
		local keys = {}
		if items[i] == inst.name then
			return true
		end
	end

	return false
end

--- Is the item a tool?
--
-- @param inst InventoryItem object
-- @return bool
function StorageCluster:itemIsTool(inst)
	return inst.components.tool and inst.components.equippable and inst.components.finiteuses
end

--- Is the item a weapon?
--
-- @param inst InventoryItem object
-- @return bool
function StorageCluster:itemIsWeapon(inst)
	return inst.components.weapon ~= nil
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

function StorageCluster:StorageArrange(player)
	local open_chest=nil
	local direction=0 -- 0 : fill opened 1 : empty opened
	
	if player == nil then
		return
	end
	--determine direction
	if self.directionOfConvey[player].firstSort then
		self.directionOfConvey[player].firstSort=false
	else
		self.directionOfConvey[player].direction=1-self.directionOfConvey[player].direction
	end
	direction=self.directionOfConvey[player].direction
	--find supported container that player opened
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
	-- share lock : remove occupied chest
	for i=#groupStorages,1,-1 do
		local v=groupStorages[i].components.container
		if v:IsOpen() and not v:IsOpenedBy(player) then
			table.remove(groupStorages,i)
		end
	end
	if direction == 1 then
		RemoveByValue(groupStorages,open_chest)
		table.insert(groupStorages,open_chest)
	else
		RemoveByValue(groupStorages,open_chest)
		table.insert(groupStorages,1,open_chest)
	end
	local integralSlotsCount={}
	local firstIndex=1
	table.insert(integralSlotsCount,firstIndex)
	for _,v in pairs(groupStorages) do
		if v ~= open_chest then
			v.components.container.onopenfn(v)
		end
		--Partition address space into seperate container
		firstIndex=firstIndex+v.components.container.numslots
		table.insert(integralSlotsCount,firstIndex)
	end

	local armourBag    = { contents = {}, sortBy = 'value', type = 'armour' }
	local foodBag      = { contents = {}, sortBy = 'value', type = 'food' }
	local lightBag     = { contents = {}, sortBy = 'value', type = 'light' }
	local miscBag      = { contents = {}, sortBy = 'name',  type = 'misc' }
	local resourceBag  = { contents = {}, sortBy = 'name',  type = 'resources' }
	local toolBag      = { contents = {}, sortBy = 'name',  type = 'tools' }
	local weaponBag    = { contents = {}, sortBy = 'value', type = 'weapons' }

	for _,s in pairs(groupStorages) do
		local storage=s.components.container
		for _,item in pairs(storage.slots) do
			-- Figure out what kind of item we're dealing with.
			if item then
				local bag  = miscBag
				local sort = 0

				-- Armour (chest and head)
				if self:itemIsArmour(item) then
					bag  = armourBag
					sort = item.components.armor:GetPercent()

				-- Food
				elseif self:itemIsFood(item) then
					bag  = foodBag
					sort = item.components.edible.hungervalue

				-- Light
				elseif self:itemIsLight(item) then
					bag  = lightBag
					sort = item.components.fueled:GetPercent()
				-- Priority resources
				elseif self:itemIsResource(item) then
					bag = resourceBag

				-- Tools
				elseif self:itemIsTool(item) then
					bag  = toolBag
					sort = item.components.finiteuses:GetUses()

				-- Weapons (MUST be below the tools block)
				elseif self:itemIsWeapon(item) then
					bag  = weaponBag
					sort = item.components.weapon.damage
				end


				table.insert(bag.contents, {
					obj   = item,
					value = sort
				})
			end

			-- Detach the item from the player's inventory.
			storage:RemoveItem(item, true)
		end
	end
	
	--[[Sorry,I adjust this Hat]]
	local sortingHat = {
		foodBag,
		resourceBag,
		miscBag,
		lightBag,
		toolBag,
		weaponBag,
		armourBag,
	}


	-- Sort the categorised items.
	local currentIndex=0
	for i = 1, #sortingHat do
		local bag = self:sortBag(sortingHat[i])
		for _, c in ipairs(bag.contents) do
			currentIndex=currentIndex+1
			local itemObj       = c.obj
			-- Put the item in its sorted slot/container.
			local container,slot = self:getNextAvailableStorageSlot(groupStorages,integralSlotsCount,currentIndex)
			container:GiveItem(itemObj,slot)
		end
	end
	for _,v in pairs(groupStorages) do
		if v ~= open_chest then
			v.components.container.onclosefn(v)
		end
	end
end

return StorageCluster