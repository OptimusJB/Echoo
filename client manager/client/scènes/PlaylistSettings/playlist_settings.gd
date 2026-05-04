extends Control
var script_get_ressource = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()

func charger_playlist_settings(nom:String, description:String, image:String):
	$"fond informations/éléments/infos/droite/nom".text = FonctionsGlobal.to_text(nom)
	$"fond informations/éléments/infos/droite/description".text = FonctionsGlobal.to_text(description)
	$"fond informations/éléments/infos/gauche/cache/image".texture = await script_get_ressource.easy_get_image(image)
	visible = true

func _on_fond_decharger_settings() -> void:
	visible = false
