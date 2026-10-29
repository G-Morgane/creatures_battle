class_name Data
extends RefCounted

# Le sac : un damier de 8 colonnes sur 4 rangees, dont la partie n'ouvre
# d'abord que le centre (Partie.COLONNES_DEPART).
const NID_L := 8
const NID_H := 4

# --- creature --------------------------------------------------------------

const PV_BASE := 600.0
const ATTAQUE_BASE := 5.0
const INTERVALLE_BASE := 1.0   # secondes entre deux attaques de base

# forme : ce qui eclot quand l'element domine
# Pas d'avantage elementaire : aucun element ne bat un autre (CONCEPTION.md §5).
const FORMES := {
	"feu":   {"nom": "Phénix",        "passif": "Renaît une fois à 50 % de PV, plus vite à chaque combustion (Braise)"},
	"nuit":  {"nom": "Chauve-souris", "passif": "Vol de vie sur les attaques, +20 % de dégâts par malédiction sur la cible"},
	"glace": {"nom": "Ours",          "passif": "Ses attaques posent du givre, +100 % de dégâts contre une cible gelée"},
	"aube":  {"nom": "Lion",          "passif": "Régénère, et ses soins chargent l'Éclat (un coup de lumière)"},
	"crepuscule": {"nom": "Papillon", "passif": "Un Transfert sans rien à voler ni à renvoyer lance un projectile d'arcane"},
	"nature":{"nom": "Cerf",          "passif": "Épines : blesse qui le frappe (3 dégâts par coup reçu)"},
	# Dynasties sans objets pour l'instant : la monture est prete, le set reste a concevoir.
	"automne": {"nom": "Renard",      "passif": "À concevoir"},
	"jour":  {"nom": "Paon",          "passif": "À concevoir"},
	"":      {"nom": "Informe",       "passif": "Aucun"},
}

const RENAISSANCE_PV := 0.5
const VOL_DE_VIE_NUIT := 0.15
const NUIT_PAR_MALEDICTION := 0.20  # degats de la Chauve-souris par malediction differente
# Malediction : un etat de 6 s sur l'adversaire, renouvele si on le reapplique.
# Une seule charge, trois avec le Chapelet des rancunes. Effet par charge :
const MALEDICTIONS := ["faiblesse", "langueur", "fletrissure", "stigmate"]
const NOMS_MALEDICTION := {"faiblesse": "Faiblesse", "langueur": "Langueur", "fletrissure": "Flétrissure", "stigmate": "Stigmate"}
const MALEDICTION_DUREE := 6.0
const CHAPELET_CHARGES := 3
const FAIBLESSE := 0.15            # degats infliges en moins
const LANGUEUR := 0.15             # vitesse d'attaque en moins (pas les sorts)
const FLETRISSURE := 0.30          # soins recus en moins
const STIGMATE := 0.10             # degats recus en plus
# Pacte : s'ouvre a partir de ce nombre de maledictions differentes.
const PACTE_SEUIL := 3
# Coups critiques : identite de la famille Lame. Une Lame donne CRIT_LAME de chance
# (plus si l'arme le precise) a toute la monture.
const CRIT_MULT := 1.75
const CRIT_LAME := 0.10
const FESTIN_DEGATS := 15.0        # Faux de la Nuit profonde : par charge consumee
# Lion : on stocke du soin pour frapper. Tous les soins chargent l'Eclat (aux trois quarts),
# les soins excedentaires (au-dela des PV max) comptent double. La charge se fait
# sur le soin prevu : un soin bloque (Belladone) ou reduit (Fletrissure) charge quand meme.
const REGEN_LION := 0.5            # PV par seconde
const ECLAT_SEUIL := 60.0
const ECLAT_SEUIL_MIN := 20.0
const ECLAT_DEGATS := 60.0
const ECLAT_PAR_SOIN := 0.75
const ECLAT_PAR_EXCES := 2.0
const BANDE_SEUIL := 0.5           # Bande de lin : regeneration renforcee sous ce seuil
const ENCENSOIR_DUREE := 4.0
const CARILLON_TOUS := 3
# Papillon : Transfert = renvoyer un malus (poison, brulure, givre, maledictions) ou
# voler un bonus (bouclier, Braise, jauge d'Eclat, bonus d'epines). Chaque source a
# une puissance : quantite volee, et degats du projectile d'arcane si rien a deplacer.
const ARCANE_PAR_PUISSANCE := 1.5
const MUE := 1.5                   # malus renvoye renforce
const BRUME_SOIN := 12.0
const AILE_BRAISE := 2.0           # hate volee : Braise temporaire
const AILE_DUREE := 3.0
const CHRYSALIDE_SEUIL := 0.5
const INVERSION_T := 12.0
# Cerf : epines (riposte a chaque coup recu) et poison (doses qui s'empilent,
# ne s'effacent pas, passent a travers le bouclier).
const EPINES_CERF := 3.0
const POISON_DPS_PAR_DOSE := 0.5
const POISON_MAX := 100
const EPINES_BONUS_MAX := 2.0      # Coeur de roncier et Graine : epines x2 au plus
const COEUR_PAR_RIPOSTE := 0.1
const GRAINE_POUSSE := 0.05        # bonus d'epines par seconde ou l'adversaire est empoisonne
const GRAINE_DEGATS_PAR_DOSE := 1.0  # Fleche-graine : chaque dose recue blesse aussi
const GOUSSE_COUPS := 5            # Gousse eclatante : une salve tous les 5 coups recus
# Loup : chaque charge de givre ralentit attaques et recharges de sorts ;
# au seuil, la cible gele (plus rien ne part) et ses charges retombent a zero.
const LOUP_GIVRE := 1.0
const LOUP_BONUS_GEL := 2.0        # degats du Loup contre une cible gelee
const GIVRE_RALENTI := 0.03        # par charge
const RALENTI_MAX := 0.4
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
# Brulure : des charges qui s'empilent, chacune s'eteint au bout de BRULURE_DUREE.
# Combustion : consume des charges (la moitie, ou toutes) pour des degats immediats.
# Braise : +1 par combustion declenchee, chaque point accelere attaques et recharges.
const BRULURE_DPS_CHARGE := 2.0
const BRULURE_DUREE := 5.0
const BRULURE_MAX := 50
const COMBUSTION_PAR_CHARGE := 4.0
const COMBUSTION_TOTALE_BONUS := 1.5
const HATE_PAR_BRAISE := 0.04
const BRAISE_MAX := 10.0
const RESINE_SEUIL := 0.5          # Resine ambree : brulure doublee sous ce seuil de PV
const FOURNAISE_SEUIL := 0.5       # Coeur de fournaise
const FOURNAISE_BRAISE := 5.0
const FOURNAISE_DUREE := 6.0

# --- reliques --------------------------------------------------------------

# type : essence (stats), sort (actif avec recharge), catalyseur (modifie ses voisins)
# Essences : attaque, vitesse, vol_de_vie, pv, bouclier (au depart).
# Un sort gagne `par_affinite` par point d'affinite dans son element, sur sa valeur
# principale : `echelle` si elle est donnee, sinon degats, bouclier ou poison.
const RELIQUES := {
	# feu : on allume (brulure), puis on consume (combustion), et la Braise accelere.
	# Plume incandescente et Tison tenace renforcent leurs voisins.
	"charbon":        {"nom": "Charbon ardent", "element": "feu",   "affinite": 2, "type": "essence",
		"brulure_attaque": 1.0},
	"plume_incandescente": {"nom": "Plume incandescente", "element": "feu", "affinite": 1, "type": "catalyseur",
		"effet": "brulure", "valeur": 0.5},
	"tison":          {"nom": "Tison tenace",   "element": "feu",   "affinite": 1, "type": "catalyseur",
		"effet": "braise", "valeur": 0.5},
	"cendre":         {"nom": "Cendre tiède",   "element": "feu",   "affinite": 1, "type": "essence",
		"combustion_soin": 4.0},
	"graine_brasier": {"nom": "Graine de brasier", "element": "feu", "affinite": 1, "type": "sort", "rarete": "rare",
		"sort": "Embrasement", "recharge": 5.0, "combustion": 0.5, "braise": 1.0},
	"obsidienne":     {"nom": "Éclat d'obsidienne", "element": "feu", "affinite": 1, "type": "essence", "rarete": "rare",
		"degats_en_feu": 4.0},
	"resine":         {"nom": "Résine ambrée",  "element": "feu",   "affinite": 1, "type": "essence", "rarete": "rare",
		"resine": true},
	"coeur_fournaise":{"nom": "Cœur de fournaise", "element": "feu", "affinite": 1, "type": "essence", "rarete": "epique",
		"fournaise": true},
	"fleur_cendres":  {"nom": "Fleur des cendres", "element": "feu", "affinite": 1, "type": "essence", "rarete": "epique",
		"soin_par_charge": 1.0},
	"oeuf_brasier":   {"nom": "Œuf du Premier Brasier", "element": "feu", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"oeuf": true},
	# portee "rangee" : le catalyseur agit sur toute sa rangee, pas seulement ses voisins
	"trainee":        {"nom": "Traînée de cendres", "element": "feu", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "brulure", "valeur": 0.5, "portee": "rangee"},
	# nuit : vol de vie et maledictions. Le Chapelet permet de les empiler.
	"ruban":          {"nom": "Ruban sanguin",  "element": "nuit",  "affinite": 2, "type": "essence",
		"vol_de_vie": 0.08, "attaque": 4.0},
	"aiguille":       {"nom": "Aiguille noire", "element": "nuit",  "affinite": 2, "type": "essence",
		"faiblesse_tous": 3, "attaque": 4.0},
	"sceau":          {"nom": "Sceau de cire",  "element": "nuit",  "affinite": 1, "type": "sort",
		"sort": "Sceau", "recharge": 4.0, "malediction": "langueur"},
	"sablier":        {"nom": "Sablier vermeil","element": "nuit",  "affinite": 1, "type": "essence",
		"sablier": 3.0},
	"poupee":         {"nom": "Poupée cousue",  "element": "nuit",  "affinite": 1, "type": "essence", "rarete": "rare",
		"renvoi": 0.3},
	"peigne":         {"nom": "Peigne de la veuve","element": "nuit", "affinite": 1, "type": "essence", "rarete": "rare",
		"crit": 0.08, "crit_fletrissure": true},
	"chapelet":       {"nom": "Chapelet des rancunes","element": "nuit", "affinite": 1, "type": "essence", "rarete": "rare",
		"chapelet": true},
	"masque":         {"nom": "Masque du festin","element": "nuit", "affinite": 1, "type": "essence", "rarete": "epique",
		"vol_par_malediction": 0.06},
	"grimoire":       {"nom": "Grimoire des noms perdus","element": "nuit", "affinite": 1, "type": "essence", "rarete": "epique",
		"grimoire": 40.0},
	"pacte":          {"nom": "Pacte de la Nuit profonde","element": "nuit", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"pacte": 5.0},
	"calice":         {"nom": "Calice de sang", "element": "nuit",  "affinite": 1, "type": "catalyseur",
		"effet": "vol_de_vie", "valeur": 0.10},
	# nature : epines et poison. Ortie et Amanite renforcent leurs voisins.
	"epine_ronce":    {"nom": "Épine de ronce", "element": "nature", "affinite": 2, "type": "essence",
		"epines": 2.0, "pv": 40.0},
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
	# grappe : stats par relique voisine de la meme dynastie
	"mousse":         {"nom": "Mousse des sous-bois","element": "nature", "affinite": 1, "type": "essence",
		"pv": 10.0, "grappe": {"pv": 15.0}},
	# Terreau : ses voisines grandissent a chaque victoire ou il est dans le sac
	"terreau":        {"nom": "Terreau fertile","element": "nature", "affinite": 1, "type": "essence", "rarete": "rare",
		"terreau": true},
	# glace : givre jusqu'au gel, et un bouclier fait pour se briser.
	# Croc du blizzard : les voisins posent plus de givre. Fourrure : plus de bouclier.
	"flocon":         {"nom": "Flocon intact",  "element": "glace", "affinite": 2, "type": "essence",
		"givre_attaque": 1.0, "attaque": 1.0},
	"galet":          {"nom": "Galet gelé",     "element": "glace", "affinite": 1, "type": "sort",
		"sort": "Armure de givre", "recharge": 6.0, "bouclier": 5.0, "par_affinite": 0.5},
	"eclat_givre":    {"nom": "Éclat de givre", "element": "glace", "affinite": 2, "type": "essence",
		"bris_degats": 30.0},
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
	# solitaire : ces stats seulement si aucune relique ne la touche
	"stalagmite":     {"nom": "Stalagmite solitaire","element": "glace", "affinite": 1, "type": "essence", "rarete": "rare",
		"solitaire": {"bouclier": 40.0, "attaque": 3.0}},
	# aube : soin et Eclat. Huile de premiere lumiere renforce les soins voisins.
	"meche":          {"nom": "Mèche de veille","element": "aube",  "affinite": 1, "type": "sort",
		"sort": "Veille", "recharge": 4.0, "soin": 6.0, "par_affinite": 0.75},
	"huile":          {"nom": "Huile de première lumière", "element": "aube", "affinite": 1, "type": "catalyseur",
		"effet": "soin", "valeur": 0.5},
	"miroir":         {"nom": "Miroir de poche","element": "aube",  "affinite": 2, "type": "essence",
		"miroir": 10.0},
	"bande":          {"nom": "Bande de lin",   "element": "aube",  "affinite": 2, "type": "essence",
		"bande": 1.0},
	"encensoir":      {"nom": "Encensoir du matin","element": "aube", "affinite": 1, "type": "essence", "rarete": "rare",
		"encensoir": 3.0},
	"vasque":         {"nom": "Vasque de rosée","element": "aube",  "affinite": 1, "type": "essence", "rarete": "rare",
		"vasque": 0.5},
	"prisme":         {"nom": "Prisme d'aurore","element": "aube",  "affinite": 1, "type": "essence", "rarete": "rare",
		"prisme": 15.0},
	"voile_aube":     {"nom": "Voile de l'aube","element": "aube",  "affinite": 1, "type": "essence", "rarete": "epique",
		"voile_aube": 1.0},
	"carillon":       {"nom": "Carillon du réveil","element": "aube", "affinite": 1, "type": "essence", "rarete": "epique",
		"carillon": 40.0},
	"lanterne":       {"nom": "Lanterne du Premier Matin","element": "aube", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"lanterne": 1.0},
	"cadran":         {"nom": "Cadran solaire", "element": "aube",  "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "recharge", "valeur": 0.25},
	# crepuscule : Transfert. Pollen dore renforce les Transferts voisins.
	"battement":      {"nom": "Battement d'ailes","element": "crepuscule", "affinite": 1, "type": "sort",
		"sort": "Battement d'ailes", "recharge": 5.0, "transfert": "renvoyer", "puissance": 10.0, "par_affinite": 0.5, "echelle": "puissance"},
	"poudre":         {"nom": "Poudre d'écailles","element": "crepuscule", "affinite": 2, "type": "essence",
		"poudre": 4.0},
	"cocon":          {"nom": "Cocon",          "element": "crepuscule", "affinite": 2, "type": "essence",
		"bouclier": 30.0, "cocon": 3.0},
	"pollen":         {"nom": "Pollen doré",    "element": "crepuscule", "affinite": 1, "type": "catalyseur",
		"effet": "transfert", "valeur": 0.5},
	"mue":            {"nom": "Mue",            "element": "crepuscule", "affinite": 1, "type": "essence", "rarete": "rare",
		"mue": true},
	"brume":          {"nom": "Brume du soir",  "element": "crepuscule", "affinite": 1, "type": "essence", "rarete": "rare",
		"brume": true},
	"phalene":        {"nom": "Phalène",        "element": "crepuscule", "affinite": 1, "type": "essence", "rarete": "rare",
		"phalene": true},
	"chrysalide":     {"nom": "Chrysalide",     "element": "crepuscule", "affinite": 1, "type": "essence", "rarete": "epique",
		"chrysalide": true},
	"aile_lune":      {"nom": "Aile de lune",   "element": "crepuscule", "affinite": 1, "type": "essence", "rarete": "epique",
		"aile_lune": true},
	"inversion":      {"nom": "Inversion",      "element": "crepuscule", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"inversion": true},
	# copie : reprend cette part de l'essence voisine la plus forte
	"reflet":         {"nom": "Reflet d'aile",  "element": "crepuscule", "affinite": 1, "type": "essence", "rarete": "epique",
		"copie": 0.75},
	# armes : le cavalier les tient toutes, chacune lance son propre sort.
	# Les catalyseurs voisins s'appliquent aussi a ce sort.
	# armes du Phenix : Baton et Faux
	"baton_braise":   {"nom": "Bâton de braise","element": "feu",   "affinite": 1, "type": "arme", "famille": "baton",
		"sort": "Étincelle", "recharge": 3.0, "degats": 4.0, "par_affinite": 0.8, "coups": 1, "brulure": 1.0},
	"faux_tison":     {"nom": "Faux de tison",  "element": "feu",   "affinite": 1, "type": "arme", "famille": "faux",
		"sort": "Taille", "recharge": 4.0, "degats": 8.0, "coups": 1, "achever_seuil": 0.5, "achever_mult": 1.5},
	"baton_brasier":  {"nom": "Bâton du brasier","element": "feu",  "affinite": 1, "type": "arme", "famille": "baton", "rarete": "rare",
		"sort": "Brasier", "recharge": 4.0, "degats": 3.0, "coups": 1, "brulure": 1.0, "par_affinite": 0.3, "echelle": "brulure"},
	"faux_cendres":   {"nom": "Faux des cendres","element": "feu",  "affinite": 1, "type": "arme", "famille": "faux", "rarete": "epique",
		"sort": "Moisson ardente", "recharge": 6.0, "degats": 10.0, "coups": 1, "combustion_affaiblie": true},
	"baton_premier":  {"nom": "Bâton du Premier Brasier","element": "feu", "affinite": 2, "type": "arme", "famille": "baton", "rarete": "legendaire",
		"sort": "Premier brasier", "recharge": 3.0, "degats": 6.0, "coups": 1, "brulure": 1.0, "combustion_tous": 4, "tir_renaissance": true},
	"lance_guet":     {"nom": "Lance du guet",  "element": "",      "affinite": 0, "type": "arme", "famille": "hast",
		"sort": "Estoc", "recharge": 2.5, "degats": 8.0, "coups": 1, "perce": true},
	# armes de la Nuit : Lames, un Arc, une Hache, et la Faux pour le legendaire
	"dague_minuit":   {"nom": "Dague de minuit","element": "nuit",  "affinite": 1, "type": "arme", "famille": "lame",
		"sort": "Entaille", "recharge": 2.0, "degats": 5.0, "coups": 1, "crit": 0.25},
	"arc_echo":       {"nom": "Arc de l'écho",  "element": "nuit",  "affinite": 1, "type": "arme", "famille": "tir",
		"sort": "Écho", "recharge": 4.0, "degats": 4.0, "coups": 2, "malediction": "stigmate"},
	"lame_veuve":     {"nom": "Lame de la veuve","element": "nuit", "affinite": 1, "type": "arme", "famille": "lame", "rarete": "rare",
		"sort": "Coup de la veuve", "recharge": 3.0, "degats": 7.0, "coups": 1, "crit": 0.15, "crit_stigmate": true},
	"hache_bourreau": {"nom": "Hache du bourreau","element": "nuit", "affinite": 1, "type": "arme", "famille": "hache", "rarete": "epique",
		"sort": "Sentence", "recharge": 6.0, "degats": 14.0, "coups": 1, "par_malediction": 0.35, "execution": true},
	"faux_nuit":      {"nom": "Faux de la Nuit profonde","element": "nuit", "affinite": 2, "type": "arme", "famille": "faux", "rarete": "legendaire",
		"sort": "Nuit profonde", "recharge": 7.0, "degats": 10.0, "coups": 1, "consume_maledictions": true, "achever_seuil": 0.4, "achever_mult": 1.5},
	# armes du Cerf
	"sarbacane":      {"nom": "Sarbacane de roseau","element": "nature", "affinite": 1, "type": "arme", "famille": "tir",
		"sort": "Fléchette", "recharge": 2.0, "degats": 2.0, "coups": 1, "poison": 1.0},
	"dague_epine":    {"nom": "Dague d'épine",  "element": "nature", "affinite": 1, "type": "arme", "famille": "lame",
		"sort": "Contre", "contre": 4, "degats": 8.0, "par_epine": 2.0, "coups": 1},
	"arc_saule":      {"nom": "Arc de saule",   "element": "nature", "affinite": 1, "type": "arme", "famille": "tir", "rarete": "rare",
		"sort": "Flèche de chasse", "recharge": 5.0, "degats": 10.0, "par_poison": 1.0, "coups": 1},
	"serpe_ronces":   {"nom": "Serpe de ronces","element": "nature", "affinite": 1, "type": "arme", "famille": "lame", "rarete": "epique",
		"sort": "Lacération", "recharge": 4.0, "degats": 2.0, "coups": 4, "degats_epines": true},
	# armes de l'Ours : Hast et Hache
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
	# armes du Lion : Baton et Hache
	"sceptre_aurore": {"nom": "Sceptre de l'aurore","element": "aube", "affinite": 1, "type": "arme", "famille": "baton",
		"sort": "Rayon", "recharge": 3.0, "degats": 5.0, "par_affinite": 0.8, "coups": 1},
	"hachette_matin": {"nom": "Hachette du matin","element": "aube", "affinite": 1, "type": "arme", "famille": "hache",
		"sort": "Coup du matin", "recharge": 5.0, "degats": 14.0, "coups": 1, "charge_eclat": 15.0},
	"baton_rosee":    {"nom": "Bâton de rosée", "element": "aube",  "affinite": 1, "type": "arme", "famille": "baton", "rarete": "rare",
		"sort": "Rosée", "recharge": 3.0, "degats": 4.0, "coups": 1, "soin": 6.0, "par_affinite": 0.5, "echelle": "soin"},
	"hache_solaire":  {"nom": "Hache solaire",  "element": "aube",  "affinite": 1, "type": "arme", "famille": "hache", "rarete": "epique",
		"sort": "Hache solaire", "recharge": 5.0, "degats": 12.0, "coups": 1, "apres_eclat": true},
	"sceptre_premier":{"nom": "Sceptre du Premier Matin","element": "aube", "affinite": 2, "type": "arme", "famille": "baton", "rarete": "legendaire",
		"sort": "Premier matin", "recharge": 3.0, "degats": 6.0, "coups": 1, "eclat_tous": 4},
	# armes du Papillon : Tir et Hast
	"arc_crepuscule": {"nom": "Arc du crépuscule","element": "crepuscule", "affinite": 1, "type": "arme", "famille": "tir",
		"sort": "Flèche du soir", "recharge": 3.0, "degats": 6.0, "coups": 1, "transfert": "bouclier", "puissance": 6.0},
	"flechettes":     {"nom": "Fléchettes d'écailles","element": "crepuscule", "affinite": 1, "type": "arme", "famille": "tir",
		"sort": "Fléchettes", "recharge": 1.5, "degats": 3.0, "coups": 1, "transfert": "renvoyer", "puissance": 8.0, "transfert_tous": 3},
	"glaive_brume":   {"nom": "Glaive de brume","element": "crepuscule", "affinite": 1, "type": "arme", "famille": "hast", "rarete": "rare",
		"sort": "Glaive", "recharge": 4.0, "degats": 8.0, "coups": 1, "perce": true, "transfert": "voler", "puissance": 8.0},
	"arc_lunes":      {"nom": "Arc des deux lunes","element": "crepuscule", "affinite": 1, "type": "arme", "famille": "tir", "rarete": "epique",
		"sort": "Deux lunes", "recharge": 4.0, "degats": 6.0, "coups": 1, "par_transfert": 1.5},
	"lance_entre":    {"nom": "Lance de l'entre-deux","element": "crepuscule", "affinite": 2, "type": "arme", "famille": "hast", "rarete": "legendaire",
		"sort": "Entre-deux", "recharge": 3.0, "degats": 8.0, "coups": 1, "transfert": "echange", "puissance": 10.0},
	"arc_jardin":     {"nom": "Arc du Jardin interdit","element": "nature", "affinite": 2, "type": "arme", "famille": "tir", "rarete": "legendaire",
		"sort": "Flèche-graine", "recharge": 6.0, "degats": 12.0, "coups": 1, "graine": true},
}

# --- familles d'armes ------------------------------------------------------

# Chaque arme a une famille, partagee entre elements : les objets neutres
# viseront une famille (CONCEPTION.md, Familles d'armes).
const FAMILLES := {"tir": "Tir", "lame": "Lame", "hast": "Hast", "hache": "Hache", "baton": "Bâton", "faux": "Faux"}

# --- rarete ----------------------------------------------------------------

# Une relique sans champ "rarete" est commune.
# Les huit Dynasties (archetypes) et l'element qui les porte dans le code, dans
# l'ordre du choix en debut de partie. Automne (Renard) et Jour (Paon) n'ont pas
# encore d'objets : on ne peut pas encore les choisir.
const DYNASTIES := {"nature": "Dynastie du Printemps", "feu": "Dynastie de l'Été", "automne": "Dynastie de l'Automne",
	"glace": "Dynastie de l'Hiver", "aube": "Dynastie de l'Aube", "jour": "Dynastie du Jour",
	"crepuscule": "Dynastie du Crépuscule", "nuit": "Dynastie de la Nuit"}
const DYNASTIES_A_VENIR := ["automne", "jour"]
# Ce qu'on explique au survol, au moment de les choisir.
const IDENTITES := {
	"nature": "Épines et poison. Punit qui le frappe, et le poison s'accumule sans passer par les boucliers.",
	"feu": "Brûlure, combustion et Braise. Les brûlures s'empilent, la combustion les consume d'un coup, la Braise accélère tout.",
	"automne": "À venir : la Ruse, entre esquive et feintes.",
	"glace": "Givre, gel et bouclier qui se brise. Le givre ralentit jusqu'au gel, qui bloque les recharges adverses.",
	"aube": "Soin et Éclat. Les soins se stockent dans l'Éclat, qui frappe quand la jauge est pleine.",
	"jour": "À venir : la Parade, des bonus qui montent par paliers.",
	"crepuscule": "Transfert. Vole les bonus adverses et renvoie ses malus ; sinon, un projectile d'arcane.",
	"nuit": "Vol de vie, malédictions et coups critiques. Affaiblit l'adversaire et se soigne en frappant.",
}

# --- cavaliers ---------------------------------------------------------------
# Choisi en debut de partie (images/cavaliers). Chacun a un talent, d'un
# domaine different : combat offensif, sac, combat defensif, boutique.
const CAVALIERS := {"ombre": "L'Ombre", "pousse": "La Pousse", "coquille": "La Coquille", "capuchon": "Le Capuchon"}
const TALENTS := {
	"ombre": ["Embuscade", "Au début de chaque combat, tes armes lancent leur sort tout de suite."],
	"pousse": ["Croissance", "Tu commences avec 4 cases de sac offertes, à placer où tu veux."],
	"coquille": ["Éclosion", "Ta monture commence chaque combat avec un bouclier de 40."],
	"capuchon": ["Érudit", "La première relance de chaque boutique est gratuite."],
}
const ECLOSION_BOUCLIER := 40.0
const EMBUSCADE_DELAI := 0.1

# --- elites (PvE) ------------------------------------------------------------
# Une elite est le Nid d'un fantome en avance, avec une regle qui lui est propre
# (voir Combat._elite) et sa propre image (images/montures/ennemis).
const ELITES := {
	"sanglier": {"nom": "Sanglier des Racines", "element": "nature",
		"texte": "Accumule de la protection, puis la dépense dans une charge puissante."},
	"phalene": {"nom": "Phalène de l'Ouest", "element": "crepuscule",
		"texte": "Dissipe ses malus et prépare une attaque qui traverse les boucliers."},
	"vouivre": {"nom": "Vouivre des Cendres", "element": "feu",
		"texte": "Se renforce grâce aux malus reçus, puis brise ses entraves à mi-vie."},
}
# Sanglier : bouclier par seconde, puis une charge qui le depense (x mult).
const SANGLIER_RACINES := 5.0
const SANGLIER_CHARGE_TOUS := 8.0
const SANGLIER_CHARGE_MULT := 1.5
# Phalene : dissipe ses malus, et un trait qui passe les boucliers.
const PHALENE_DISSIPE_TOUS := 6.0
const PHALENE_TRAIT_TOUS := 7.0
const PHALENE_TRAIT := 25.0
# Vouivre : +3 % de degats par malus subi (charge de brulure, de givre, de
# malediction, 5 doses de poison), plafond +90 % ; a mi-vie, une fois, elle
# brise ses entraves : malus effaces, +40 % de degats et d'attaque.
const VOUIVRE_PAR_MALUS := 0.03
const VOUIVRE_MAX := 0.9
const VOUIVRE_FURIE := 1.4
# --- gardiens (boss de fin d'acte) ---------------------------------------------
# Meme mecanisme que les elites (cle "elite" de la creature), une regle par
# gardien. Acte I : le Bastion endormi.
const GARDIENS := {
	"bastion": {"nom": "Le Bastion endormi", "element": "glace",
		"texte": "Une tortue-sanctuaire possédée. Son rempart nourrit l'œil du temple, qui frappe d'autant plus fort que le bouclier est intact."},
}
const GARDIEN_ACTE := ["bastion"]
# Le cycle du Bastion : rempart (bouclier, attaques lentes), ouverture (immobile,
# l'oeil absorbe le bouclier), regard (frappe selon l'absorbe, plafonne), puis
# resistance (le cavalier referme la porte : sans protection un moment).
const BASTION_REMPART := 7.0          # bouclier par seconde
const BASTION_REMPART_DUREE := 8.0
const BASTION_LENTEUR := 1.8          # attaques plus lentes pendant le rempart
const BASTION_OUVERTURE_DUREE := 3.0
const BASTION_REGARD_MULT := 1.5
const BASTION_REGARD_MAX := 90.0
const BASTION_RESISTANCE_DUREE := 3.0
const BASTION_RESISTANCE_FRAGILE := 1.25  # degats recus sans protection

# Les chiffres d'une elite grandissent avec la manche.
const ELITE_PAR_MANCHE := 0.05

static func dynasties_jouables() -> Array:
	return DYNASTIES.keys().filter(func(d): return not d in DYNASTIES_A_VENIR)

const RARETES := ["commun", "rare", "epique", "legendaire"]
const NOMS_RARETE := {"commun": "Commun", "rare": "Rare", "epique": "Épique", "legendaire": "Légendaire"}

# --- formes ----------------------------------------------------------------
# Cases qu'occupe une relique dans le sac, en decalages depuis son ancre (coin
# haut gauche). Regle : les armes selon leur famille, les autres selon leur
# rarete ; FORMES_OBJETS corrige a la main ceux qui le meritent.
const FORMES_FAMILLE := {
	"hast": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	"faux": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	"baton": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	"tir": [Vector2i(0, 0), Vector2i(0, 1)],
	"lame": [Vector2i(0, 0), Vector2i(0, 1)],
	"hache": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
}
const FORMES_RARETE := {
	"commun": [Vector2i(0, 0)],
	"rare": [Vector2i(0, 0), Vector2i(1, 0)],
	"epique": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"legendaire": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
}
const FORMES_OBJETS := {}

# Forme de id tournee de rot quarts de tour (sens horaire), ramenee en (0, 0).
static func empreinte(id: String, rot := 0) -> Array:
	var r: Dictionary = RELIQUES[id]
	var f: Array = FORMES_OBJETS.get(id, FORMES_FAMILLE[r["famille"]] if r.has("famille") else FORMES_RARETE[rarete(id)])
	for k in posmod(rot, 4):
		f = f.map(func(d): return Vector2i(-d.y, d.x))
	var mini := Vector2i(999, 999)
	for d in f:
		mini = Vector2i(mini(mini.x, d.x), mini(mini.y, d.y))
	return f.map(func(d): return d - mini)

static func rarete(id: String) -> String:
	return RELIQUES[id].get("rarete", "commun")

# Fusion : 3 copies d'un niveau donnent 1 relique du niveau suivant.
# Multiplicateur des stats par niveau (index 0 inutilise). Le niveau 2 vaut un
# peu moins que trois copies (x2,5 contre x3) mais libere deux cases.
const NIVEAU_MAX := 3
const NIVEAU_MULT := [0.0, 1.0, 2.5, 6.0]

# Signature de dynastie : a chaque activation, un sort ou une arme ajoute un
# petit effet de son element (x niveau). Brulure, poison et givre en charges,
# drain (passe le bouclier et soigne), soin, projectile d'arcane en degats.
const SIGNATURES := {"feu": 1.0, "nature": 1.0, "glace": 1.0, "nuit": 3.0, "aube": 3.0, "crepuscule": 4.0}
const NOMS_SIGNATURE := {"feu": "%s brûlure", "nature": "%s dose de poison", "glace": "%s givre",
	"nuit": "draine %s PV", "aube": "soigne %s PV", "crepuscule": "projectile d'arcane de %s"}
# Une essence n'a pas d'activation : elle donne cette part de sa signature a
# chaque attaque de la monture (5 essences de l'Ete : 1 brulure par attaque).
const SIGNATURE_ESSENCE := 0.2

# Terreau fertile : +4 % aux voisines par saison (victoire avec le Terreau dans
# le sac), saisons comptees jusqu'a 10.
const TERREAU_PAR_SAISON := 0.04
const TERREAU_SAISONS_MAX := 10

# Moisson double ses degats sous ce seuil de PV.
const SEUIL_EXECUTION := 0.4
