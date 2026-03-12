extends Control
var noeud_database

func _ready() -> void:
	noeud_database = get_tree().get_nodes_in_group("database")[0]
	
func init():
	# fonction appelée par Manager, sert à charger les premiers trucs
	# on charge les artistes
	var artistes = noeud_database.exec_sql("SELECT * FROM Artistes JOIN Ressources ON Artistes.id_image = Ressources.id", [])
	if not artistes[0]:
		# envoyer une notif
		Notif.add_notif("échec du chargement des artistes")
		return
