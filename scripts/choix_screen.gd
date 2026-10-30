class_name ChoixScreen
extends Control

# Debut de partie : on choisit les dynasties en jeu (de 3 a 8). La boutique ne
# proposera que leurs reliques. Survol : ce que fait chaque dynastie.

signal commencer(dynasties: Array, cavalier: String)

const MIN := 3
const MAX := 8
const ALEATOIRE := 4

var choisies: Array = []
var cavalier := "capuchon"
var cavaliers_ui := {}
var talent: RichTextLabel
var survolee := ""
var cartes := {}       # element -> Blason
var info: RichTextLabel
var bouton: Button
var compte: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fond := TextureRect.new()
	fond.texture = Palette.image("res://images/fond_map.png")
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)

	var panneau := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FOND, 0.88)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	panneau.add_theme_stylebox_override("panel", style)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	centre.add_child(panneau)
	var pile := VBoxContainer.new()
	pile.add_theme_constant_override("separation", 14)
	panneau.add_child(pile)

	# le Reveur : ou en est la traque, d'une run a l'autre
	var reveur := HBoxContainer.new()
	reveur.add_theme_constant_override("separation", 12)
	reveur.alignment = BoxContainer.ALIGNMENT_CENTER
	var t0 := Label.new()
	t0.text = "Le Rêveur"
	t0.add_theme_font_size_override("font_size", 20)
	Palette.titre(t0)
	t0.add_theme_color_override("font_color", Color("#f2c94c"))
	reveur.add_child(t0)
	var etat := Label.new()
	etat.text = Progression.etat()
	etat.tooltip_text = Progression.etape()["texte"]
	etat.mouse_filter = Control.MOUSE_FILTER_STOP
	etat.add_theme_color_override("font_color", Palette.TEXTE)
	reveur.add_child(etat)
	pile.add_child(reveur)

	var titre := Label.new()
	titre.text = "Choisis les dynasties de ta partie"
	titre.add_theme_font_size_override("font_size", 28)
	Palette.titre(titre)
	titre.add_theme_color_override("font_color", Palette.TEXTE)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pile.add_child(titre)
	var sous := Label.new()
	sous.text = "De %d à %d. La boutique ne proposera que leurs reliques." % [MIN, MAX]
	sous.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pile.add_child(sous)

	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 12)
	for e in Data.DYNASTIES:
		var b := Blason.new(self, e)
		cartes[e] = b
		grille.add_child(b)
	pile.add_child(grille)

	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.fit_content = true
	info.custom_minimum_size = Vector2(0, 64)
	info.add_theme_color_override("default_color", Palette.TEXTE)
	info.add_theme_font_size_override("normal_font_size", 16)
	info.add_theme_font_size_override("bold_font_size", 17)
	pile.add_child(info)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	var t2 := Label.new()
	t2.text = "Ton cavalier"
	t2.add_theme_font_size_override("font_size", 20)
	Palette.titre(t2)
	ligne.add_child(t2)
	for id in Data.CAVALIERS:
		var cv := Portrait.new(self, id)
		cavaliers_ui[id] = cv
		ligne.add_child(cv)
	pile.add_child(ligne)
	talent = RichTextLabel.new()
	talent.bbcode_enabled = true
	talent.fit_content = true
	talent.add_theme_color_override("default_color", Palette.TEXTE)
	talent.add_theme_font_size_override("normal_font_size", 15)
	talent.add_theme_font_size_override("bold_font_size", 15)
	pile.add_child(talent)
	choisir_cavalier(cavalier)

	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 12)
	bas.alignment = BoxContainer.ALIGNMENT_CENTER
	var hasard := Button.new()
	hasard.text = "Aléatoire (%d)" % ALEATOIRE
	hasard.custom_minimum_size = Vector2(170, 42)
	hasard.pressed.connect(_aleatoire)
	bas.add_child(hasard)
	compte = Label.new()
	compte.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	compte.custom_minimum_size.x = 160
	compte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bas.add_child(compte)
	bouton = Button.new()
	bouton.text = "Commencer"
	bouton.custom_minimum_size = Vector2(170, 42)
	bouton.pressed.connect(func(): commencer.emit(choisies.duplicate(), cavalier))
	bas.add_child(bouton)
	pile.add_child(bas)
	_rafraichir()

func choisir_cavalier(id: String) -> void:
	cavalier = id
	for c in cavaliers_ui.values():
		c.queue_redraw()
	talent.text = "[b]%s, %s[/b] : %s" % [Data.CAVALIERS[id], Data.TALENTS[id][0], Data.TALENTS[id][1]]

func basculer(e: String) -> void:
	if e in Data.DYNASTIES_A_VENIR:
		return
	if e in choisies:
		choisies.erase(e)
	elif choisies.size() < MAX:
		choisies.append(e)
	_rafraichir()

func _aleatoire() -> void:
	var l := Data.dynasties_jouables()
	l.shuffle()
	choisies = l.slice(0, ALEATOIRE)
	_rafraichir()

func survoler(e: String) -> void:
	survolee = e
	_rafraichir()

func _rafraichir() -> void:
	for e in cartes:
		cartes[e].queue_redraw()
	bouton.disabled = choisies.size() < MIN or choisies.size() > MAX
	compte.text = "%d choisie%s" % [choisies.size(), "s" if choisies.size() > 1 else ""]
	var e := survolee
	if e == "":
		info.text = "[color=#8a8f99]Survole une dynastie pour voir comment elle joue.[/color]"
		return
	var forme: Dictionary = Data.FORMES[e]
	var texte := "[b]%s[/b]\n%s" % [Data.DYNASTIES[e], Data.IDENTITES[e]]
	if not e in Data.DYNASTIES_A_VENIR:
		texte += "\n[color=#8a8f99]Passif : %s.[/color]" % forme["passif"]
	info.text = texte

# Une dynastie : sa monture, son nom ; cadre a sa couleur quand elle est choisie.
class Blason extends Control:
	var ecran: ChoixScreen
	var element: String
	func _init(e: ChoixScreen, el: String) -> void:
		ecran = e
		element = el
		custom_minimum_size = Vector2(180, 170)
		mouse_entered.connect(func(): ecran.survoler(element))
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			ecran.basculer(element)
	func _draw() -> void:
		var c: Dictionary = Palette.ELEMENTS[element]
		var choisie := element in ecran.choisies
		var a_venir := element in Data.DYNASTIES_A_VENIR
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, c["fond"] if choisie else Palette.CASE)
		# le blason seul : la monture se decouvre en jouant
		var teinte := Color(0.4, 0.4, 0.4) if a_venir else Color.WHITE
		var blason := Palette.blason(element)
		if blason != null:
			var kb := (size.y - 64) / blason.get_height()
			var tb := blason.get_size() * kb
			draw_texture_rect(blason, Rect2(Vector2((size.x - tb.x) / 2, 8), tb), false, teinte)
		var police := ThemeDB.fallback_font
		draw_string(Palette.police_titre(), Vector2(0, size.y - 26), NidScreen._NOMS_ELEMENTS[element],
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Palette.TEXTE)
		if a_venir:
			draw_string(police, Vector2(0, size.y - 8), "à venir", HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Palette.TEXTE_DOUX)
		if choisie:
			draw_rect(r, c["vif"], false, 4.0)
		elif ecran.survolee == element and not a_venir:
			draw_rect(r, Palette.TEXTE_DOUX, false, 2.0)

# Un cavalier a choisir : son portrait, cadre dore quand il est choisi.
class Portrait extends Control:
	var ecran: ChoixScreen
	var id: String
	func _init(e: ChoixScreen, i: String) -> void:
		ecran = e
		id = i
		custom_minimum_size = Vector2(84, 92)
		tooltip_text = "%s, %s : %s" % [Data.CAVALIERS[i], Data.TALENTS[i][0], Data.TALENTS[i][1]]
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			ecran.choisir_cavalier(id)
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var choisi := ecran.cavalier == id
		draw_rect(r, Color("#2e3442") if choisi else Palette.CASE)
		var tex := Palette.image("res://images/cavaliers/%s.png" % id)
		if tex != null:
			var k := minf((size.x - 16) / tex.get_width(), (size.y - 16) / tex.get_height())
			var t := tex.get_size() * k
			draw_texture_rect(tex, Rect2((size - t) / 2, t), false)
		draw_rect(r, Color("#f2c94c") if choisi else Palette.CASE_BORD, false, 3.0 if choisi else 1.0)
