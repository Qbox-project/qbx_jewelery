local QBCore = exports['qbx-core']:GetCoreObject()
local ElectricalBoxEntity
local ElectricalBusy
local StartedElectrical = {}
local StartedCabinet = {}
local AlarmFired

lib.callback.register('qb-jewelery:callback:electricalbox', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local Amount = QBCore.Functions.GetDutyCountType('leo')

    if ElectricalBusy then QBCore.Functions.Notify(source, Lang:t('notify.busy')) return end
    if not Player.Functions.GetItemByName(Config.Doorlock.RequiredItem) then QBCore.Functions.Notify(source, Lang:t('notify.noitem', { item = QBCore.Shared.Items[Config.Doorlock.RequiredItem].label }), 'error') return end
    if Amount < Config.MinimumCops then if Config.NotEnoughCopsNotify then QBCore.Functions.Notify(source, Lang:t('notify.nopolice', { Required = Config.MinimumCops }), 'error') end return end
    if #(PlayerCoords - vector3(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z)) > 2 then return end

    ElectricalBusy = true
    StartedElectrical[source] = true
    if Config.Doorlock.LoseItemOnUse then Player.Functions.RemoveItem(Config.Doorlock.RequiredItem) end
    return true
end)

lib.callback.register('qb-jewelery:callback:cabinet', function(source, ClosestCabinet)
    local PlayerPed = GetPlayerPed(source)
    local PlayerCoords = GetEntityCoords(PlayerPed)
    local AllPlayers = QBCore.Functions.GetQBPlayers()

    if #(PlayerCoords - Config.Cabinets[ClosestCabinet].coords) > 1.8 then return end
    if not Config.AllowedWeapons[GetSelectedPedWeapon(PlayerPed)] then QBCore.Functions.Notify(source, Lang:t('notify.noweapon')) return end
    if Config.Cabinets[ClosestCabinet].isBusy then QBCore.Functions.Notify(source, Lang:t('notify.busy')) return end
    if Config.Cabinets[ClosestCabinet].isOpened then QBCore.Functions.Notify(source, Lang:t('notify.cabinetdone')) return end

    StartedCabinet[source] = ClosestCabinet
    Config.Cabinets[ClosestCabinet].isBusy = true
    for k in pairs(AllPlayers) do
        if k ~= source then
            if #(GetEntityCoords(GetPlayerPed(k)) - Config.Cabinets[ClosestCabinet].coords) < 20 then
                TriggerClientEvent('qb-jewelery:client:synceffects', k, ClosestCabinet, source)
            end
        end
    end
    return true
end)

local function FireAlarm()
    if AlarmFired then return end

    TriggerEvent('police:server:policeAlert', Lang:t('notify.police'))
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', true)
    TriggerClientEvent('qb-jewelery:client:alarm', -1)
    AlarmFired = true
    SetTimeout(Config.Timeout, function()
        local DoorEntrance = exports.ox_doorlock:getDoorFromName(Config.Doorlock.Name)
        TriggerEvent('ox_doorlock:setState', DoorEntrance.id, 1)
        AlarmFired = false
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', false)
        for i = 1, #Config.Cabinets do
            Config.Cabinets[i].isOpened = false
        end
        TriggerClientEvent('qb-jewelery:client:syncconfig', -1, Config.Cabinets)
    end)
end

RegisterNetEvent('qb-jewelery:server:endcabinet', function()
    local Player = QBCore.Functions.GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestCabinet = StartedCabinet[source]

    if not ClosestCabinet then return end
    if Config.Cabinets[ClosestCabinet].isOpened then return end
    if not Config.Cabinets[ClosestCabinet].isBusy then return end
    if #(PlayerCoords - Config.Cabinets[ClosestCabinet].coords) > 1.8 then return end

    Config.Cabinets[ClosestCabinet].isOpened = true
    Config.Cabinets[ClosestCabinet].isBusy = false
    StartedCabinet[source] = nil
    for _ = 1, math.random(Config.Reward.MinAmount, Config.Reward.MaxAmount) do
        local RandomItem = Config.Reward.Items[math.random(1, #Config.Reward.Items)]
        Player.Functions.AddItem(RandomItem.Name, math.random(RandomItem.Min, RandomItem.Max))
    end
    TriggerClientEvent('qb-jewelery:client:syncconfig', -1, Config.Cabinets)
    FireAlarm()
end)

RegisterNetEvent('qb-jewellery:server:failedhackdoor', function()
    ElectricalBusy = false
    StartedElectrical[source] = false
    QBCore.Functions.Notify(source, 'Hack failed', 'error')
end)

RegisterNetEvent('qb-jewellery:server:succeshackdoor', function()
    local DoorEntrance = exports.ox_doorlock:getDoorFromName(Config.Doorlock.Name)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))

    if not ElectricalBusy then return end
    if not StartedElectrical[source] then return end
    if #(PlayerCoords - vector3(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z)) > 2 then return end

    ElectricalBusy = false
    StartedElectrical[source] = false
    QBCore.Functions.Notify(source, 'Hack successful')
    TriggerEvent('ox_doorlock:setState', DoorEntrance.id, 0)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not DoesEntityExist(ElectricalBoxEntity) then return end
    DeleteEntity(ElectricalBoxEntity)
end)

CreateThread(function()
    Wait(250)
    ElectricalBoxEntity = CreateObject(`tr_prop_tr_elecbox_01a`, Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, true, false, false)
    while ElectricalBoxEntity == 0 do ElectricalBoxEntity = CreateObject(`tr_prop_tr_elecbox_01a`, Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, true, false, false) Wait(3000) end
    while not DoesEntityExist(ElectricalBoxEntity) do Wait(0) end
    Wait(100)
    SetEntityHeading(ElectricalBoxEntity, Config.Electrical.w)
end)

AddEventHandler('playerJoining', function(source)
    TriggerClientEvent('qb-jewelery:client:syncconfig', source, Config.Cabinets)
end)

lib.versionCheck('Qbox-project/qb-jewelery')
