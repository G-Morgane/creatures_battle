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

static func icone(id: String) -> Texture2D:
	return image("res://images/icones/%s.png" % id)

const ELEMENTS := {
	"feu":   {"fond": Color("#5a2a14"), "vif": Color("#ff8a3d"), "clair": Color("#ffd27a")},
	"nuit":  {"fond": Color("#2a1d3d"), "vif": Color("#9d6bff"), "clair": Color("#d7c4ff")},
	"terre": {"fond": Color("#3a3220"), "vif": Color("#b08a4a"), "clair": Color("#e3cf9a")},
	"vent":  {"fond": Color("#1c3338"), "vif": Color("#6fd3d6"), "clair": Color("#d4f6f4")},
	"nature":{"fond": Color("#1d3027"), "vif": Color("#3f9e7a"), "clair": Color("#e8d5b0")},
	"":      {"fond": Color("#2a2d33"), "vif": Color("#8a8f99"), "clair": Color("#c9ccd2")},
}
