local config = require 'config.client'
local sharedConfig = require 'config.shared'
local AnimDictBox = 'anim@scripted@player@mission@tun_control_tower@male@'
local AnimDictCabinet = 'missheist_jewel'
local IsHacking
local IsSmashing
local ClosestCabinet = 1
local AnimName
local AnimNameSmashTop = {
    'smash_case_tray_a',
    'smash_case_d',
    'smash_case_e'
}
local AnimNameSmashFront = {
    'smash_case_tray_b',
    'smash_case_necklace_skull'
}
local insideJewelry = false
local electricalBoxEntity

local function createElectricalBox()
    electricalBoxEntity = CreateObject(`tr_prop_tr_elecbox_01a`, config.electrical.x, config.electrical.y, config.electrical.z, false, false, false)
    while not DoesEntityExist(electricalBoxEntity) do
        Wait(0)
    end
    SetEntityHeading(electricalBoxEntity, config.electrical.w)
    if config.useTarget then
        local options = {
            {
                name = 'qb-jewelery:electricalBox',
                icon = 'fab fa-usb',
                label = Lang:t('text.electricalTarget'),
                distance = 1.6,
                items = sharedConfig.doorlock.requiredItem,
                onSelect = function()
                    lib.callback('qb-jewelery:callback:electricalbox', false, function(CanHack)
                        if not CanHack then return end
                        TriggerEvent('qb-jewelery:client:electricalHandler')
                    end)
                end
            }
        }
        exports.ox_target:addLocalEntity(electricalBoxEntity, options)
    end
end

local function removeElectricalBox()
    if config.useTarget then
        exports.ox_target:removeLocalEntity(electricalBoxEntity, 'qb-jewelery:electricalBox')
    end
    if electricalBoxEntity ~= nil and DoesEntityExist(electricalBoxEntity) then
        DeleteObject(electricalBoxEntity)
    end
    electricalBoxEntity = nil
end

if not config.useTarget then
    CreateThread(function()
        local HasShownText
        while true do
            local PlayerCoords = GetEntityCoords(cache.ped)
            local ElectricalCoords = vector3(config.electrical.x, config.electrical.y, config.electrical.z + 1.1)
            local WaitTime = 800
            local Nearby = false
            if #(PlayerCoords - ElectricalCoords) <= 1.5 and not IsHacking then
                WaitTime = 0
                Nearby = true
                if config.useDrawText then
                    if not HasShownText then HasShownText = true lib.showTextUI(Lang:t('text.electrical'), 'left-center') end
                else
                    DrawText3D(Lang:t('text.electrical'), ElectricalCoords)
                end
                if IsControlJustPressed(0, 38) then
                    lib.callback('qb-jewelery:callback:electricalbox', false, function(CanHack)
                        if not CanHack then return end

                        IsHacking = true
                        TriggerEvent('qb-jewelery:client:electricalHandler')
                    end)
                end
            end
            if not Nearby and HasShownText then HasShownText = false lib.hideTextUI() end
            Wait(WaitTime)
        end
    end)
end

AddEventHandler('qb-jewelery:client:electricalHandler', function()
    lib.requestAnimDict(AnimDictBox)
    local PlayerCoords = GetEntityCoords(cache.ped)
    local Box = GetClosestObjectOfType(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1.5, `tr_prop_tr_elecbox_01a`, false, false, false)
    local EnterScene = NetworkCreateSynchronisedScene(config.electrical.x, config.electrical.y, config.electrical.z, 0, 0, config.electrical.w, 2, true, false, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, EnterScene, AnimDictBox, 'enter', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(Box, EnterScene, AnimDictBox, 'enter_electric_box', 4.0, -8.0, 1)
    local LoopingScene = NetworkCreateSynchronisedScene(config.electrical.x, config.electrical.y, config.electrical.z, 0, 0, config.electrical.w, 2, false, true, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, LoopingScene, AnimDictBox, 'loop', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(Box, LoopingScene, AnimDictBox, 'loop_electric_box', 4.0, -8.0, 1)
    local LeavingScene = NetworkCreateSynchronisedScene(config.electrical.x, config.electrical.y, config.electrical.z, 0, 0, config.electrical.w, 2, true, false, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, LeavingScene, AnimDictBox, 'exit', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(Box, LeavingScene, AnimDictBox, 'exit_electric_box', 4.0, -8.0, 1)

    NetworkStartSynchronisedScene(EnterScene)
    Wait(GetAnimDuration(AnimDictBox, 'enter') * 1000)
    NetworkStartSynchronisedScene(LoopingScene)

    TriggerEvent('ultra-voltlab', math.random(sharedConfig.doorlock.hackTime.min, sharedConfig.doorlock.hackTime.max), function(result, reason)
        Wait(2500)
        NetworkStartSynchronisedScene(LeavingScene)
        IsHacking = false
        if result == 0 then
            TriggerServerEvent('qb-jewellery:server:failedhackdoor')
        elseif result == 1 then
            TriggerServerEvent('qb-jewellery:server:succeshackdoor')
        elseif result == 2 then
            exports.qbx_core:Notify('Timed out', 'error')
        elseif result == -1 then
            print('Error occured', reason)
        end
        Wait(GetAnimDuration(AnimDictBox, 'exit') * 1000)
        NetworkStopSynchronisedScene(LeavingScene)
    end)
end)

local function StartRayFire(Coords, RayFire)
    local RayFireObject = GetRayfireMapObject(Coords.x, Coords.y, Coords.z, 1.4, RayFire)
    SetStateOfRayfireMapObject(RayFireObject, 4)
    Wait(100)
    SetStateOfRayfireMapObject(RayFireObject, 6)
end

local function LoadParticle()
    lib.requestNamedPtfxAsset('scr_jewelheist')
    UseParticleFxAsset('scr_jewelheist')
end

local function PlaySmashAudio(Coords)
    local SoundId = GetSoundId()
    PlaySoundFromCoord(SoundId, 'Glass_Smash', Coords.x, Coords.y, Coords.z, '', false, 6.0, false)
    ReleaseSoundId(SoundId)
end

if config.useTarget then
    for i = 1, #sharedConfig.cabinets do
        exports.ox_target:addBoxZone({
            coords = sharedConfig.cabinets[i].coords,
            size = vec3(1.2, 1.6, 1),
            rotation = sharedConfig.cabinets[i].heading,
            --debug = true,
            options = {
                {
                    icon = 'fas fa-gem',
                    label = Lang:t('text.cabinet'),
                    distance = 0.6,
                    onSelect = function()
                        ClosestCabinet = i
                        lib.callback('qb-jewelery:callback:cabinet', false, function(CanSmash)
                            if not CanSmash then return end
                            TriggerEvent('qb-jewelery:client:cabinetHandler')
                        end, ClosestCabinet)
                    end
                }
            }
        })
    end
else
    CreateThread(function()
        local HasShownText
        while true do
            local PlayerCoords = GetEntityCoords(cache.ped)
            local Nearby = false
            local WaitTime = 800
            for i = 1, #sharedConfig.cabinets do
                if #(PlayerCoords - sharedConfig.cabinets[i].coords) < 0.5 then
                    if not ClosestCabinet then ClosestCabinet = i
                    elseif #(PlayerCoords - sharedConfig.cabinets[i].coords) < #(PlayerCoords - sharedConfig.cabinets[ClosestCabinet].coords) then ClosestCabinet = i end
                    WaitTime = 0
                    Nearby = true
                end
            end
            if Nearby and not (IsSmashing or sharedConfig.cabinets[ClosestCabinet].isOpened) then
                if config.useDrawText then
                    if not HasShownText then HasShownText = true lib.showTextUI(Lang:t('text.cabinet'),  'left-center') end
                else
                    DrawText3D(Lang:t('text.cabinet'), sharedConfig.cabinets[ClosestCabinet].coords)
                end
                if IsControlJustPressed(0, 38) then
                    lib.callback('qb-jewelery:callback:cabinet', false, function(CanSmash)
                        if not CanSmash then return end

                        IsSmashing = true
                        if HasShownText then HasShownText = false lib.hideTextUI() end
                        TriggerEvent('qb-jewelery:client:cabinetHandler')
                    end, ClosestCabinet)
                end
            end
            if not Nearby and HasShownText then HasShownText = false lib.hideTextUI() end
            Wait(WaitTime)
        end
    end)
end

AddEventHandler('qb-jewelery:client:cabinetHandler', function()
    local PlayerCoords = GetEntityCoords(cache.ped)
    if not IsWearingGloves() then
        if config.fingerprintDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
    end
    TaskAchieveHeading(cache.ped, sharedConfig.cabinets[ClosestCabinet].heading, 1500)
    Wait(1500)
    lib.requestAnimDict(AnimDictCabinet)
    if sharedConfig.cabinets[ClosestCabinet].rayFire == 'DES_Jewel_Cab4' then
        AnimName = AnimNameSmashFront[math.random(1, #AnimNameSmashFront)]
        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(150)
        StartRayFire(PlayerCoords, sharedConfig.cabinets[ClosestCabinet].rayFire)
    elseif sharedConfig.cabinets[ClosestCabinet].rayFire then
        AnimName = AnimNameSmashTop[math.random(1, #AnimNameSmashTop)]
        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(300)
        StartRayFire(PlayerCoords, sharedConfig.cabinets[ClosestCabinet].rayFire)
    else
        AnimName = AnimNameSmashTop[math.random(1, #AnimNameSmashTop)]
        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(300)
    end
    LoadParticle()
    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(cache.ped), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
    PlaySmashAudio(PlayerCoords)
    Wait(GetAnimDuration(AnimDictCabinet, AnimName) * 850)
    ClearPedTasks(cache.ped)
    IsSmashing = false
    TriggerServerEvent('qb-jewelery:server:endcabinet')
end)

RegisterNetEvent('qb-jewelery:client:synceffects', function(ClosestCabinet, OriginalPlayer)
    Wait(1500)
    if sharedConfig.cabinets[ClosestCabinet].rayFire == 'DES_Jewel_Cab4' then
        Wait(150)
        StartRayFire(sharedConfig.cabinets[ClosestCabinet].coords, sharedConfig.cabinets[ClosestCabinet].rayFire)
    elseif sharedConfig.cabinets[ClosestCabinet].rayFire then
        Wait(300)
        StartRayFire(sharedConfig.cabinets[ClosestCabinet].coords, sharedConfig.cabinets[ClosestCabinet].rayFire)
    end
    LoadParticle()
    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(GetPlayerPed(GetPlayerFromServerId(OriginalPlayer))), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
    PlaySmashAudio(sharedConfig.cabinets[ClosestCabinet].coords)
end)

RegisterNetEvent('qb-jewelery:client:syncconfig', function(Cabinets)
    sharedConfig.cabinets = Cabinets
end)

RegisterNetEvent('qb-jewelery:client:alarm', function()
    PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
    Wait(100)
    StartAlarm('JEWEL_STORE_HEIST_ALARMS', false)
    Wait(config.alarmDuration)
    StopAlarm('JEWEL_STORE_HEIST_ALARMS', true)
end)

lib.zones.sphere({
    coords = vec3(sharedConfig.cabinets[1].coords.x, sharedConfig.cabinets[1].coords.y, sharedConfig.cabinets[1].coords.z),
    radius = 80,
    --debug = true,
    onEnter = function()
        insideJewelry = true
        createElectricalBox()
        CreateThread(function()
            
            while insideJewelry do
                for i = 1, #sharedConfig.cabinets do
                    if sharedConfig.cabinets[i].isOpened then
                        local RayFire = GetRayfireMapObject(sharedConfig.cabinets[i].coords.x, sharedConfig.cabinets[i].coords.y, sharedConfig.cabinets[i].coords.z, 1.4, sharedConfig.cabinets[i].rayFire)
                        SetStateOfRayfireMapObject(RayFire, 9)
                    end
                end
                Wait(6000)
            end
        end)
    end,
    onExit = function()
        removeElectricalBox()
        insideJewelry = false
    end,
})

if GetResourceMetadata(GetCurrentResourceName(), 'shared_script', GetNumResourceMetadata(GetCurrentResourceName(), 'shared_script') - 1) == 'configs/kambi.lua' then
    --- Add more functionality later
end

AddEventHandler('onResourceStop', function(res)
    if res ~= cache.resource then return end
    removeElectricalBox()
end)