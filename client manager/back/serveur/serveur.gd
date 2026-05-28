extends Node

var port = 25565

var serveur = TCPServer.new()
var connexions = {}	# liste des connexions actives de la forme id:connexion
var last_id = 0


"""
tests réalisés (godot 4.6.1):
	- put_packet envoie les données, pas besoin de poll() juste après
	- si le wifi est coupé sur la machine locale, connexion perdu quasi immédiatement
	- si le wifi est coupé sur l'autre machine, plusieurs put_packet nécessaires avant connexion rompue (potentiellement pas lié au nombre de put_packet, mais plutôt par rapport au temps depuis le premier)
	- si heartbeat interval activé et pas de réponse (pong) rapidement, connexion rompue, le receveur doit donc poll() souvent
	note : le receveur semble être prévenu quand la connexion est coupée à cause de heartbeat_interval
	note 2 : ça paraît évident mais l'envoyeur doit aussi poll() souvent pour recevoir le pong
	- connect_to_url n'est pas bloquant (pareil pour connect_to_host de tcp)
	- si tentative de connexion sur serveur ws avec wss, les deux restent à state_connecting à vie
	
à tester:
	- tentative connexion ws sur serveur wss
	- tentative connexion wss sur serveur wss mais avec certificat pas bon
	"""
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
		var message
		message = ws.get_packet()
		if ws.was_string_packet():
			message = message.get_string_from_utf8()
			if message == "quoi":
				ws.send_text("feur")
		# on met le heartbeat
		ws.heartbeat_interval = 10
