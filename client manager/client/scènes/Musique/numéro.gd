extends Label
var texte_visible = visible

func afficher():
	self_modulate.a = 1
	texte_visible = true
	#visible = true

func cacher():
	self_modulate.a = 0
	texte_visible = false
	#visible = false

func est_visible():
	return texte_visible
	
