extends PanelContainer

var id_album:int
var id_artiste:int

signal charger_artiste

func _ready() -> void:
	# on connecte le signal charger_artiste à enumeration
	charger_artiste.connect(get_tree().get_first_node_in_group("enumeration")._artiste_clicked)


func _on_artiste_pressed() -> void:
	charger_artiste.emit(id_artiste)
