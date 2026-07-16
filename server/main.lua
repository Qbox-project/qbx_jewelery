local config = require 'config.server'
local sharedConfig = require 'config.shared'
local electricalBusy
local startedElectrical = {}
local startedVitrine = {}
local vitrineOwners = {}
local alarmFired
local ITEMS = exports.ox_inventory:Items()
local ELECTRICAL_MIN_DURATION = 5000
local ELECTRICAL_TIMEOUT = 90000
local VITRINE_MIN_DURATION = 2500
local VITRINE_TIMEOUT = 15000

---@param startedAt number
---@param timeout number
---@return boolean
local function isExpired(startedAt, timeout)
    return GetGameTimer() - startedAt > timeout
end

---@param source number
local function releaseVitrine(source)
    local session = startedVitrine[source]
    if not session then return end

    local vitrine = sharedConfig.vitrines[session.index]
    if vitrine then
        vitrine.isBusy = false
    end
    vitrineOwners[session.index] = nil
    startedVitrine[source] = nil
end

lib.callback.register('qbx_jewelery:callback:electricalbox', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local amount = exports.qbx_core:GetDutyCountType('leo')

    if electricalBusy then
        local session = startedElectrical[electricalBusy]
        if session and not isExpired(session.startedAt, ELECTRICAL_TIMEOUT) then
            exports.qbx_core:Notify(source, locale('notify.busy'))
            return
        end

        startedElectrical[electricalBusy] = nil
        electricalBusy = nil
    end

    if exports.ox_inventory:Search(source, 'count', sharedConfig.doorlock.requiredItem) == 0 then
        exports.qbx_core:Notify(source, locale('notify.noitem', ITEMS[sharedConfig.doorlock.requiredItem].label), 'error')
        return
    end
    if amount < config.minimumPolice then
        if config.notEnoughPoliceNotify then
            exports.qbx_core:Notify(source, locale('notify.nopolice', config.minimumPolice), 'error')
        end
        return
    end

    if #(playerCoords - vector3(sharedConfig.electrical.x, sharedConfig.electrical.y, sharedConfig.electrical.z)) > 2 then return end

    electricalBusy = source
    startedElectrical[source] = { startedAt = GetGameTimer() }

    if sharedConfig.doorlock.loseItemOnUse then
        if not player.Functions.RemoveItem(sharedConfig.doorlock.requiredItem, 1) then
            electricalBusy = nil
            startedElectrical[source] = nil
            return
        end
    end

    return true
end)

lib.callback.register('qbx_jewelery:callback:cabinet', function(source, closestVitrine)
    if type(closestVitrine) ~= 'number' or closestVitrine % 1 ~= 0 then return end

    local vitrine = sharedConfig.vitrines[closestVitrine]
    if not vitrine then return end

    local playerPed = GetPlayerPed(source)
    if playerPed <= 0 then return end

    local playerCoords = GetEntityCoords(playerPed)
    local allPlayers = exports.qbx_core:GetQBPlayers()

    if #(playerCoords - vitrine.coords) > 1.8 then return end

    if not config.allowedWeapons[GetSelectedPedWeapon(playerPed)] then
        exports.qbx_core:Notify(source, locale('notify.noweapon'))
        return
    end

    if vitrine.isBusy then
        local owner = vitrineOwners[closestVitrine]
        local session = owner and startedVitrine[owner]
        if session and not isExpired(session.startedAt, VITRINE_TIMEOUT) then
            exports.qbx_core:Notify(source, locale('notify.busy'))
            return
        end

        if owner then
            releaseVitrine(owner)
        else
            vitrine.isBusy = false
        end
    end

    if vitrine.isOpened then
        exports.qbx_core:Notify(source, locale('notify.cabinetdone'))
        return
    end

    if startedVitrine[source] then return end

    startedVitrine[source] = {
        index = closestVitrine,
        startedAt = GetGameTimer(),
    }
    vitrineOwners[closestVitrine] = source
    vitrine.isBusy = true
    for k in pairs(allPlayers) do
        if k ~= source then
            if #(GetEntityCoords(GetPlayerPed(k)) - vitrine.coords) < 20 then
                TriggerClientEvent('qbx_jewelery:client:synceffects', k, closestVitrine, source)
            end
        end
    end
    return true
end)

---@param source number
local function fireAlarm(source)
    if alarmFired then return end

    TriggerEvent('police:server:policeAlert', locale('notify.police'), 1, source)
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', true)
    TriggerClientEvent('qbx_jewelery:client:alarm', -1)
    alarmFired = true

    SetTimeout(config.timeOut, function()
        local doorEntrance = exports.ox_doorlock:getDoorFromName(sharedConfig.doorlock.name)
        TriggerEvent('ox_doorlock:setState', doorEntrance.id, 1)
        alarmFired = false
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', false)

        for i = 1, #sharedConfig.vitrines do
            sharedConfig.vitrines[i].isOpened = false
            sharedConfig.vitrines[i].isBusy = false
            vitrineOwners[i] = nil
        end
        for playerId in pairs(startedVitrine) do
            startedVitrine[playerId] = nil
        end

        TriggerClientEvent('qbx_jewelery:client:syncconfig', -1, sharedConfig.vitrines)
    end)
end

RegisterNetEvent('qbx_jewelery:server:endcabinet', function()
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local session = startedVitrine[source]
    if not session then return end

    local closestVitrine = session.index
    local vitrine = sharedConfig.vitrines[closestVitrine]
    local elapsed = GetGameTimer() - session.startedAt
    if not vitrine or vitrineOwners[closestVitrine] ~= source then return end
    if elapsed < VITRINE_MIN_DURATION or elapsed > VITRINE_TIMEOUT then
        releaseVitrine(source)
        return
    end
    if vitrine.isOpened or not vitrine.isBusy then return end
    if #(playerCoords - vitrine.coords) > 1.8 then
        releaseVitrine(source)
        return
    end

    vitrine.isOpened = true
    releaseVitrine(source)

    local customDropItems = {}
    for _ = 1, math.random(config.reward.minAmount, config.reward.maxAmount) do
        local RandomItem = config.reward.items[math.random(1, #config.reward.items)]
        local quantity = math.random(RandomItem.min, RandomItem.max)

        if exports.ox_inventory:CanCarryItem(source, RandomItem.name, quantity) then
            exports.ox_inventory:AddItem(source, RandomItem.name, quantity)
        else
            customDropItems[#customDropItems+1] = {RandomItem.name, quantity}
        end
    end

    if #customDropItems > 0 then
        exports.ox_inventory:CustomDrop('jewelery', customDropItems, playerCoords)
        exports.qbx_core:Notify(source, locale('notify.reward_dropped'), 'warning')
    end

    TriggerClientEvent('qbx_jewelery:client:syncconfig', -1, sharedConfig.vitrines)
    fireAlarm(source)
end)

RegisterNetEvent('qbx_jewelery:server:failedhackdoor', function()
    if electricalBusy ~= source or not startedElectrical[source] then return end

    electricalBusy = nil
    startedElectrical[source] = nil
end)

RegisterNetEvent('qbx_jewelery:server:succeshackdoor', function()
    local session = startedElectrical[source]
    if electricalBusy ~= source or not session then return end

    local doorEntrance = exports.ox_doorlock:getDoorFromName(sharedConfig.doorlock.name)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local elapsed = GetGameTimer() - session.startedAt

    if elapsed < ELECTRICAL_MIN_DURATION or elapsed > ELECTRICAL_TIMEOUT then return end
    if #(playerCoords - vector3(sharedConfig.electrical.x, sharedConfig.electrical.y, sharedConfig.electrical.z)) > 2 then return end
    if not doorEntrance then return end

    electricalBusy = nil
    startedElectrical[source] = nil
    exports.qbx_core:Notify(source, 'Hack successful')
    TriggerEvent('ox_doorlock:setState', doorEntrance.id, 0)
end)

AddEventHandler('playerDropped', function()
    if electricalBusy == source then
        electricalBusy = nil
        startedElectrical[source] = nil
    end
    releaseVitrine(source)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    TriggerClientEvent('qbx_jewelery:client:syncconfig', source, sharedConfig.vitrines)
end)
