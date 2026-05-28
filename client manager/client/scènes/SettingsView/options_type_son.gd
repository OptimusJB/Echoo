extends OptionButton

func _on_item_selected(index: int) -> void:
	var transposition = {0:0, 1:2, 2:1}
	Settings.set_setting("type son", transposition[index])
	
	# on change directement
	#print("avant", get_tree().get_first_node_in_group("player").get_node("../AudioStreamPlayer").mix_target)
	#get_tree().get_first_node_in_group("player").get_node("../AudioStreamPlayer").mix_target = index
	#print("après", get_tree().get_first_node_in_group("player").get_node("../AudioStreamPlayer").mix_target)
