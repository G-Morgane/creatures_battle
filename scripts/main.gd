extends Node

# Prototype : Nid -> combat anime -> Nid. Le Nid survit aux allers-retours.

var nid := Exemples.nid_feu()
var ecran: Node = null

func _ready() -> void:
	aller_nid()

func _vider() -> void:
	if ecran != null:
		ecran.queue_free()
		ecran = null

func aller_nid() -> void:
	_vider()
	var e := NidScreen.new()
	e.nid = nid
	e.combattre.connect(_combattre)
	ecran = e
	add_child(e)

func _combattre(adverse: Nid) -> void:
	_vider()
	var c := CombatScreen.new(nid.eclore(), adverse.eclore())
	c.retour.connect(aller_nid)
	ecran = c
	add_child(c)
