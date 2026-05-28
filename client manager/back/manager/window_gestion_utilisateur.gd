extends Control
var noeud_utilisateur = load("res://back/manager/Utilisateur/Utilisateur.tscn")

func charger():
	# on charge le bouton de mode de bannissement
	if not FonctionsGlobal.to_int(Settings.get_setting("mode bannissement")) in [0, 1]:
		Notif.add_notif("le mode de bannissement sauvegardé n'est pas valide")
		return
	#print("mode bannissement : ", FonctionsGlobal.to_int(Settings.get_setting("mode bannissement")))
	$"marges/elements/type ban".selected = FonctionsGlobal.to_int(Settings.get_setting("mode bannissement"))
