class_name NidScreen
extends Control

# Ecran du Nid : boutique (3 x 3 offres) a gauche, reserve et sac a droite.
# Glisser une offre dans une case vide l'achete, glisser une case vers une
# autre echange, la ramener sur le comptoir la revend.

signal continuer
signal nouvelle_partie

const TUILE := Vector2(124, 64)
const CASE_TAILLE := Vector2(104, 104)

var partie := Partie.new()
var nid: Nid:
	get: return partie.nid
var cases_ui := {}   # Vector2i -> CaseNid
var barre: Label
var compteurs := {}     # vie, victoires, or -> Label
var niveau_ui: Label    # niveau et experience
var message_ui: Label
var offres_ui: Array = []
var relance: Button
var agrandir: Button
var bouton_combat: Button
var sac: Control
var haut: Control
var boutique_ui: Control
var aide_ui: Control
var vente: Control
var reserve_ui: Control
var reserve_cases: Array = []
var revente := -1        # prix de revente de la relique tenue depuis le sac, -1 sinon
var bandeau_vente: Label
# Relique tenue : rotation (R ou molette) et case saisie dans sa forme.
var rot_prise := 0
var prise := Vector2i.ZERO
var pose_vue := {}       # apercu de la pose en cours : {cases, ok}
var case_survolee = null # case du sac sous la souris
var choix_case := false  # Agrandir : on clique la case du sac a ouvrir

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fond := ColorRect.new()
	fond.color = Palette.FOND
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	# l'echoppe peinte, qui couvre tout l'ecran sans se deformer
	var peint := TextureRect.new()
	peint.texture = Palette.image("res://images/boutique_fond.png")
	peint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	peint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	peint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	peint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(peint)

	# le sac : un tapis assemble en tuiles, une par colonne ouverte
	sac = Tapis.new(self)
	add_child(sac)
	for y in Data.NID_H:
		for x in Data.NID_L:
			var c := CaseNid.new(self, Vector2i(x, y))
			cases_ui[c.position_nid] = c
			sac.add_child(c)

	# bandeau : acte, vie, victoires, or, puis le message du dernier noeud
	var bandeau := HBoxContainer.new()
	bandeau.add_theme_constant_override("separation", 34)
	barre = Palette.titre(_titre(""))
	bandeau.add_child(barre)
	for nom in ["vie", "victoires", "or"]:
		var c: Array = Palette.compteur(nom, 20)
		compteurs[nom] = c[1]
		bandeau.add_child(c[0])
	niveau_ui = _titre("")
	niveau_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	niveau_ui.tooltip_text = "Le niveau monte d'un point d'expérience par nœud franchi. Chaque niveau : +%d PV pour la monture et une case de sac offerte." % Partie.PV_PAR_NIVEAU
	bandeau.add_child(niveau_ui)
	message_ui = _titre("")
	message_ui.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	bandeau.add_child(message_ui)
	haut = _cadre(bandeau)
	add_child(haut)
	# tout le comptoir est une zone de vente, sous les offres
	vente = ZoneVente.new(self)
	add_child(vente)
	# les offres sont posees sur le comptoir peint, sans cadre
	boutique_ui = _boutique()
	add_child(boutique_ui)
	bouton_combat = Button.new()
	bouton_combat.custom_minimum_size = Vector2(360, 44)
	bouton_combat.pressed.connect(_combattre)
	add_child(bouton_combat)
	reserve_ui = _cadre(_reserve())
	add_child(reserve_ui)
	var aide := Label.new()
	aide.text = "Glisse pour acheter, R ou molette pour tourner. 3 copies (sac ou réserve) : ★, puis 2 ★ : ★★.
Ramène un objet sur le comptoir pour le revendre. Clic droit sur une offre : la verrouiller (elle reste aux relances)."
	aide.add_theme_font_size_override("font_size", 13)
	aide.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	aide_ui = _cadre(aide)
	add_child(aide_ui)
	# bandeau de revente, au premier plan, qui ne capte pas la souris
	bandeau_vente = Label.new()
	bandeau_vente.add_theme_font_size_override("font_size", 24)
	bandeau_vente.add_theme_color_override("font_color", Color("#f2c94c"))
	var fond_bandeau := StyleBoxFlat.new()
	fond_bandeau.bg_color = Color(Palette.FOND, 0.92)
	fond_bandeau.set_content_margin_all(12)
	fond_bandeau.set_corner_radius_all(6)
	bandeau_vente.add_theme_stylebox_override("normal", fond_bandeau)
	bandeau_vente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bandeau_vente.visible = false
	add_child(bandeau_vente)
	# des cases offertes a placer : on propose tout de suite de les choisir
	choix_case = partie.cases_offertes > 0
	resized.connect(_placer)
	_placer()
	rafraichir()

func _placer() -> void:
	var marge := 20.0
	haut.position = Vector2(marge, 14)
	haut.size = Vector2(size.x - 2 * marge, 0)
	# a gauche le comptoir (offres) ; a droite la reserve, le sac, puis le bouton
	var droite := size.x * 0.5
	aide_ui.reset_size()
	aide_ui.position = Vector2(marge, size.y - aide_ui.size.y - 6)
	vente.position = Vector2(marge, 70)
	vente.size = Vector2(droite - 2 * marge, aide_ui.position.y - 10 - 70)
	boutique_ui.reset_size()
	boutique_ui.position = vente.position + (vente.size - boutique_ui.size) / 2
	reserve_ui.reset_size()
	reserve_ui.position = Vector2(size.x - reserve_ui.size.x - marge, 80)
	bouton_combat.reset_size()
	var largeur := size.x - marge - droite
	bouton_combat.position = Vector2(droite + (largeur - bouton_combat.size.x) / 2, size.y - bouton_combat.size.y - marge)
	# le sac prend la place libre entre les deux, en cases carrees : tout le
	# damier, pour qu'on voie ou il peut grandir
	var dessus := reserve_ui.position.y + reserve_ui.size.y + 14
	var dessous := bouton_combat.position.y - 14
	var cote := minf((dessous - dessus) / Data.NID_H, largeur / Data.NID_L)
	sac.cote = cote
	sac.position = Vector2(droite + (largeur - Data.NID_L * cote) / 2, dessus + (dessous - dessus - Data.NID_H * cote) / 2)
	sac.size = Vector2(Data.NID_L, Data.NID_H) * cote
	for c in cases_ui:
		cases_ui[c].position = Vector2(c) * cote
		cases_ui[c].size = Vector2(cote, cote)
	_cases_visibles()

# Les cases ouvertes, et pendant Agrandir celles qu'on peut ouvrir.
func _cases_visibles() -> void:
	var bord := nid.bordure() if choix_case else []
	for c in cases_ui:
		cases_ui[c].visible = nid.ouverte(c) or c in bord
	sac.queue_redraw()

func ouvrir(c: Vector2i) -> void:
	if partie.agrandir(c):
		choix_case = partie.cases_offertes > 0
	rafraichir()

# Cadre sombre sous une zone, pour lire le texte sur le fond peint.
func _cadre(contenu: Control) -> PanelContainer:
	var c := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FOND, 0.8)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	c.add_theme_stylebox_override("panel", style)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.add_child(contenu)
	return c

func _titre(texte: String) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Palette.TEXTE)
	return l

func _boutique() -> Control:
	var col := Boutique.new(self)
	col.add_theme_constant_override("separation", 6)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 6)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for i in Partie.TAILLE_BOUTIQUE:
		var o := Offre.new(self, i)
		offres_ui.append(o)
		g.add_child(o)
	col.add_child(g)
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 8)
	boutons.alignment = BoxContainer.ALIGNMENT_CENTER
	relance = Button.new()
	relance.custom_minimum_size = Vector2(150, 34)
	relance.pressed.connect(func():
		partie.relancer()
		rafraichir())
	boutons.add_child(relance)
	agrandir = Button.new()
	agrandir.custom_minimum_size = Vector2(150, 34)
	agrandir.tooltip_text = "Puis clique une case collée au sac pour l'ouvrir."
	agrandir.pressed.connect(func():
		choix_case = not choix_case
		rafraichir())
	boutons.add_child(agrandir)
	col.add_child(boutons)
	return col

func _reserve() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var t := Label.new()
	t.text = "Réserve (sans effet)"
	t.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	col.add_child(t)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for k in Partie.TAILLE_RESERVE:
		var c := CaseReserve.new(self, k)
		reserve_cases.append(c)
		g.add_child(c)
	col.add_child(g)
	return col

# --- actions ---------------------------------------------------------------

# depuis : case d'origine si on deplace une relique deja posee, null sinon.
# Un glisser de relique (offre, sac, reserve ou main) ?
static func glisse(data) -> bool:
	return data is Dictionary and data.has("id") and (data.has("offre") or data.has("depuis") or data.has("reserve") or data.has("main"))

# Apres une pose : si une relique a ete delogee, on la reprend en main tout de
# suite, pour la reposer ailleurs.
func apres_pose() -> void:
	rafraichir()
	if not partie.main.is_empty():
		call_deferred("_reprendre")

func _reprendre() -> void:
	if partie.main.is_empty():
		return
	rot_prise = partie.main.get("rot", 0)
	prise = Vector2i.ZERO
	montrer_vente(Partie.prix_revente(partie.main["id"], partie.main["niv"]))
	force_drag({"id": partie.main["id"], "main": true}, apercu(partie.main["id"]))

# La main lachee nulle part : en reserve, sinon dans le sac, sinon revendue.
func _fin_glisser() -> void:
	if not get_viewport().gui_is_dragging() and not partie.main.is_empty():
		partie.poser_main()
		rafraichir()

# depuis : ancre de la relique deplacee, ou null pour poser id directement.
func deposer(c: Vector2i, id: String, depuis, rot := -1) -> void:
	if depuis != null:
		nid.deplacer(depuis, c, rot)
	elif nid.accepte(c, id, null):
		nid.retirer(c)
		nid.placer(c, id)
	rafraichir()

func acheter(i: int, c: Vector2i, rot := 0) -> void:
	partie.acheter(i, c, rot)
	rafraichir()

# Pendant qu'on tient une relique : R ou la molette la tournent d'un quart.
func _input(ev: InputEvent) -> void:
	if not get_viewport().gui_is_dragging():
		return
	var tourne: bool = ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_R
	tourne = tourne or (ev is InputEventMouseButton and ev.pressed and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN])
	if tourne:
		rot_prise = (rot_prise + 1) % 4
		prise = Vector2i.ZERO
		pose_vue = {}
		sac.queue_redraw()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and sac != null:
		pose_vue = {}
		vente.survol = false
		montrer_vente(-1)
		sac.queue_redraw()
		call_deferred("_fin_glisser")

# Pendant qu'on tient une relique du sac : le comptoir s'eclaire, les offres
# s'estompent et un bandeau donne le prix de revente. prix < 0 : on cache.
func montrer_vente(prix: int) -> void:
	revente = prix
	vente.queue_redraw()
	boutique_ui.modulate.a = 0.3 if prix >= 0 else 1.0
	bandeau_vente.visible = prix >= 0
	if prix >= 0:
		bandeau_vente.text = "Lâche sur le comptoir pour revendre : +%d or" % prix
		bandeau_vente.reset_size()
		bandeau_vente.position = vente.position + (vente.size - bandeau_vente.size) / 2

func vendre(c: Vector2i) -> void:
	partie.vendre(c)
	rafraichir()

func rafraichir() -> void:
	var prix_sac := partie.prix_agrandir()
	if prix_sac < 0 or partie.bourse < prix_sac or partie.terminee():
		choix_case = false
	_cases_visibles()
	for c in cases_ui:
		cases_ui[c].queue_redraw()
	for c in reserve_cases:
		c.queue_redraw()
	for o in offres_ui:
		o.queue_redraw()
	relance.text = "Relancer (%s)" % ("gratuit" if partie.prix_relance() == 0 else "%d or" % partie.prix_relance())
	relance.disabled = partie.bourse < partie.prix_relance() or partie.terminee()
	if prix_sac < 0:
		agrandir.text = "Sac complet"
	elif choix_case:
		agrandir.text = "Choisis une case"
	elif partie.cases_offertes > 0:
		agrandir.text = "Agrandir (offert x%d)" % partie.cases_offertes
	else:
		agrandir.text = "Agrandir (%d or)" % prix_sac
	agrandir.disabled = prix_sac < 0 or partie.bourse < prix_sac or partie.terminee()
	barre.text = "Acte %d" % (partie.acte + 1)
	compteurs["vie"].text = "%d / %d" % [maxi(partie.ferveur, 0), Partie.FERVEUR]
	compteurs["victoires"].text = "%d" % partie.victoires
	compteurs["or"].text = "%d" % partie.bourse
	var suivant := partie.xp_suivant()
	niveau_ui.text = "Niveau %d" % partie.niveau() + ("" if suivant < 0 else "  (%d / %d XP)" % [partie.xp(), suivant])
	message_ui.text = partie.message
	if partie.terminee():
		bouton_combat.text = ("Run gagnée !" if partie.gagnee else "Run perdue.") + " Nouvelle partie"
	else:
		bouton_combat.text = "Vers la carte"
	if not partie.fusion.is_empty():
		_animer_fusion(partie.fusion)
		partie.fusion = {}

# Cellules d'un lieu de la partie ({"depuis": ancre} ou {"reserve": k}) dans
# le repere de l'ecran, et leur cote. cases : celles d'une relique deja retiree.
func _cellules(lieu: Dictionary, cases := []) -> Array:
	if lieu.has("reserve"):
		var r: Rect2 = reserve_cases[lieu["reserve"]].get_global_rect()
		return [[Rect2(r.position - global_position, r.size)], r.size.x]
	if cases.is_empty():
		cases = nid.cases_de(lieu["depuis"])
	var l := []
	for k in cases:
		l.append(Rect2(sac.global_position - global_position + Vector2(k) * sac.cote, Vector2(sac.cote, sac.cote)))
	return [l, sac.cote]

func _animer_fusion(f: Dictionary) -> void:
	var e := EffetFusion.new()
	var cible := _cellules(f["lieu"])
	e.cible = cible[0]
	e.niv = f["niv"]
	for a in f["absorbees"]:
		var c := _cellules(a["lieu"], a["cases"])
		e.copies.append({"id": a["id"], "cellules": c[0], "cote": c[1]})
	add_child(e)

# Les affinites portent le nom de la dynastie de leur element.
const _NOMS_ELEMENTS := {"nature": "Printemps", "feu": "Été", "automne": "Automne", "glace": "Hiver",
	"aube": "Aube", "jour": "Jour", "crepuscule": "Crépuscule", "nuit": "Nuit"}

func _combattre() -> void:
	if partie.terminee():
		nouvelle_partie.emit()
	else:
		continuer.emit()

# --- elements d'interface --------------------------------------------------

# nom : false dans le sac, ou l'infobulle donne le nom et l'icone prend toute la case.
static func dessiner_relique(ci: CanvasItem, rect: Rect2, id: String, niv := 1, nom := true) -> void:
	var r: Dictionary = Data.RELIQUES[id]
	var couleurs: Dictionary = Palette.ELEMENTS[r["element"]]
	var police := ThemeDB.fallback_font
	var cadre := rect.grow(-3)
	ci.draw_rect(cadre, couleurs["fond"])
	ci.draw_rect(cadre, couleurs["vif"], false, 2.0)
	# rarete : bande de couleur en bas de la tuile (rien pour un commun)
	var rarete := Data.rarete(id)
	if rarete != "commun":
		ci.draw_rect(Rect2(cadre.position.x, cadre.end.y - 5, cadre.size.x, 5), Palette.RARETES[rarete])
	var tex := Palette.icone(id)
	if tex == null:
		var milieu := rect.position.y + rect.size.y / 2
		ci.draw_string(police, Vector2(rect.position.x, milieu), r["nom"],
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Palette.TEXTE)
		ci.draw_string(police, Vector2(rect.position.x, milieu + 18), r["type"],
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, couleurs["clair"])
	elif rect.size.x > rect.size.y * 1.4:
		# tuile large (boutique) : icone a gauche, nom a droite sur deux lignes
		var cote := cadre.size.y - 10
		_icone(ci, tex, Rect2(cadre.position + Vector2(5, 5), Vector2(cote, cote)))
		var x := cadre.position.x + cote + 10
		ci.draw_multiline_string(police, Vector2(x, cadre.position.y + 22), r["nom"],
			HORIZONTAL_ALIGNMENT_LEFT, cadre.end.x - x - 4, 12, 2, Palette.TEXTE)
	elif not nom:
		_icone(ci, tex, cadre.grow(-6))
	else:
		# case du Nid : icone en haut, nom en bas
		_icone(ci, tex, Rect2(cadre.position + Vector2(8, 6), Vector2(cadre.size.x - 16, cadre.size.y - 34)))
		ci.draw_string(police, Vector2(rect.position.x, cadre.end.y - 11), r["nom"],
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Palette.TEXTE)
	# niveau : une etoile par niveau au-dessus du premier, en haut de la tuile
	if niv > 1:
		ci.draw_string(police, Vector2(rect.position.x, rect.position.y + 20), "★".repeat(niv - 1),
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, Color("#f2c94c"))

# Une relique sur ses cases : fond de son element (les cases d'une meme
# relique se rejoignent), contour a la couleur de sa rarete, icone sur
# l'ensemble, etoiles de niveau. cote : taille d'une case.
static func dessiner_forme(ci: CanvasItem, cellules: Array, id: String, niv: int, cote: float, survol := false) -> void:
	var r: Dictionary = Data.RELIQUES[id]
	var couleurs: Dictionary = Palette.ELEMENTS[r["element"]]
	var rarete := Data.rarete(id)
	var bord: Color = Palette.RARETES[rarete] if rarete != "commun" else couleurs["vif"]
	var marge := cote * 0.12
	var boite: Rect2 = cellules[0]
	for c in cellules:
		boite = boite.merge(c)
	for c in cellules:
		# on ne rentre que sur les cotes qui ne touchent pas une autre case de la relique
		var g := 0.0 if cellules.has(Rect2(c.position - Vector2(cote, 0), c.size)) else marge
		var d := 0.0 if cellules.has(Rect2(c.position + Vector2(cote, 0), c.size)) else marge
		var h := 0.0 if cellules.has(Rect2(c.position - Vector2(0, cote), c.size)) else marge
		var b := 0.0 if cellules.has(Rect2(c.position + Vector2(0, cote), c.size)) else marge
		var plein := Rect2(c.position + Vector2(g, h), c.size - Vector2(g + d, h + b))
		ci.draw_rect(plein, couleurs["fond"].lightened(0.12) if survol else couleurs["fond"])
		if g > 0.0:
			ci.draw_line(plein.position, Vector2(plein.position.x, plein.end.y), bord, 2.0)
		if d > 0.0:
			ci.draw_line(Vector2(plein.end.x, plein.position.y), plein.end, bord, 2.0)
		if h > 0.0:
			ci.draw_line(plein.position, Vector2(plein.end.x, plein.position.y), bord, 2.0)
		if b > 0.0:
			ci.draw_line(Vector2(plein.position.x, plein.end.y), plein.end, bord, 2.0)
		# catalyseur : une fleche vers l'exterieur sur chaque cote libre, pour
		# montrer qu'il renforce ce qui le touche
		if r["type"] == "catalyseur":
			var f := cote * 0.09
			var jaune := Color("#f2c94c")
			var centre: Vector2 = c.get_center()
			for cote_libre in [[g, Vector2(-1, 0)], [d, Vector2(1, 0)], [h, Vector2(0, -1)], [b, Vector2(0, 1)]]:
				if cote_libre[0] <= 0.0:
					continue
				var dir: Vector2 = cote_libre[1]
				var pointe: Vector2 = centre + dir * (c.size.x / 2 - 1)
				var base: Vector2 = pointe - dir * f * 1.4
				var perp := Vector2(-dir.y, dir.x) * f
				var tri := PackedVector2Array([pointe, base + perp, base - perp])
				ci.draw_colored_polygon(tri, jaune)
				ci.draw_polyline(PackedVector2Array([pointe, base + perp, base - perp, pointe]), Color(0, 0, 0, 0.6), 1.0, true)
	var tex := Palette.icone(id)
	if tex != null:
		_icone(ci, tex, boite.grow(-marge - 4))
	else:
		ci.draw_string(ThemeDB.fallback_font, Vector2(boite.position.x, boite.get_center().y), r["nom"],
			HORIZONTAL_ALIGNMENT_CENTER, boite.size.x, 12, Palette.TEXTE)
	if niv > 1:
		ci.draw_string(ThemeDB.fallback_font, Vector2(boite.position.x, boite.position.y + marge + 16), "★".repeat(niv - 1),
			HORIZONTAL_ALIGNMENT_CENTER, boite.size.x, 16, Color("#f2c94c"))

# Icone centree dans la zone, proportions gardees.
static func _icone(ci: CanvasItem, tex: Texture2D, zone: Rect2) -> void:
	var k := minf(zone.size.x / tex.get_width(), zone.size.y / tex.get_height())
	var taille := tex.get_size() * k
	ci.draw_texture_rect(tex, Rect2(zone.position + (zone.size - taille) / 2, taille), false)

static func info(id: String) -> String:
	var r: Dictionary = Data.RELIQUES[id]
	var genre: String = r["type"]
	if r.has("famille"):
		genre = "arme (%s)" % Data.FAMILLES[r["famille"]]
	return "%s\n%s, %s" % [r["nom"], Data.NOMS_RARETE[Data.rarete(id)], genre]

# Infobulle d'une relique : nom a la couleur de sa rarete, genre, Cour,
# affinite, puis ce qu'elle fait.
const TROP_CHER := Color("#e5604f")

static func bulle(id: String, niv := 1, manque := 0) -> Control:
	var r: Dictionary = Data.RELIQUES[id]
	var rarete := Data.rarete(id)
	var pile := VBoxContainer.new()
	pile.add_theme_constant_override("separation", 6)
	# en tete : le blason de la dynastie, puis le nom
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 10)
	var blason := Palette.blason(r["element"])
	if blason != null:
		var ic := TextureRect.new()
		ic.texture = blason
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(30, 38)
		tete.add_child(ic)
	var nom := Label.new()
	nom.text = r["nom"] + ("  " + "★".repeat(niv - 1) if niv > 1 else "")
	nom.add_theme_font_size_override("font_size", 18)
	nom.add_theme_color_override("font_color", Palette.RARETES[rarete])
	nom.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tete.add_child(nom)
	pile.add_child(tete)
	var genre: String = r["type"].capitalize()
	if r.has("famille"):
		genre = "Arme (%s)" % Data.FAMILLES[r["famille"]]
	var cour: String = Data.DYNASTIES.get(r["element"], "Neutre")
	var taille := Data.empreinte(id).size()
	var ligne := "%s, %s, %d case%s" % [Data.NOMS_RARETE[rarete], genre.to_lower(), taille, "s" if taille > 1 else ""]
	var sous := Label.new()
	sous.text = ligne + "\n" + cour + ("" if r["affinite"] == 0 else ", affinité +%d" % r["affinite"])
	sous.add_theme_color_override("font_color", Palette.ELEMENTS[r["element"]]["clair"])
	pile.add_child(sous)
	var texte := Label.new()
	texte.text = Descriptions.TEXTES.get(id, "")
	# signature de dynastie, commune a tous les sorts et armes d'un element
	if r["type"] in ["sort", "arme", "essence"] and Data.SIGNATURES.has(r["element"]):
		var v: float = Data.SIGNATURES[r["element"]]
		var quand := "À chaque activation : "
		if r["type"] == "essence":
			v *= Data.SIGNATURE_ESSENCE
			quand = "À chaque attaque de la monture : "
		texte.text += "\n" + quand + Data.NOMS_SIGNATURE[r["element"]] % ("%d" % v if v == int(v) else str(v).replace(".", ","))
	if niv > 1:
		var mult: float = Data.NIVEAU_MULT[niv]
		texte.text += "\nNiveau %d : effets x%s." % [niv, ("%d" % mult) if mult == int(mult) else str(mult).replace(".", ",")]
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte.custom_minimum_size.x = 300
	texte.add_theme_color_override("font_color", Palette.TEXTE)
	pile.add_child(texte)
	if manque > 0:
		var prix := Label.new()
		prix.text = "Pas assez d'or : il manque %d or." % manque
		prix.add_theme_color_override("font_color", TROP_CHER)
		pile.add_child(prix)
	# fond plein a la couleur de la dynastie, liseré a la couleur de la rarete
	var fond := StyleBoxFlat.new()
	fond.bg_color = Palette.ELEMENTS[r["element"]]["fond"]
	fond.border_color = Palette.RARETES[rarete]
	fond.set_border_width_all(2)
	fond.set_corner_radius_all(6)
	fond.set_content_margin_all(12)
	var cadre := PanelContainer.new()
	cadre.add_theme_stylebox_override("panel", fond)
	cadre.add_child(pile)
	return cadre

# Ce qu'on tient sous la souris : la forme de la relique, a la taille des
# cases du sac, qui tourne avec R ou la molette.
# Le moteur replace la racine de l'apercu sous la souris a chaque mouvement :
# la forme est un enfant decale, pour que la case saisie reste sous le curseur.
func apercu(id: String) -> Control:
	var racine := Control.new()
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var a := Apercu.new()
	a.id = id
	a.ecran = self
	a.modulate.a = 0.85
	racine.add_child(a)
	return racine

class Apercu extends Control:
	var id := ""
	var ecran: NidScreen
	func _process(_d: float) -> void:
		var cote: float = ecran.sac.cote
		position = -(Vector2(ecran.prise) * cote + Vector2(cote, cote) / 2)
		queue_redraw()
	func _draw() -> void:
		var cote: float = ecran.sac.cote
		var cellules := []
		for d in Data.empreinte(id, ecran.rot_prise):
			cellules.append(Rect2(Vector2(d) * cote, Vector2(cote, cote)))
		NidScreen.dessiner_forme(self, cellules, id, 1, cote)

# Une fusion : les copies absorbees volent vers la relique qui monte de
# niveau, puis eclat dore, anneaux et « Fusion ! ★ » qui s'eleve.
class EffetFusion extends Control:
	const VOL := 0.4
	const DUREE := 1.6
	const OR := Color("#f2c94c")
	var cible: Array = []    # cellules de la relique fusionnee
	var niv := 2
	var copies: Array = []   # {id, cellules, cote}
	var t := 0.0
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(d: float) -> void:
		t += d
		if t >= DUREE:
			queue_free()
		queue_redraw()
	static func _boite(cellules: Array) -> Rect2:
		var b: Rect2 = cellules[0]
		for c in cellules:
			b = b.merge(c)
		return b
	func _draw() -> void:
		var dest := _boite(cible)
		var centre := dest.get_center()
		# 1. les copies filent vers la cible en retrecissant
		if t < VOL:
			var e := ease(t / VOL, 2.4)
			for c in copies:
				var depart := _boite(c["cellules"]).get_center()
				var locales := []
				for r in c["cellules"]:
					locales.append(Rect2(r.position - depart, r.size))
				var pos: Vector2 = depart.lerp(centre, e)
				draw_circle(pos, 10.0 + 16.0 * e, Color(OR, 0.35))
				draw_set_transform(pos, e * 0.6, Vector2.ONE * lerpf(1.0, 0.35, e))
				NidScreen.dessiner_forme(self, locales, c["id"], 1, c["cote"])
				draw_set_transform(Vector2.ZERO)
			return
		# 2. l'eclat sur la relique fusionnee
		var u := (t - VOL) / (DUREE - VOL)
		var flash := 1.0 - minf(u * 3.0, 1.0)
		for r in cible:
			draw_rect(r, Color(1.0, 0.95, 0.7, 0.75 * flash))
		var rayon := maxf(dest.size.x, dest.size.y) * 0.5
		for i in 3:
			var v := clampf(u * 1.6 - i * 0.18, 0.0, 1.0)
			if v > 0.0 and v < 1.0:
				draw_arc(centre, rayon * (0.6 + 1.4 * v), 0, TAU, 48, Color(OR, 1.0 - v), 6.0 * (1.0 - v) + 1.0, true)
		for i in 14:
			var a := TAU * i / 14.0 + 0.3
			var p := centre + Vector2.from_angle(a) * rayon * (0.5 + 1.6 * ease(u, 0.4))
			draw_circle(p, 4.0 * (1.0 - u) + 0.5, Color(OR, 1.0 - u))
		for r in cible:
			draw_rect(r.grow(-2), Color(OR, 1.0 - u), false, 4.0)
		# 3. le titre s'eleve
		var police := ThemeDB.fallback_font
		var texte := "Fusion !  " + "★".repeat(niv - 1)
		var taille := int(lerpf(22.0, 34.0, minf(u * 4.0, 1.0)))
		var y := dest.position.y - 10.0 - 40.0 * u
		var alpha := 1.0 if u < 0.6 else 1.0 - (u - 0.6) / 0.4
		var largeur := 320.0
		draw_string_outline(police, Vector2(centre.x - largeur / 2, y), texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille, 6, Color(0, 0, 0, 0.8 * alpha))
		draw_string(police, Vector2(centre.x - largeur / 2, y), texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille, Color(OR, alpha))

class Offre extends Control:
	var ecran: NidScreen
	var index: int
	func _init(e: NidScreen, i: int) -> void:
		ecran = e
		index = i
		custom_minimum_size = Vector2(130, 146)
		tooltip_text = " "
	func _get_tooltip(_p: Vector2) -> String:
		return "" if _id() == "" else NidScreen.info(_id())
	func _make_custom_tooltip(_t: String) -> Object:
		# offre vendue : pas d'infobulle
		return null if _id() == "" else NidScreen.bulle(_id(), 1, _manque())
	func _id() -> String:
		return ecran.partie.offres[index]
	# Clic droit : verrouiller l'offre (elle reste aux relances et a la boutique suivante).
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and _id() != "":
			ecran.partie.verrouiller(index)
			ecran.rafraichir()
			accept_event()
	# Posee sur le comptoir : une ombre sur le bois, l'icone, une pierre a la
	# couleur de sa rarete, sa forme en petit, et une etiquette nom et prix.
	func _draw() -> void:
		var cote := 92.0
		var icone := Rect2(Vector2((size.x - cote) / 2, 4), Vector2(cote, cote))
		var police := ThemeDB.fallback_font
		if _id() == "":
			draw_string(police, Vector2(0, icone.get_center().y), "Vendu", HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(Palette.TEXTE, 0.6))
			return
		var prix := ecran.partie.prix_offre(index)
		var manque := _manque()
		draw_set_transform(Vector2(size.x / 2, icone.end.y - 6), 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, cote * 0.45, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO)
		if ecran.partie.verrous[index]:
			draw_circle(icone.get_center(), cote * 0.55, Color("#9cd3f0", 0.25))
			draw_arc(icone.get_center(), cote * 0.55, 0, TAU, 40, Color("#9cd3f0"), 2.0, true)
		var tex := Palette.icone(_id())
		var teinte := Color(0.45, 0.45, 0.45) if manque > 0 else Color.WHITE
		if tex != null:
			var k := minf(cote / tex.get_width(), cote / tex.get_height())
			var t := tex.get_size() * k
			draw_texture_rect(tex, Rect2(icone.get_center() - t / 2, t), false, teinte)
		else:
			draw_string(police, Vector2(0, icone.get_center().y), Data.RELIQUES[_id()]["nom"], HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Palette.TEXTE)
		var rarete := Data.rarete(_id())
		if rarete != "commun":
			draw_circle(icone.position + Vector2(8, cote - 8), 7, Palette.RARETES[rarete])
			draw_arc(icone.position + Vector2(8, cote - 8), 7, 0, TAU, 16, Color(0, 0, 0, 0.6), 1.5, true)
		var forme := Data.empreinte(_id())
		if forme.size() > 1:
			var bas := Vector2i.ZERO
			for d in forme:
				bas = Vector2i(maxi(bas.x, d.x), maxi(bas.y, d.y))
			var o := Vector2(icone.end.x - (bas.x + 1) * 8, icone.position.y)
			for d in forme:
				draw_rect(Rect2(o + Vector2(d) * 8, Vector2(7, 7)), Palette.TEXTE)
				draw_rect(Rect2(o + Vector2(d) * 8, Vector2(7, 7)), Color(0, 0, 0, 0.6), false, 1.0)
		if manque > 0:
			_cadenas(icone.get_center())
		# verrouillee : le flocon peint, pose sur l'objet, en haut a gauche
		if ecran.partie.verrous[index]:
			var flocon := Palette.image("res://images/freeze.png")
			if flocon != null:
				draw_texture_rect(flocon, Rect2(icone.position + Vector2(-6, -6), Vector2(40, 38)), false)
		# etiquette : nom et prix
		var texte := "Offert" if index == ecran.partie.gratuite else "%d or" % prix
		if ecran.partie.soldes[index] and index != ecran.partie.gratuite:
			texte = "Soldé : %d or" % prix
		if manque > 0:
			texte = "%d or, il manque %d" % [prix, manque]
		var etiquette := Rect2(Vector2(2, icone.end.y + 6), Vector2(size.x - 4, 40))
		draw_rect(etiquette, Color(Palette.FOND, 0.78))
		draw_rect(Rect2(etiquette.position, Vector2(etiquette.size.x, 2)), Palette.RARETES[rarete] if rarete != "commun" else Palette.CASE_BORD)
		draw_string(police, etiquette.position + Vector2(0, 17), Data.RELIQUES[_id()]["nom"], HORIZONTAL_ALIGNMENT_CENTER, etiquette.size.x, 12, Palette.TEXTE)
		draw_string(police, etiquette.position + Vector2(0, 34), texte, HORIZONTAL_ALIGNMENT_CENTER, etiquette.size.x, 13,
			NidScreen.TROP_CHER if manque > 0 else Color("#f2c94c"))
	func _manque() -> int:
		return maxi(0, ecran.partie.prix_offre(index) - ecran.partie.bourse)
	func _cadenas(c: Vector2) -> void:
		draw_arc(c + Vector2(0, -6), 8, PI, TAU, 12, NidScreen.TROP_CHER, 3.0, true)
		draw_rect(Rect2(c + Vector2(-11, -6), Vector2(22, 17)), NidScreen.TROP_CHER)
		draw_circle(c + Vector2(0, 2), 2.5, Color(0, 0, 0, 0.8))
	func _get_drag_data(_p: Vector2) -> Variant:
		if _id() == "" or ecran.partie.bourse < ecran.partie.prix_offre(index):
			return null
		ecran.rot_prise = 0
		ecran.prise = Vector2i.ZERO
		set_drag_preview(ecran.apercu(_id()))
		return {"id": _id(), "offre": index}
	# Ramener une relique posee sur la boutique la revend.
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return NidScreen.glisse(data) and not data.has("offre")
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.vendre_source(data)
		ecran.apres_pose()

class Boutique extends VBoxContainer:
	var ecran: NidScreen
	func _init(e: NidScreen) -> void:
		ecran = e
		mouse_filter = Control.MOUSE_FILTER_PASS
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return NidScreen.glisse(data) and not data.has("offre")
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.vendre_source(data)
		ecran.apres_pose()

# Le comptoir : y lacher une relique du sac la revend. Pendant qu'on en tient
# une, il s'eclaire et affiche le prix de revente.
class ZoneVente extends Control:
	var ecran: NidScreen
	var survol := false
	func _init(e: NidScreen) -> void:
		ecran = e
		mouse_filter = Control.MOUSE_FILTER_PASS
		mouse_exited.connect(func():
			survol = false
			queue_redraw())
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		var ok: bool = NidScreen.glisse(data) and not data.has("offre")
		if ok and not survol:
			survol = true
			queue_redraw()
		return ok
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.vendre_source(data)
		ecran.apres_pose()
	func _draw() -> void:
		if ecran.revente < 0:
			return
		var r := Rect2(Vector2.ZERO, size)
		var or_ := Color("#f2c94c")
		draw_rect(r, Color(or_, 0.22 if survol else 0.1))
		draw_rect(r, Color(or_, 0.9 if survol else 0.5), false, 3.0)

# Un emplacement de la reserve : une relique de cote, sans effet.
class CaseReserve extends Control:
	var ecran: NidScreen
	var index: int
	func _init(e: NidScreen, k: int) -> void:
		ecran = e
		index = k
		custom_minimum_size = Vector2(52, 52)
		tooltip_text = " "
	func _r() -> Dictionary:
		return ecran.partie.reserve[index]
	func _get_tooltip(_p: Vector2) -> String:
		return "" if _r().is_empty() else NidScreen.info(_r()["id"])
	func _make_custom_tooltip(_t: String) -> Object:
		return null if _r().is_empty() else NidScreen.bulle(_r()["id"], _r()["niv"])
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(Palette.CASE, 0.9))
		draw_rect(r, Palette.CASE_BORD, false, 1.0)
		if not _r().is_empty():
			NidScreen.dessiner_forme(self, [r], _r()["id"], _r()["niv"], size.x)
	func _get_drag_data(_p: Vector2) -> Variant:
		if _r().is_empty():
			return null
		ecran.rot_prise = 0
		ecran.prise = Vector2i.ZERO
		ecran.montrer_vente(Partie.prix_revente(_r()["id"], _r()["niv"]))
		set_drag_preview(ecran.apercu(_r()["id"]))
		return {"id": _r()["id"], "reserve": index}
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return NidScreen.glisse(data) and ecran.partie.ranger(data, index, true)
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.ranger(data, index)
		ecran.apres_pose()

class CaseNid extends Control:
	var ecran: NidScreen
	var position_nid: Vector2i
	func _init(e: NidScreen, c: Vector2i) -> void:
		ecran = e
		position_nid = c
		tooltip_text = " "
		mouse_entered.connect(func(): ecran.case_survolee = position_nid; ecran.sac.queue_redraw())
		mouse_exited.connect(func():
			if ecran.case_survolee == position_nid:
				ecran.case_survolee = null
			ecran.sac.queue_redraw())
	# ancre de la relique qui couvre cette case, null si vide
	func _ancre():
		return ecran.nid.ancre(position_nid)
	# Agrandir : un clic sur une case fermee l'ouvre.
	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and not ecran.nid.ouverte(position_nid):
			ecran.ouvrir(position_nid)
			accept_event()
	func _get_tooltip(_p: Vector2) -> String:
		var a = _ancre()
		return "" if a == null else NidScreen.info(ecran.nid.cases[a])
	func _make_custom_tooltip(_t: String) -> Object:
		var a = _ancre()
		return null if a == null else NidScreen.bulle(ecran.nid.cases[a], ecran.nid.niveau(a))
	func _get_drag_data(_p: Vector2) -> Variant:
		var a = _ancre()
		if a == null:
			return null
		ecran.montrer_vente(Partie.prix_revente(ecran.nid.cases[a], ecran.nid.niveau(a)))
		ecran.rot_prise = ecran.nid.rotation(a)
		ecran.prise = position_nid - a
		set_drag_preview(ecran.apercu(ecran.nid.cases[a]))
		return {"id": ecran.nid.cases[a], "depuis": a}
	# Ou tomberait la relique tenue si on la lachait ici. Sur une autre relique,
	# elle prend sa place et l'autre passe dans la main.
	func _pose(data: Dictionary) -> Dictionary:
		var b: Vector2i = position_nid - ecran.prise
		var pose := ecran.partie.poser(data, position_nid, b, ecran.rot_prise, true)
		pose["ancre"] = b
		return pose
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		if not NidScreen.glisse(data):
			return false
		var pose := _pose(data)
		ecran.pose_vue = pose
		ecran.sac.queue_redraw()
		return pose["ok"]
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.poser(data, position_nid, position_nid - ecran.prise, ecran.rot_prise)
		ecran.apres_pose()

# Tapis du sac, en tuiles : chaque case prend la tuile dont les bords en cuir
# correspondent a sa place (haut, droite, bas, gauche du tapis). Une case sur
# deux est assombrie pour lire la grille.
# Les tuiles du tapis pour ces cases ouvertes, de cote pixels ; la case coin
# est dessinee en origine. Sert au sac et au Nid en combat.
const TAPIS_SOMBRE := Color(0.8, 0.75, 0.68)

static func dessiner_tapis(ci: CanvasItem, ouvertes: Array, cote: float, origine: Vector2, coin := Vector2i.ZERO) -> void:
	for c in ouvertes:
		var bords := ""
		for b in [["H", Vector2i(0, -1)], ["D", Vector2i(1, 0)], ["B", Vector2i(0, 1)], ["G", Vector2i(-1, 0)]]:
			if not ouvertes.has(c + b[1]):
				bords += b[0]
		var tex := Palette.image("res://images/tapis/%s.png" % (bords if bords != "" else "toile"))
		var r := Rect2(origine + Vector2(c - coin) * cote, Vector2(cote, cote))
		var teinte := TAPIS_SOMBRE if (c.x + c.y) % 2 == 1 else Color.WHITE
		if tex != null:
			ci.draw_texture_rect(tex, r, false, teinte)
		else:
			ci.draw_rect(r, Color("#d9c9a6") * teinte)

# Plus petit rectangle du damier qui contient ces cases.
static func boite(cases: Array) -> Rect2i:
	var r := Rect2i(cases[0], Vector2i.ONE)
	for c in cases:
		r = r.merge(Rect2i(c, Vector2i.ONE))
	return r

class Tapis extends Control:
	var ecran: NidScreen
	var cote := 100.0
	func _init(e: NidScreen) -> void:
		ecran = e
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var nid := ecran.nid
		NidScreen.dessiner_tapis(self, nid.ouvertes, cote, Vector2.ZERO)
		# Agrandir : les cases qu'on peut ouvrir, en pointille dore, avec un +
		if ecran.choix_case:
			var or_ := Color("#f2c94c")
			for k in nid.bordure():
				var r := _rect(k).grow(-cote * 0.08)
				var survol: bool = ecran.case_survolee == k
				draw_rect(r, Color(or_, 0.3 if survol else 0.12))
				for bord in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end],
						[r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
					draw_dashed_line(bord[0], bord[1], or_, 2.0, 8.0)
				var c := r.get_center()
				var l := cote * 0.14
				draw_line(c - Vector2(l, 0), c + Vector2(l, 0), or_, 4.0)
				draw_line(c - Vector2(0, l), c + Vector2(0, l), or_, 4.0)
		var survolee = nid.ancre(ecran.case_survolee) if ecran.case_survolee != null else null
		# survol d'un catalyseur : les reliques qu'il touche s'allument
		var renforcees := []
		if survolee != null and Data.RELIQUES[nid.cases[survolee]]["type"] == "catalyseur":
			renforcees = nid.cases.keys().filter(func(a): return survolee in nid.influents(a))
		for a in nid.cases:
			var cellules := []
			for k in nid.cases_de(a):
				cellules.append(_rect(k))
			NidScreen.dessiner_forme(self, cellules, nid.cases[a], nid.niveau(a), cote, a == survolee)
			if a in renforcees:
				for r in cellules:
					draw_rect(r.grow(-cote * 0.1), Color("#f2c94c", 0.25))
					draw_rect(r.grow(-cote * 0.1), Color("#f2c94c"), false, 2.0)
		# apercu de la pose : vert si permise, rouge sinon
		if not ecran.pose_vue.is_empty():
			var couleur := Color(0.4, 0.9, 0.4, 0.35) if ecran.pose_vue["ok"] else Color(0.95, 0.3, 0.25, 0.35)
			for k in ecran.pose_vue["cases"]:
				if nid.ouverte(k):
					draw_rect(_rect(k).grow(-cote * 0.06), couleur)
	func _rect(k: Vector2i) -> Rect2:
		return Rect2(Vector2(k) * cote, Vector2(cote, cote))
