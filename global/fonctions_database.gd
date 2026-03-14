extends Node

# fichier qui contient toutes les fonctions de gestion de database
var database = SQLite.new()
const database_filename = "server_data.db"

func is_database_exists() -> int:
	# retourne 1 si le fichier data.db existe déjà, 0 sinon
	#return FileAccess.file_exists(OS.get_executable_path().get_base_dir() + "/" + database_filename)
	return FileAccess.file_exists("user://" + database_filename)

func fermer_database():
	return database.close_db()
	
func ouvrir_database():
	# ouvre la database, émet db_open_failed si raté
	#database.path = OS.get_executable_path().get_base_dir() + "/" + database_filename
	database.path = "user://" + database_filename
	if not database.open_db():
		#push_error("erreur lors de l'ouverture de la database")
		Notif.add_notif("échec de l'ouverture de la base de données")
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
	#database.query("CREATE TABLE Ressources(id INTEGER, chemin_ressource TEXT, PRIMARY KEY (id AUTOINCREMENT))")
	database.query("CREATE TABLE Artistes(id INTEGER, nom TEXT, image TEXT, PRIMARY KEY (id AUTOINCREMENT))")
	database.query("CREATE TABLE Albums(id INTEGER, id_artiste INTEGER, nom TEXT, annee INTEGER, image TEXT, genre TEXT, PRIMARY KEY (id AUTOINCREMENT), FOREIGN KEY (id_artiste) REFERENCES Artistes(id))")
	database.query("CREATE TABLE Musiques(id INTEGER, id_album INT, min TEXT, moy TEXT, max TEXT, PRIMARY KEY (id AUTOINCREMENT), FOREIGN KEY(id_album) REFERENCES Albums(id))")
	database.query("CREATE TABLE Utilisateurs(id INTEGER, username TEXT, password TEXT, PRIMARY KEY (id AUTOINCREMENT))")
	database.query("CREATE TABLE UPlaylists(id INTEGER, id_utilisateur INTEGER, nom TEXT, description TEXT, image TEXT, musiques TEXT, PRIMARY KEY (id AUTOINCREMENT), FOREIGN KEY (id_utilisateur) REFERENCES Utilisateurs(id))")
	database.query("CREATE TABLE ListeNoire(id INTEGER, adresse TEXT, PRIMARY KEY (id), FOREIGN KEY (id) REFERENCES Utilisateurs(id))")
	#database.close_db()
	return 1

func exec_sql(requete, args):
	# requete : c'est la requête
	# args, les ? de requete seront remplacés par les args
	var resultat = database.query_with_bindings(requete, args)
	
	# resultat = 0 ou 1 = succes ou pas de la requete
	# query_result : resultat de la requete, sous forme [{attribut:valeur, attribut:valeur}, {attribut:valeur, attribut:valeur}]
	return [resultat, database.query_result]
