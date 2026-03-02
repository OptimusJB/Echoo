extends Node

var url = "ws://127.0.0.1"
var port = 25565

# instance websocket
var socket = WebSocketPeer.new()

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

func connexion_serveur():
	var err	# résultat des requêtes
	# on check si c'est pas déjà connecté
	if check_connected(socket):
		push_error("connexion déjà active")
		return -2
	
	# connexion au serveur
	err = socket.connect_to_url(url + ":" + str(port))
	if err != OK:
		push_error("connexion échouée")
		return -1
	
	# connexion partiellement réussie, on met le heartbeat
	socket.heartbeat_interval = 10
	return 1
