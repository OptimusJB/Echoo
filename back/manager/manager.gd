extends Control
signal create_database
signal test_ouverture_database

func _ready() -> void:
	get_window().title = "Server Manager"
	
	# on charge les settings
	Settings.load_settings("manager")
	
	# on met le content_scale_factor
	get_window().content_scale_factor = Settings.get_setting("echelle")
	
	# on envoie le signal et on change la page si réussi (ouvrir_app)
	test_ouverture_database.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("echelle_down"):
		get_window().content_scale_factor -= 0.25
		Settings.set_setting("echelle", get_window().content_scale_factor)
	elif event.is_action_pressed("echelle_up"):
		get_window().content_scale_factor += 0.25
		Settings.set_setting("echelle", get_window().content_scale_factor)

func _on_create_database_pressed() -> void:
	# création de la base de données
	create_database.emit()

func ouvrir_app() -> void:
	$"creation database".visible = false
	$App.visible = true
