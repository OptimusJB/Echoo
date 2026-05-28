extends Button
var noeud_ip_confiance = load("res://back/manager/IpConfiance/IpConfiance.tscn")

func _on_pressed() -> void:
	var new_ip = $"../ip choisie".text
	if new_ip in Settings.get_setting("liste blanche ip"):
		Notif.add_notif("cette ip est déjà présente")
		return
		
	Settings.get_setting("liste blanche ip").append(new_ip)
	Settings.save_settings()
	
	# on ajoute la nouvelle ip
	var new_noeud_ip = noeud_ip_confiance.instantiate()
	new_noeud_ip.get_node("HBoxContainer/ip").text = FonctionsGlobal.to_text(new_ip)
	get_tree().get_nodes_in_group("liste blanche ip")[0].add_child(new_noeud_ip)
	
	# on vide le linedit
	$"../ip choisie".text = ""
	
	Notif.add_notif("ip ajoutée")
