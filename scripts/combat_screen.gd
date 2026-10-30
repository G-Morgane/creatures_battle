class_name CombatScreen
extends Control

# Rejoue un combat deja simule : le resultat est connu avant la premiere image,
# l'ecran ne fait que lire evenements et PV au rythme de l'horloge.

signal retour

const VOL_PROJECTILE := 0.35
const DUREE_TEXTE := 1.0
const ECART_COUPS := 0.08   # entre deux coups d'un meme sort (Nuee)
const TEXTES_MAX := 4       # textes empiles au meme endroit

var combat: Combat
var vainqueur := -1
var vues: Array = []
var lecture := 0.0
# La vitesse choisie reste pour les combats suivants.
static var vitesse_retenue := 1.0
var vitesse := vitesse_retenue
var prochain := 0          # index du prochain evenement a jouer
var effets: Array = []     # projectiles et textes flottants en cours
var fini := false
var calque: Control
var bandeau: Label
var bouton_vitesse: Button
var boutons_ui: Control
var nids: Array = []      # MiniNid de chaque cote
var recap: Recap

func _init(a: Dictionary, b: Dictionary) -> void:
	combat = Combat.new(a, b)
	vainqueur = combat.simuler()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fond := ColorRect.new()
	fond.color = Palette.FOND
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	# arene peinte, qui couvre tout l'ecran sans se deformer
	var peint := TextureRect.new()
	peint.texture = Palette.image("res://images/fond_cbt.png")
	peint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	peint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	peint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	peint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(peint)
	for i in 2:
		var cr: Dictionary = combat.cotes[i]["cr"]
		var v := CreatureVue.new()
		v.fond = false
		v.miroir = i == 1
		v.size = Vector2(660, 570)
		v.zoom = 1.725
		v.a_terre = true
		v.cavalier = cr.get("cavalier", "capuchon")
		v.montrer(cr["forme"], cr["affinite"], cr["armes"], cr.get("hybride", ""), cr.get("elite", ""))
		vues.append(v)
		add_child(v)
	calque = Control.new()
	calque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	calque.draw.connect(_dessiner)
	add_child(calque)

	bandeau = Label.new()
	bandeau.add_theme_font_size_override("font_size", 40)
	Palette.titre(bandeau)
	bandeau.add_theme_constant_override("outline_size", 10)
	bandeau.add_theme_color_override("font_outline_color", Color(Palette.FOND, 0.85))
	bandeau.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bandeau.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bandeau.offset_top = 80
	bandeau.visible = false
	add_child(bandeau)

	# boutons au centre du bas : les Nids prennent les deux coins
	var boutons := GridContainer.new()
	boutons.columns = 3
	boutons.add_theme_constant_override("h_separation", 10)
	boutons.add_theme_constant_override("v_separation", 8)
	boutons_ui = boutons
	bouton_vitesse = _bouton("Vitesse x%d" % vitesse, _changer_vitesse)
	boutons.add_child(bouton_vitesse)
	boutons.add_child(_bouton("Rejouer", _rejouer))
	boutons.add_child(_bouton("Retour au Nid", func(): retour.emit()))
	add_child(boutons)
	for i in 2:
		var m := MiniNid.new(self, i)
		nids.append(m)
		add_child(m)
	recap = Recap.new(combat)
	recap.visible = false
	add_child(recap)
	resized.connect(_placer)
	_placer()

func _bouton(texte: String, f: Callable) -> Button:
	var b := Button.new()
	b.text = texte
	b.custom_minimum_size = Vector2(150, 40)
	b.pressed.connect(f)
	return b

func _placer() -> void:
	var milieu := size.y * 0.45
	vues[0].position = Vector2(size.x * 0.27 - 330, milieu - 285)
	vues[1].position = Vector2(size.x * 0.73 - 330, milieu - 285)
	nids[0].position = Vector2(20, size.y - nids[0].size.y - 20)
	nids[1].position = Vector2(size.x - nids[1].size.x - 20, size.y - nids[1].size.y - 20)
	boutons_ui.reset_size()
	boutons_ui.position = Vector2((size.x - boutons_ui.size.x) / 2, size.y - boutons_ui.size.y - 24)
	recap.position = (size - recap.size) / 2 - Vector2(0, 30)

# x1, x2, puis retour a x1. Le bouton affiche la vitesse en cours.
const VITESSES := [1.0, 2.0]

func _changer_vitesse() -> void:
	vitesse = VITESSES[(VITESSES.find(vitesse) + 1) % VITESSES.size()]
	vitesse_retenue = vitesse
	bouton_vitesse.text = "Vitesse x%d" % vitesse

func _rejouer() -> void:
	lecture = 0.0
	prochain = 0
	effets.clear()
	fini = false
	bandeau.visible = false
	recap.visible = false

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
			_elan(moi, "elan")
			# griffure sur la cible, au moment ou l'elan la touche
			_animer("griffe", cible.position + cible.size / 2 + Vector2(0, 10), 0.08, 0.32, 240.0, moi.miroir)
		"sort":
			# le cavalier frappe avec ses armes, la monture avec tout le reste
			_elan(moi, "elan_cavalier" if e["cavalier"] else "elan")
			var couleurs: Dictionary = Palette.ELEMENTS[e["element"]]
			var de: Vector2 = moi.position + moi.source(e["cavalier"])
			var a: Vector2 = cible.position + cible.size / 2 + Vector2(0, 20)
			var famille: String = e.get("famille", "")
			# l'arc tire des fleches (des plumes pour le Jour), les autres sorts leur comete
			var anim: String = "fleche" if famille == "tir" and e["element"] != "jour" else ANIM_PROJECTILE.get(e["element"], "")
			for k in maxi(e["coups"], 1):
				# arme de corps a corps : le coup se voit sur la cible, sans projectile
				if ANIM_ARME.has(famille):
					_animer(ANIM_ARME[famille], a, 0.08 + k * ECART_COUPS, 0.3, 260.0 if e["coups"] <= 1 else 180.0, moi.miroir)
					continue
				effets.append({"type": "projectile", "de": de, "a": a, "t0": lecture + k * ECART_COUPS,
					"duree": VOL_PROJECTILE, "couleur": couleurs["vif"], "coeur": couleurs["clair"],
					"taille": 12.0 if e["coups"] <= 1 else 6.0, "anim": anim})
				# un sort qui n'a pas sa propre comete eclate a l'arrivee
				if anim == "":
					_animer("coup", a, k * ECART_COUPS + VOL_PROJECTILE, 0.3, 150.0 if e["coups"] <= 1 else 90.0)
			var qui := "Cavalier : " if e["cavalier"] else ""
			_texte(moi, 0 if e["cavalier"] else 1, qui + e["nom"], couleurs["clair"])
		"bouclier":
			_animer("shield", _centre(moi), 0.0, 0.45, moi.size.x * 0.7)
			_texte(moi, 2, "+%d bouclier" % roundi(e["valeur"]), Palette.ELEMENTS["terre"]["clair"])
		"epines":
			# petite epine qui repart vers l'attaquant, sans texte (trop frequent)
			var n: Dictionary = Palette.ELEMENTS["nature"]
			effets.append({"type": "projectile", "de": moi.position + moi.size / 2 + Vector2(0, 20),
				"a": cible.position + cible.size / 2 + Vector2(0, 20), "t0": lecture,
				"duree": VOL_PROJECTILE * 0.6, "couleur": n["vif"], "coeur": n["clair"], "taille": 5.0})
		"combustion":
			var f: Dictionary = Palette.ELEMENTS["feu"]
			_animer("combustion", _centre(moi), 0.0, 0.5, moi.size.x * (0.8 if e["totale"] else 0.55))
			_texte(moi, 2, ("Combustion totale !" if e["totale"] else "Combustion") + " %d" % roundi(e["valeur"]), f["clair"])
		"eclat":
			# rayon de lumiere : beaucoup de petites lueurs en ligne, de l'autre monture vers moi
			var a: Dictionary = Palette.ELEMENTS["aube"]
			var de: Vector2 = cible.position + cible.source(false)
			for k in 8:
				effets.append({"type": "projectile", "de": de, "a": moi.position + moi.size / 2 + Vector2(0, 20),
					"t0": lecture + k * 0.03, "duree": VOL_PROJECTILE * 0.7, "couleur": a["vif"], "coeur": a["clair"], "taille": 11.0})
			_texte(moi, 2, "Éclat %d" % roundi(e["valeur"]), a["clair"])
		"arcane":
			# comete d'arcane : de l'autre monture vers moi
			var cp: Dictionary = Palette.ELEMENTS["crepuscule"]
			effets.append({"type": "projectile", "de": cible.position + cible.source(false),
				"a": moi.position + moi.size / 2 + Vector2(0, 20), "t0": lecture,
				"duree": VOL_PROJECTILE, "couleur": Color("#7b5cff"), "coeur": cp["clair"], "taille": 10.0, "anim": "arcane"})
		"illusion":
			_texte(moi, 2, "Illusion %d" % e["n"], Palette.ELEMENTS["crepuscule"]["clair"])
		"malediction":
			_animer("curse", _centre(moi), 0.0, 0.5, moi.size.x * 0.4)
			_texte(moi, 2, Data.NOMS_MALEDICTION[e["nom"]], Palette.ELEMENTS["nuit"]["clair"])
		"crit":
			_texte(moi, 2, "Critique !", Color("#f2c94c"))
		"soin":
			_animer("heal", _centre(moi), 0.0, 0.5, moi.size.x * 0.6)
		"relique":
			nids[e["cote"]].flash[e["id"]] = lecture
		"esquive":
			_animer("esquive", _centre(moi), 0.0, 0.4, moi.size.x * 0.7, moi.miroir)
			_texte(moi, 2, "Esquive", Palette.ELEMENTS["automne"]["clair"])
		"bourrasque":
			_texte(moi, 1, "Bourrasque", Palette.ELEMENTS["automne"]["clair"])
		"gel":
			_animer("freeze", _centre(moi), 0.0, 0.45, moi.size.x * 0.6)
			_texte(moi, 2, "Gel !", Palette.ELEMENTS["glace"]["clair"])
		"charge":
			_texte(moi, 1, "Charge ! %d" % roundi(e["valeur"]), Palette.ELEMENTS["nature"]["clair"])
		"dissipe":
			_texte(moi, 1, "Malus dissipés", Palette.ELEMENTS["crepuscule"]["clair"])
		"trait":
			_texte(moi, 2, "Trait de l'Ouest %d" % roundi(e["valeur"]), Color("#e8e4da"))
		"ouverture":
			_texte(moi, 1, "La porte du sanctuaire s'ouvre", Color("#c79bff"))
		"regard":
			_texte(moi, 2, "Le Regard %d" % roundi(e["valeur"]), Color("#e0c8ff"))
		"resistance":
			_texte(moi, 1, "Le cavalier referme la porte", Palette.TEXTE)
		"oeil_ouvert":
			_texte(moi, 1, "Un œil s'ouvre (%d)" % e["n"], Color("#ff8a8a"))
		"communion":
			_texte(moi, 1, "Communion : tous les yeux te regardent", Color("#c79bff"))
		"oeil_ferme":
			_texte(moi, 2, "Un œil se ferme", Palette.TEXTE)
		"maree":
			_texte(moi, 2, "Marée noire : %d frappes" % e["n"], Color("#e0c8ff"))
		"silence":
			_texte(moi, 1, "Silence : le cavalier reprend la main", Palette.TEXTE)
		"sceau_brise":
			_texte(moi, 1, "Un sceau se brise (%d/2)" % e["n"], Color("#f2c94c"))
		"sceau_libere":
			_texte(moi, 1, {"fissure": "La Fissure s'ouvre", "emprise": "L'Emprise s'éveille"}.get(e["nom"], ""), Color("#c79bff"))
		"prepare":
			_texte(moi, 1, "Il se dresse…", Palette.TEXTE)
		"grand_coup":
			_texte(moi, 2, "Grand coup %d" % roundi(e["valeur"]), Color("#ffb070"))
		"fissure":
			_texte(moi, 2, "Fissure : %d frappes" % e["n"], Color("#c79bff"))
		"entraves":
			_texte(moi, 1, "Entraves brisées !", Palette.ELEMENTS["feu"]["vif"])
		"renaissance":
			_texte(moi, 2, "%s renaît !" % nom, Palette.ELEMENTS["feu"]["clair"])
			moi.modulate = Color(2.2, 1.8, 1.2)
			create_tween().tween_property(moi, "modulate", Color.WHITE, 0.8)

# Sorts qui ont leur propre comete (images/spells) ; les autres eclatent en
# « coup » a l'arrivee.
const ANIM_PROJECTILE := {"feu": "feu", "crepuscule": "arcane", "glace": "glace", "aube": "lumiere",
	"nuit": "ombre", "nature": "poison", "jour": "plume", "automne": "automne_projectile"}
# Armes de corps a corps : leur coup joue sur la cible.
const ANIM_ARME := {"lame": "entaille_fine", "faux": "fauche", "hache": "hache", "hast": "epee"}

# Une animation de 4 images a pos, dans delai secondes, pendant duree.
func _animer(nom: String, pos: Vector2, delai: float, duree: float, taille: float, miroir := false) -> void:
	effets.append({"type": "anim", "anim": nom, "pos": pos, "t0": lecture + delai, "duree": duree,
		"taille": taille, "miroir": miroir})

# Une image d'animation fait `largeur` pour une case d'origine (3/4 de sa
# hauteur) ; les cases elargies par l'outil gardent la meme echelle.
static func _taille_anim(tex: Texture2D, largeur: float) -> Vector2:
	return tex.get_size() * largeur / (tex.get_height() * 0.75)

func _centre(v: CreatureVue) -> Vector2:
	return v.position + v.size / 2 + Vector2(0, 20)

func _elan(v: CreatureVue, qui: String) -> void:
	var tw := create_tween()
	tw.tween_property(v, qui, 24.0, 0.08 / vitesse)
	tw.tween_property(v, qui, 0.0, 0.14 / vitesse)

# Textes sur trois lignes fixes au-dessus de la monture, pour ne pas la cacher :
# 0 cavalier, 1 monture, 2 reactions (bouclier, renaissance).
func _texte(v: CreatureVue, ligne: int, texte: String, couleur: Color) -> void:
	var pos := v.position + Vector2(v.size.x / 2, 30 + ligne * 26)
	# deux textes au meme endroit en meme temps : le nouveau descend d'un cran
	# (vers le haut, il passerait sur la barre de PV) ; au-dela de 4, on l'oublie
	var crans := 0
	while effets.any(func(e): return e["type"] == "texte" and absf(e["pos"].x - pos.x) < 1.0 and absf(e["pos"].y - pos.y) < 22.0 and lecture - e["t0"] < 0.4):
		pos.y += 22
		crans += 1
		if crans >= TEXTES_MAX:
			return
	effets.append({"type": "texte", "pos": pos, "texte": texte, "couleur": couleur,
		"t0": lecture, "duree": DUREE_TEXTE})

func _fin() -> void:
	bandeau.visible = true
	recap.visible = true
	if vainqueur == -1:
		bandeau.text = "Égalité"
		bandeau.add_theme_color_override("font_color", Palette.TEXTE)
		return
	var cr: Dictionary = combat.cotes[vainqueur]["cr"]
	bandeau.text = ("Victoire !" if vainqueur == 0 else "Défaite") + "  (%s)" % cr["nom"]
	# un gardien vaincu n'est pas tue : il est libere de l'emprise
	var gardien: String = combat.cotes[1]["cr"].get("elite", "")
	if vainqueur == 0 and gardien in Data.GARDIENS:
		bandeau.text = "Purifié ! %s est libéré." % Data.GARDIENS[gardien]["nom"]
	bandeau.add_theme_color_override("font_color", Palette.ELEMENTS[cr["forme"]]["clair"])
	var perdant: CreatureVue = vues[1 - vainqueur]
	create_tween().tween_property(perdant, "modulate", Color(1, 1, 1, 0.25), 0.6)

# --- dessin ----------------------------------------------------------------

# Recharge des sorts du cote i au moment rejoue.
func recharges(i: int) -> Array:
	var k := clampi(int(lecture / Data.PAS), 0, combat.recharges.size() - 1)
	return combat.recharges[k][i]

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
		var etats := []
		if img[2 + i] > 0.0:
			etats.append(["Brûlure %d" % roundi(img[2 + i]), Palette.ELEMENTS["feu"]["vif"]])
		if img[12 + i] > 0:
			etats.append(["Illusions %d" % img[12 + i], Palette.ELEMENTS["crepuscule"]["clair"]])
		if img[22 + i] > 0.0:
			etats.append(["Éventail %d" % roundi(img[22 + i]), Palette.ELEMENTS["jour"]["clair"]])
		if img[6 + i] > 0.0:
			etats.append(["Poison %d" % roundi(img[6 + i]), Palette.POISON])
		if img[10 + i]:
			etats.append(["Gelé", Palette.ELEMENTS["glace"]["clair"]])
		elif img[8 + i] > 0.0:
			etats.append(["Givre %d" % roundi(img[8 + i]), Palette.ELEMENTS["glace"]["vif"]])
		if cr["eclat"]:
			var seuil := maxf(Data.ECLAT_SEUIL - cr["miroir"], Data.ECLAT_SEUIL_MIN)
			etats.append(["Éclat %d/%d" % [roundi(img[16 + i]), roundi(seuil)], Palette.ELEMENTS["aube"]["vif"]])
		# Bastion : la phase et l'eclat de l'oeil, aussi sur la bete
		if img[20 + i] != "":
			v.oeil = img[18 + i]
			v.phase = img[20 + i]
			var noms_phase := {"rempart": "Rempart", "ouverture": "L'œil s'ouvre", "resistance": "Sans protection",
				"eveil": "Éveil", "communion": "Communion", "silence": "Silence",
				"gardien": "Le Gardien", "fissure": "La Fissure", "emprise": "L'Emprise", "repit": "Répit"}
			var g: String = cr.get("elite", "")
			var detail := ""
			if g == "voix":
				detail = ", yeux %d" % roundi(img[18 + i] * Data.VOIX_YEUX_MAX)
			elif g == "sceau":
				detail = ", sceaux brisés %d/2" % roundi(img[18 + i] * 2)
			else:
				detail = ", œil %d %%" % roundi(img[18 + i] * 100)
			etats.append([noms_phase.get(img[20 + i], img[20 + i]) + detail, Color("#c79bff")])
		# cadre sombre sous le nom, la barre et les etats : lisible sur le fond peint
		var demi := maxf(162.0, 75.0 * etats.size() + 20.0)
		var bas := 62.0 if img[14 + i] != "" else 44.0
		calque.draw_rect(Rect2(x + 150 - demi, y - 36, demi * 2, bas + 36), Color(Palette.FOND, 0.7))
		calque.draw_string(Palette.police_titre(), Vector2(x, y - 12), cr["nom"], HORIZONTAL_ALIGNMENT_CENTER, 300, 20, Palette.TEXTE)
		var part := clampf(img[i] / cr["pv_max"], 0.0, 1.0)
		calque.draw_rect(Rect2(x, y, 300, 16), Palette.CASE)
		calque.draw_rect(Rect2(x, y, 300 * part, 16), Palette.ELEMENTS[cr["forme"]]["vif"])
		calque.draw_rect(Rect2(x, y, 300, 16), Palette.CASE_BORD, false, 1.0)
		# bouclier : fine barre sous les PV, visible meme quand les PV sont pleins
		var bouclier: float = img[4 + i]
		var texte := "%d / %d" % [maxi(ceili(img[i]), 0), cr["pv_max"]]
		if bouclier > 0.0:
			calque.draw_rect(Rect2(x, y + 17, 300 * clampf(bouclier / cr["pv_max"], 0.0, 1.0), 4), Color("#cfe3f2"))
			texte += "  +%d" % roundi(bouclier)
		calque.draw_string_outline(police, Vector2(x, y + 13), texte,
			HORIZONTAL_ALIGNMENT_CENTER, 300, 13, 3, Color(0, 0, 0, 0.7))
		calque.draw_string(police, Vector2(x, y + 13), texte,
			HORIZONTAL_ALIGNMENT_CENTER, 300, 13, Palette.TEXTE)
		if img[2 + i]:
			_brulure(v)
		if img[14 + i] != "":
			calque.draw_string(police, Vector2(x, y + 54), img[14 + i],
				HORIZONTAL_ALIGNMENT_CENTER, 300, 14, Palette.ELEMENTS["nuit"]["clair"])
		for k in etats.size():
			calque.draw_string(police, Vector2(x + 150 * k - 75 * (etats.size() - 1), y + 34), etats[k][0],
				HORIZONTAL_ALIGNMENT_CENTER, 300, 15, etats[k][1])
		if img[10 + i]:
			_gel(v)
	if lecture > Data.MORT_SUBITE and not fini:
		calque.draw_string(police, Vector2(0, 50), "Mort subite", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color("#e5834f"))
	for e in effets:
		var p: float = (lecture - e["t0"]) / e["duree"]
		if p < 0.0:
			continue
		match e["type"]:
			"projectile":
				var pos: Vector2 = e["de"].lerp(e["a"], p) + Vector2(0, -sin(p * PI) * 50)
				var images: Array = Palette.anim(e.get("anim", ""))
				if images.is_empty():
					calque.draw_circle(pos, e["taille"] * 1.6, Color(e["couleur"], 0.35))
					calque.draw_circle(pos, e["taille"], e["couleur"])
					calque.draw_circle(pos, e["taille"] * 0.45, e["coeur"])
				else:
					# la comete, tete vers la cible, en boucle sur ses 4 images
					var suivant: Vector2 = e["de"].lerp(e["a"], minf(p + 0.05, 1.0)) + Vector2(0, -sin(minf(p + 0.05, 1.0) * PI) * 50)
					var tex: Texture2D = images[int(lecture * 16.0) % images.size()]
					var taille := _taille_anim(tex, e["taille"] * 14.0)
					calque.draw_set_transform(pos, (suivant - pos).angle(), Vector2.ONE)
					calque.draw_texture_rect(tex, Rect2(Vector2(-taille.x * 0.8, -taille.y / 2), taille), false)
					calque.draw_set_transform(Vector2.ZERO)
			"anim":
				# une animation en 4 images, jouee une fois sur sa duree
				var images: Array = Palette.anim(e["anim"])
				if not images.is_empty():
					var tex: Texture2D = images[mini(int(p * images.size()), images.size() - 1)]
					var taille := _taille_anim(tex, e["taille"])
					calque.draw_set_transform(e["pos"], 0.0, Vector2(-1.0 if e["miroir"] else 1.0, 1.0))
					calque.draw_texture_rect(tex, Rect2(-taille / 2, taille), false)
					calque.draw_set_transform(Vector2.ZERO)
			"texte":
				var c: Color = e["couleur"]
				c.a = 1.0 - p * p
				calque.draw_string(police, e["pos"] + Vector2(-150, -p * 30), e["texte"],
					HORIZONTAL_ALIGNMENT_CENTER, 300, 18, c)

# Monture gelee : halo de glace et eclats autour d'elle.
func _gel(v: CreatureVue) -> void:
	var g: Dictionary = Palette.ELEMENTS["glace"]
	var centre := v.position + v.size / 2 + Vector2(0, 30)
	calque.draw_circle(centre, 140, Color(g["vif"], 0.16))
	calque.draw_arc(centre, 140, 0.0, TAU, 64, Color(g["clair"], 0.7), 3.0)
	for k in 7:
		var a := TAU * k / 7.0
		var p := centre + Vector2(cos(a) * 130, sin(a) * 90)
		var dir := Vector2(cos(a), sin(a))
		calque.draw_colored_polygon(PackedVector2Array([p - dir.orthogonal() * 7, p + dir * 26, p + dir.orthogonal() * 7]),
			Color(g["clair"], 0.85))

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

# --- Nid en combat ---------------------------------------------------------

# Le Nid d'un cote, en petit : chaque relique a sorts se remplit avec sa
# recharge et s'allume quand elle part. Survol : l'infobulle de la relique.
class MiniNid extends Control:
	const ECART := 0.0   # cases jointives, comme le tapis du sac
	var ecran: CombatScreen
	var cote: int
	var cr: Dictionary
	var sort_de := {}   # case -> index du sort
	var flash := {}     # relique -> moment ou elle a agi (lecture)
	var ouvertes: Array  # cases ouvertes du sac
	var boite: Rect2i    # le rectangle du damier qu'elles occupent
	var CASE := 44.0
	func _init(e: CombatScreen, i: int) -> void:
		ecran = e
		cote = i
		cr = e.combat.cotes[i]["cr"]
		for k in cr["sorts"].size():
			sort_de[cr["sorts"][k]["case"]] = k
		ouvertes = cr.get("ouvertes", Nid.toutes())
		boite = NidScreen.boite(ouvertes)
		# le plus grand possible dans son coin : jusqu'a 440 x 210, cases de 80 au plus
		CASE = minf(80.0, minf(440.0 / boite.size.x, 210.0 / boite.size.y))
		size = Vector2(boite.size) * (CASE + ECART) - Vector2(ECART, ECART)
		tooltip_text = " "
	# Cases de la relique d'ancre a (sa forme si le sac en a).
	func _cases(a: Vector2i) -> Array:
		if not cr.get("encombrement", false):
			return [a]
		return Data.empreinte(cr["cases"][a], cr["rotations"].get(a, 0)).map(func(d): return a + d)
	func _ancre_sous(p: Vector2):
		if p.x < 0 or p.y < 0:
			return null
		var c := boite.position + Vector2i(p / (CASE + ECART))
		for a in cr["cases"]:
			if c in _cases(a):
				return a
		return null
	func _get_tooltip(p: Vector2) -> String:
		var a = _ancre_sous(p)
		return "" if a == null else NidScreen.info(cr["cases"][a])
	func _make_custom_tooltip(_t: String) -> Object:
		var a = _ancre_sous(get_local_mouse_position())
		return null if a == null else NidScreen.bulle(cr["cases"][a], cr["niveaux"].get(a, 1))
	func _process(_d: float) -> void:
		queue_redraw()
	# Case du sac -> rectangle a l'ecran, agrandi de la moitie de l'ecart pour
	# que les cases d'une meme relique se touchent.
	func _rect(c: Vector2i) -> Rect2:
		var pas := CASE + ECART
		return Rect2(Vector2(c - boite.position) * pas, Vector2(CASE, CASE)).grow(ECART / 2)
	func _draw() -> void:
		var police := ThemeDB.fallback_font
		NidScreen.dessiner_tapis(self, ouvertes, CASE, Vector2.ZERO, boite.position)
		var prog := ecran.recharges(cote)
		for a in cr["cases"]:
			var id: String = cr["cases"][a]
			var cellules := []
			for c in _cases(a):
				cellules.append(_rect(c))
			NidScreen.dessiner_forme(self, cellules, id, cr["niveaux"].get(a, 1), CASE + ECART)
			# une essence qui vient d'agir s'allume un instant
			var age: float = ecran.lecture - flash.get(id, -9.0)
			if age >= 0.0 and age < 0.4:
				var clair: Color = Palette.ELEMENTS[Data.RELIQUES[id]["element"]]["clair"]
				for r in cellules:
					draw_rect(r, Color(clair, 0.5 * (1.0 - age / 0.4)))
					draw_rect(r, clair, false, 2.0)
			# recharge : une seule jauge pour toute la relique, qui se devoile de bas
			# en haut sur sa hauteur entiere, et la relique s'allume au depart
			if sort_de.has(a):
				var p: float = prog[sort_de[a]]
				if p >= 0.0:
					var boite: Rect2 = cellules[0]
					for r in cellules:
						boite = boite.merge(r)
					var ombre := Rect2(boite.position, Vector2(boite.size.x, boite.size.y * (1.0 - p)))
					for r in cellules:
						var morceau: Rect2 = r.grow(-ECART / 2).intersection(ombre)
						if morceau.has_area():
							draw_rect(morceau, Color(0, 0, 0, 0.55))
						if p < 0.12:
							draw_rect(r.grow(-ECART / 2), Color(Palette.ELEMENTS[Data.RELIQUES[id]["element"]]["clair"], 0.45))

# --- recap -----------------------------------------------------------------

# Fin de combat : pour chaque cote, ce qui a fait le plus de degats, de soins,
# de bouclier, et combien de fois c'est parti. Survol d'une relique : son infobulle.
class Recap extends Control:
	const MECANIQUES := {"~attaque": "Attaques", "~poison": "Poison", "~brulure": "Brûlure",
		"~combustion": "Combustion", "~epines": "Épines", "~eclat": "Éclat",
		"~regen": "Régénération", "~illusion": "Illusions", "~renaissance": "Renaissance", "~racines": "Racines",
		"~charge": "Charge", "~trait": "Trait de l'Ouest", "~rempart": "Rempart", "~regard": "Le Regard",
		"~maree": "Marée noire", "~gardien": "Grand coup", "~fissure": "Fissure", "~emprise": "Emprise",
		"~faiblesse": "Faiblesse", "~fletrissure": "Flétrissure", "~stigmate": "Stigmate", "~givre": "Givre", "~gel": "Gel"}
	# Ce que chaque malus a fait a l'adversaire, en clair.
	const IMPACTS := {"~faiblesse": "%d dégâts évités", "~fletrissure": "%d soins empêchés",
		"~stigmate": "+%d dégâts", "~givre": "%.1f s volées", "~gel": "%.1f s volées",
		"pacte": "+%d dégâts", "oeil_chasseur": "+%d dégâts de crit", "belladone": "%d soins bloqués",
		"lanterne": "%d d'Éclat chargé", "coeur_fournaise": "%.1f brûlures gardées", "coeur_banquise": "%.1f givre gardé"}
	const MALUS := Color("#6a3a9c")
	const LIGNES := 10
	const BORD := 44.0   # epaisseur du cadre de la fenetre
	const LARGEUR := 470.0
	const HAUTEUR_LIGNE := 34.0
	const DEGATS := Color("#b5461c")
	const SOINS := Color("#3d7a1e")
	const BOUCLIER := Color("#2d6596")
	var combat: Combat
	var lignes: Array = [[], []]   # par cote : [source, valeurs]
	func _init(c: Combat) -> void:
		combat = c
		var n := 0
		for i in 2:
			var l := []
			for source in c.stats[i]:
				l.append([source, c.stats[i][source]])
			l.sort_custom(func(a, b): return _poids(a[0], a[1]) > _poids(b[0], b[1]))
			lignes[i] = l.slice(0, LIGNES)
			n = maxi(n, lignes[i].size())
		size = Vector2(LARGEUR * 2 + 60, 84 + n * HAUTEUR_LIGNE + 34) + Vector2.ONE * BORD * 2
		tooltip_text = " "
		mouse_filter = Control.MOUSE_FILTER_PASS
	# Un malus pese par son impact ; une seconde volee compte comme 10 PV.
	static func _poids(source: String, v: Dictionary) -> float:
		var impact: float = v.get("impact", 0.0) * (10.0 if source in ["~givre", "~gel"] else 1.0)
		return v["degats"] + v["soins"] + v["bouclier"] + impact
	func _source_sous(p: Vector2):
		p -= Vector2.ONE * BORD
		var i := 0 if p.x < size.x / 2 - BORD else 1
		var k := int((p.y - 84) / HAUTEUR_LIGNE)
		if p.y < 84 or k >= lignes[i].size():
			return null
		var source: String = lignes[i][k][0]
		return null if source.begins_with("~") else source
	func _get_tooltip(p: Vector2) -> String:
		var s = _source_sous(p)
		return "" if s == null else NidScreen.info(s)
	func _make_custom_tooltip(_t: String) -> Object:
		var s = _source_sous(get_local_mouse_position())
		return null if s == null else NidScreen.bulle(s)
	func _nom(source: String) -> String:
		return MECANIQUES.get(source, Data.RELIQUES[source]["nom"] if Data.RELIQUES.has(source) else source)
	func _draw() -> void:
		var police := ThemeDB.fallback_font
		draw_style_box(Palette.fenetre(), Rect2(Vector2.ZERO, size))
		draw_set_transform(Vector2.ONE * BORD)
		var dedans := size - Vector2.ONE * BORD * 2
		draw_string(Palette.police_titre(), Vector2(0, 34), "Récap du combat", HORIZONTAL_ALIGNMENT_CENTER, dedans.x, 22, Palette.ENCRE_TITRE)
		for i in 2:
			var x0 := 24.0 + i * (LARGEUR + 12)
			var cr: Dictionary = combat.cotes[i]["cr"]
			draw_string(police, Vector2(x0, 70), ("Toi" if i == 0 else "Adversaire") + " (%s)" % cr["nom"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.ELEMENTS[cr["forme"]]["fond"])
			var maxi := 1.0
			for l in lignes[i]:
				maxi = maxf(maxi, maxf(l[1]["degats"], maxf(l[1]["soins"], l[1]["bouclier"])))
			for k in lignes[i].size():
				var source: String = lignes[i][k][0]
				var v: Dictionary = lignes[i][k][1]
				var y: float = 84.0 + k * HAUTEUR_LIGNE
				var tex := Palette.icone(source) if Data.RELIQUES.has(source) else null
				if tex != null:
					var kk := minf(26.0 / tex.get_width(), 26.0 / tex.get_height())
					draw_texture_rect(tex, Rect2(Vector2(x0, y + 3), tex.get_size() * kk), false)
				else:
					draw_circle(Vector2(x0 + 13, y + 16), 6, Palette.ENCRE_DOUCE)
				draw_string(police, Vector2(x0 + 34, y + 21), _nom(source), HORIZONTAL_ALIGNMENT_LEFT, 150, 14, Palette.ENCRE)
				# une barre par valeur, a l'echelle de la plus grande du cote
				var bx: float = x0 + 190
				var by: float = y + 6
				for champ in [["degats", DEGATS], ["soins", SOINS], ["bouclier", BOUCLIER]]:
					var val: float = v[champ[0]]
					if val <= 0.0:
						continue
					draw_rect(Rect2(bx, by, 150 * val / maxi, 6), champ[1])
					by += 8
				var textes := []
				if v["degats"] > 0.0:
					textes.append(["%d" % roundi(v["degats"]), DEGATS])
				if v["soins"] > 0.0:
					textes.append(["+%d" % roundi(v["soins"]), SOINS])
				if v["bouclier"] > 0.0:
					textes.append(["%d" % roundi(v["bouclier"]), BOUCLIER])
				if v["activations"] > 0.0:
					textes.append(["x%d" % roundi(v["activations"]), Palette.ENCRE_DOUCE])
				if v.get("impact", 0.0) > 0.0 and IMPACTS.has(source):
					textes.append([(IMPACTS[source] % v["impact"]).replace(".", ","), MALUS])
				var tx: float = x0 + 350
				for t in textes:
					draw_string(police, Vector2(tx, y + 21), t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, t[1])
					tx += police.get_string_size(t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 10
		# legende
		var lx := 24.0
		for l in [["Dégâts", DEGATS], ["Soins", SOINS], ["Bouclier", BOUCLIER], ["Effet des malus", MALUS], ["xN : activations", Palette.ENCRE_DOUCE]]:
			draw_rect(Rect2(lx, dedans.y - 20, 10, 10), l[1])
			draw_string(police, Vector2(lx + 16, dedans.y - 10), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.ENCRE_DOUCE)
			lx += police.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 40
