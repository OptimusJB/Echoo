extends PanelContainer

func set_banni():
	var style = get_theme_stylebox("panel").duplicate()	# on duplique pour éviter de modifier tous les utilisateurs
	style.bg_color = Color(0.846, 0.0, 0.23)
	add_theme_stylebox_override("panel", style)

func set_pas_banni():
	var style = get_theme_stylebox("panel", "Utilisateur").duplicate()	# on duplique pour éviter de modifier tous les utilisateurs
	style.bg_color = Color(0.255, 0.255, 0.255)
	add_theme_stylebox_override("panel", style)
