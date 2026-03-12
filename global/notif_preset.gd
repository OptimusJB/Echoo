extends MarginContainer


func _on_temps_affichage_timeout() -> void:
	queue_free()
