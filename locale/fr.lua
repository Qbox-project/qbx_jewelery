local Translations = {
    text = {
        electrical = '~g~E~w~ - Hacker le vérrou',
        electricalTarget = 'Hacker le vérrou',
        cabinet = '~g~E~w~ - Casser la vitre'
    },
    notify = {
        busy = 'Quelqu\'un le fait déjà',
        cabinetdone = 'Celui là est déjà cassé',
        noweapon = 'Vous n\'avez pas d\'arme en mains',
        noitem = 'Vous n\'avez pas de %{item} avec vous',
        police = 'Braquage de la Bijouterie Vangelico reportée',
        nopolice = 'Pas assez de policiers (%{Required} Requis)',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
