--- @class BN.RadialMenu
BN.RadialMenu = {}

local radialSystem = nil
local registeredMenus = {}
local registeredItems = {}
local menuHandlers = {}

--- Initialize the radial menu system by checking available resources.
local function Initialize()
    local resources = { "ox_lib", "qb-radialmenu" }
    for _, resource in ipairs(resources) do
        if GetResourceState(resource) == 'started' then
            radialSystem = resource
            break
        end
    end

    if not radialSystem then
        return false
    end

    return true
end

Initialize()

--- Register a menu handler function for onSelect callbacks
---@param handlerName string The name of the handler
---@param handlerFunc function The handler function
BN.RadialMenu.RegisterHandler = function(handlerName, handlerFunc)
    menuHandlers[handlerName] = handlerFunc
end

--- Convert BN format items to ox_lib format
---@param items table The items in BN format
---@return table The items in ox_lib format
local function convertToOxLib(items)
    local oxItems = {}
    for _, item in ipairs(items) do
        local oxItem = {
            label = item.label or item.title,
            icon = item.icon,
            menu = item.menu or item.id,
        }
        
        if item.onSelect then
            if type(item.onSelect) == "function" then
                oxItem.onSelect = item.onSelect
            elseif type(item.onSelect) == "string" and menuHandlers[item.onSelect] then
                oxItem.onSelect = menuHandlers[item.onSelect]
            end
        elseif item.event then
            if item.type == "server" then
                oxItem.onSelect = function()
                    TriggerServerEvent(item.event, item.args)
                end
            elseif item.type == "command" then
                oxItem.onSelect = function()
                    ExecuteCommand(item.event)
                end
            else
                oxItem.onSelect = function()
                    TriggerEvent(item.event, item.args)
                end
            end
        end
        
        table.insert(oxItems, oxItem)
    end
    return oxItems
end

--- Convert BN format items to qb-radialmenu format
---@param items table The items in BN format
---@param parentId string|nil The parent menu id
---@return table The items in qb-radialmenu format
local function convertToQBRadial(items, parentId)
    local qbItems = {}
    for i, item in ipairs(items) do
        local qbItem = {
            id = item.id or (parentId and parentId .. "_" .. i) or ("item_" .. i),
            title = item.title or item.label,
            icon = item.icon,
            shouldClose = item.shouldClose ~= false,
        }
        
        if item.items then
            qbItem.items = convertToQBRadial(item.items, qbItem.id)
        elseif item.onSelect then
            if type(item.onSelect) == "function" then
                -- QB radial uses events, so we need to register an event
                local eventName = "bn_radial:" .. qbItem.id
                RegisterNetEvent(eventName, item.onSelect)
                qbItem.type = "client"
                qbItem.event = eventName
            elseif type(item.onSelect) == "string" and menuHandlers[item.onSelect] then
                local eventName = "bn_radial:" .. qbItem.id
                RegisterNetEvent(eventName, function()
                    menuHandlers[item.onSelect](parentId, i)
                end)
                qbItem.type = "client"
                qbItem.event = eventName
            end
        elseif item.event then
            qbItem.type = item.type or "client"
            qbItem.event = item.event
        end
        
        table.insert(qbItems, qbItem)
    end
    return qbItems
end

--- Register a radial menu (sub-menu)
---@param data table Menu data with id and items
BN.RadialMenu.RegisterMenu = function(data)
    if not data.id or not data.items then
        return
    end
    
    registeredMenus[data.id] = data
    
    if radialSystem == "ox_lib" then
        lib.registerRadial({
            id = data.id,
            items = convertToOxLib(data.items)
        })
    end
    -- QB radial handles sub-menus through nested items, registered with AddItem
end

--- Add a radial menu item to the main menu
---@param data table|array Single item or array of items
BN.RadialMenu.AddItem = function(data)
    -- Handle both single item and array of items
    local items = data[1] and data or { data }
    
    for _, item in ipairs(items) do
        if not item.id then
            return
        end
        
        registeredItems[item.id] = item
        
        if radialSystem == "ox_lib" then
            local oxItem = {
                id = item.id,
                label = item.label or item.title,
                icon = item.icon,
                menu = item.menu,
            }
            
            if item.onSelect then
                if type(item.onSelect) == "function" then
                    oxItem.onSelect = item.onSelect
                elseif type(item.onSelect) == "string" and menuHandlers[item.onSelect] then
                    oxItem.onSelect = menuHandlers[item.onSelect]
                end
            elseif item.event then
                if item.type == "server" then
                    oxItem.onSelect = function()
                        TriggerServerEvent(item.event, item.args)
                    end
                elseif item.type == "command" then
                    oxItem.onSelect = function()
                        ExecuteCommand(item.event)
                    end
                else
                    oxItem.onSelect = function()
                        TriggerEvent(item.event, item.args)
                    end
                end
            end
            
            lib.addRadialItem(oxItem)
        elseif radialSystem == "qb-radialmenu" then
            local qbItem = {
                id = item.id,
                title = item.title or item.label,
                icon = item.icon,
                shouldClose = item.shouldClose ~= false,
            }
            
            if item.items then
                qbItem.items = convertToQBRadial(item.items, item.id)
            elseif item.menu and registeredMenus[item.menu] then
                qbItem.items = convertToQBRadial(registeredMenus[item.menu].items, item.menu)
            elseif item.onSelect then
                if type(item.onSelect) == "function" then
                    local eventName = "bn_radial:" .. item.id
                    RegisterNetEvent(eventName, item.onSelect)
                    qbItem.type = "client"
                    qbItem.event = eventName
                elseif type(item.onSelect) == "string" and menuHandlers[item.onSelect] then
                    local eventName = "bn_radial:" .. item.id
                    RegisterNetEvent(eventName, function()
                        menuHandlers[item.onSelect](nil, item.id)
                    end)
                    qbItem.type = "client"
                    qbItem.event = eventName
                end
            elseif item.event then
                qbItem.type = item.type or "client"
                qbItem.event = item.event
            end
            
            exports['qb-radialmenu']:AddOption(qbItem, qbItem.id)
        end
    end
end

--- Remove a radial menu item
---@param id string The id of the item to remove
BN.RadialMenu.RemoveItem = function(id)
    registeredItems[id] = nil
    
    if radialSystem == "ox_lib" then
        lib.removeRadialItem(id)
    elseif radialSystem == "qb-radialmenu" then
        exports['qb-radialmenu']:RemoveOption(id)
    end
end

return BN.RadialMenu