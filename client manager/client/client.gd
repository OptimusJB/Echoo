extends Node
signal connected
signal disconnected

var url = "wss://192.168.1.26"
var port = 25565

var max_buffer = 1.049e+9 # environ 1000mio
var reponse = {"text":"", "bytes":null}	# reçu par le serveur

# instance websocket
var socket = WebSocketPeer.new()

# timer pour l'exécution du ping
var timer_ping:Timer
var last_reponse
var timeout_time = 10000 # en msec

# nombre de réponses attendues actuellement
var nb_reponses_attendues = 0

# variable permettant d'éviter que plusieurs trucs envoient des données en même temps
var is_locked = false

var est_connecte = false
var connexion_en_cours = false

func wait_connected(connexion:WebSocketPeer):
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
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		push_error("connexion déjà active")
		#print(socket.get_ready_state())
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
	nb_reponses_attendues = 0
	last_reponse = Time.get_ticks_msec()
	timer_ping.start()
	connexion_en_cours = true
	return 1

func timer_ping_timeout():
	if nb_reponses_attendues == 0 && socket.get_ready_state() == socket.STATE_OPEN:
		reponse = {"text":"", "bytes":null}
		socket.send_text("quoi")
		nb_reponses_attendues += 1
	
func _ready() -> void:
	# on initialise le timer
	timer_ping = Timer.new()
	timer_ping.autostart = false
	timer_ping.one_shot = true
	timer_ping.wait_time = 5 # ping toutes les 5 sec
	timer_ping.timeout.connect(timer_ping_timeout)
	add_child(timer_ping)
	
	# on augmente les limites de buffer du socket (environ 100mio pour être large)
	socket.inbound_buffer_size = max_buffer
	socket.outbound_buffer_size = max_buffer
	#print("inbound : %d, outbound : %d" % [socket.inbound_buffer_size, socket.outbound_buffer_size])

func _process(_delta: float) -> void:
	var paquet
	socket.poll()
	
	# on check si c'est connecté, si oui on le met dans est_connecte
	if socket.get_ready_state() == socket.STATE_OPEN:
		if est_connecte == false:
			# le socket est connecté
			connexion_en_cours = false
			est_connecte = true
			print("connexion réussie")
			connected.emit()
		
	elif socket.get_ready_state() != socket.STATE_CONNECTING:
		if est_connecte == true or connexion_en_cours == true:
			# la connexion a été perdue
			est_connecte = false
			connexion_en_cours = false
			print("connexion perdue")
			disconnected.emit()
		return
	
	# si nb_reponses_attendues > 0, on check les potentiels paquets arrivés
	if nb_reponses_attendues > 0:
		# on regarde d'abord le temps de timeout
		if Time.get_ticks_msec() - last_reponse > timeout_time:
			print("connexion perdue")
			nb_reponses_attendues = 0
			socket.close()
			return
		
		if socket.get_available_packet_count():
			last_reponse = Time.get_ticks_msec()
		while socket.get_available_packet_count():
			paquet = socket.get_packet()
			if socket.was_string_packet():
				paquet = paquet.get_string_from_utf8()
				
				# on check si c'est un pong
				if paquet == "feur":
					print("pong reçu")
					timer_ping.start()
					nb_reponses_attendues -= 1
					return
					
				reponse["text"] += paquet
			else:
				if not reponse["bytes"]:
					reponse["bytes"] = paquet
				else:
					reponse["bytes"] += paquet
