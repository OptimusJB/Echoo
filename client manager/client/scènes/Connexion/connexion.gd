extends Control

func _ready() -> void:
	# on charge les settings
	Settings.use_json = false
	Settings.load_settings("client")
	
	# on met le content_scale_factor
	get_window().content_scale_factor = Settings.get_setting("echelle")

# fonction à copier coller à chaque racine
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("echelle_down") and get_window().content_scale_factor > 0.25:
		get_window().content_scale_factor -= 0.25
		Notif.add_notif("nouvelle échelle : " + str(get_window().content_scale_factor))
		Settings.set_setting("echelle", get_window().content_scale_factor)
	elif event.is_action_pressed("echelle_up"):
		get_window().content_scale_factor += 0.25
		Notif.add_notif("nouvelle échelle : " + str(get_window().content_scale_factor))
		Settings.set_setting("echelle", get_window().content_scale_factor)
	elif event.is_action_pressed("clear ram"):
		RessourceLoad.clear()
		Notif.add_notif("fichiers stockés en ram supprimés")
