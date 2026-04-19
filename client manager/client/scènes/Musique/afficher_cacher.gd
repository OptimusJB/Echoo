extends Control

func afficher():
	visible = true

func cacher():
	visible = false

func _on_mouse_entered() -> void:
	custom_minimum_size.x += 5
	custom_minimum_size.y += 5

func _on_mouse_exited() -> void:
	custom_minimum_size.x -= 5
	custom_minimum_size.y -= 5

func _on_button_down() -> void:
	_on_mouse_entered()

func _on_button_up() -> void:
	_on_mouse_exited()
