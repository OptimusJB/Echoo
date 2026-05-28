extends Control

func _ready() -> void:
	if OS.has_feature("manager"):
		get_tree().change_scene_to_file.call_deferred("res://back/manager/Manager.tscn")
	else:
		get_tree().change_scene_to_file.call_deferred("res://client/scènes/Connexion/connexion.tscn")
