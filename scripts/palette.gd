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

# Polices : Nunito Sans pour le texte, Cinzel Decorative pour les titres
# (Google Fonts, licence OFL : polices/OFL-*.txt).
const TITRE_POLICE := "res://polices/CinzelDecorative-Bold.ttf"
static var _polices := {}

# Police variable : sans reglage elle sort sa graisse la plus fine, on la fixe.
static func _graisse(chemin: String, poids: int) -> Font:
	var f := FontVariation.new()
	f.base_font = load(chemin)
	var ts := TextServerManager.get_primary_interface()
	f.variation_opentype = {ts.name_to_tag("wght"): poids, ts.name_to_tag("opsz"): 12}
	return f

static func police() -> Font:
	if not _polices.has("texte"):
		_polices["texte"] = _graisse("res://polices/NunitoSans-Variable.ttf", 500)
	return _polices["texte"]

static func police_grasse() -> Font:
	if not _polices.has("gras"):
		_polices["gras"] = _graisse("res://polices/NunitoSans-Variable.ttf", 800)
	return _polices["gras"]

static func police_italique() -> Font:
	if not _polices.has("italique"):
		_polices["italique"] = _graisse("res://polices/NunitoSans-Italic-Variable.ttf", 500)
	return _polices["italique"]

static func police_titre() -> Font:
	if not _polices.has("titre"):
		_polices["titre"] = load(TITRE_POLICE)
	return _polices["titre"]

# Un Label en police de titre.
static func titre(l: Control) -> Control:
	l.add_theme_font_override("font", police_titre())
	return l

# Theme commun : chaque bouton prend le cadre feuillage et parchemin
# (images/ui/bouton.png), etire en 9 tranches, texte brun sur le parchemin.
static func theme_jeu() -> Theme:
	var t := Theme.new()
	t.default_font = police()
	t.set_font("bold_font", "RichTextLabel", police_grasse())
	t.set_font("italics_font", "RichTextLabel", police_italique())
	# les textes dessines a la main (draw_string) prennent la police par defaut
	ThemeDB.fallback_font = police()
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
	# infobulles : fond opaque, liseré discret, pour lire sur n'importe quel decor
	var bulle := StyleBoxFlat.new()
	bulle.bg_color = PANNEAU
	bulle.border_color = CASE_BORD
	bulle.set_border_width_all(2)
	bulle.set_corner_radius_all(6)
	bulle.set_content_margin_all(12)
	# le cadre va sur le texte : une infobulle de relique porte le sien (NidScreen.bulle)
	t.set_stylebox("normal", "TooltipLabel", bulle)
	t.set_stylebox("panel", "TooltipPanel", StyleBoxEmpty.new())
	t.set_color("font_color", "TooltipLabel", TEXTE)
	t.set_color("font_color", "Button", Color("#3b2a18"))
	t.set_color("font_hover_color", "Button", Color("#1f150b"))
	t.set_color("font_pressed_color", "Button", Color("#1f150b"))
	t.set_color("font_hover_pressed_color", "Button", Color("#1f150b"))
	t.set_color("font_focus_color", "Button", Color("#3b2a18"))
	t.set_color("font_disabled_color", "Button", Color("#6f6252"))
	return t

# Blason d'une dynastie (images/blasons), null pour un objet neutre.
static func blason(element: String) -> Texture2D:
	return image("res://images/blasons/%s.png" % element) if element != "" else null

# Animations de sorts (images/spells/<nom>.png) : une bande de 4 images de
# meme largeur. Renvoie les 4 images, ou [] si la planche manque.
static var _anims := {}

static func anim(nom: String) -> Array:
	if not _anims.has(nom):
		var l := []
		var tex := image("res://images/spells/%s.png" % nom)
		if tex != null:
			var w := tex.get_width() / 4.0
			for k in 4:
				var a := AtlasTexture.new()
				a.atlas = tex
				a.region = Rect2(k * w, 0, w, tex.get_height())
				l.append(a)
		_anims[nom] = l
	return _anims[nom]

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
