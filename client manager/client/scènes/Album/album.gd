extends PanelContainer
var id:int

signal charger_album

func _ready() -> void:
	# on connecte charger_album à enumeration
	charger_album.connect(get_tree().get_first_node_in_group("enumeration")._album_clicked)

func _on_charger_album_pressed() -> void:
	charger_album.emit(id)
