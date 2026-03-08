extends Control

var state = "connexion"

func _ready() -> void:
	get_window().title = "Server Manager"
	
	# on charge les settings
	Settings.load_settings("manager")
	
	# on met le content_scale_factor
	get_window().content_scale_factor = Settings.get_setting("echelle")
	
	# on regarde si la db existe et on change la page si oui (ouvrir_app)
	if get_tree().get_nodes_in_group("database")[0].is_database_exists():
		get_tree().get_nodes_in_group("database")[0].ouvrir_database()
		ouvrir_app()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("echelle_down"):
		get_window().content_scale_factor -= 0.25
		Settings.set_setting("echelle", get_window().content_scale_factor)
	elif event.is_action_pressed("echelle_up"):
		get_window().content_scale_factor += 0.25
		Settings.set_setting("echelle", get_window().content_scale_factor)

func _on_create_database_pressed() -> void:
	# création de la base de données
	if get_tree().get_nodes_in_group("database")[0].create_database():
		ouvrir_app()
	

func ouvrir_app() -> void:
	state = "app"
	$"creation database".visible = false
	$App.visible = true
