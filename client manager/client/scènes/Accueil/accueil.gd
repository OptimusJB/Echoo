extends Control

func disconnected():
	Notif.add_notif.call_deferred(tr("CONNECTION_FAILED"))
	get_tree().change_scene_to_file("res://client/scènes/Connexion/connexion.tscn")
	
func _ready() -> void:
	# on se connecte au disconnected du client
	Client.disconnected.connect(disconnected)
