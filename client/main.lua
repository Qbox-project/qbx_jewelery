local QBCore = exports['qb-core']:GetCoreObject()
local firstAlarm = false
local smashing = false

-- Functions

local function loadParticle()
	if not HasNamedPtfxAssetLoaded("scr_jewelheist") then
		RequestNamedPtfxAsset("scr_jewelheist")
    end
    while not HasNamedPtfxAssetLoaded("scr_jewelheist") do
		Wait(0)
    end
    SetPtfxAssetNextCall("scr_jewelheist")
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(3)
    end
end

local function validWeapon()
    local ped = PlayerPedId()
    local pedWeapon = GetSelectedPedWeapon(ped)

    for k, _ in pairs(Config.WhitelistedWeapons) do
        if pedWeapon == k then
            return true
        end
    end
    return false
end

local function IsWearingHandshoes()
    local armIndex = GetPedDrawableVariation(PlayerPedId(), 3)
    local model = GetEntityModel(PlayerPedId())
    local retval = true
    if model == `mp_m_freemode_01` then
        if Config.MaleNoHandshoes[armIndex] ~= nil and Config.MaleNoHandshoes[armIndex] then
            retval = false
        end
    else
        if Config.FemaleNoHandshoes[armIndex] ~= nil and Config.FemaleNoHandshoes[armIndex] then
            retval = false
        end
    end
    return retval
end

local function smashVitrine(k)
    if not firstAlarm then
        TriggerServerEvent('police:server:policeAlert', 'Suspicious Activity')
        firstAlarm = true
    end

    QBCore.Functions.TriggerCallback('qb-jewellery:server:getCops', function(cops)
        if cops >= Config.RequiredCops then
            local animDict = "missheist_jewel"
            local animName = "smash_case"
            local ped = PlayerPedId()
            local plyCoords = GetOffsetFromEntityInWorldCoords(ped, 0, 0.6, 0)
            local pedWeapon = GetSelectedPedWeapon(ped)
            if math.random(1, 100) <= 80 and not IsWearingHandshoes() then
                TriggerServerEvent("evidence:server:CreateFingerDrop", plyCoords)
            elseif math.random(1, 100) <= 5 and IsWearingHandshoes() then
                TriggerServerEvent("evidence:server:CreateFingerDrop", plyCoords)
                lib.notify({
                    id = 'progressbar',
                    title = Lang:t('error.fingerprints'),
                    duration = 2500,
                    style = {
                        backgroundColor = '#141517',
                        color = '#ffffff'
                    },
                    icon = 'xmark',
                    iconColor = '#C0392B'
                })
            end
            smashing = true
            CreateThread(function()
                while smashing do
                    loadAnimDict(animDict)
                    TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 2, 0, 0, 0, 0 )
                    Wait(500)
                    TriggerServerEvent("InteractSound_SV:PlayOnSource", "breaking_vitrine_glass", 0.25)
                    loadParticle()
                    StartParticleFxLoopedAtCoord("scr_jewel_cab_smash", plyCoords.x, plyCoords.y, plyCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                    Wait(2500)
                end
            end)
            if lib.progressCircle({
                duration = Config.WhitelistedWeapons[pedWeapon]["timeOut"],
                position = 'bottom',
                label = Lang:t('info.progressbar'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = false,
                    combat = true,
                    mouse = false,
                },
            })
            then
                TriggerServerEvent('qb-jewellery:server:vitrineReward', k)
                TriggerServerEvent('qb-jewellery:server:setTimeout')
                TriggerServerEvent('police:server:policeAlert', 'Robbery in progress')
                smashing = false
                TaskPlayAnim(ped, animDict, "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
            else
                TriggerServerEvent('qb-jewellery:server:setVitrineState', "isBusy", false, k)
                smashing = false
                TaskPlayAnim(ped, animDict, "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
            end
            TriggerServerEvent('qb-jewellery:server:setVitrineState', "isBusy", true, k)
        else
            lib.notify({
                id = 'min_police',
                title = Lang:t('error.minimum_police', {value = Config.RequiredCops}),
                duration = 2500,
                style = {
                    backgroundColor = '#141517',
                    color = '#ffffff'
                },
                icon = 'xmark',
                iconColor = '#C0392B'
            })
        end
    end)
end

-- Events

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	QBCore.Functions.TriggerCallback('qb-jewellery:server:getVitrineState', function(result)
		Config.Locations = result
	end)
end)

RegisterNetEvent('qb-jewellery:client:setVitrineState', function(stateType, state, k)
    Config.Locations[k][stateType] = state
end)

-- Threads

CreateThread(function()
    local Dealer = AddBlipForCoord(Config.JewelleryLocation["coords"]["x"], Config.JewelleryLocation["coords"]["y"], Config.JewelleryLocation["coords"]["z"])
    SetBlipSprite (Dealer, 617)
    SetBlipDisplay(Dealer, 4)
    SetBlipScale  (Dealer, 0.7)
    SetBlipAsShortRange(Dealer, true)
    SetBlipColour(Dealer, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Vangelico Jewelry")
    EndTextCommandSetBlipName(Dealer)
end)

local listen = false
local function Listen4Control(case)
    listen = true
    CreateThread(function()
        while listen do
            if IsControlJustPressed(0, 38) then
                listen = false
                if not Config.Locations[case]["isBusy"] and not Config.Locations[case]["isOpened"] then
                    exports['qb-core']:KeyPressed()
                        if validWeapon() then
                            smashVitrine(case)
                            lib.hideTextUI()
                        else
                            lib.notify({
                                id = 'weapon_error',
                                title = Lang:t('error.wrong_weapon'),
                                duration = 2500,
                                style = {
                                    backgroundColor = '#141517',
                                    color = '#ffffff'
                                },
                                icon = 'gun',
                                iconColor = '#C0392B'
                            })
                        end
                    else
                        lib.showTextUI(Lang:t('general.drawtextui_broken'), {
                            position = "top-center",
                            icon = "store-slash",
                            style = {
                                borderRadius = 5,
                                backgroundColor = '#141517',
                                color = 'white'
                            }
                        })
                    end
                end
            Wait(1)
        end
    end)
end

CreateThread(function()
    if Config.UseTarget then
        for k, v in pairs(Config.Locations) do
            exports.ox_target:addBoxZone({
                name = "duty" .. k,
                coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                size = vec3(1, 1, 2),
                rotation = 36,
                debug = false,
                options = {
                    {
                        distance = 1.5,
                        type = "client",
                        icon = "fa-solid fa-bell",
                        label = Lang:t('general.target_label'),
                        onSelect = function()
                            if validWeapon() then
                                smashVitrine(k)
                            else
                                lib.notify({
                                    id = 'weapon_error',
                                    title = Lang:t('error.wrong_weapon'),
                                    duration = 2500,
                                    style = {
                                        backgroundColor = '#141517',
                                        color = '#ffffff'
                                    },
                                    icon = 'gun',
                                    iconColor = '#C0392B'
                                })
                            end
                        end,
                        canInteract = function()
                            if v["isOpened"] or v["isBusy"] then
                                return false
                            end
                            return true
                        end,
                    }
                }
            })
        end
    else
        for k, v in pairs(Config.Locations) do
            local function nearCase()
                lib.showTextUI(Lang:t('general.drawtextui_grab'), {
                    position = "top-center",
                    icon = "circle-info",
                    style = {
                        borderRadius = 2,
                        backgroundColor = '#141517',
                        color = 'white'
                    }
                })
                Listen4Control(k)
            end

            local function awayFromCase()
                listen = false
                lib.hideTextUI()
            end

            lib.zones.box({
                coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                size = vec3(1, 1, 2),
                rotation = 36,
                debug = false,
                onEnter = nearCase,
                onExit = awayFromCase
            })
        end
    end
end)
