extends "res://client/scènes/Accueil/resize.gd"
var etat = 0
var etat_texte = {0:"off", 1:"on", 2:"track"}
var etat_textures = {0:load("res://assets/repeat_off.png"), 1:load("res://assets/repeat_on.png"), 2:load("res://assets/repeat_track.png")}

signal changed

func _on_pressed() -> void:
	etat = (etat + 1) % 3
	texture_normal = etat_textures[etat]
	changed.emit(etat)

func reset():
	etat = 0
	texture_normal = etat_textures[etat]
