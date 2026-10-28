class_name Palette
extends RefCounted

# Fond sombre et neutre : seule la creature et les reliques portent la couleur.

const FOND        := Color("#0e1014")
const PANNEAU     := Color("#171a21")
const CASE        := Color("#1f232b")
const CASE_BORD   := Color("#2f333d")
const SURVOL      := Color("#3a3f4a")
const TEXTE       := Color("#e8e4da")
const TEXTE_DOUX  := Color("#8a8f99")

const RARETES := {
	"commun": Color("#8a8f99"),
	"rare": Color("#5b9bd5"),
	"epique": Color("#a855c9"),
	"legendaire": Color("#e0a526"),
}
const POISON := Color("#8fd16a")

# Images dessinees (icones d'objets, montures) : chargees une fois, null si absentes.
static var _cache := {}

static func image(chemin: String) -> Texture2D:
	if not _cache.has(chemin):
		_cache[chemin] = load(chemin) if ResourceLoader.exists(chemin) else null
	return _cache[chemin]

# Theme commun : chaque bouton prend le cadre feuillage et parchemin
# (images/ui/bouton.png), etire en 9 tranches, texte brun sur le parchemin.
static func theme_jeu() -> Theme:
	var t := Theme.new()
	var tex := ui("bouton")
	if tex == null:
		return t
	var etats := {"normal": Color.WHITE, "hover": Color(1.1, 1.08, 0.98), "pressed": Color(0.86, 0.84, 0.8),
		"disabled": Color(0.7, 0.7, 0.7, 0.6), "hover_pressed": Color(0.92, 0.9, 0.86)}
	for etat in etats:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		# seuls les bouts (feuilles) restent fixes ; la hauteur suit l'image
		sb.texture_margin_left = 24
		sb.texture_margin_right = 24
		sb.content_margin_left = 28
		sb.content_margin_right = 28
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		sb.modulate_color = etats[etat]
		t.set_stylebox(etat, "Button", sb)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color("#3b2a18"))
	t.set_color("font_hover_color", "Button", Color("#1f150b"))
	t.set_color("font_pressed_color", "Button", Color("#1f150b"))
	t.set_color("font_hover_pressed_color", "Button", Color("#1f150b"))
	t.set_color("font_focus_color", "Button", Color("#3b2a18"))
	t.set_color("font_disabled_color", "Button", Color("#6f6252"))
	return t

# Icones d'interface (images/ui) : vie, victoires, or, glossaire.
static func ui(nom: String) -> Texture2D:
	return image("res://images/ui/%s.png" % nom)

# Un compteur : l'icone, puis un texte. Le Label rendu se met a jour par .text.
static func compteur(nom: String, taille := 22) -> Array:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 6)
	var ic := TextureRect.new()
	ic.texture = ui(nom)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(taille + 8, taille + 8)
	ligne.add_child(ic)
	var l := Label.new()
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", TEXTE)
	ligne.add_child(l)
	return [ligne, l]

static func icone(id: String) -> Texture2D:
	return image("res://images/icones/%s.png" % id)

const ELEMENTS := {
	"feu":   {"fond": Color("#5a2a14"), "vif": Color("#ff8a3d"), "clair": Color("#ffd27a")},
	"nuit":  {"fond": Color("#2a1d3d"), "vif": Color("#9d6bff"), "clair": Color("#d7c4ff")},
	"glace": {"fond": Color("#1b2a3a"), "vif": Color("#6aa8de"), "clair": Color("#e4f1fb")},
	"aube":  {"fond": Color("#3a2b22"), "vif": Color("#f2b26b"), "clair": Color("#fff1d6")},
	"crepuscule": {"fond": Color("#2e1d33"), "vif": Color("#f0645a"), "clair": Color("#f6c48c")},
	"nature":{"fond": Color("#1d3027"), "vif": Color("#3f9e7a"), "clair": Color("#e8d5b0")},
	"automne": {"fond": Color("#3d2216"), "vif": Color("#d9622b"), "clair": Color("#f2c27a")},
	"jour":  {"fond": Color("#1c3236"), "vif": Color("#4fb3b0"), "clair": Color("#f3e3a6")},
	# plus de dynastie Terre ni Vent : leurs couleurs servent encore aux effets en combat
	"terre": {"fond": Color("#3a3220"), "vif": Color("#b08a4a"), "clair": Color("#e3cf9a")},
	"vent":  {"fond": Color("#1c3338"), "vif": Color("#6fd3d6"), "clair": Color("#d4f6f4")},
	"":      {"fond": Color("#2a2d33"), "vif": Color("#8a8f99"), "clair": Color("#c9ccd2")},
}
