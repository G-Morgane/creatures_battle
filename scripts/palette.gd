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

const ELEMENTS := {
	"feu":   {"fond": Color("#5a2a14"), "vif": Color("#ff8a3d"), "clair": Color("#ffd27a")},
	"ombre": {"fond": Color("#2a1d3d"), "vif": Color("#9d6bff"), "clair": Color("#d7c4ff")},
	"":      {"fond": Color("#2a2d33"), "vif": Color("#8a8f99"), "clair": Color("#c9ccd2")},
}
