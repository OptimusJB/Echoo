extends FileDialog

func _ready() -> void:
	# on ajoute les filtres
	add_filter("*.png", "images png")
	add_filter("*.jpg", "images jpg")
	add_filter("*.jpeg", "images jpeg")
	add_filter("*.bmp", "images bmp")
	add_filter("*.svg", "images svg")
