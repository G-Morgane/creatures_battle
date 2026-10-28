class_name CarteScreen
extends Control

# Carte de l'acte en cours : les etages de gauche a droite, le boss au bout.
# On clique un noeud accessible pour y entrer. Une rencontre s'ouvre ici,
# un combat part dans l'arene, le feu de camp ramene au Nid.

signal combat
signal fini
signal retour

const RAYON := 24.0
const NOMS := {"duel": "Duel", "elite": "Élite", "rencontre": "Rencontre",
	"feu": "Feu de camp", "boss": "Boss"}
# Icones peintes (images/carte) ; le feu de camp garde sa lettre.
const ICONES := {"duel": "duel", "rencontre": "rencontre", "elite": "elite", "boss": "elite"}
const SIGLES := {"duel": "D", "elite": "E", "rencontre": "?", "feu": "F", "boss": "B"}
const COULEURS := {"duel": Color("#5b9bd5"), "elite": Color("#d0564a"), "rencontre": Color("#a855c9"),
	"feu": Color("#ff8a3d"), "boss": Color("#e8e4da")}

var partie: Partie
var survol := -1
var t := 0.0
var barre: Label
var compteurs := {}
var panneau: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bandeau := HBoxContainer.new()
	bandeau.add_theme_constant_override("separation", 34)
	bandeau.position = Vector2(32, 22)
	add_child(bandeau)
	barre = Label.new()
	barre.add_theme_font_size_override("font_size", 22)
	barre.add_theme_color_override("font_color", Palette.TEXTE)
	bandeau.add_child(barre)
	for nom in ["vie", "victoires", "or"]:
		var c: Array = Palette.compteur(nom)
		compteurs[nom] = c[1]
		bandeau.add_child(c[0])
	var nid := Button.new()
	nid.text = "Retour au Nid"
	nid.custom_minimum_size = Vector2(160, 40)
	nid.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	# a gauche du bouton du glossaire
	nid.offset_left = -350
	nid.offset_top = 22
	nid.offset_right = -190
	nid.pressed.connect(func(): retour.emit())
	add_child(nid)
	_rafraichir()

func _rafraichir() -> void:
	barre.text = "Acte %d sur %d" % [partie.acte + 1, Carte.ACTES]
	compteurs["vie"].text = "%d / %d" % [partie.pv_run, Partie.PV_RUN]
	compteurs["victoires"].text = "%d" % partie.victoires
	compteurs["or"].text = "%d" % partie.bourse
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

# Position a l'ecran d'un noeud, avec un leger decalage fixe pour casser la grille.
func centre(i: int) -> Vector2:
	var n: Dictionary = partie.noeuds()[i]
	# Les chemins restent dans la plaine claire du fond peint, entre les falaises,
	# les montagnes et la riviere ; le boss attend au pied du chateau.
	var fond := Rect2(0, HAUT, size.x, size.y - HAUT - BAS)
	var zone := Rect2(fond.position + fond.size * PLAINE.position, fond.size * PLAINE.size)
	var x: float = zone.position.x + n["etage"] * zone.size.x / (Carte.ETAGES - 2)
	if n["type"] == "boss":
		x = fond.position.x + fond.size.x * BOSS_X
	var y: float = zone.position.y + n["col"] * zone.size.y / (Carte.COLONNES - 1)
	if n["type"] != "boss":
		var h := absi(hash(Vector2i(n["etage"], int(n["col"])) + Vector2i(partie.acte * 31, 0)))
		x += (h % 21) - 10
		y += ((h / 21) % 21) - 10
	return Vector2(x, y)

# Fond peint, etire sur toute la largeur entre le bandeau du haut et la legende.
const HAUT := 90.0
# Plaine du fond peint, en fraction de l'image, et position du boss.
const PLAINE := Rect2(0.17, 0.26, 0.62, 0.46)
const BOSS_X := 0.87
const BAS := 70.0
const TRAIT := Color("#2b2117")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.FOND)
	var fond := Palette.image("res://images/fond_map.png")
	if fond != null:
		draw_texture_rect(fond, Rect2(0, HAUT, size.x, size.y - HAUT - BAS), false)
	var noeuds := partie.noeuds()
	var acc := partie.accessibles()
	var police := ThemeDB.fallback_font
	# liens : ceux du chemin parcouru et ceux qu'on peut prendre ressortent
	for i in noeuds.size():
		for j in noeuds[i]["suivants"]:
			var fait: bool = i in partie.chemin and j in partie.chemin
			var possible: bool = i == partie.position and j in acc
			var c := Color(TRAIT, 0.95 if fait else (0.75 if possible else 0.3))
			draw_line(centre(i), centre(j), c, 4.0 if fait else (3.0 if possible else 2.0), true)
	for i in noeuds.size():
		var n: Dictionary = noeuds[i]
		var p := centre(i)
		var r := RAYON * (1.5 if n["type"] == "boss" else 1.0)
		var couleur: Color = COULEURS[n["type"]]
		var visite: bool = i in partie.chemin
		var ouvert: bool = i in acc
		if ouvert:
			r *= 1.0 + 0.08 * sin(t * 4.0)
			draw_circle(p, r + 7, Color(couleur, 0.25))
		var plein := couleur if visite or ouvert else couleur.darkened(0.3)
		draw_circle(p, r, Palette.CASE if visite or ouvert else Color(Palette.CASE, 0.8))
		draw_circle(p, r, plein, false, 3.0, true)
		if visite:
			draw_circle(p, r - 6, Color(couleur, 0.35))
		if i == survol and ouvert:
			draw_circle(p, r + 3, Palette.TEXTE, false, 2.0, true)
		var ic := _icone(n["type"])
		if ic != null:
			var teinte := Color.WHITE if visite or ouvert else Color(0.65, 0.65, 0.65)
			_dessiner_icone(ic, Rect2(p - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6), teinte)
		else:
			var taille := 26 if n["type"] == "boss" else 20
			draw_string(police, p + Vector2(-r, taille * 0.35), SIGLES[n["type"]],
				HORIZONTAL_ALIGNMENT_CENTER, r * 2, taille, plein)
		if ouvert or n["type"] == "boss":
			var nom: String = NOMS[n["type"]]
			if n["type"] == "elite":
				nom = Data.ELITES[partie.elite_de(i)]["nom"]
			elif n["type"] == "boss" and partie.acte < Data.GARDIEN_ACTE.size():
				nom = Data.GARDIENS[Data.GARDIEN_ACTE[partie.acte]]["nom"]
			var l := police.get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 12
			draw_rect(Rect2(p + Vector2(-l / 2, r + 6), Vector2(l, 20)), Color(Palette.FOND, 0.8))
			draw_string(police, p + Vector2(-60, r + 21), nom,
				HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Palette.TEXTE)
	# legende
	var x := 32.0
	for type in NOMS:
		draw_circle(Vector2(x + 10, size.y - 40), 9, COULEURS[type], false, 2.0, true)
		if _icone(type) != null:
			_dessiner_icone(_icone(type), Rect2(x + 3, size.y - 47, 14, 14), Color.WHITE)
		else:
			draw_string(police, Vector2(x, size.y - 35), SIGLES[type], HORIZONTAL_ALIGNMENT_CENTER, 20, 12, COULEURS[type])
		draw_string(police, Vector2(x + 26, size.y - 35), NOMS[type], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.TEXTE_DOUX)
		x += 150.0

func _icone(type: String) -> Texture2D:
	return Palette.image("res://images/carte/%s.png" % ICONES[type]) if ICONES.has(type) else null

# Icone centree dans la zone, proportions gardees.
func _dessiner_icone(tex: Texture2D, zone: Rect2, teinte: Color) -> void:
	var k := minf(zone.size.x / tex.get_width(), zone.size.y / tex.get_height())
	var taille := tex.get_size() * k
	draw_texture_rect(tex, Rect2(zone.position + (zone.size - taille) / 2, taille), false, teinte)

func _noeud_sous(p: Vector2) -> int:
	for i in partie.accessibles():
		if centre(i).distance_to(p) <= RAYON * 1.6:
			return i
	return -1

func _gui_input(ev: InputEvent) -> void:
	if panneau != null:
		return
	if ev is InputEventMouseMotion:
		survol = _noeud_sous(ev.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if survol >= 0 else Control.CURSOR_ARROW
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var i := _noeud_sous(ev.position)
		if i >= 0:
			entrer(i)

func entrer(i: int) -> void:
	if not partie.entrer(i):
		return
	if partie.combat():
		combat.emit()
	elif partie.noeud()["type"] == "rencontre":
		_rencontre()
	else:
		partie.conclure()
		fini.emit()

func _rencontre() -> void:
	panneau = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANNEAU
	style.border_color = COULEURS["rencontre"]
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	panneau.add_theme_stylebox_override("panel", style)
	var pile := VBoxContainer.new()
	pile.add_theme_constant_override("separation", 16)
	panneau.add_child(pile)
	var titre := Label.new()
	titre.text = partie.rencontre["titre"]
	titre.add_theme_font_size_override("font_size", 28)
	titre.add_theme_color_override("font_color", Palette.TEXTE)
	pile.add_child(titre)
	var texte := Label.new()
	texte.text = partie.rencontre["texte"]
	texte.add_theme_font_size_override("font_size", 17)
	texte.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	pile.add_child(texte)
	for k in partie.rencontre["choix"].size():
		var b := Button.new()
		b.text = partie.rencontre["choix"][k]
		b.custom_minimum_size.y = 42
		b.pressed.connect(func():
			partie.choisir(k)
			fini.emit())
		pile.add_child(b)
	add_child(panneau)
	panneau.reset_size()
	panneau.position = (size - panneau.size) / 2
