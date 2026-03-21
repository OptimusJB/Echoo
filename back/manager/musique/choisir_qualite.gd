extends Button

var file_select
@export var qualite:String	# = min, moy ou max

func _ready() -> void:
	# on crée le filedialog
	file_select = FileDialog.new()
	file_select.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_select.access = FileDialog.ACCESS_FILESYSTEM
	# ajouter les codecs ici
	file_select.add_filter("*.mp3", "fichiers mp3")
	get_tree().get_nodes_in_group("windows")[1].add_child(file_select)
	file_select.file_selected.connect(fichier_choisi)
	
func fichier_choisi(chemin_fichier):
	# on change le fichier audio (pas de vérification)
	var id_musique = get_tree().get_nodes_in_group("noeud racine")[0].id
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("UPDATE Musiques SET " + qualite + " = ? WHERE id=?", [chemin_fichier, id_musique])
	if not resultat[0]:
		Notif.add_notif("échec du changement de musique")
		return
		
	# on change le texte affiché
	$"../".get_child(1).text = chemin_fichier


func _on_pressed() -> void:
	file_select.popup_file_dialog()
	
