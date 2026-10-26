class_name CombatScreen
extends Control

# Rejoue un combat deja simule : le resultat est connu avant la premiere image,
# l'ecran ne fait que lire evenements et PV au rythme de l'horloge.

signal retour

const VOL_PROJECTILE := 0.35
const DUREE_TEXTE := 1.0
const ECART_COUPS := 0.08   # entre deux coups d'un meme sort (Nuee)

var combat: Combat
var vainqueur := -1
var vues: Array = []
var lecture := 0.0
var vitesse := 1.0
var prochain := 0          # index du prochain evenement a jouer
var effets: Array = []     # projectiles et textes flottants en cours
var fini := false
var calque: Control
var bandeau: Label
var bouton_vitesse: Button

func _init(a: Dictionary, b: Dictionary) -> void:
	combat = Combat.new(a, b)
	vainqueur = combat.simuler()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fond := ColorRect.new()
	fond.color = Palette.FOND
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	for i in 2:
		var cr: Dictionary = combat.cotes[i]["cr"]
		var v := CreatureVue.new()
		v.fond = false
		v.miroir = i == 1
		v.size = Vector2(440, 380)
		v.montrer(cr["forme"], cr["affinite"], cr["arme"])
		vues.append(v)
		add_child(v)
	calque = Control.new()
	calque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	calque.draw.connect(_dessiner)
	add_child(calque)

	bandeau = Label.new()
	bandeau.add_theme_font_size_override("font_size", 40)
	bandeau.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bandeau.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bandeau.offset_top = 80
	bandeau.visible = false
	add_child(bandeau)

	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 12)
	boutons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	boutons.offset_top = -110
	boutons.offset_bottom = -60
	boutons.alignment = BoxContainer.ALIGNMENT_CENTER
	bouton_vitesse = _bouton("Vitesse x2", _changer_vitesse)
	boutons.add_child(bouton_vitesse)
	boutons.add_child(_bouton("Rejouer", _rejouer))
	boutons.add_child(_bouton("Retour au Nid", func(): retour.emit()))
	add_child(boutons)
	resized.connect(_placer)
	_placer()

func _bouton(texte: String, f: Callable) -> Button:
	var b := Button.new()
	b.text = texte
	b.custom_minimum_size = Vector2(150, 40)
	b.pressed.connect(f)
	return b

func _placer() -> void:
	var milieu := size.y * 0.52
	vues[0].position = Vector2(size.x * 0.27 - 220, milieu - 190)
	vues[1].position = Vector2(size.x * 0.73 - 220, milieu - 190)

func _changer_vitesse() -> void:
	vitesse = 2.0 if vitesse == 1.0 else 1.0
	bouton_vitesse.text = "Vitesse x1" if vitesse > 1.0 else "Vitesse x2"

func _rejouer() -> void:
	lecture = 0.0
	prochain = 0
	effets.clear()
	fini = false
	bandeau.visible = false

# --- lecture ---------------------------------------------------------------

func _process(delta: float) -> void:
	if not fini:
		lecture += delta * vitesse
	var evs: Array = combat.evenements
	while prochain < evs.size() and evs[prochain]["t"] <= lecture:
		_jouer(evs[prochain])
		prochain += 1
	if not fini and lecture >= combat.t:
		fini = true
		_fin()
	effets = effets.filter(func(e): return lecture < e["t0"] + e["duree"])
	calque.queue_redraw()

func _jouer(e: Dictionary) -> void:
	var moi: CreatureVue = vues[e["cote"]]
	var cible: CreatureVue = vues[1 - e["cote"]]
	var nom: String = combat.cotes[e["cote"]]["cr"]["nom"]
	match e["type"]:
		"attaque":
			_elan(moi)
		"sort":
			var couleurs: Dictionary = Palette.ELEMENTS[e["element"]]
			var de: Vector2 = moi.position + moi.source(e["cavalier"])
			var a: Vector2 = cible.position + cible.size / 2 + Vector2(0, 20)
			for k in maxi(e["coups"], 1):
				effets.append({"type": "projectile", "de": de, "a": a, "t0": lecture + k * ECART_COUPS,
					"duree": VOL_PROJECTILE, "couleur": couleurs["vif"], "coeur": couleurs["clair"],
					"taille": 12.0 if e["coups"] <= 1 else 6.0})
			var qui := "Cavalier : " if e["cavalier"] else ""
			_texte(moi, 0 if e["cavalier"] else 1, qui + e["nom"], couleurs["clair"])
		"voile":
			_texte(moi, 2, "Voile", Palette.ELEMENTS["nuit"]["clair"])
		"bouclier":
			_texte(moi, 2, "+%d bouclier" % roundi(e["valeur"]), Palette.ELEMENTS["terre"]["clair"])
		"eclair":
			var vent: Dictionary = Palette.ELEMENTS["vent"]
			effets.append({"type": "projectile", "de": moi.position + moi.source(false),
				"a": cible.position + cible.size / 2 + Vector2(0, 20), "t0": lecture,
				"duree": VOL_PROJECTILE * 0.5, "couleur": vent["vif"], "coeur": vent["clair"], "taille": 8.0})
			_texte(moi, 1, "Éclair", vent["clair"])
		"esquive":
			_texte(moi, 2, "Esquive !", Palette.TEXTE)
		"renaissance":
			_texte(moi, 2, "%s renaît !" % nom, Palette.ELEMENTS["feu"]["clair"])
			moi.modulate = Color(2.2, 1.8, 1.2)
			create_tween().tween_property(moi, "modulate", Color.WHITE, 0.8)

func _elan(v: CreatureVue) -> void:
	var tw := create_tween()
	tw.tween_property(v, "elan", 24.0, 0.08 / vitesse)
	tw.tween_property(v, "elan", 0.0, 0.14 / vitesse)

# Textes sur trois lignes fixes au-dessus de la monture, pour ne pas la cacher :
# 0 cavalier, 1 monture, 2 reactions (voile, esquive, renaissance).
func _texte(v: CreatureVue, ligne: int, texte: String, couleur: Color) -> void:
	var pos := v.position + Vector2(v.size.x / 2, 30 + ligne * 26)
	# deux textes au meme endroit en meme temps : le nouveau monte d'un cran
	while effets.any(func(e): return e["type"] == "texte" and e["pos"].distance_to(pos) < 1.0 and lecture - e["t0"] < 0.4):
		pos.y -= 22
	effets.append({"type": "texte", "pos": pos, "texte": texte, "couleur": couleur,
		"t0": lecture, "duree": DUREE_TEXTE})

func _fin() -> void:
	bandeau.visible = true
	if vainqueur == -1:
		bandeau.text = "Égalité"
		bandeau.add_theme_color_override("font_color", Palette.TEXTE)
		return
	var cr: Dictionary = combat.cotes[vainqueur]["cr"]
	bandeau.text = ("Victoire !" if vainqueur == 0 else "Défaite") + "  (%s)" % cr["nom"]
	bandeau.add_theme_color_override("font_color", Palette.ELEMENTS[cr["forme"]]["clair"])
	var perdant: CreatureVue = vues[1 - vainqueur]
	create_tween().tween_property(perdant, "modulate", Color(1, 1, 1, 0.25), 0.6)

# --- dessin ----------------------------------------------------------------

func _image() -> Array:
	var i := clampi(int(lecture / Data.PAS), 0, combat.images.size() - 1)
	return combat.images[i]

func _dessiner() -> void:
	var img := _image()
	var police := ThemeDB.fallback_font
	for i in 2:
		var cr: Dictionary = combat.cotes[i]["cr"]
		var v: CreatureVue = vues[i]
		var x := v.position.x + v.size.x / 2 - 150
		var y := v.position.y - 30
		calque.draw_string(police, Vector2(x, y - 12), cr["nom"], HORIZONTAL_ALIGNMENT_CENTER, 300, 20, Palette.TEXTE)
		var part := clampf(img[i] / cr["pv_max"], 0.0, 1.0)
		calque.draw_rect(Rect2(x, y, 300, 16), Palette.CASE)
		calque.draw_rect(Rect2(x, y, 300 * part, 16), Palette.ELEMENTS[cr["forme"]]["vif"])
		# bouclier : bande claire au bout des PV
		var bouclier := clampf(img[4 + i] / cr["pv_max"], 0.0, 1.0 - part)
		if bouclier > 0.0:
			calque.draw_rect(Rect2(x + 300 * part, y, 300 * bouclier, 16), Color("#cfe3f2"))
		calque.draw_rect(Rect2(x, y, 300, 16), Palette.CASE_BORD, false, 1.0)
		calque.draw_string(police, Vector2(x, y + 13), "%d / %d" % [maxi(ceili(img[i]), 0), cr["pv_max"]],
			HORIZONTAL_ALIGNMENT_CENTER, 300, 13, Palette.TEXTE)
		if img[2 + i]:
			_brulure(v)
	if lecture > Data.MORT_SUBITE and not fini:
		calque.draw_string(police, Vector2(0, 50), "Mort subite", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color("#e5834f"))
	for e in effets:
		var p: float = (lecture - e["t0"]) / e["duree"]
		if p < 0.0:
			continue
		match e["type"]:
			"projectile":
				var pos: Vector2 = e["de"].lerp(e["a"], p) + Vector2(0, -sin(p * PI) * 50)
				calque.draw_circle(pos, e["taille"] * 1.6, Color(e["couleur"], 0.35))
				calque.draw_circle(pos, e["taille"], e["couleur"])
				calque.draw_circle(pos, e["taille"] * 0.45, e["coeur"])
			"texte":
				var c: Color = e["couleur"]
				c.a = 1.0 - p * p
				calque.draw_string(police, e["pos"] + Vector2(-150, -p * 30), e["texte"],
					HORIZONTAL_ALIGNMENT_CENTER, 300, 18, c)

# Petites flammes qui dansent autour d'une monture qui brule.
func _brulure(v: CreatureVue) -> void:
	var centre := v.position + v.size / 2 + Vector2(0, 40)
	for k in 6:
		var a := TAU * k / 6.0 + lecture * 2.0
		var p := centre + Vector2(cos(a) * 80, 60 + sin(a) * 18)
		var h := 22.0 + sin(lecture * 12.0 + k) * 8.0
		calque.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(0, -h), p + Vector2(9, 0)]),
			Palette.ELEMENTS["feu"]["vif"])
		calque.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(0, -h * 0.5), p + Vector2(4, 0)]),
			Palette.ELEMENTS["feu"]["clair"])
