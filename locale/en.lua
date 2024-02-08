local Translations = {
    text = {
        electrical = '[E] - Hack Doorlock',
        electricalTarget = 'Hack Doorlock',
        cabinet = '[E] - Smash Cabinet'
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
