extends Control

var state = "connexion"

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if get_tree().get_nodes_in_group("database")[0].fermer_database():
			print("database fermée")
		else:
			print("échec de la fermeture de la database")
		get_tree().quit()
		
func _ready() -> void:
	get_window().title = "Server Manager"
	get_tree().auto_accept_quit = false	# pour NOTIFICATION_WM_CLOSE_REQUEST
	
	# on charge les settings
	Settings.save_filename = "server_settings.txt"
	Settings.load_settings("server_manager")
	
	# on met le content_scale_factor
	get_window().content_scale_factor = Settings.get_setting("echelle")
	
	# on regarde si la db existe et on change la page si oui (ouvrir_app)
	if get_tree().get_nodes_in_group("database")[0].is_database_exists():
		if get_tree().get_nodes_in_group("database")[0].ouvrir_database():
			ouvrir_app()

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
	
func _on_create_database_pressed() -> void:
	# création de la base de données
	if get_tree().get_nodes_in_group("database")[0].create_database():
		ouvrir_app()
	

func ouvrir_app() -> void:
	state = "app"
	$"creation database".visible = false
	$App.visible = true
	$App.init()
