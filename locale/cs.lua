local Translations = {
    text = {
        electrical = '~g~E~w~ - Pro hackování dveří',
        electricalTarget = 'Hackování dveří',
        cabinet = '~g~E~w~ - Rozbít vytrínu'
    },
    notify = {
        busy = 'Někdo už na něm je',
        cabinetdone = 'Tohle už je hotové',
        noweapon = 'Nemáte zbraň v ruce',
        noitem = 'Nemáte s sebou %{item}',
        police = 'Vangelico Oznámila loupež v obchodě',
        nopolice = 'Nedostatek policistů (%{Required} Požadovaný)',
    }
}

if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end