extends Node

# Une run : Nid (boutique facultative) -> carte -> noeud -> Nid, jusqu'au
# dernier boss ou a 0 PV de run. La partie survit aux allers-retours.

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
	e.continuer.connect(aller_carte)
	e.nouvelle_partie.connect(func():
		partie = Partie.new()
		aller_nid())
	ecran = e
	add_child(e)

func aller_carte() -> void:
	_vider()
	var c := CarteScreen.new()
	c.partie = partie
	c.combat.connect(_combattre)
	c.fini.connect(aller_nid)
	c.retour.connect(aller_nid)
	ecran = c
	add_child(c)

func _combattre() -> void:
	_vider()
	var c := CombatScreen.new(partie.nid.eclore(), partie.adversaire_noeud().eclore())
	c.retour.connect(func():
		var adverse: Dictionary = c.combat.cotes[1]
		partie.conclure_combat(c.vainqueur, adverse["pv"] / adverse["cr"]["pv_max"])
		aller_nid())
	ecran = c
	add_child(c)
