extends Label

func _ready() -> void:
	text = "chemin : " + ProjectSettings.globalize_path("user://")
