extends Node

# Prototype : Nid (boutique) -> combat anime -> Nid, manche apres manche.
# La partie survit aux allers-retours, le resultat est compte au retour.

var partie := Partie.new()
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
	e.partie = partie
	e.combattre.connect(_combattre)
	e.nouvelle_partie.connect(func():
		partie = Partie.new()
		aller_nid())
	ecran = e
	add_child(e)

func _combattre() -> void:
	_vider()
	var c := CombatScreen.new(partie.nid.eclore(), partie.adversaire().eclore())
	c.retour.connect(func():
		partie.enregistrer(c.vainqueur)
		aller_nid())
	ecran = c
	add_child(c)
