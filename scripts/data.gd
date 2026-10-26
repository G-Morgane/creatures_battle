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
	"nuit":  {"nom": "Chauve-souris", "passif": "Vol de vie sur les attaques de base"},
	"terre": {"nom": "Tortue",        "passif": "Fatigue de l'adversaire 10 s plus tôt, la sienne réduite de moitié"},
	"vent":  {"nom": "Cheval",        "passif": "15 % d'esquive, chaque esquive lance un éclair"},
	"glace": {"nom": "Loup",          "passif": "Ses attaques posent du givre, +50 % de dégâts contre une cible gelée"},
	"nature":{"nom": "Cerf",          "passif": "Épines : blesse qui le frappe (2 dégâts par coup reçu)"},
	"":      {"nom": "Informe",       "passif": "Aucun"},
}

const RENAISSANCE_PV := 0.25
const VOL_DE_VIE_NUIT := 0.15
# Tortue : veut des combats longs, joue sur la fatigue (mort subite).
const TORTUE_AVANCE_FATIGUE := 10.0
const TORTUE_FATIGUE_MULT := 0.5
# Cheval : esquive au hasard (tirage deterministe par combat), riposte par l'eclair.
const ESQUIVE_CHEVAL := 0.15
const ESQUIVE_MAX := 0.5
const ECLAIR_DEGATS := 10.0
# Cerf : epines (riposte a chaque coup recu) et poison (doses qui s'empilent,
# ne s'effacent pas, passent a travers le bouclier).
const EPINES_CERF := 2.0
const POISON_DPS_PAR_DOSE := 0.2
const POISON_MAX := 100
const EPINES_BONUS_MAX := 2.0      # Coeur de roncier et Graine : epines x2 au plus
const COEUR_PAR_RIPOSTE := 0.1
const GRAINE_POUSSE := 0.05        # bonus d'epines par seconde ou l'adversaire est empoisonne
const GRAINE_DEGATS_PAR_DOSE := 1.0  # Fleche-graine : chaque dose recue blesse aussi
const GOUSSE_COUPS := 5            # Gousse eclatante : une salve tous les 5 coups recus
# Loup : chaque charge de givre ralentit attaques et recharges de sorts ;
# au seuil, la cible gele (plus rien ne part) et ses charges retombent a zero.
const LOUP_GIVRE := 1.0
const LOUP_BONUS_GEL := 1.5        # degats du Loup contre une cible gelee
const GIVRE_RALENTI := 0.03        # par charge
const RALENTI_MAX := 0.6
const GEL_SEUIL := 10.0
const GEL_SEUIL_MIN := 4.0
const GEL_DUREE := 1.5
const ROSE_RABAIS := 3.0           # Rose des neiges : charges en moins pour le prochain gel
const REFORME_DELAI := 3.0         # Ecorce de pergelisol

# --- combat ----------------------------------------------------------------

const PAS := 0.1
const MORT_SUBITE := 30.0      # apres, degats croissants des deux cotes
const FATIGUE_RAMPE := 2.0     # degats par seconde gagnes chaque seconde de fatigue
const DUREE_MAX := 90.0
const BRULURE_DPS := 3.0
const BRULURE_DUREE := 3.0

# --- reliques --------------------------------------------------------------

# type : essence (stats), sort (actif avec recharge), catalyseur (modifie ses voisins)
# Essences : attaque, vitesse, vol_de_vie, pv, bouclier (au depart), esquive (chance).
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
	# nuit
	"croc_noir":      {"nom": "Croc noir",      "element": "nuit", "affinite": 2, "type": "essence",
		"attaque": 2.5, "vol_de_vie": 0.10},
	"nuee":           {"nom": "Nuée",           "element": "nuit", "affinite": 1, "type": "sort",
		"recharge": 5.0, "degats": 3.0, "par_affinite": 0.5, "coups": 5},
	"voile":          {"nom": "Voile",          "element": "nuit", "affinite": 1, "type": "sort",
		"recharge": 6.0, "esquive": true},
	"lune_creuse":    {"nom": "Lune creuse",    "element": "nuit", "affinite": 1, "type": "catalyseur",
		"effet": "vol_de_vie", "valeur": 0.30},
	# terre : encaisser, durer, laisser la fatigue faire le reste
	"pierre":         {"nom": "Pierre",         "element": "terre", "affinite": 2, "type": "essence",
		"pv": 40.0},
	"ecaille":        {"nom": "Écaille",        "element": "terre", "affinite": 1, "type": "essence",
		"bouclier": 30.0},
	"rempart":        {"nom": "Rempart",        "element": "terre", "affinite": 1, "type": "sort",
		"recharge": 6.0, "bouclier": 15.0, "par_affinite": 3.0},
	"socle":          {"nom": "Socle",          "element": "terre", "affinite": 1, "type": "catalyseur",
		"effet": "bouclier", "valeur": 0.4},
	# vent : vitesse, esquive, coups rapides
	"sabot":          {"nom": "Sabot",          "element": "vent",  "affinite": 2, "type": "essence",
		"attaque": 1.5, "vitesse": 0.10},
	"crin":           {"nom": "Crin",           "element": "vent",  "affinite": 1, "type": "essence",
		"esquive": 0.06},
	"rafale":         {"nom": "Rafale",         "element": "vent",  "affinite": 1, "type": "sort",
		"recharge": 3.0, "degats": 4.0, "par_affinite": 0.4, "coups": 3},
	"girouette":      {"nom": "Girouette",      "element": "vent",  "affinite": 1, "type": "catalyseur",
		"effet": "recharge", "valeur": 0.25},
	# nature : epines et poison. Ortie et Amanite renforcent leurs voisins.
	"epine_ronce":    {"nom": "Épine de ronce", "element": "nature", "affinite": 2, "type": "essence",
		"epines": 2.0},
	"baie":           {"nom": "Baie vénéneuse", "element": "nature", "affinite": 2, "type": "essence",
		"poison_attaque": 0.5},
	"ortie":          {"nom": "Feuille d'ortie","element": "nature", "affinite": 1, "type": "catalyseur",
		"effet": "epines", "valeur": 0.5},
	"spore":          {"nom": "Spore amère",    "element": "nature", "affinite": 1, "type": "sort",
		"sort": "Nuage de spores", "recharge": 6.0, "poison": 2.0, "par_affinite": 0.2},
	"liane":          {"nom": "Liane barbelée", "element": "nature", "affinite": 1, "type": "essence", "rarete": "rare",
		"epines_poison": 1.0},
	"amanite":        {"nom": "Amanite pourpre","element": "nature", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "poison", "valeur": 0.5},
	"gousse":         {"nom": "Gousse éclatante","element": "nature", "affinite": 1, "type": "essence", "rarete": "rare",
		"gousse": 15.0},
	"belladone":      {"nom": "Fleur de belladone","element": "nature", "affinite": 1, "type": "essence", "rarete": "epique",
		"belladone": true},
	"coeur_roncier":  {"nom": "Cœur de roncier","element": "nature", "affinite": 1, "type": "essence", "rarete": "epique",
		"coeur": true, "epines": 2.0},
	"graine_jardin":  {"nom": "Graine du Jardin interdit","element": "nature", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"graine": true, "epines": 3.0},
	# glace : givre jusqu'au gel, et un bouclier fait pour se briser.
	# Croc du blizzard : les voisins posent plus de givre. Fourrure : plus de bouclier.
	"flocon":         {"nom": "Flocon intact",  "element": "glace", "affinite": 2, "type": "essence",
		"givre_attaque": 1.0},
	"galet":          {"nom": "Galet gelé",     "element": "glace", "affinite": 1, "type": "sort",
		"sort": "Armure de givre", "recharge": 6.0, "bouclier": 6.0, "par_affinite": 1.0},
	"eclat_givre":    {"nom": "Éclat de givre", "element": "glace", "affinite": 2, "type": "essence",
		"bris_degats": 20.0},
	"fourrure":       {"nom": "Fourrure hivernale","element": "glace", "affinite": 1, "type": "catalyseur",
		"effet": "bouclier", "valeur": 0.5},
	"croc_blizzard":  {"nom": "Croc du blizzard","element": "glace", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "givre", "valeur": 0.5},
	"ecorce":         {"nom": "Écorce de pergélisol","element": "glace", "affinite": 1, "type": "essence", "rarete": "rare",
		"reforme": 20.0},
	"cristal":        {"nom": "Cristal fêlé",   "element": "glace", "affinite": 1, "type": "essence", "rarete": "rare",
		"bris_givre": 3.0},
	"coeur_banquise": {"nom": "Cœur de banquise","element": "glace", "affinite": 1, "type": "essence", "rarete": "epique",
		"gel_bouclier": 25.0},
	"rose_neiges":    {"nom": "Rose des neiges","element": "glace", "affinite": 1, "type": "essence", "rarete": "epique",
		"rose": true},
	"noyau_hiver":    {"nom": "Noyau de l'Hiver éternel","element": "glace", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"nova": 20.0},
	# armes : le cavalier en tient une seule et lance son propre sort.
	# Les catalyseurs voisins s'appliquent aussi a ce sort.
	"baton_braise":   {"nom": "Bâton de braise","element": "feu",   "affinite": 1, "type": "arme", "famille": "baton",
		"sort": "Boule de feu", "recharge": 3.0, "degats": 6.0, "par_affinite": 1.0, "coups": 1},
	"lance_guet":     {"nom": "Lance du guet",  "element": "",      "affinite": 0, "type": "arme", "famille": "hast",
		"sort": "Estoc", "recharge": 2.5, "degats": 8.0, "coups": 1, "perce": true},
	"faux_lunaire":   {"nom": "Faux lunaire",   "element": "nuit", "affinite": 1, "type": "arme", "famille": "faux",
		"sort": "Moisson", "recharge": 6.0, "degats": 6.0, "par_affinite": 1.0, "coups": 1, "execution": true},
	# armes du Cerf
	"sarbacane":      {"nom": "Sarbacane de roseau","element": "nature", "affinite": 1, "type": "arme", "famille": "tir",
		"sort": "Fléchette", "recharge": 2.0, "degats": 2.0, "coups": 1, "poison": 1.0},
	"dague_epine":    {"nom": "Dague d'épine",  "element": "nature", "affinite": 1, "type": "arme", "famille": "lame",
		"sort": "Contre", "contre": 4, "degats": 8.0, "par_epine": 2.0, "coups": 1},
	"arc_saule":      {"nom": "Arc de saule",   "element": "nature", "affinite": 1, "type": "arme", "famille": "tir", "rarete": "rare",
		"sort": "Flèche de chasse", "recharge": 5.0, "degats": 10.0, "par_poison": 1.0, "coups": 1},
	"serpe_ronces":   {"nom": "Serpe de ronces","element": "nature", "affinite": 1, "type": "arme", "famille": "lame", "rarete": "epique",
		"sort": "Lacération", "recharge": 4.0, "degats": 2.0, "coups": 4, "degats_epines": true},
	# armes du Loup : Hast et Hache
	"javelot":        {"nom": "Javelot de stalactite","element": "glace", "affinite": 1, "type": "arme", "famille": "hast",
		"sort": "Javelot", "recharge": 3.0, "degats": 8.0, "coups": 1, "givre": 2.0},
	"hachette":       {"nom": "Hachette de givre","element": "glace", "affinite": 1, "type": "arme", "famille": "hache",
		"sort": "Taille", "recharge": 6.0, "degats": 18.0, "coups": 1, "double_ralenti": true},
	"pique":          {"nom": "Pique de banquise","element": "glace", "affinite": 1, "type": "arme", "famille": "hast", "rarete": "rare",
		"sort": "Estoc glacé", "recharge": 4.0, "degats": 8.0, "coups": 1, "perce": true, "givre": 4.0},
	"hache_glace":    {"nom": "Hache brise-glace","element": "glace", "affinite": 1, "type": "arme", "famille": "hache", "rarete": "epique",
		"sort": "Fracas", "recharge": 7.0, "degats": 10.0, "coups": 1, "fracas": true},
	"lance_hiver":    {"nom": "Lance du Grand Hiver","element": "glace", "affinite": 2, "type": "arme", "famille": "hast", "rarete": "legendaire",
		"sort": "Brise-gel", "recharge": 5.0, "degats": 12.0, "coups": 1, "brise_gel": true},
	"arc_jardin":     {"nom": "Arc du Jardin interdit","element": "nature", "affinite": 2, "type": "arme", "famille": "tir", "rarete": "legendaire",
		"sort": "Flèche-graine", "recharge": 6.0, "degats": 12.0, "coups": 1, "graine": true},
}

# --- familles d'armes ------------------------------------------------------

# Chaque arme a une famille, partagee entre elements : les objets neutres
# viseront une famille (CONCEPTION.md, Familles d'armes).
const FAMILLES := {"tir": "Tir", "lame": "Lame", "hast": "Hast", "hache": "Hache", "baton": "Bâton", "faux": "Faux"}

# --- rarete ----------------------------------------------------------------

# Une relique sans champ "rarete" est commune.
const RARETES := ["commun", "rare", "epique", "legendaire"]
const NOMS_RARETE := {"commun": "Commun", "rare": "Rare", "epique": "Épique", "legendaire": "Légendaire"}

static func rarete(id: String) -> String:
	return RELIQUES[id].get("rarete", "commun")

# Fusion : 3 copies d'un niveau donnent 1 relique du niveau suivant.
# Multiplicateur des stats par niveau (index 0 inutilise). Le niveau 2 vaut un
# peu moins que trois copies (x2,5 contre x3) mais libere deux cases.
const NIVEAU_MAX := 3
const NIVEAU_MULT := [0.0, 1.0, 2.5, 6.0]

# Estoc ignore l'esquive. Moisson double ses degats sous ce seuil de PV.
const SEUIL_EXECUTION := 0.4
