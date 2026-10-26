class_name Data
extends RefCounted

const NID_L := 4
const NID_H := 4

# --- creature --------------------------------------------------------------

const PV_BASE := 300.0
const ATTAQUE_BASE := 5.0
const INTERVALLE_BASE := 1.0   # secondes entre deux attaques de base

# forme : ce qui eclot quand l'element domine
# Pas d'avantage elementaire : aucun element ne bat un autre (CONCEPTION.md §5).
const FORMES := {
	"feu":   {"nom": "Phénix",        "passif": "Renaît une fois à 25 % de PV"},
	"ombre": {"nom": "Chauve-souris", "passif": "Vol de vie sur les attaques de base"},
	"":      {"nom": "Informe",       "passif": "Aucun"},
}

const RENAISSANCE_PV := 0.25
const VOL_DE_VIE_OMBRE := 0.15

# --- combat ----------------------------------------------------------------

const PAS := 0.1
const MORT_SUBITE := 30.0      # apres, degats croissants des deux cotes
const DUREE_MAX := 90.0
const BRULURE_DPS := 3.0
const BRULURE_DUREE := 3.0

# --- reliques --------------------------------------------------------------

# type : essence (stats), sort (actif avec recharge), catalyseur (modifie ses voisins)
# Un sort gagne `par_affinite` par point d'affinite dans son element.
const RELIQUES := {
	# feu
	"braise":         {"nom": "Braise",         "element": "feu",   "affinite": 2, "type": "essence",
		"attaque": 2.0},
	"plume_cendre":   {"nom": "Plume de cendre","element": "feu",   "affinite": 1, "type": "essence",
		"vitesse": 0.15},
	"souffle_ardent": {"nom": "Souffle ardent", "element": "feu",   "affinite": 1, "type": "sort",
		"recharge": 4.0, "degats": 10.0, "par_affinite": 1.5, "coups": 1},
	"foyer":          {"nom": "Foyer",          "element": "feu",   "affinite": 1, "type": "catalyseur",
		"effet": "brulure"},
	# ombre
	"croc_noir":      {"nom": "Croc noir",      "element": "ombre", "affinite": 2, "type": "essence",
		"attaque": 2.5, "vol_de_vie": 0.10},
	"nuee":           {"nom": "Nuée",           "element": "ombre", "affinite": 1, "type": "sort",
		"recharge": 5.0, "degats": 3.0, "par_affinite": 0.5, "coups": 5},
	"voile":          {"nom": "Voile",          "element": "ombre", "affinite": 1, "type": "sort",
		"recharge": 6.0, "esquive": true},
	"lune_creuse":    {"nom": "Lune creuse",    "element": "ombre", "affinite": 1, "type": "catalyseur",
		"effet": "vol_de_vie", "valeur": 0.30},
	# armes : le cavalier en tient une seule et lance son propre sort.
	# Les catalyseurs voisins s'appliquent aussi a ce sort.
	"baton_braise":   {"nom": "Bâton de braise","element": "feu",   "affinite": 1, "type": "arme",
		"sort": "Boule de feu", "recharge": 3.0, "degats": 6.0, "par_affinite": 1.0, "coups": 1},
	"lance_guet":     {"nom": "Lance du guet",  "element": "",      "affinite": 0, "type": "arme",
		"sort": "Estoc", "recharge": 2.5, "degats": 8.0, "coups": 1, "perce": true},
	"faux_lunaire":   {"nom": "Faux lunaire",   "element": "ombre", "affinite": 1, "type": "arme",
		"sort": "Moisson", "recharge": 6.0, "degats": 6.0, "par_affinite": 1.0, "coups": 1, "execution": true},
}

# Estoc ignore l'esquive. Moisson double ses degats sous ce seuil de PV.
const SEUIL_EXECUTION := 0.4
