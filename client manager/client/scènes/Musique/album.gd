extends LinkButton

func cacher():
	visible = false


func _on_button_down_up() -> void:
	accept_event()
