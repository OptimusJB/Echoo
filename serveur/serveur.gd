extends Node

var port = 25565

var serveur = TCPServer.new()
var connexions = {}	# liste des connexions actives de la forme id:connexion
var last_id = 0

func lancer_serveur():
	var err # erreur serveur
	err = serveur.listen(port)
	
	if err != OK:
		return -1
	return 1
	
func _ready() -> void:
	if lancer_serveur() < 1:
		push_error("erreur lors du lancement du serveur")
		set_process(false)

func check_connected(connexion:WebSocketPeer):
	# fonction bloquante qui attend que le socket a établi la connexion
	# à utiliser avant d'envoyer des données
	# retourne 0 si deconnecté, 1 si connecté
	# WARNING à mettre dans un fichier différent
	var etat
	connexion.poll()
	etat = connexion.get_ready_state()
	
	while not etat == connexion.STATE_OPEN:
		connexion.poll()
		etat = connexion.get_ready_state()
		if etat == connexion.STATE_CLOSED or etat == connexion.STATE_CLOSING:
			return 0
	return 1
	
func _process(_delta: float) -> void:
	# on accepte toutes les nouvelles connexions
	var ws	# surcouche websocket
	while serveur.is_connection_available():
		ws = WebSocketPeer.new()
		ws.accept_stream(serveur.take_connection())
		connexions[last_id] = ws
		last_id += 1
		print("nouvelle connexion enregistré avec l'id %d" % last_id)
		
		# on met le heartbeat
		ws.heartbeat_interval = 10
