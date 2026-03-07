extends Label

func _on_database_db_open_failed() -> void:
	visible = true
	$"../erreur timer".start()

func _on_erreur_timer_timeout() -> void:
	visible = false
