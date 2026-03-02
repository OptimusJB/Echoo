extends Timer

func _on_timeout() -> void:
	if not $"../Client".check_connected():
		print("deconnecté")
	else:
		print("connecté")

func _ready() -> void:
	$"../Client".connexion_serveur()
