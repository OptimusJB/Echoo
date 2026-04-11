extends Node

var url = "wss://192.168.1.26"
var port = 8080

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
		#print("état opening : %s", etat==connexion.STATE_CONNECTING)
		if etat == connexion.STATE_CLOSED or etat == connexion.STATE_CLOSING:
			print(connexion.get_close_reason())
			print("closing : %s, closed : %s" % [etat == connexion.STATE_CLOSING, etat == connexion.STATE_CLOSED])
			return 0
	return 1

func connexion_serveur():
	var err	# résultat des requêtes
	# on check si c'est pas déjà connecté
	if check_connected(socket):
		push_error("connexion déjà active")
		return -2
	
	# connexion au serveur
	var tls = TLSOptions.client()
	err = socket.connect_to_url(url + ":" + str(port), tls)
	if err != OK:
		push_error("connexion échouée")
		return -1
	
	# on n'utilise pas heartbeat_interval parce que c'est de la merde
	# à la place on crée notre propose système de ping
	#socket.heartbeat_interval = 2
	print("connexion")
	return 1
