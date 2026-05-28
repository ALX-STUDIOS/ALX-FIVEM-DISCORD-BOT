local function getPed()
    return PlayerPedId()
end

local function getVehicle()
    return GetVehiclePedIsIn(getPed(), false)
end

local function loadModel(model, timeout)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return nil
    end
    RequestModel(hash)
    local deadline = GetGameTimer() + (timeout or 5000)
    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then return nil end
        Wait(0)
    end
    return hash
end

local function keyboardInput(title, maxLength)
    DisplayOnscreenKeyboard(1, title or 'Input', '', '', '', '', '', maxLength or 60)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        return result and result ~= '' and result or nil
    end
    return nil
end


RegisterNetEvent('alx-discbot:Heal', function(value)
    SetEntityHealth(getPed(), tonumber(value) or 200)
end)

RegisterNetEvent('alx-discbot:Armour', function(value)
    SetPedArmour(getPed(), tonumber(value) or 100)
end)

RegisterNetEvent('alx-discbot:Kill', function()
    SetEntityHealth(getPed(), 0)
end)

RegisterNetEvent('alx-discbot:setcoords', function(x, y, z)
    SetEntityCoords(getPed(), x + 0.0, y + 0.0, z + 0.0, false, false, false, true)
end)

RegisterNetEvent('alx-discbot:Freeze', function()
    FreezeEntityPosition(getPed(), true)
end)

RegisterNetEvent('alx-discbot:UnFreeze', function()
    FreezeEntityPosition(getPed(), false)
end)

RegisterNetEvent('alx-discbot:visible', function()
    SetEntityVisible(getPed(), true, false)
end)

RegisterNetEvent('alx-discbot:invisible', function()
    SetEntityVisible(getPed(), false, false)
end)

RegisterNetEvent('alx-discbot:spawnveh', function(model)
    local name = model
    if not name or name == '' then
        name = keyboardInput('Vehicle name', 60)
    end
    if not name then return end

    local hash = loadModel(name, 5000)
    if not hash then return end

    local ped = getPed()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fx, fy = GetEntityForwardX(ped), GetEntityForwardY(ped)

    local veh = CreateVehicle(hash, coords.x + fx * 5.0, coords.y + fy * 5.0, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleEngineOn(veh, true, true, false)
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('alx-discbot:fixveh', function()
    local veh = getVehicle()
    if not veh or veh == 0 then return end
    SetVehicleFixed(veh)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleUndriveable(veh, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleFuelLevel(veh, 100.0)
end)

RegisterNetEvent('alx-discbot:delveh', function()
    local veh = getVehicle()
    if not veh or veh == 0 then return end
    SetEntityAsMissionEntity(veh, true, true)
    DeleteEntity(veh)
end)



RegisterNetEvent('alx-discbot:tpway', function()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then return end

    local coords = GetBlipInfoIdCoord(blip)
    local ped = getPed()

    for h = 0, 1000, 25 do
        SetPedCoordsKeepVehicle(ped, coords.x, coords.y, h + 0.0)
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, h + 0.0, false)
        if found then
            SetPedCoordsKeepVehicle(ped, coords.x, coords.y, groundZ + 0.0)
            return
        end
        Wait(50)
    end
end)

RegisterNetEvent('alx-discbot:screenshotCL', function(webhookUrl)
    if not webhookUrl or webhookUrl == '' then
        TriggerServerEvent('alx-discbot:ScreenshotSV', 'https://cdn.discordapp.com/embed/avatars/5.png')
        return
    end

    if GetResourceState('screenshot-basic') ~= 'started' then
        TriggerServerEvent('alx-discbot:ScreenshotSV', 'https://cdn.discordapp.com/embed/avatars/5.png')
        return
    end

    exports['screenshot-basic']:requestScreenshotUpload(webhookUrl, 'files[]', function(data)
        if not data or data == '' then return end
        local ok, resp = pcall(json.decode, data)
        if not ok or not resp or not resp.attachments or not resp.attachments[1] then return end
        local url = resp.attachments[1].proxy_url or resp.attachments[1].url
        if url then
            TriggerServerEvent('alx-discbot:ScreenshotSV', url)
        end
    end)
end)
