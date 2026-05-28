Bridge = {}

local ESX = nil
local inventorySystem = nil
local skinSystem = nil

local function resolveESX()
    -- Modern ESX (1.9+): exports
    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if ok and obj then return obj end

    local legacy = nil
    TriggerEvent('esx:getSharedObject', function(o) legacy = o end)
    if legacy then return legacy end

    return nil
end

function Bridge.getESX()
    return ESX
end


Bridge.player = {}

local METHOD_CANDIDATES = {
    identifier = { 'getIdentifier' },
    name       = { 'getName' },
    group      = { 'getGroup' },
    job        = { 'getJob' },
    coords     = { 'getCoords' },
    account    = { 'getAccount' },
    money      = { 'getMoney' },
    setJob     = { 'setJob' },
    addMoney   = { 'addMoney' },
    addAccount = { 'addAccountMoney', 'addAccount' },
    addItem    = { 'addInventoryItem', 'addItem' },
    addWeapon  = { 'addWeapon' },
    kick       = { 'kick', 'drop' },
}

local FIELD_FALLBACKS = {
    identifier = { 'identifier' },
    name       = { 'name', 'playerName' },
    group      = { 'group' },
    job        = { 'job' },
    coords     = { 'coords' },
}

local function candidatesFor(key)
    local override = Config.framework.methods and Config.framework.methods[key]
    if override then
        if type(override) == 'table' then return override end
        return { override }
    end
    return METHOD_CANDIDATES[key] or {}
end

local function resolveFn(xPlayer, key)
    local names = candidatesFor(key)
    for i = 1, #names do
        local fn = xPlayer[names[i]]
        if type(fn) == 'function' then return fn end
    end
    return nil
end

local function resolveField(xPlayer, key)
    local names = FIELD_FALLBACKS[key]
    if not names then return nil end
    for i = 1, #names do
        local v = xPlayer[names[i]]
        if v ~= nil then return v end
    end
    return nil
end

function Bridge.player.identifier(xPlayer)
    local fn = resolveFn(xPlayer, 'identifier')
    if fn then return fn() end
    return resolveField(xPlayer, 'identifier') or 'unknown'
end

function Bridge.player.name(xPlayer)
    local fn = resolveFn(xPlayer, 'name')
    if fn then return fn() end
    return resolveField(xPlayer, 'name') or '?'
end

function Bridge.player.group(xPlayer)
    local fn = resolveFn(xPlayer, 'group')
    if fn then return fn() end
    return resolveField(xPlayer, 'group') or 'user'
end

function Bridge.player.job(xPlayer)
    local job
    local fn = resolveFn(xPlayer, 'job')
    if fn then job = fn() else job = resolveField(xPlayer, 'job') end
    job = job or {}
    return {
        name        = job.name or 'unknown',
        grade       = job.grade or 0,
        grade_label = job.grade_label or job.gradeLabel or tostring(job.grade or 0),
    }
end

function Bridge.player.coords(xPlayer)
    local fn = resolveFn(xPlayer, 'coords')
    if fn then return fn(true) end
    local field = resolveField(xPlayer, 'coords')
    if field then return field end
    if xPlayer.source then
        local ped = GetPlayerPed(xPlayer.source)
        if ped and ped ~= 0 then return GetEntityCoords(ped) end
    end
    return vector3(0.0, 0.0, 0.0)
end


function Bridge.player.accountMoney(xPlayer, accountName)
    local fn = resolveFn(xPlayer, 'account')
    if fn then
        local acc = fn(accountName)
        if type(acc) == 'table' then return acc.money or 0 end
        if type(acc) == 'number' then return acc end
    end
    if accountName == 'money' then
        local moneyFn = resolveFn(xPlayer, 'money')
        if moneyFn then return moneyFn() or 0 end
    end
    return 0
end

function Bridge.player.setJob(xPlayer, job, grade)
    local fn = resolveFn(xPlayer, 'setJob')
    if fn then fn(job, grade) return true end
    return false
end

function Bridge.player.addMoney(xPlayer, amount)
    local fn = resolveFn(xPlayer, 'addMoney')
    if fn then fn(amount) return true end
    return false
end

function Bridge.player.addAccountMoney(xPlayer, accountName, amount)
    local fn = resolveFn(xPlayer, 'addAccount')
    if fn then fn(accountName, amount) return true end
    return false
end

function Bridge.player.addItem(xPlayer, item, count)
    local fn = resolveFn(xPlayer, 'addItem')
    if fn then fn(item, count) return true end
    return false
end

function Bridge.player.addWeapon(xPlayer, weapon, ammo)
    local fn = resolveFn(xPlayer, 'addWeapon')
    if fn then fn(weapon, ammo) return true end
    return false
end

function Bridge.player.kick(xPlayer, reason)
    local fn = resolveFn(xPlayer, 'kick')
    if fn then fn(reason) return true end
    if xPlayer.source then DropPlayer(xPlayer.source, reason) return true end
    return false
end

local function detectInventory()
    local choice = Config.framework.inventory
    if choice ~= 'auto' then return choice end
    if GetResourceState('ox_inventory') == 'started' then return 'ox_inventory' end
    return 'esx'
end

function Bridge.fetchInventory(xPlayer, cb)
    if inventorySystem == 'ox_inventory' then
        local items = exports.ox_inventory:GetInventoryItems(xPlayer.source)
        local lines = {}
        if items then
            for _, item in pairs(items) do
                if item and item.name and (item.count or 0) > 0 then
                    lines[#lines + 1] = ('%s x%d'):format(item.name, item.count)
                end
            end
        end
        cb({ inventory = (#lines > 0) and table.concat(lines, ', ') or 'empty', loadout = nil })
        return
    end

    local identifier = Bridge.player.identifier(xPlayer)
    local invCol  = Config.framework.esxInventoryColumn
    local loadCol = Config.framework.esxLoadoutColumn
    local query = ('SELECT `%s` AS inventory, `%s` AS loadout FROM users WHERE identifier = ?'):format(invCol, loadCol)
    MySQL.query(query, { identifier }, function(rows)
        local row = rows and rows[1] or {}
        cb({ inventory = row.inventory or '{}', loadout = row.loadout or '{}' })
    end)
end

function Bridge.giveItem(xPlayer, item, count)
    if inventorySystem == 'ox_inventory' then
        return exports.ox_inventory:AddItem(xPlayer.source, item, count) and true or false
    end
    return Bridge.player.addItem(xPlayer, item, count)
end

function Bridge.giveWeapon(xPlayer, weapon, ammo)
    if inventorySystem == 'ox_inventory' then
        -- ox_inventory treats weapons as items; ammo is set via metadata.
        return exports.ox_inventory:AddItem(xPlayer.source, weapon, 1, { ammo = ammo }) and true or false
    end
    return Bridge.player.addWeapon(xPlayer, weapon, ammo)
end


local function detectSkin()
    local choice = Config.framework.skin
    if choice ~= 'auto' then return choice end
    if GetResourceState('illenium-appearance') == 'started' then return 'illenium' end
    if GetResourceState('esx_skin') == 'started' then return 'esx_skin' end
    return 'esx_skin'
end

function Bridge.openSkin(src)
    if skinSystem == 'illenium' then
        TriggerClientEvent('illenium-appearance:client:openClothingShopMenu', src)
    elseif skinSystem == 'custom' and Config.framework.customSkinTrigger then
        TriggerClientEvent(Config.framework.customSkinTrigger, src)
    else
        TriggerClientEvent('esx_skin:openSaveableMenu', src)
    end
end

CreateThread(function()
    local deadline = GetGameTimer() + (Config.framework.esxLoadTimeout or 30000)
    while not ESX do
        ESX = resolveESX()
        if ESX then break end
        if GetGameTimer() > deadline then break end
        Wait(500)
    end

    if not ESX then
        Utils.log('error', 'es_extended shared object could not be resolved before timeout.')
        return
    end

    inventorySystem = detectInventory()
    skinSystem = detectSkin()
    Utils.log('ok', ('ESX resolved. inventory=%s skin=%s'):format(inventorySystem, skinSystem))
end)

function Bridge.ready()
    return ESX ~= nil
end

function Bridge.info()
    return {
        esx       = ESX ~= nil,
        inventory = inventorySystem,
        skin      = skinSystem,
    }
end
