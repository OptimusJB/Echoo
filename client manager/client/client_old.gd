extends Node
signal connected
signal disconnected

var url = "wss://192.168.1.26"
var port = 25565

var max_buffer = 1.049e+7 # environ 10mio
var buffer_slice = 2.097e+6 # environ 2mio
#var buffer_slice = 1
var reponse = {"text":null, "bytes":null}	# reçu par le serveur

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
		socket.inbound_buffer_size = max_buffer
		socket.outbound_buffer_size = max_buffer
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
	if socket.get_ready_state() == socket.STATE_OPEN:
		# la ligne suivante était là auparavant mais elle posait problème car elle pouvait supprimer une portion de musique dans bytes
		# je ne sais plus pourquoi elle était là avant, parce que à première vue elle sert à rien
		# la ligne était déjà là avant la refonte, sous la forme {"text":"", "bytes":null}, à l'époque où ce code s'exécutait seulement quand il n'y avait aucun message en attente de réception
		# reponse = {"text":null, "bytes":null}
		while len("quoi".to_utf8_buffer()) > socket.outbound_buffer_size - socket.get_current_outbound_buffered_amount() or socket.send_text("quoi") == ERR_OUT_OF_MEMORY:
			#print("pas assez de place dans le buffer pour le ping, on attend la prochaine frame")
			await get_tree().process_frame
			socket.poll()
		nb_reponses_attendues += 1
		print("ping envoyé")
	timer_ping.start()

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
	#socket.outbound_buffer_size = 12
	#print("inbound : %d, outbound : %d" % [socket.inbound_buffer_size, socket.outbound_buffer_size])

func verif_no_number(message_json):
	if message_json is not Array and message_json is not Dictionary:
		return
	for element in message_json.values():
		if element is Dictionary:
			verif_no_number(element)
		if element is Array:
			for element_liste in element:
				verif_no_number(element_liste)
		if element is float:
			push_error("float repéré. élément concerné : " + str(element) + "\nmessage_json : " + JSON.stringify(message_json))
			
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
			
			# on reset les messages
			reponse = {"text":null, "bytes":null}
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
			#timer_ping.start()
			
			paquet = socket.get_packet()
			if socket.was_string_packet():
				paquet = paquet.get_string_from_utf8()
				
				# on check si c'est un pong
				if paquet == "feur":
					print("pong reçu")
					nb_reponses_attendues -= 1
					return
			else:
				#socket.send_text("ok")
				if paquet.slice(0, len("&SPFCHAINE&".to_utf8_buffer())) == "&SPFCHAINE&".to_utf8_buffer():
					paquet = paquet.slice(len("&SPFCHAINE&".to_utf8_buffer()))
					if not reponse["text"]:
						reponse["text"] = paquet
					else:
						reponse["text"].append_array(paquet)
						
				elif not reponse["bytes"]:
					reponse["bytes"] = paquet
				else:
					reponse["bytes"].append_array(paquet)
			
			# on check si le message entier est parvenu
			if not reponse["text"] == null and reponse["text"].slice(len(reponse["text"]) - len("&SPFEND&".to_utf8_buffer())) == "&SPFEND&".to_utf8_buffer():
				# on tronque pour enlever &SPFEND&
				reponse["text"] = reponse["text"].get_string_from_utf8()
				reponse["text"] = reponse["text"].substr(0, len(reponse["text"]) - len("&SPFEND&"))
				
				# reponse["text"] doit être sous forme de JSON
				var message_text = JSON.parse_string(reponse["text"])
				var message_bytes = reponse["bytes"]
				reponse = {"text":null, "bytes":null}	# on supprime le contenu de réponse
				
				if message_text == null:
					print("un message a été reçu, mais le parse en json a échoué")
					return
				
				nb_reponses_attendues -= 1
				#print("reçu : ", message_text)
				#verif_no_number(message_text)
				noeud_appelant.received(message_text, message_bytes)
				
func send(message):	# soit str soit bytes, le stringify doit avoir été fait avant
	var est_chaine = false
	if message is String:
		#verif_no_number(JSON.parse_string(message))	# TODO à enlever à la fin
		# on convertit la chaine en bytes
		est_chaine = true
		message = (message + "&SPFEND&").to_utf8_buffer()
		nb_reponses_attendues += 1
	
	var sous_message
	while message:
		await get_tree().process_frame
		socket.poll()
		
		sous_message = message.slice(0, buffer_slice)
		if est_chaine:
			sous_message = "&SPFCHAINE&".to_utf8_buffer() + sous_message
		while len(sous_message) > socket.outbound_buffer_size - socket.get_current_outbound_buffered_amount() or socket.send(sous_message) == ERR_OUT_OF_MEMORY:
			#print("pas assez de place dans le buffer, on attend la prochaine frame")
			await get_tree().process_frame
			socket.poll()
			if socket.get_ready_state() != socket.STATE_OPEN:
				return
		if socket.get_ready_state() != socket.STATE_OPEN:
			return
		message = message.slice(buffer_slice)
	#socket.send_text("&SPFEND&")

func check_keys(message_json:Dictionary, liste_cles:Array):
	# retourne true si toutes les clés sont dans message_json
	var liste_cles_message = message_json.keys()
	for cle in liste_cles:
		if not cle in liste_cles_message:
			return 0
	return 1

func send_file(chemin_fichier:String):
	# fonction optimisée pour l'envoi de fichiers (chargement progressif en ram, et pas de slice qui prend 3 sec)
	var fichier = FileAccess.open(chemin_fichier, FileAccess.READ)
	if not fichier:
		return 0
	var data = fichier.get_buffer(buffer_slice)
	while data:
		await send(data)
		data = fichier.get_buffer(buffer_slice)
	return 1
