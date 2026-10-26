extends Node

# Prototype : l'ecran du Nid, la creature eclot en direct.

func _ready() -> void:
	var ecran := NidScreen.new()
	ecran.nid = Exemples.nid_feu()
	add_child(ecran)
