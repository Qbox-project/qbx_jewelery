local config = require 'config.server'
local sharedConfig = require 'config.shared'
local electricalBusy
local startedElectrical = {}
local startedVitrine = {}
local alarmFired
local ITEMS = exports.ox_inventory:Items()

lib.callback.register('qbx_jewelery:callback:electricalbox', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local amount = exports.qbx_core:GetDutyCountType('leo')

    if electricalBusy then
        exports.qbx_core:Notify(source, locale('notify.busy'))
        return
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

    electricalBusy = true
    startedElectrical[source] = true

    if sharedConfig.doorlock.loseItemOnUse then
        player.Functions.RemoveItem(sharedConfig.doorlock.requiredItem, 1)
    end

    return true
end)

lib.callback.register('qbx_jewelery:callback:cabinet', function(source, closestVitrine)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local allPlayers = exports.qbx_core:GetQBPlayers()

    if #(playerCoords - sharedConfig.vitrines[closestVitrine].coords) > 1.8 then return end

    if not config.allowedWeapons[GetSelectedPedWeapon(playerPed)] then
        exports.qbx_core:Notify(source, locale('notify.noweapon'))
        return
    end

    if sharedConfig.vitrines[closestVitrine].isBusy then
        exports.qbx_core:Notify(source, locale('notify.busy'))
        return
    end

    if sharedConfig.vitrines[closestVitrine].isOpened then
        exports.qbx_core:Notify(source, locale('notify.cabinetdone'))
        return
    end

    startedVitrine[source] = closestVitrine
    sharedConfig.vitrines[closestVitrine].isBusy = true
    for k in pairs(allPlayers) do
        if k ~= source then
            if #(GetEntityCoords(GetPlayerPed(k)) - sharedConfig.vitrines[closestVitrine].coords) < 20 then
                TriggerClientEvent('qbx_jewelery:client:synceffects', k, closestVitrine, source)
            end
        end
    end
    return true
end)

local function fireAlarm()
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
        end

        TriggerClientEvent('qbx_jewelery:client:syncconfig', -1, sharedConfig.vitrines)
    end)
end

RegisterNetEvent('qbx_jewelery:server:endcabinet', function()
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local closestVitrine = startedVitrine[source]

    if not closestVitrine then return end
    if sharedConfig.vitrines[closestVitrine].isOpened then return end
    if not sharedConfig.vitrines[closestVitrine].isBusy then return end
    if #(playerCoords - sharedConfig.vitrines[closestVitrine].coords) > 1.8 then return end

    sharedConfig.vitrines[closestVitrine].isOpened = true
    sharedConfig.vitrines[closestVitrine].isBusy = false
    startedVitrine[source] = nil

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
    fireAlarm()
end)

RegisterNetEvent('qbx_jewelery:server:failedhackdoor', function()
    electricalBusy = false
    startedElectrical[source] = false
end)

RegisterNetEvent('qbx_jewelery:server:succeshackdoor', function()
    local doorEntrance = exports.ox_doorlock:getDoorFromName(sharedConfig.doorlock.name)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))

    if not electricalBusy then return end
    if not startedElectrical[source] then return end
    if #(playerCoords - vector3(sharedConfig.electrical.x, sharedConfig.electrical.y, sharedConfig.electrical.z)) > 2 then return end

    electricalBusy = false
    startedElectrical[source] = false
    exports.qbx_core:Notify(source, 'Hack successful')
    TriggerEvent('ox_doorlock:setState', doorEntrance.id, 0)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    TriggerClientEvent('qbx_jewelery:client:syncconfig', source, sharedConfig.vitrines)
end)
