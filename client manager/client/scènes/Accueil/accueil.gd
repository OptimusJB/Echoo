extends Control

func disconnected():
	Notif.add_notif.call_deferred("CONNECTION_FAILED")
	Client.is_locked = false
	get_tree().change_scene_to_file("res://client/scènes/Connexion/connexion.tscn")
	

func _ready() -> void:
	# on se connecte au disconnected du client
	Client.disconnected.connect(disconnected)

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
