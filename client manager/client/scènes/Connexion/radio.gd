extends HBoxContainer
var mode = "wss"

func check_pressed():
	if mode == "wss":
		if not $wss.button_pressed:
			$wss.button_pressed = true
		if $ws.button_pressed:
			$ws.button_pressed = false
		
		# on cache l'avertissement
		$"../avertissement".visible = false
		
	elif mode == "ws":
		if $wss.button_pressed:
			$wss.button_pressed = false
		if not $ws.button_pressed:
			$ws.button_pressed = true
		
		# on affiche l'avertissement
		$"../avertissement".visible = true
	else:
		push_error("problème de mode")
	
func _on_wss_pressed() -> void:
	if $wss.button_pressed:
		mode = "wss"
		check_pressed()
	else:
		$wss.button_pressed = true

func _on_ws_pressed() -> void:
	if $ws.button_pressed:
		mode = "ws"
		check_pressed()
	else:
		$ws.button_pressed = true
