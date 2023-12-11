local config = require 'config.server'
local sharedConfig = require 'config.shared'
local ElectricalBusy
local StartedElectrical = {}
local StartedCabinet = {}
local AlarmFired

lib.callback.register('qb-jewelery:callback:electricalbox', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Amount = exports.qbx_core:GetDutyCountType('leo')

    if ElectricalBusy then exports.qbx_core:Notify(source, Lang:t('notify.busy')) return end
    if exports.ox_inventory:Search(source, 'count', sharedConfig.doorlock.requiredItem) == 0 then exports.qbx_core:Notify(source, Lang:t('notify.noitem', { item = exports.ox_inventory:Items()[sharedConfig.doorlock.RrequiredItem].label }), 'error') return end
    if Amount < config.minimumPolice then if config.notEnoughPoliceNotify then exports.qbx_core:Notify(source, Lang:t('notify.nopolice', { Required = config.minimumPolice }), 'error') end return end
    if #(PlayerCoords - vector3(config.electrical.x, config.electrical.y, config.electrical.z)) > 2 then return end
    ElectricalBusy = true
    StartedElectrical[source] = true
    if sharedConfig.doorlock.loseItemOnUse then Player.Functions.RemoveItem(sharedConfig.doorlock.requiredItem) end
    return true
end)

lib.callback.register('qb-jewelery:callback:cabinet', function(source, ClosestCabinet)
    local PlayerPed = GetPlayerPed(source)
    local PlayerCoords = GetEntityCoords(PlayerPed)
    local AllPlayers = exports.qbx_core:GetQBPlayers()

    if #(PlayerCoords - sharedConfig.cabinets[ClosestCabinet].coords) > 1.8 then return end
    if not config.allowedWeapons[GetSelectedPedWeapon(PlayerPed)] then exports.qbx_core:Notify(source, Lang:t('notify.noweapon')) return end
    if sharedConfig.cabinets[ClosestCabinet].isBusy then exports.qbx_core:Notify(source, Lang:t('notify.busy')) return end
    if sharedConfig.cabinets[ClosestCabinet].isOpened then exports.qbx_core:Notify(source, Lang:t('notify.cabinetdone')) return end

    StartedCabinet[source] = ClosestCabinet
    sharedConfig.cabinets[ClosestCabinet].isBusy = true
    for k in pairs(AllPlayers) do
        if k ~= source then
            if #(GetEntityCoords(GetPlayerPed(k)) - sharedConfig.cabinets[ClosestCabinet].coords) < 20 then
                TriggerClientEvent('qb-jewelery:client:synceffects', k, ClosestCabinet, source)
            end
        end
    end
    return true
end)

local function FireAlarm()
    if AlarmFired then return end

    TriggerEvent('police:server:policeAlert', Lang:t('notify.police'), 1, source)
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', true)
    TriggerClientEvent('qb-jewelery:client:alarm', -1)
    AlarmFired = true
    SetTimeout(config.timeOut, function()
        local DoorEntrance = exports.ox_doorlock:getDoorFromName(sharedConfig.doorlock.name)
        TriggerEvent('ox_doorlock:setState', DoorEntrance.id, 1)
        AlarmFired = false
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', false)
        for i = 1, #sharedConfig.cabinets do
            sharedConfig.cabinets[i].isOpened = false
        end
        TriggerClientEvent('qb-jewelery:client:syncconfig', -1, sharedConfig.cabinets)
    end)
end

RegisterNetEvent('qb-jewelery:server:endcabinet', function()
    local Player = exports.qbx_core:GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestCabinet = StartedCabinet[source]

    if not ClosestCabinet then return end
    if sharedConfig.cabinets[ClosestCabinet].isOpened then return end
    if not sharedConfig.cabinets[ClosestCabinet].isBusy then return end
    if #(PlayerCoords - sharedConfig.cabinets[ClosestCabinet].coords) > 1.8 then return end

    sharedConfig.cabinets[ClosestCabinet].isOpened = true
    sharedConfig.cabinets[ClosestCabinet].isBusy = false
    StartedCabinet[source] = nil
    for _ = 1, math.random(config.reward.minAmount, config.reward.maxAmount) do
        local RandomItem = config.reward.items[math.random(1, #config.reward.items)]
        Player.Functions.AddItem(RandomItem.name, math.random(RandomItem.min, RandomItem.max))
    end
    TriggerClientEvent('qb-jewelery:client:syncconfig', -1, sharedConfig.cabinets)
    FireAlarm()
end)

RegisterNetEvent('qb-jewellery:server:failedhackdoor', function()
    ElectricalBusy = false
    StartedElectrical[source] = false
    exports.qbx_core:Notify(source, 'Hack failed', 'error')
end)

RegisterNetEvent('qb-jewellery:server:succeshackdoor', function()
    local DoorEntrance = exports.ox_doorlock:getDoorFromName(sharedConfig.doorlock.name)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))

    if not ElectricalBusy then return end
    if not StartedElectrical[source] then return end
    if #(PlayerCoords - vector3(config.electrical.x, config.electrical.y, config.electrical.z)) > 2 then return end

    ElectricalBusy = false
    StartedElectrical[source] = false
    exports.qbx_core:Notify(source, 'Hack successful')
    TriggerEvent('ox_doorlock:setState', DoorEntrance.id, 0)
end)

AddEventHandler('playerJoining', function(source)
    TriggerClientEvent('qb-jewelery:client:syncconfig', source, sharedConfig.cabinets)
end)