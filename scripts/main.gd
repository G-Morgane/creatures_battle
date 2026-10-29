extends Node

# Une run : choix des dynasties -> Nid (boutique facultative) -> carte -> noeud
# -> Nid, jusqu'au dernier boss ou a 0 Ferveur. La partie survit aux
# allers-retours. Le glossaire est par-dessus tout.

var partie: Partie
var ecran: Node = null

func _ready() -> void:
	get_window().theme = Palette.theme_jeu()
	add_child(Glossaire.new())
	aller_choix()

func aller_choix() -> void:
	_vider()
	var c := ChoixScreen.new()
	c.commencer.connect(func(dyn: Array, cav: String):
		partie = Partie.new(0, dyn)
		partie.choisir_cavalier(cav)
		aller_nid())
	ecran = c
	add_child(c)

func _vider() -> void:
	if ecran != null:
		ecran.queue_free()
		ecran = null

func aller_nid() -> void:
	_vider()
	var e := NidScreen.new()
	e.partie = partie
	e.continuer.connect(aller_carte)
	e.nouvelle_partie.connect(aller_choix)
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
	var moi := partie.creature_joueur()
	var c := CombatScreen.new(moi, partie.creature_adverse())
	c.retour.connect(func():
		var adverse: Dictionary = c.combat.cotes[1]
		partie.conclure_combat(c.vainqueur, adverse["pv"] / adverse["cr"]["pv_max"])
		aller_nid())
	ecran = c
	add_child(c)
