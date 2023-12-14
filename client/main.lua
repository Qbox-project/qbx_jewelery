local config = require 'config.client'
local sharedConfig = require 'config.shared'
local isHacking
local isSmashing

local animName
local insideJewelry = false
local electricalBoxEntity

local function createElectricalBox()
    electricalBoxEntity = CreateObject(`tr_prop_tr_elecbox_01a`, config.electrical.x, config.electrical.y, config.electrical.z, false, false, false)
    while not DoesEntityExist(electricalBoxEntity) do
        Wait(0)
    end
    SetEntityHeading(electricalBoxEntity, config.electrical.w)
    if config.useTarget then
        exports.ox_target:addLocalEntity(electricalBoxEntity, {
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
        })
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
        local hasShownText
        while true do
            local playerCoords = GetEntityCoords(cache.ped)
            local electricalCoords = vector3(config.electrical.x, config.electrical.y, config.electrical.z + 1.1)
            local waitTime = 800
            local nearby = false
            if #(playerCoords - electricalCoords) <= 1.5 and not isHacking then
                waitTime = 0
                nearby = true
                if config.useDrawText then
                    if not hasShownText then
                        hasShownText = true
                        lib.showTextUI(Lang:t('text.electrical'), 'left-center')
                    end
                else
                    DrawText3D(Lang:t('text.electrical'), electricalCoords)
                end
                if IsControlJustPressed(0, 38) then
                    lib.callback('qb-jewelery:callback:electricalbox', false, function(CanHack)
                        if not CanHack then return end
                        isHacking = true
                        TriggerEvent('qb-jewelery:client:electricalHandler')
                    end)
                end
            end
            if not nearby and hasShownText then
                hasShownText = false
                lib.hideTextUI()
            end
            Wait(waitTime)
        end
    end)
end

AddEventHandler('qb-jewelery:client:electricalHandler', function()
    local animDictBox = 'anim@scripted@player@mission@tun_control_tower@male@'
    lib.requestAnimDict(animDictBox)
    local playerCoords = GetEntityCoords(cache.ped)
    local box = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 1.5, `tr_prop_tr_elecbox_01a`, false, false, false)
    local enterScene = NetworkCreateSynchronisedScene(config.electrical.x, config.electrical.y, config.electrical.z, 0, 0, config.electrical.w, 2, true, false, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDictBox, 'enter', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(box, enterScene, animDictBox, 'enter_electric_box', 4.0, -8.0, 1)
    local loopingScene = NetworkCreateSynchronisedScene(config.electrical.x, config.electrical.y, config.electrical.z, 0, 0, config.electrical.w, 2, false, true, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, loopingScene, animDictBox, 'loop', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(box, loopingScene, animDictBox, 'loop_electric_box', 4.0, -8.0, 1)
    local leavingScene = NetworkCreateSynchronisedScene(config.electrical.x, config.electrical.y, config.electrical.z, 0, 0, config.electrical.w, 2, true, false, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, leavingScene, animDictBox, 'exit', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(box, leavingScene, animDictBox, 'exit_electric_box', 4.0, -8.0, 1)

    local duration = GetAnimDuration(animDictBox, 'enter')
    NetworkStartSynchronisedScene(enterScene)
    Wait(duration * 1000)
    NetworkStartSynchronisedScene(loopingScene)

    TriggerEvent('ultra-voltlab', math.random(sharedConfig.doorlock.hackTime.min, sharedConfig.doorlock.hackTime.max), function(result, reason)
        Wait(2500)
        NetworkStartSynchronisedScene(leavingScene)
        isHacking = false
        if result == 0 then
            TriggerServerEvent('qb-jewellery:server:failedhackdoor')
        elseif result == 1 then
            TriggerServerEvent('qb-jewellery:server:succeshackdoor')
        elseif result == 2 then
            exports.qbx_core:Notify('Timed out', 'error')
        elseif result == -1 then
            print('Error occured', reason)
        end
        Wait(GetAnimDuration(animDictBox, 'exit') * 1000)
        NetworkStopSynchronisedScene(leavingScene)
    end)
end)

local function startRayFire(coords, rayFire)
    local RayFireObject = GetRayfireMapObject(coords.x, coords.y, coords.z, 1.4, rayFire)
    SetStateOfRayfireMapObject(RayFireObject, 4)
    Wait(100)
    SetStateOfRayfireMapObject(RayFireObject, 6)
end

local function loadParticle()
    lib.requestNamedPtfxAsset('scr_jewelheist')
    UseParticleFxAsset('scr_jewelheist')
end

local function playSmashAudio(coords)
    local soundId = GetSoundId()
    PlaySoundFromCoord(soundId, 'Glass_Smash', coords.x, coords.y, coords.z, '', false, 6.0, false)
    ReleaseSoundId(soundId)
end

local closestVitrine = 1
if config.useTarget then
    for i = 1, #sharedConfig.vitrines do
        exports.ox_target:addBoxZone({
            coords = sharedConfig.vitrines[i].coords,
            size = vec3(1.2, 1.6, 1),
            rotation = sharedConfig.vitrines[i].heading,
            --debug = true,
            options = {
                {
                    icon = 'fas fa-gem',
                    label = Lang:t('text.cabinet'),
                    distance = 0.6,
                    onSelect = function()
                        closestVitrine = i
                        lib.callback('qb-jewelery:callback:cabinet', false, function(CanSmash)
                            if not CanSmash then return end
                            TriggerEvent('qb-jewelery:client:cabinetHandler')
                        end, closestVitrine)
                    end
                }
            }
        })
    end
else
    CreateThread(function()
        local hasShownText
        while true do
            local playerCoords = GetEntityCoords(cache.ped)
            local nearby = false
            local waitTime = 800
            for i = 1, #sharedConfig.vitrines do
                if #(playerCoords - sharedConfig.vitrines[i].coords) < 0.5 then
                    if not closestVitrine then closestVitrine = i
                    elseif #(playerCoords - sharedConfig.vitrines[i].coords) < #(playerCoords - sharedConfig.vitrines[closestVitrine].coords) then closestVitrine = i end
                    waitTime = 0
                    nearby = true
                end
            end
            if nearby and not (isSmashing or sharedConfig.vitrines[closestVitrine].isOpened) then
                if config.useDrawText then
                    if not hasShownText then hasShownText = true lib.showTextUI(Lang:t('text.cabinet'),  'left-center') end
                else
                    DrawText3D(Lang:t('text.cabinet'), sharedConfig.vitrines[closestVitrine].coords)
                end
                if IsControlJustPressed(0, 38) then
                    lib.callback('qb-jewelery:callback:cabinet', false, function(CanSmash)
                        if not CanSmash then return end

                        isSmashing = true
                        if hasShownText then hasShownText = false lib.hideTextUI() end
                        TriggerEvent('qb-jewelery:client:cabinetHandler')
                    end, closestVitrine)
                end
            end
            if not nearby and hasShownText then hasShownText = false lib.hideTextUI() end
            Wait(waitTime)
        end
    end)
end

AddEventHandler('qb-jewelery:client:cabinetHandler', function()
    local animDictCabinet = 'missheist_jewel'
    local animNameSmashFront = {
        'smash_case_tray_b',
        'smash_case_necklace_skull'
    }
    local animNameSmashTop = {
        'smash_case_tray_a',
        'smash_case_d',
        'smash_case_e'
    }
    local playerCoords = GetEntityCoords(cache.ped)
    if not IsWearingGloves() then
        if config.fingerprintDropChance > math.random(0, 100) then
            TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped))
        end
    end
    TaskAchieveHeading(cache.ped, sharedConfig.vitrines[closestVitrine].heading, 1500)
    Wait(1500)
    lib.requestAnimDict(animDictCabinet)
    if sharedConfig.vitrines[closestVitrine].rayFire == 'DES_Jewel_Cab4' then
        animName = animNameSmashFront[math.random(1, #animNameSmashFront)]
        TaskPlayAnim(cache.ped, animDictCabinet, animName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(150)
        startRayFire(playerCoords, sharedConfig.vitrines[closestVitrine].rayFire)
    elseif sharedConfig.vitrines[closestVitrine].rayFire then
        animName = animNameSmashTop[math.random(1, #animNameSmashTop)]
        TaskPlayAnim(cache.ped, animDictCabinet, animName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(300)
        startRayFire(playerCoords, sharedConfig.vitrines[closestVitrine].rayFire)
    else
        animName = animNameSmashTop[math.random(1, #animNameSmashTop)]
        TaskPlayAnim(cache.ped, animDictCabinet, animName, 3.0, 3.0, -1, 2, 0, false, false, false)
        Wait(300)
    end
    loadParticle()
    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(cache.ped), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
    playSmashAudio(playerCoords)
    Wait(GetAnimDuration(animDictCabinet, animName) * 850)
    ClearPedTasks(cache.ped)
    isSmashing = false
    TriggerServerEvent('qb-jewelery:server:endcabinet')
end)

RegisterNetEvent('qb-jewelery:client:synceffects', function(closestVitrine, originalPlayer)
    Wait(1500)
    if sharedConfig.vitrines[closestVitrine].rayFire == 'DES_Jewel_Cab4' then
        Wait(150)
        startRayFire(sharedConfig.vitrines[closestVitrine].coords, sharedConfig.vitrines[closestVitrine].rayFire)
    elseif sharedConfig.vitrines[closestVitrine].rayFire then
        Wait(300)
        startRayFire(sharedConfig.vitrines[closestVitrine].coords, sharedConfig.vitrines[closestVitrine].rayFire)
    end
    loadParticle()
    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(GetPlayerPed(GetPlayerFromServerId(originalPlayer))), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
    playSmashAudio(sharedConfig.vitrines[closestVitrine].coords)
end)

RegisterNetEvent('qb-jewelery:client:syncconfig', function(vitrines)
    sharedConfig.vitrines = vitrines
end)

RegisterNetEvent('qb-jewelery:client:alarm', function()
    PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
    Wait(100)
    StartAlarm('JEWEL_STORE_HEIST_ALARMS', false)
    Wait(config.alarmDuration)
    StopAlarm('JEWEL_STORE_HEIST_ALARMS', true)
end)

lib.zones.sphere({
    coords = vec3(sharedConfig.vitrines[1].coords.x, sharedConfig.vitrines[1].coords.y, sharedConfig.vitrines[1].coords.z),
    radius = 80,
    --debug = true,
    onEnter = function()
        insideJewelry = true
        createElectricalBox()
        CreateThread(function()
            while insideJewelry do
                for i = 1, #sharedConfig.vitrines do
                    if sharedConfig.vitrines[i].isOpened then
                        local rayFire = GetRayfireMapObject(sharedConfig.vitrines[i].coords.x, sharedConfig.vitrines[i].coords.y, sharedConfig.vitrines[i].coords.z, 1.4, sharedConfig.vitrines[i].rayFire)
                        SetStateOfRayfireMapObject(rayFire, 9)
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

AddEventHandler('onResourceStop', function(resouce)
    if resouce ~= cache.resource then return end
    removeElectricalBox()
end)