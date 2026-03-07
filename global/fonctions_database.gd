extends Node

# fichier qui contient toutes les fonctions de gestion de database
var database = SQLite.new()
const database_filename = "data.db"

signal db_open_failed
signal db_open_success

func is_database_exists():
	# retourne 1 si le fichier data.db existe déjà, 0 sinon
	return FileAccess.file_exists(OS.get_executable_path().get_base_dir() + "/" + database_filename)

func ouvrir_database():
	# ouvre la database, émet db_open_failed si raté
	database.path = OS.get_executable_path().get_base_dir() + "/" + database_filename
	if not database.open_db():
		#push_error("erreur lors de l'ouverture de la database")
		db_open_failed.emit()
		return 0
	return 1
		
func create_database() -> int:
	# crée les différentes tables de la database
	if is_database_exists():
		push_error("le fichier data.db existe déjà")
		return 0
		
	if not ouvrir_database():
		return 0
	
	# création des différentes tables
	database.query("CREATE TABLE Artistes(id INTEGER, nom TEXT, PRIMARY KEY (id AUTOINCREMENT))")
	database.query("CREATE TABLE Albums(id INTEGER, id_artiste INTEGER, nom TEXT, annee INTEGER, image TEXT, genre TEXT, PRIMARY KEY (id AUTOINCREMENT), FOREIGN KEY (id_artiste) REFERENCES Artistes(id))")
	database.query("CREATE TABLE Musiques(id INTEGER, id_album INT, min TEXT, moy TEXT, max TEXT, PRIMARY KEY (id AUTOINCREMENT), FOREIGN KEY (id_album) REFERENCES Albums(id))")
	database.query("CREATE TABLE Utilisateurs(id INTEGER, username TEXT, password TEXT, PRIMARY KEY (id AUTOINCREMENT))")
	database.query("CREATE TABLE UPlaylists(id INTEGER, id_utilisateur INTEGER, nom TEXT, description TEXT, image TEXT, musiques TEXT, PRIMARY KEY (id AUTOINCREMENT), FOREIGN KEY (id_utilisateur) REFERENCES Utilisateurs(id))")
	database.close_db()
	
	test_ouverture_database()	# pour le signal (permet de switcher vers l'app)
	return 1

func test_ouverture_database():
	# émet le signal db_signal_success si le fichier data.db existe et que l'ouverture n'a pas posé problème
	if not is_database_exists():
		return 0
	if ouvrir_database():
		db_open_success.emit()
		database.close_db()
		return 1
	database.close_db()
	return 0
