extends Node
signal connected
signal disconnected

var url = "wss://192.168.1.26"
var port = 25565

var max_buffer = 1.049e+7 # environ 10mio
var buffer_slice = 2.097e+6 # environ 2mio
var reponse = {"text":"", "bytes":null}	# reçu par le serveur

# instance websocket
var socket = WebSocketPeer.new()

# timer pour l'exécution du ping
var timer_ping:Timer
var last_reponse
var timeout_time =  10000 # en msec

# nombre de réponses attendues actuellement
var nb_reponses_attendues = 0

# variable permettant d'éviter que plusieurs trucs envoient des données en même temps
var is_locked = false

var est_connecte = false
var connexion_en_cours = false
var timer_timeout:Timer

var noeud_appelant

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
		print("connexion déjà active, on recrée le socket")
		socket = WebSocketPeer.new()
		#print(socket.get_ready_state())
		#return -2
	
	# connexion au serveur
	var tls = TLSOptions.client()
	err = socket.connect_to_url(url + ":" + str(port), tls)
	if err != OK:
		push_error("connexion échouée")
		return -1
	
	# on n'utilise pas heartbeat_interval parce que c'est de la merde
	# à la place on crée notre propose système de ping
	#socket.heartbeat_interval = 2
	print("connexion en cours à " + url + ":" + str(port))
	nb_reponses_attendues = 0
	last_reponse = Time.get_ticks_msec()
	timer_ping.start()
	timer_timeout.start()
	connexion_en_cours = true
	return 1

func timer_ping_timeout():
	#print("rep attendues : ", nb_reponses_attendues)
	if nb_reponses_attendues == 0 && socket.get_ready_state() == socket.STATE_OPEN:
		reponse = {"text":"", "bytes":null}
		socket.send_text("quoi")
		nb_reponses_attendues += 1
		print("ping envoyé")

func timer_timeout_timeout():
	# STATE_CONNECTING à enlever si on veut pas que ça timeout pendant la connexion
	var timeout_state = [socket.STATE_OPEN, socket.STATE_CONNECTING]
	if Time.get_ticks_msec() - last_reponse > timeout_time && socket.get_ready_state() in timeout_state:
		print("timeout déclenché")
		nb_reponses_attendues = 0
		socket.close()
	
func _ready() -> void:
	# on initialise le timer
	timer_ping = Timer.new()
	timer_ping.autostart = false
	timer_ping.one_shot = true
	timer_ping.wait_time = 5 # ping toutes les 5 sec
	timer_ping.ignore_time_scale = true
	timer_ping.timeout.connect(timer_ping_timeout)
	add_child(timer_ping)
	
	timer_timeout = Timer.new()
	timer_timeout.autostart = false
	timer_timeout.one_shot = false
	timer_timeout.wait_time = 10
	timer_timeout.ignore_time_scale = true
	timer_timeout.timeout.connect(timer_timeout_timeout)
	add_child(timer_timeout)
	
	# on augmente les limites de buffer du socket (environ 100mio pour être large)
	socket.inbound_buffer_size = max_buffer
	socket.outbound_buffer_size = max_buffer
	#print("inbound : %d, outbound : %d" % [socket.inbound_buffer_size, socket.outbound_buffer_size])

func verif_no_number(message_json):
	for element in message_json.values():
		if element is Dictionary:
			verif_no_number(element)
		if element is float:
			push_error("float repéré pour réponse de type " + str(message_json["type"] + ". élément concerné : " + str(element)))
			
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
			
			# on reset le temps
			last_reponse = Time.get_ticks_msec()
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
		if socket.get_available_packet_count():
			last_reponse = Time.get_ticks_msec()
			timer_ping.start()
			#print("reset temps")
			#print("nb available : ", socket.get_available_packet_count())
		while socket.get_available_packet_count():
			paquet = socket.get_packet()
			if socket.was_string_packet():
				paquet = paquet.get_string_from_utf8()
				
				# on check si c'est un pong
				if paquet == "feur":
					print("pong reçu")
					nb_reponses_attendues -= 1
					return
					
				reponse["text"] += paquet
			else:
				if not reponse["bytes"]:
					reponse["bytes"] = paquet
				else:
					reponse["bytes"] += paquet
			
			# on check si le message entier est parvenu
			if "&SPFEND&" in reponse["text"]:
				# on tronque pour enlever &SPFEND&
				reponse["text"] = reponse["text"].substr(0, len(reponse["text"]) - len("&SPFEND&"))
				
				# reponse["text"] doit être sous forme de JSON
				var message_text = JSON.parse_string(reponse["text"])
				var message_bytes = reponse["bytes"]
				reponse = {"text":"", "bytes":null}	# on supprime le contenu de réponse
				
				if message_text == null:
					print("un message a été reçu, mais le parse en json a échoué")
					return
				
				nb_reponses_attendues -= 1
				#print("reçu : ", message_text)
				verif_no_number(message_text)	# TODO à enlever à la fin
				noeud_appelant.received(message_text, message_bytes)
				
func send(message):	# soit str soit bytes, le stringify doit avoir été fait avant
	if message is String:
		# on envoie directement le message sans découpe (on suppose qu'on est en dessous de la limite)
		socket.send_text(message + "&SPFEND&")
		nb_reponses_attendues += 1
		return
		
	# sinon on suppose que c'est des bytes, on découpe
	while message:
		socket.send(message.slice(0, buffer_slice))
		message = message.slice(buffer_slice)
	#socket.send_text("&SPFEND&")
	nb_reponses_attendues += 1

func check_keys(message_json:Dictionary, liste_cles:Array):
	# retourne true si toutes les clés sont dans message_json
	var liste_cles_message = message_json.keys()
	for cle in liste_cles:
		if not cle in liste_cles_message:
			return 0
	return 1
