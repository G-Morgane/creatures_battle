class_name ChoixScreen
extends Control

# Debut de partie : on choisit les dynasties en jeu (de 3 a 8). La boutique ne
# proposera que leurs reliques. Survol : ce que fait chaque dynastie.

signal commencer(dynasties: Array)

const MIN := 3
const MAX := 8
const ALEATOIRE := 4

var choisies: Array = []
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

	var titre := Label.new()
	titre.text = "Choisis les dynasties de ta partie"
	titre.add_theme_font_size_override("font_size", 28)
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
	info.custom_minimum_size = Vector2(0, 76)
	info.add_theme_color_override("default_color", Palette.TEXTE)
	info.add_theme_font_size_override("normal_font_size", 16)
	info.add_theme_font_size_override("bold_font_size", 17)
	pile.add_child(info)

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
	bouton.pressed.connect(func(): commencer.emit(choisies.duplicate()))
	bas.add_child(bouton)
	pile.add_child(bas)
	_rafraichir()

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
	var texte := "[b]%s[/b], monture : %s\n%s" % [Data.DYNASTIES[e], forme["nom"], Data.IDENTITES[e]]
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
		custom_minimum_size = Vector2(190, 170)
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
		var tex := Palette.image("res://images/montures/%s.png" % element)
		if tex != null:
			var k := minf((size.x - 30) / tex.get_width(), (size.y - 60) / tex.get_height())
			var t := tex.get_size() * k
			draw_texture_rect(tex, Rect2(Vector2((size.x - t.x) / 2, 12), t), false,
				Color(0.4, 0.4, 0.4) if a_venir else Color.WHITE)
		var police := ThemeDB.fallback_font
		draw_string(police, Vector2(0, size.y - 26), NidScreen._NOMS_ELEMENTS[element],
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Palette.TEXTE)
		draw_string(police, Vector2(0, size.y - 8), "à venir" if a_venir else Data.FORMES[element]["nom"],
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Palette.TEXTE_DOUX)
		if choisie:
			draw_rect(r, c["vif"], false, 4.0)
		elif ecran.survolee == element and not a_venir:
			draw_rect(r, Palette.TEXTE_DOUX, false, 2.0)
