local QBCore = exports['qb-core']:GetCoreObject()
local AnimDictBox = 'anim@scripted@player@mission@tun_control_tower@male@'
local AnimDictCabinet = 'missheist_jewel'
local AnimNameSmashTop = {
    'smash_case_tray_a',
    'smash_case_d',
    'smash_case_e'
}
local AnimNameSmashFront = {
    'smash_case_tray_b',
    'smash_case_necklace_skull'
}

CreateThread(function()
    local IsHacking
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local ElectricalCoords = vector3(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z + 1.1)
        local WaitTime = 800
        if #(PlayerCoords - ElectricalCoords) <= 1.5 and not IsHacking then
            WaitTime = 0
            QBCore.Functions.DrawText3D(ElectricalCoords, Lang:t('text.electrical'))
            if IsControlJustPressed(0, 38) then
                lib.callback('qb-jewelery:callback:electricalbox', false, function(CanHack)
                    if not CanHack then return end

                    IsHacking = true
                    lib.requestAnimDict(AnimDictBox)
                    local Box = GetClosestObjectOfType(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1.5, `tr_prop_tr_elecbox_01a`, false, false, false)
                    local EnterScene = NetworkCreateSynchronisedScene(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, 0, 0, Config.Electrical.w, 2, true, false, 1065353216, -1, 1.0)
                    NetworkAddPedToSynchronisedScene(cache.ped, EnterScene, AnimDictBox, 'enter', 1.5, -4.0, 1, 16, 1148846080, 0)
                    NetworkAddEntityToSynchronisedScene(Box, EnterScene, AnimDictBox, 'enter_electric_box', 4.0, -8.0, 1)
                    local LoopingScene = NetworkCreateSynchronisedScene(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, 0, 0, Config.Electrical.w, 2, false, true, 1065353216, -1, 1.0)
                    NetworkAddPedToSynchronisedScene(cache.ped, LoopingScene, AnimDictBox, 'loop', 1.5, -4.0, 1, 16, 1148846080, 0)
                    NetworkAddEntityToSynchronisedScene(Box, LoopingScene, AnimDictBox, 'loop_electric_box', 4.0, -8.0, 1)
                    local LeavingScene = NetworkCreateSynchronisedScene(Config.Electrical.x, Config.Electrical.y, Config.Electrical.z, 0, 0, Config.Electrical.w, 2, true, false, 1065353216, -1, 1.0)
                    NetworkAddPedToSynchronisedScene(cache.ped, LeavingScene, AnimDictBox, 'exit', 1.5, -4.0, 1, 16, 1148846080, 0)
                    NetworkAddEntityToSynchronisedScene(Box, LeavingScene, AnimDictBox, 'exit_electric_box', 4.0, -8.0, 1)

                    NetworkStartSynchronisedScene(EnterScene)
                    Wait(GetAnimDuration(AnimDictBox, 'enter') * 1000)
                    NetworkStartSynchronisedScene(LoopingScene)

                    TriggerEvent('ultra-voltlab', math.random(Config.Doorlock.HackTime.Min, Config.Doorlock.HackTime.Max), function(result, reason)
                        Wait(2500)
                        NetworkStartSynchronisedScene(LeavingScene)
                        IsHacking = false
                        if result == 0 then
                            TriggerServerEvent('qb-jewellery:server:failedhackdoor')
                        elseif result == 1 then
                            TriggerServerEvent('qb-jewellery:server:succeshackdoor')
                        elseif result == 2 then
                            QBCore.Functions.Notify('Timed out', 'error')
                        elseif result == -1 then
                            print('Error occured', reason)
                        end
                        Wait(GetAnimDuration(AnimDictBox, 'exit') * 1000)
                        NetworkStopSynchronisedScene(LeavingScene)
                    end)
                end)
            end
        end
        Wait(WaitTime)
    end
end)

local function StartRayFire(Coords, RayFire)
    local RayFire = GetRayfireMapObject(Coords.x, Coords.y, Coords.z, 1.4, RayFire)
    SetStateOfRayfireMapObject(RayFire, 4)
    Wait(100)
    SetStateOfRayfireMapObject(RayFire, 6)
end

local function LoadParticle()
    if not HasNamedPtfxAssetLoaded('scr_jewelheist') then
        RequestNamedPtfxAsset('scr_jewelheist')
        while not HasNamedPtfxAssetLoaded('scr_jewelheist') do Wait(0) end
    end
    UseParticleFxAsset('scr_jewelheist')
end

local function PlaySmashAudio(Coords)
    local SoundId = GetSoundId()
    PlaySoundFromCoord(SoundId, 'Glass_Smash', Coords.x, Coords.y, Coords.z, '', false, 6.0, false)
    ReleaseSoundId(SoundId)
end

CreateThread(function()
    local ClosestCabinet, IsSmashing, AnimName = 1, nil, nil
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local Nearby = false
        local WaitTime = 800
        for i = 1, #Config.Cabinets do
            if #(PlayerCoords - Config.Cabinets[i].coords) < 0.5 then
                if not ClosestCabinet then ClosestCabinet = i
                elseif #(PlayerCoords - Config.Cabinets[i].coords) < #(PlayerCoords - Config.Cabinets[ClosestCabinet].coords) then ClosestCabinet = i end
                WaitTime = 0
                Nearby = true
            end
        end
        if Nearby and not (IsSmashing or Config.Cabinets[ClosestCabinet].isOpened) then
            QBCore.Functions.DrawText3D(Config.Cabinets[ClosestCabinet].coords, Lang:t('text.cabinet'))
            if IsControlJustPressed(0, 38) then
                lib.callback('qb-jewelery:callback:cabinet', false, function(CanSmash)
                    if not CanSmash then return end

                    IsSmashing = true
                    if not QBCore.Functions.IsWearingGloves() then
                        if Config.FingerDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
                    end
                    TaskAchieveHeading(cache.ped, Config.Cabinets[ClosestCabinet].heading, 1500)
                    Wait(1500)
                    lib.requestAnimDict(AnimDictCabinet)
                    if Config.Cabinets[ClosestCabinet].rayFire == 'DES_Jewel_Cab4' then
                        AnimName = AnimNameSmashFront[math.random(1, #AnimNameSmashFront)]
                        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
                        Wait(150)
                        StartRayFire(PlayerCoords, Config.Cabinets[ClosestCabinet].rayFire)
                    elseif Config.Cabinets[ClosestCabinet].rayFire then
                        AnimName = AnimNameSmashTop[math.random(1, #AnimNameSmashTop)]
                        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
                        Wait(300)
                        StartRayFire(PlayerCoords, Config.Cabinets[ClosestCabinet].rayFire)
                    else
                        AnimName = AnimNameSmashTop[math.random(1, #AnimNameSmashTop)]
                        TaskPlayAnim(cache.ped, AnimDictCabinet, AnimName, 3.0, 3.0, -1, 2, 0, false, false, false)
                    end
                    LoadParticle()
                    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(cache.ped), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
                    PlaySmashAudio(PlayerCoords)
                    Wait(GetAnimDuration(AnimDictCabinet, AnimName) * 850)
                    ClearPedTasks(cache.ped)
                    TriggerServerEvent('qb-jewelery:server:endcabinet')
                    IsSmashing = false
                end, ClosestCabinet)
            end
        end
        Wait(WaitTime)
    end
end)

RegisterNetEvent('qb-jewelery:client:synceffects', function(ClosestCabinet, OriginalPlayer)
    Wait(1500)
    if Config.Cabinets[ClosestCabinet].rayFire == 'DES_Jewel_Cab4' then
        Wait(150)
        StartRayFire(Config.Cabinets[ClosestCabinet].coords, Config.Cabinets[ClosestCabinet].rayFire)
    elseif Config.Cabinets[ClosestCabinet].rayFire then
        Wait(300)
        StartRayFire(Config.Cabinets[ClosestCabinet].coords, Config.Cabinets[ClosestCabinet].rayFire)
    end
    LoadParticle()
    StartNetworkedParticleFxNonLoopedOnEntity('scr_jewel_cab_smash', GetCurrentPedWeaponEntityIndex(GetPlayerPed(GetPlayerFromServerId(OriginalPlayer))), 0, 0, 0, 0, 0, 0, 1.6, false, false, false)
    PlaySmashAudio(Config.Cabinets[ClosestCabinet].coords)
end)

RegisterNetEvent('qb-jewelery:client:syncconfig', function(Cabinets)
    Config.Cabinets = Cabinets
end)

RegisterNetEvent('qb-jewelery:client:alarm', function()
    PrepareAlarm('JEWEL_STORE_HEIST_ALARMS')
    StartAlarm('JEWEL_STORE_HEIST_ALARMS', false)
    Wait(120000)
    StopAlarm('JEWEL_STORE_HEIST_ALARMS', true)
end)

CreateThread(function()
    while true do
        if #(GetEntityCoords(cache.ped) - Config.Cabinets[1].coords) < 50 then
            for i = 1, #Config.Cabinets do
                if Config.Cabinets[i].isOpened then
                    local RayFire = GetRayfireMapObject(Config.Cabinets[i].coords.x, Config.Cabinets[i].coords.y, Config.Cabinets[i].coords.z, 1.4, Config.Cabinets[i].rayFire)
                    SetStateOfRayfireMapObject(RayFire, 9)
                end
            end
        end
        Wait(6000)
    end
end)
