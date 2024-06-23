local config = require 'config.client'
local sharedConfig = require 'config.shared'
local isHacking
local isSmashing
local closestVitrine = 1
local animName
local insideJewelry = false
local electricalBoxEntity

local function dropFingerprint()
    if qbx.isWearingGloves() then return end
    if config.fingerprintChance > math.random(0, 100) then
        local coords = GetEntityCoords(cache.ped)
        TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
    end
end

local function createElectricalBox()
    lib.requestModel(`tr_prop_tr_elecbox_01a`)
    electricalBoxEntity = CreateObject(`tr_prop_tr_elecbox_01a`, sharedConfig.electrical.x, sharedConfig.electrical.y, sharedConfig.electrical.z, false, false, false)
    SetModelAsNoLongerNeeded(`tr_prop_tr_elecbox_01a`)
    while not DoesEntityExist(electricalBoxEntity) do
        Wait(0)
    end
    SetEntityHeading(electricalBoxEntity, sharedConfig.electrical.w)
    if config.useTarget then
        exports.ox_target:addLocalEntity(electricalBoxEntity, {
            {
                name = 'qbx_jewelery:electricalBox',
                icon = 'fab fa-usb',
                label = locale('text.electricalTarget'),
                distance = 1.6,
                items = sharedConfig.doorlock.requiredItem,
                onSelect = function()
                    lib.callback('qbx_jewelery:callback:electricalbox', false, function(CanHack)
                        if not CanHack then return end
                        TriggerEvent('qbx_jewelery:client:electricalHandler')
                    end)
                end
            }
        })
    end
end

local function removeElectricalBox()
    if config.useTarget then
        exports.ox_target:removeLocalEntity(electricalBoxEntity, 'qbx_jewelery:electricalBox')
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
            local electricalCoords = vector3(sharedConfig.electrical.x, sharedConfig.electrical.y, sharedConfig.electrical.z + 1.1)
            local waitTime = 800
            local nearby = false
            if #(playerCoords - electricalCoords) <= 1.5 and not isHacking then
                waitTime = 0
                nearby = true
                if config.useDrawText then
                    qbx.drawText3d({text = locale('text.electrical'), coords = electricalCoords})
                elseif not config.useDrawText and not hasShownText then
                    hasShownText = true
                    lib.showTextUI(locale('text.electrical'), {position = 'left-center'})
                end
                if IsControlJustPressed(0, 38) then
                    lib.callback('qbx_jewelery:callback:electricalbox', false, function(CanHack)
                        if not CanHack then return end
                        isHacking = true
                        TriggerEvent('qbx_jewelery:client:electricalHandler')
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

AddEventHandler('qbx_jewelery:client:electricalHandler', function()
    local animDictBox = 'anim@scripted@player@mission@tun_control_tower@male@'
    lib.requestAnimDict(animDictBox)
    local playerCoords = GetEntityCoords(cache.ped)
    local box = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 1.5, `tr_prop_tr_elecbox_01a`, false, false, false)
    local enterScene = NetworkCreateSynchronisedScene(sharedConfig.electrical.x, sharedConfig.electrical.y, sharedConfig.electrical.z, 0, 0, sharedConfig.electrical.w, 2, true, false, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, enterScene, animDictBox, 'enter', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(box, enterScene, animDictBox, 'enter_electric_box', 4.0, -8.0, 1)
    local loopingScene = NetworkCreateSynchronisedScene(sharedConfig.electrical.x, sharedConfig.electrical.y, sharedConfig.electrical.z, 0, 0, sharedConfig.electrical.w, 2, false, true, 1065353216, -1, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, loopingScene, animDictBox, 'loop', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(box, loopingScene, animDictBox, 'loop_electric_box', 4.0, -8.0, 1)
    local leavingScene = NetworkCreateSynchronisedScene(sharedConfig.electrical.x, sharedConfig.electrical.y, sharedConfig.electrical.z, 0, 0, sharedConfig.electrical.w, 2, true, false, 1065353216, -1, 1.0)
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
        if result == 0 then -- Failed
            TriggerServerEvent('qbx_jewelery:server:failedhackdoor')
            exports.qbx_core:Notify(reason, 'error')
        elseif result == 1 then -- Succeeded
            TriggerServerEvent('qbx_jewelery:server:succeshackdoor')
        elseif result == 2 then -- Timed out
            TriggerServerEvent('qbx_jewelery:server:failedhackdoor')
            exports.qbx_core:Notify(reason, 'error')
        elseif result == -1 then -- Some error
            TriggerServerEvent('qbx_jewelery:server:failedhackdoor')
            exports.qbx_core:Notify('Failed hack', 'error')
            print('Error occured', reason)
        end
        Wait(GetAnimDuration(animDictBox, 'exit') * 1000)
        NetworkStopSynchronisedScene(leavingScene)
        RemoveAnimDict(animDictBox)
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
                    label = locale('text.cabinet'),
                    distance = 0.6,
                    onSelect = function()
                        closestVitrine = i
                        lib.callback('qbx_jewelery:callback:cabinet', false, function(CanSmash)
                            if not CanSmash then return end
                            TriggerEvent('qbx_jewelery:client:cabinetHandler')
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
                    qbx.drawText3d({text = locale('text.cabinet'), coords = sharedConfig.vitrines[closestVitrine].coords})
                elseif not config.useDrawText and not hasShownText then
                    hasShownText = true
                    lib.showTextUI(locale('text.cabinet'), {position = 'left-center'})
                end
                if IsControlJustPressed(0, 38) then
                    lib.callback('qbx_jewelery:callback:cabinet', false, function(CanSmash)
                        if not CanSmash then return end

                        isSmashing = true
                        if hasShownText then hasShownText = false lib.hideTextUI() end
                        TriggerEvent('qbx_jewelery:client:cabinetHandler')
                    end, closestVitrine)
                end
            end
            if not nearby and hasShownText then hasShownText = false lib.hideTextUI() end
            Wait(waitTime)
        end
    end)
end

AddEventHandler('qbx_jewelery:client:cabinetHandler', function()
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

    dropFingerprint()

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
    RemoveAnimDict(animDictCabinet)
    loadParticle()
    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(cache.ped), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
    playSmashAudio(playerCoords)
    Wait(GetAnimDuration(animDictCabinet, animName) * 850)
    ClearPedTasks(cache.ped)
    RemoveNamedPtfxAsset('scr_jewelheist')
    isSmashing = false
    TriggerServerEvent('qbx_jewelery:server:endcabinet')
end)

RegisterNetEvent('qbx_jewelery:client:synceffects', function(closestVitrines, originalPlayer)
    closestVitrine = closestVitrines
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
    RemoveNamedPtfxAsset('scr_jewelheist')
end)

RegisterNetEvent('qbx_jewelery:client:syncconfig', function(vitrines)
    sharedConfig.vitrines = vitrines
end)

RegisterNetEvent('qbx_jewelery:client:alarm', function()
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

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    removeElectricalBox()
end)