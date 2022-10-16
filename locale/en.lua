local Translations = {
    text = {
        electrical = '~g~E~w~ - Hack Doorlock',
        cabinet = '~g~E~w~ - Smash Cabinet'
    },
    notify = {
        busy = 'Someone is already on it',
        cabinetdone = 'This one is done already',
        noweapon = 'You don\'t have a weapon in hand',
        noitem = 'You don\'t have an %{item} with you',
        police = 'Vangelico Store robbery reported',
        nopolice = 'Not Enough Police (%{Required} Required)',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
