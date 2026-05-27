extends Control
var close_no_message = false # si true, n'envoie pas le message la notif de déconnexion

func disconnected():
	if not close_no_message:
		Notif.add_notif.call_deferred("CONNECTION_FAILED")
	Client.is_locked = false
	get_tree().change_scene_to_file("res://client/scènes/Connexion/connexion.tscn")

func _ready() -> void:
	# on se connecte au disconnected du client
	Client.disconnected.connect(disconnected)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("echelle_down") and get_window().content_scale_factor > 0.25:
		get_window().content_scale_factor -= 0.25
		Notif.add_notif(tr("NEW_SCALE") + str(get_window().content_scale_factor))
		Settings.set_setting("echelle", get_window().content_scale_factor)
	elif event.is_action_pressed("echelle_up"):
		get_window().content_scale_factor += 0.25
		Notif.add_notif(tr("NEW_SCALE") + str(get_window().content_scale_factor))
		Settings.set_setting("echelle", get_window().content_scale_factor)
	elif event.is_action_pressed("clear ram"):
		RessourceLoad.clear()
		Notif.add_notif(tr("RAM_CLEAR"))

var retour_au_lobby = false
func _on_deconnexion_pressed() -> void:
	#$"retour au lobby".connexion = true
	#get_tree().change_scene_to_file.call_deferred("res://client/scènes/Connexion/connexion.tscn")
	# on n'exécute pas change_scene_to_file ici, car celui-ci retire intantanément tout de l'arbre de scène
	# call_deferred ne marche pas, car celui-ci est exécuté entre _physics_process et _process
	# donc ça peut poser problème pour d'autres noeuds (voir resize_temps.gd avec sa boucle de process_frame)
	retour_au_lobby = true

func _process(_delta: float) -> void:
	if retour_au_lobby:
		close_no_message = true
		Client.socket.close()
		#get_tree().change_scene_to_file.call_deferred("res://client/scènes/Connexion/connexion.tscn")
