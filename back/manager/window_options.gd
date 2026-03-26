extends Control
var noeud_ip_confiance = load("res://back/manager/IpConfiance/IpConfiance.tscn")
var is_charging = false

func charger():
	if is_charging:
		return
	is_charging = true
	# on charge la taille max d'envoi et la liste des ips white listées
	$"marges/elements/taille max fichier".text = FonctionsGlobal.to_text_float(Settings.get_setting("taille envoi fichier"))
	$"marges/elements/taille max fichier".old_text = $"marges/elements/taille max fichier".text
	
	# on supprime tout avant d'ajouter
	for ip_actuelle in get_tree().get_nodes_in_group("liste blanche ip")[0].get_children():
		ip_actuelle.queue_free()
		
	var new_ip
	for ip_actuelle in Settings.get_setting("liste blanche ip"):
		await get_tree().process_frame
		new_ip = noeud_ip_confiance.instantiate()
		new_ip.get_node("HBoxContainer/ip").text = FonctionsGlobal.to_text(ip_actuelle)
		get_tree().get_nodes_in_group("liste blanche ip")[0].add_child(new_ip)
	is_charging = false
