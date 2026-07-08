Locale = {
    ['no_permission']      = "Vous n'avez pas la permission d'effectuer cette action.",
    ['not_enough_cash']    = "Vous n'avez pas assez d'argent liquide.",
    ['not_enough_bank']    = "Vous n'avez pas assez d'argent en banque.",
    ['character_created']  = "Personnage créé avec succès.",
    ['character_deleted']  = "Personnage supprimé.",
    ['max_characters']     = "Vous avez atteint le nombre maximum de personnages.",
    ['whitelist_closed']   = "Ce serveur est en accès restreint (whitelist). Rejoignez notre Discord pour postuler.",
    ['banned']             = "Vous êtes banni de ce serveur.",
    ['db_unreachable']     = "Le serveur rencontre un problème technique. Réessayez dans un instant.",
    ['job_set']            = "Métier mis à jour.",
    ['money_given']        = "Vous avez reçu %s$.",
    ['money_removed']      = "%s$ ont été retirés.",
    ['inventory_full']     = "Votre inventaire est plein.",
    ['item_not_found']     = "Objet introuvable.",
    ['vehicle_impounded']  = "Votre véhicule a été mis en fourrière.",
    ['property_bought']    = "Vous avez acheté ce bien immobilier.",
    ['not_enough_money_property'] = "Vous n'avez pas assez d'argent pour ce bien.",
}

function _T(key, ...)
    local str = Locale[key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
