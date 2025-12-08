--- @class BN.Inventory
BN.Inventory = {}

local codemInv = 'codem-inventory'
local oxInv = 'ox_inventory'
local qbInv = 'qb-inventory'
local qsInv = 'qs-inventory'

local inventorySystem
local inventoryPath
if GetResourceState(codemInv) == 'started' then
    inventorySystem = 'codem'
    inventoryPath = 'codem-inventory/html/itemimages/'
elseif GetResourceState(oxInv) == 'started' then
    inventorySystem = 'ox'
    inventoryPath = 'ox_inventory/web/images/'
elseif GetResourceState(qbInv) == 'started' then
    inventorySystem = 'qb'
    inventoryPath = 'qb-inventory/html/images/'
elseif GetResourceState(qsInv) == 'started' then
    inventorySystem = 'qs'
    inventoryPath = 'qs-inventory/html/images/'
end

--- Dynamically selects the appropriate function to check if a player has an item.
--- @return function The function to check if a player has an item.
local HasItem = function()
    if inventorySystem == 'codem' then
        return function(player, item, source)
            return exports[codemInv]:GetItemsTotalAmount(source, item)
        end
    elseif inventorySystem == 'ox' then
        return function(player, item, source)
            return exports[oxInv]:Search(source, 'count', item)
        end
    elseif inventorySystem == 'qb' then
        return function(player, item, source)
            local itemAmount = exports[qbInv]:GetItemCount(source, item)
            return itemAmount or 0
        end
    elseif inventorySystem == 'qs' then
        return function(player, item, source)
            local itemData = exports[qsInv]:GetItemByName(source, item)
            if not itemData then return 0 end
            return itemData.amount or itemData.count or 0
        end
    else
        if Framework == 'esx' then
            return function(player, item)
                local itemData = player.getInventoryItem(item)
                if itemData then return itemData.count or itemData.amount else return 0 end
            end
        elseif Framework == 'qb' then
            return function(player, item)
                local itemData = player.Functions.GetItemByName(item)
                if itemData then return itemData.amount or itemData.count else return 0 end
            end
        else
            return function()
                error("Unsupported framework or inventory state for HasItem.")
            end
        end
    end
end

local CheckInventory = HasItem()

--- Dynamically selects the appropriate function to get item data with metadata.
--- @return function The function to get item data from a specific slot.
local GetItemData = function()
    if inventorySystem == 'codem' then
        return function(player, item, source, metadata)
            local inventory = exports[codemInv]:getUserInventory(source)
            if not inventory then return nil end
            
            for _, itemData in pairs(inventory) do
                if itemData.name == item then
                    return itemData
                end
            end
            return nil
        end
    elseif inventorySystem == 'ox' then
        return function(player, item, source, metadata)
            local items = exports[oxInv]:Search(source, 'slots', item)
            if not items or #items == 0 then return nil end
            
            -- If metadata is provided, find matching item
            if metadata then
                for _, itemData in ipairs(items) do
                    local matches = true
                    for key, value in pairs(metadata) do
                        if not itemData.metadata or itemData.metadata[key] ~= value then
                            matches = false
                            break
                        end
                    end
                    if matches then
                        return itemData
                    end
                end
            end
            
            -- Return first item if no metadata filter or no match
            return items[1]
        end
    elseif inventorySystem == 'qb' then
        return function(player, item, source, metadata)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player or not Player.PlayerData.items then return nil end
            
            for _, itemData in pairs(Player.PlayerData.items) do
                if itemData and itemData.name == item then
                    return itemData
                end
            end
            return nil
        end
    elseif inventorySystem == 'qs' then
        return function(player, item, source, metadata)
            local inventory = exports[qsInv]:GetInventory(source)
            if not inventory then return nil end
            
            for _, itemData in pairs(inventory) do
                if itemData and itemData.name == item then
                    return itemData
                end
            end
            return nil
        end
    else
        if Framework == 'esx' then
            return function(player, item)
                local itemData = player.getInventoryItem(item)
                return itemData
            end
        elseif Framework == 'qb' then
            return function(player, item)
                if not player.PlayerData.items then return nil end
                
                for _, itemData in pairs(player.PlayerData.items) do
                    if itemData and itemData.name == item then
                        return itemData
                    end
                end
                return nil
            end
        else
            return function()
                error("Unsupported framework for GetItem.")
                return nil
            end
        end
    end
end

local GetItemFromInventory = GetItemData()

--- Dynamically selects the appropriate function to check if a player can carry an item.
--- @return function The function to check if a player can carry an item.
local CanCarryItem = function()
    if inventorySystem == 'codem' then
        return function(player, item, count, metadata, source)
            return true
        end
    elseif inventorySystem == 'ox' then
        return function(player, item, count, metadata, source)
            return exports[oxInv]:CanCarryItem(source, item, count, metadata)
        end
    elseif inventorySystem == 'qb' then
        return function(player, item, count, slot, source)
            local canAdd = exports[qbInv]:CanAddItem(source, item, count)
            return canAdd
        end
    elseif inventorySystem == 'qs' then
        return function(player, item, count, slot, source)
            return exports[qsInv]:CanCarryItem(source, item, count)
        end
    else
        if Framework == 'esx' then
            return function(player, item, count)
                local currentItem = player.getInventoryItem(item)
                if currentItem then
                    local newWeight = player.getWeight() + (currentItem.weight * count)
                    return newWeight <= player.getMaxWeight()
                end
                return false
            end
        elseif Framework == 'qb' then
            return function(player, item, count)
                local totalWeight = QBCore.Player.GetTotalWeight(player.PlayerData.items)
                if not totalWeight then return false end
                local itemInfo = QBCore.Shared.Items[item:lower()]
                if not itemInfo then return false end
                if (totalWeight + (itemInfo['weight'] * count)) <= 120000 then
                    return true
                end
                return false
            end
        else
            return function()
                error("Unsupported framework for CanCarryItem.")
            end
        end
    end
end

local CanCarry = CanCarryItem()

--- Dynamically selects the appropriate function to add an item to a player's inventory.
--- @return function The function to add an item.
local AddItem = function()
    if inventorySystem == 'codem' then
        return function(player, item, count, metadata, slot, source)
            return exports[codemInv]:AddItem(source, item, count, slot or false, metadata or false)
        end
    elseif inventorySystem == 'ox' then
        return function(player, item, count, metadata, slot, source)
            return exports[oxInv]:AddItem(source, item, count, metadata or false, slot or false)
        end
    elseif inventorySystem == 'qb' then
        return function(player, item, count, metadata, slot, source)
            exports[qbInv]:AddItem(source, item, count, slot or false, metadata or false,'bn-inventory:AddItem')
        end
    elseif inventorySystem == 'qs' then
        return function(player, item, count, metadata, slot, source)
            return exports[qsInv]:AddItem(source, item, count, slot or false, metadata or false)
        end
    else
        if Framework == 'esx' then
            return function(player, item, count, metadata, slot)
                player.addInventoryItem(item, count, metadata, slot)
            end
        elseif Framework == 'qb' then
            return function(player, item, count, metadata, slot, source)
                player.Functions.AddItem(item, count, slot, metadata)
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'add', count)
            end
        else
            return function()
                error("Unsupported framework or inventory state for AddItem.")
            end
        end
    end
end

local AddItemToInventory = AddItem()

--- Dynamically selects the appropriate function to remove an item from a player's inventory.
--- @return function The function to remove an item.
local RemoveItem = function()
    if inventorySystem == 'codem' then
        return function(player, item, count, metadata, slot, source)
            return exports[codemInv]:RemoveItem(source, item, count, slot or false)
        end
    elseif inventorySystem == 'ox' then
        return function(player, item, count, metadata, slot, source)
            return exports[oxInv]:RemoveItem(source, item, count, metadata or false, slot or false)
        end
    elseif inventorySystem == 'qb' then
        return function(player, item, count, metadata, slot, source)
            exports[qbInv]:RemoveItem(source, item, count, slot or false, 'bn-inventory:RemoveItem')
        end
    elseif inventorySystem == 'qs' then
        return function(player, item, count, metadata, slot, source)
            return exports[qsInv]:RemoveItem(source, item, count, slot or false, metadata or false)
        end
    else
        if Framework == 'esx' then
            return function(player, item, count, metadata, slot)
                player.removeInventoryItem(item, count, metadata or false, slot or false)
            end
        elseif Framework == 'qb' then
            return function(player, item, count, slot, metadata, source)
                player.Functions.RemoveItem(item, count, slot, metadata or false)
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "remove", count)
            end
        else
            return function()
                error("RemoveItem function is not supported in the current framework.")
            end
        end
    end
end

local RemoveItemFromInventory = RemoveItem()

--- Dynamically selects the appropriate function to register a usable item.
--- @return function The function to register a usable item.
local RegisterUsableItem = function()
    if inventorySystem == 'ox' then
        return function(item, cb)
            local exportName = 'use' .. item:gsub("^%l", string.upper)
            exports(exportName, function(event, item, inventory, slot, data)
                if event == 'usingItem' then
                    cb(inventory.id, item, inventory, slot, data)
                end
            end)
        end
    elseif inventorySystem == 'qb' then
        return function(item, cb)
            QBCore.Functions.CreateUseableItem(item, cb)
        end
    else
        if Framework == 'esx' then
            return function(item, cb)
                ESX.RegisterUsableItem(item, cb)
            end
        elseif Framework == 'qb' then
            return function(item, cb)
                QBCore.Functions.CreateUseableItem(item, cb)
            end
        else
            return function(item, cb)
                error("RegisterUsableItem function is not supported in the current framework.")
            end
        end
    end
end

local RegisterUsableItemInInventory = RegisterUsableItem()

local RetrieveItems = function()
    local getItemsFunction

    if inventorySystem == 'codem' then
        getItemsFunction = function(source)
            return exports[codemInv]:GetItemList()
        end
    elseif inventorySystem == 'ox' then
        getItemsFunction = function(source)
            return exports[oxInv]:Items()
        end
    elseif inventorySystem == 'qb' then
        getItemsFunction = function(source)
            return QBCore.Shared.Items or {}
        end
    elseif inventorySystem == 'qs' then
        getItemsFunction = function(source)
            return exports[qsInv]:GetItemList()
        end
    elseif Framework == 'qb' then
        getItemsFunction = function(player)
            return QBCore.Shared.Items or {}
        end
    else
        getItemsFunction = function()
            error("RetrieveItems function is not supported in the current framework.")
        end
    end

    -- Function that filters and sorts the items
    return function(source)
        local items = getItemsFunction(source)
        local sortedItems = {}

        -- Extract only name and label
        for itemName, itemData in pairs(items) do
            table.insert(sortedItems, {
                name = itemName,
                label = itemData.label or "Unknown"
            })
        end

        return sortedItems
    end
end

local GetItems = RetrieveItems()

--- Dynamically selects the appropriate function to retrieve a player's inventory.
--- @return function The function to retrieve player inventory.
local GetPlayerInventory = function()
    if inventorySystem == 'codem' then
        return function(source)
            local playerItems = exports[codemInv]:getUserInventory(source)
            local itemQuantities = {}
            local formattedItems = {}
            
            -- First pass: sum up quantities for each item
            for _, itemData in pairs(playerItems) do
                local name = itemData.name
                local quantity = itemData.amount or 0
                
                if itemQuantities[name] then
                    itemQuantities[name] = itemQuantities[name] + quantity
                else
                    itemQuantities[name] = quantity
                end
            end
            
            -- Second pass: create the formatted items list with combined quantities
            for name, quantity in pairs(itemQuantities) do
                table.insert(formattedItems, {
                    name = name,
                    quantity = quantity
                })
            end
            
            return formattedItems
        end
    elseif inventorySystem == 'ox' then
        return function(source)
            local inventory = exports[oxInv]:GetInventory(source)
            local itemQuantities = {}
            local formattedItems = {}
            
            if inventory and inventory.items then
                -- First pass: sum up quantities for each item
                for _, itemData in pairs(inventory.items) do
                    if itemData and itemData.name then
                        local name = itemData.name
                        local quantity = itemData.count or 0
                        
                        if itemQuantities[name] then
                            itemQuantities[name] = itemQuantities[name] + quantity
                        else
                            itemQuantities[name] = quantity
                        end
                    end
                end
                
                -- Second pass: create the formatted items list with combined quantities
                for name, quantity in pairs(itemQuantities) do
                    table.insert(formattedItems, {
                        name = name,
                        quantity = quantity
                    })
                end
            end
            
            return formattedItems
        end
    elseif inventorySystem == 'qb' then
        return function(source)
            local player = QBCore.Functions.GetPlayer(source)
            local itemQuantities = {}
            local formattedItems = {}
            
            if player and player.PlayerData and player.PlayerData.items then
                -- First pass: sum up quantities for each item
                for _, itemData in pairs(player.PlayerData.items) do
                    if itemData and itemData.name then
                        local name = itemData.name
                        local quantity = itemData.amount or 0
                        
                        if itemQuantities[name] then
                            itemQuantities[name] = itemQuantities[name] + quantity
                        else
                            itemQuantities[name] = quantity
                        end
                    end
                end
                
                -- Second pass: create the formatted items list with combined quantities
                for name, quantity in pairs(itemQuantities) do
                    table.insert(formattedItems, {
                        name = name,
                        quantity = quantity
                    })
                end
            end
            
            return formattedItems
        end
    elseif inventorySystem == 'qs' then
        return function(source)
            local playerItems = exports[qsInv]:GetInventory(source)
            local itemQuantities = {}
            local formattedItems = {}
            
            -- First pass: sum up quantities for each item
            for _, itemData in pairs(playerItems) do
                local name = itemData.name
                local quantity = itemData.amount or itemData.count or 0
                
                if itemQuantities[name] then
                    itemQuantities[name] = itemQuantities[name] + quantity
                else
                    itemQuantities[name] = quantity
                end
            end
            
            -- Second pass: create the formatted items list with combined quantities
            for name, quantity in pairs(itemQuantities) do
                table.insert(formattedItems, {
                    name = name,
                    quantity = quantity
                })
            end
            
            return formattedItems
        end
    else
        if Framework == 'esx' then
            return function(source)
                local player = ESX.GetPlayerFromId(source)
                local itemQuantities = {}
                local formattedItems = {}
                
                if player then
                    local inventory = player.getInventory()
                    
                    -- First pass: sum up quantities for each item
                    for _, itemData in pairs(inventory) do
                        if itemData and itemData.count and itemData.count > 0 then
                            local name = itemData.name
                            local quantity = itemData.count
                            
                            if itemQuantities[name] then
                                itemQuantities[name] = itemQuantities[name] + quantity
                            else
                                itemQuantities[name] = quantity
                            end
                        end
                    end
                    
                    -- Second pass: create the formatted items list with combined quantities
                    for name, quantity in pairs(itemQuantities) do
                        table.insert(formattedItems, {
                            name = name,
                            quantity = quantity
                        })
                    end
                end
                
                return formattedItems
            end
        elseif Framework == 'qb' then
            return function(source)
                local player = QBCore.Functions.GetPlayer(source)
                local itemQuantities = {}
                local formattedItems = {}
                
                if player and player.PlayerData and player.PlayerData.items then
                    -- First pass: sum up quantities for each item
                    for _, itemData in pairs(player.PlayerData.items) do
                        if itemData and itemData.name then
                            local name = itemData.name
                            local quantity = itemData.amount or 0
                            
                            if itemQuantities[name] then
                                itemQuantities[name] = itemQuantities[name] + quantity
                            else
                                itemQuantities[name] = quantity
                            end
                        end
                    end
                    
                    -- Second pass: create the formatted items list with combined quantities
                    for name, quantity in pairs(itemQuantities) do
                        table.insert(formattedItems, {
                            name = name,
                            quantity = quantity
                        })
                    end
                end
                
                return formattedItems
            end
        else
            return function()
                error("GetPlayerInventory function is not supported in the current framework.")
                return {}
            end
        end
    end
end

local RetrievePlayerInventory = GetPlayerInventory()

--- Returns the inventory image path in use.
--- @return string The inventory image path.
local function GetInventoryPath()
    return inventoryPath
end

--- Returns the inventory image path in use.
--- @return string The inventory image path.
BN.Inventory.GetInventoryPath = GetInventoryPath

--- Returns the sorted list of items with only `name` and `label`.
--- @return table The sorted list of items.
BN.Inventory.RetrieveItems = function()
    return GetItems()
end

--- Registers a function to be called when a player uses an item.
--- @param item string The item's name.
--- @param cb function The callback function to execute when the item is used.
BN.Inventory.RegisterUsableItem = function(item, cb)
    RegisterUsableItemInInventory(item, cb)
end

--- Returns the amount of a specific item a player has.
--- @param source number The player's server ID.
--- @param item string The item's name.
--- @return number The amount of the specified item the player has.
BN.Inventory.HasItem = function(source, item)
    local player = BN.GetPlayer(source)
    if player == nil then return 0 end
    return CheckInventory(player, item, source)
end

--- Returns the full item data including metadata for a specific item.
--- @param source number The player's server ID.
--- @param item string The item's name.
--- @param metadata table|nil Optional metadata to match specific items (ox_inventory).
--- @return table|nil The item data from the inventory slot including metadata, or nil if not found.
BN.Inventory.GetItem = function(source, item, metadata)
    local player = BN.GetPlayer(source)
    if player == nil then return nil end
    return GetItemFromInventory(player, item, source, metadata)
end

--- Checks if a player can carry an item.
--- @param source number The player's server ID.
--- @param item string The item's name.
--- @param count number The amount of the item to check.
--- @param slot number|nil The inventory slot, if applicable.
--- @return boolean True if the player can carry the item, false otherwise.
BN.Inventory.CanCarry = function(source, item, count, slot)
    local player = BN.GetPlayer(source)
    if player then
        return CanCarry(player, item, count, slot, source)
    end
    return false
end

--- Adds an item to a player's inventory.
--- @param source number The player's server ID.
--- @param item string The item's name.
--- @param count number The amount of the item to add.
--- @param slot number|nil The inventory slot to add the item to, if applicable.
--- @param metadata table|nil Additional metadata for the item, if applicable.
BN.Inventory.AddItem = function(source, item, count, metadata, slot)
    local player = BN.GetPlayer(source)
    if player then
        AddItemToInventory(player, item, count, metadata, slot, source)
    end
end

--- Removes an item from a player's inventory.
--- @param source number The player's server ID.
--- @param item string The item's name.
--- @param count number The amount of the item to remove.
--- @param slot number|nil The inventory slot to remove the item from, if applicable.
--- @param metadata table|nil Additional metadata for the item, if applicable.
BN.Inventory.RemoveItem = function(source, item, count, metadata, slot)
    local player = BN.GetPlayer(source)
    if player then
        RemoveItemFromInventory(player, item, count, metadata, slot, source)
    end
end

--- Returns a player's inventory items with name and quantity.
--- @param source number The player's server ID.
--- @return table A list of player's inventory items, each with name and quantity.
BN.Inventory.GetPlayerInventory = function(source)
    return RetrievePlayerInventory(source)
end

return BN.Inventory
