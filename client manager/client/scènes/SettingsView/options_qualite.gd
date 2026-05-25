extends OptionButton


func _on_item_selected(index: int) -> void:
	var transposition = {0:"max", 1:"moy", 2:"min"}
	Settings.set_setting("qualite", transposition[index])
	print(transposition[index])
