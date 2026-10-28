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
	"feu":   {"nom": "Phénix",        "passif": "Renaît une fois à 25 % de PV, plus vite à chaque combustion (Braise)"},
	"nuit":  {"nom": "Chauve-souris", "passif": "Vol de vie sur les attaques, +12 % de dégâts par malédiction sur la cible"},
	"terre": {"nom": "Tortue",        "passif": "Fatigue de l'adversaire 10 s plus tôt, la sienne réduite de moitié"},
	"vent":  {"nom": "Cheval",        "passif": "15 % d'esquive ; attaques et esquives chargent l'Élan, qui déclenche la Foudre"},
	"glace": {"nom": "Loup",          "passif": "Ses attaques posent du givre, +50 % de dégâts contre une cible gelée"},
	"aube":  {"nom": "Lion",          "passif": "Régénère, et ses soins chargent l'Éclat (un coup de lumière)"},
	"crepuscule": {"nom": "Papillon", "passif": "Un Transfert sans rien à voler ni à renvoyer lance un projectile d'arcane"},
	"nature":{"nom": "Cerf",          "passif": "Épines : blesse qui le frappe (2 dégâts par coup reçu)"},
	"":      {"nom": "Informe",       "passif": "Aucun"},
}

const RENAISSANCE_PV := 0.25
const VOL_DE_VIE_NUIT := 0.15
const NUIT_PAR_MALEDICTION := 0.12  # degats de la Chauve-souris par malediction differente
# Malediction : un etat de 6 s sur l'adversaire, renouvele si on le reapplique.
# Une seule charge, trois avec le Chapelet des rancunes. Effet par charge :
const MALEDICTIONS := ["faiblesse", "langueur", "fletrissure"]
const NOMS_MALEDICTION := {"faiblesse": "Faiblesse", "langueur": "Langueur", "fletrissure": "Flétrissure"}
const MALEDICTION_DUREE := 6.0
const CHAPELET_CHARGES := 3
const FAIBLESSE := 0.15            # degats infliges en moins
const LANGUEUR := 0.15             # vitesse d'attaque en moins (pas les sorts)
const FLETRISSURE := 0.30          # soins recus en moins
# Coups critiques : identite de la famille Lame. Une Lame donne CRIT_LAME de chance
# (plus si l'arme le precise) a toute la monture.
const CRIT_MULT := 1.75
const CRIT_LAME := 0.10
const FESTIN_DEGATS := 15.0        # Faux de la Nuit profonde : par charge consumee
# Lion : on stocke du soin pour frapper. Tous les soins chargent l'Eclat (aux trois quarts),
# les soins excedentaires (au-dela des PV max) comptent double. La charge se fait
# sur le soin prevu : un soin bloque (Belladone) ou reduit (Fletrissure) charge quand meme.
const REGEN_LION := 1.5            # PV par seconde
const ECLAT_SEUIL := 60.0
const ECLAT_SEUIL_MIN := 20.0
const ECLAT_DEGATS := 40.0
const ECLAT_PAR_SOIN := 0.75
const ECLAT_PAR_EXCES := 2.0
const BANDE_SEUIL := 0.5           # Bande de lin : regeneration renforcee sous ce seuil
const ENCENSOIR_DUREE := 4.0
const CARILLON_TOUS := 3
# Papillon : Transfert = renvoyer un malus (poison, brulure, givre, maledictions) ou
# voler un bonus (bouclier, Braise, jauge d'Eclat, bonus d'epines). Chaque source a
# une puissance : quantite volee, et degats du projectile d'arcane si rien a deplacer.
const ARCANE_PAR_PUISSANCE := 1.0
const MUE := 1.5                   # malus renvoye renforce
const BRUME_SOIN := 8.0
const AILE_BRAISE := 2.0           # hate volee : Braise temporaire
const AILE_DUREE := 3.0
const CHRYSALIDE_SEUIL := 0.5
const INVERSION_T := 12.0
# Tortue : veut des combats longs, joue sur la fatigue (mort subite).
const TORTUE_AVANCE_FATIGUE := 10.0
const TORTUE_FATIGUE_MULT := 0.5
# Reduction de degats : retiree a chaque coup recu (pas au poison, a la brulure,
# a la fatigue), avant le bouclier, plafonnee.
const REDUCTION_MAX := 0.5
const FIL_PLOMB_DELAI := 3.0       # bouclier tenu sans bris : renforce
const TUILE := 0.5                 # premier coup apres un nouveau bouclier
const CLEF := 0.5                  # part du bouclier garde au renouvellement
const BORNE_DUREE := 4.0           # fatigue suspendue
const SCHISTE := 0.25              # Hachette de schiste : degats infliges en moins
const SCHISTE_DUREE := 3.0
const REMPART_PAS := 0.05
const REMPART_MAX := 0.2
const FONDATIONS := 0.6            # bouclier selon les degats infliges
const AGES_PAR_SECONDE := 0.5      # soin du Baton des ages par seconde de fatigue
const AGES_MAX := 15.0
# Cheval : esquive au hasard (tirage deterministe par combat). Attaques et esquives
# chargent l'Elan ; a pleine jauge, la Foudre frappe l'adversaire.
const ESQUIVE_CHEVAL := 0.15
const ESQUIVE_MAX := 0.5
const ESQUIVE_MAX_TEMP := 0.75     # avec le Voile de cavale
const ELAN_SEUIL := 100.0
const ELAN_SEUIL_MIN := 40.0
const ELAN_PAR_ATTAQUE := 10.0
const ELAN_PAR_ESQUIVE := 20.0
const ETRIER_MAX := 10.0           # bonus d'Elan de serie au plus
const FOUDRE_DEGATS := 35.0
const RUBAN_DUREE := 2.0
const VOILE_CAVALE_DUREE := 3.0
const GALOP_DUREE := 4.0           # Bride des vents libres
const GALOP_HATE := 5.0
const ALIZE_AVANCE := 0.3          # Javelot des alizes : attaque suivante avancee
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
# Brulure : des charges qui s'empilent, chacune s'eteint au bout de BRULURE_DUREE.
# Combustion : consume des charges (la moitie, ou toutes) pour des degats immediats.
# Braise : +1 par combustion declenchee, chaque point accelere attaques et recharges.
const BRULURE_DPS_CHARGE := 1.5
const BRULURE_DUREE := 4.0
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
# Essences : attaque, vitesse, vol_de_vie, pv, bouclier (au depart), esquive (chance).
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
	# nuit : vol de vie et maledictions. Le Chapelet permet de les empiler.
	"ruban":          {"nom": "Ruban sanguin",  "element": "nuit",  "affinite": 2, "type": "essence",
		"vol_de_vie": 0.08, "attaque": 2.0},
	"aiguille":       {"nom": "Aiguille noire", "element": "nuit",  "affinite": 2, "type": "essence",
		"faiblesse_tous": 3, "attaque": 2.0},
	"sceau":          {"nom": "Sceau de cire",  "element": "nuit",  "affinite": 1, "type": "sort",
		"sort": "Sceau", "recharge": 6.0, "malediction": "langueur"},
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
	# terre : un bouclier qui tient, la reduction de degats, et la fatigue.
	# Fossile spirale renforce bouclier et reduction de ses voisins.
	"brique":         {"nom": "Brique d'argile","element": "terre", "affinite": 2, "type": "essence",
		"reduction": 0.06},
	"truelle":        {"nom": "Truelle de mortier","element": "terre", "affinite": 1, "type": "sort",
		"sort": "Mortier", "recharge": 5.0, "mortier": 15.0, "par_affinite": 1.5, "echelle": "mortier"},
	"cale":           {"nom": "Cale de chêne",  "element": "terre", "affinite": 2, "type": "essence",
		"cale": 0.08},
	"fossile":        {"nom": "Fossile spiralé","element": "terre", "affinite": 1, "type": "catalyseur",
		"effet": "terre", "valeur": 0.5},
	"fil_plomb":      {"nom": "Fil à plomb",    "element": "terre", "affinite": 1, "type": "essence", "rarete": "rare",
		"fil_plomb": 8.0},
	"tuile":          {"nom": "Tuile vernissée","element": "terre", "affinite": 1, "type": "essence", "rarete": "rare",
		"tuile": true},
	"sablier_ensable":{"nom": "Sablier ensablé","element": "terre", "affinite": 1, "type": "essence", "rarete": "rare",
		"sablier_ensable": 5.0},
	"clef":           {"nom": "Clef de voûte",  "element": "terre", "affinite": 1, "type": "essence", "rarete": "epique",
		"clef": true},
	"urne":           {"nom": "Urne des siècles","element": "terre", "affinite": 1, "type": "essence", "rarete": "epique",
		"urne": true},
	"borne":          {"nom": "Borne de l'Éternité","element": "terre", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"borne": true},
	# vent : Elan et Foudre. Fer allege renforce l'Elan des voisins.
	"fer":            {"nom": "Fer allégé",     "element": "vent",  "affinite": 1, "type": "catalyseur",
		"effet": "elan", "valeur": 0.5},
	"ruban_criniere": {"nom": "Ruban de crinière","element": "vent", "affinite": 2, "type": "essence",
		"ruban_criniere": 3.0},
	"grelot":         {"nom": "Grelot de course","element": "vent", "affinite": 1, "type": "sort",
		"sort": "Galop", "recharge": 4.0, "degats": 4.0, "coups": 1, "elan": 15.0},
	"duvet":          {"nom": "Duvet de pissenlit","element": "vent", "affinite": 2, "type": "essence",
		"esquive": 0.06},
	"etrier":         {"nom": "Étrier du grand galop","element": "vent", "affinite": 1, "type": "essence", "rarete": "rare",
		"etrier": 2.0},
	"manche":         {"nom": "Manche à air",   "element": "vent",  "affinite": 1, "type": "essence", "rarete": "rare",
		"manche": 20.0},
	"eventail":       {"nom": "Éventail de bourrasque","element": "vent", "affinite": 1, "type": "essence", "rarete": "rare",
		"eventail": 15.0},
	"voile_cavale":   {"nom": "Voile de cavale","element": "vent",  "affinite": 1, "type": "essence", "rarete": "epique",
		"voile_cavale": 0.3},
	"girouette_indocile": {"nom": "Girouette indocile","element": "vent", "affinite": 1, "type": "essence", "rarete": "epique",
		"girouette": 5.0},
	"bride":          {"nom": "Bride des vents libres","element": "vent", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"bride": true},
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
	# aube : soin et Eclat. Huile de premiere lumiere renforce les soins voisins.
	"meche":          {"nom": "Mèche de veille","element": "aube",  "affinite": 1, "type": "sort",
		"sort": "Veille", "recharge": 4.0, "soin": 8.0, "par_affinite": 1.0},
	"huile":          {"nom": "Huile de première lumière", "element": "aube", "affinite": 1, "type": "catalyseur",
		"effet": "soin", "valeur": 0.5},
	"miroir":         {"nom": "Miroir de poche","element": "aube",  "affinite": 2, "type": "essence",
		"miroir": 10.0},
	"bande":          {"nom": "Bande de lin",   "element": "aube",  "affinite": 2, "type": "essence",
		"bande": 2.0},
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
	# crepuscule : Transfert. Pollen dore renforce les Transferts voisins.
	"battement":      {"nom": "Battement d'ailes","element": "crepuscule", "affinite": 1, "type": "sort",
		"sort": "Battement d'ailes", "recharge": 5.0, "transfert": "renvoyer", "puissance": 10.0, "par_affinite": 0.5, "echelle": "puissance"},
	"poudre":         {"nom": "Poudre d'écailles","element": "crepuscule", "affinite": 2, "type": "essence",
		"poudre": 4.0},
	"cocon":          {"nom": "Cocon",          "element": "crepuscule", "affinite": 2, "type": "essence",
		"bouclier": 20.0, "cocon": 3.0},
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
	# armes : le cavalier en tient une seule et lance son propre sort.
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
	# armes de la Nuit : Faux et Lame
	"dague_minuit":   {"nom": "Dague de minuit","element": "nuit",  "affinite": 1, "type": "arme", "famille": "lame",
		"sort": "Entaille", "recharge": 2.0, "degats": 5.0, "coups": 1, "crit": 0.25},
	"faux_lunaire":   {"nom": "Faux lunaire",   "element": "nuit",  "affinite": 1, "type": "arme", "famille": "faux",
		"sort": "Moisson", "recharge": 5.0, "degats": 8.0, "par_affinite": 1.0, "coups": 1, "execution": true, "vol_de_vie": 0.3},
	"lame_veuve":     {"nom": "Lame de la veuve","element": "nuit", "affinite": 1, "type": "arme", "famille": "lame", "rarete": "rare",
		"sort": "Coup de la veuve", "recharge": 3.0, "degats": 7.0, "coups": 1, "crit": 0.15, "crit_malediction": true},
	"faux_festin":    {"nom": "Faux du festin", "element": "nuit",  "affinite": 1, "type": "arme", "famille": "faux", "rarete": "epique",
		"sort": "Festin", "recharge": 5.0, "degats": 10.0, "coups": 1, "par_malediction": 0.35, "achever_seuil": 0.4, "achever_mult": 1.5},
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
	# armes du Cheval : Lame et Hast
	"dague_brise":    {"nom": "Dague de brise", "element": "vent",  "affinite": 1, "type": "arme", "famille": "lame",
		"sort": "Brise", "recharge": 1.5, "degats": 3.0, "coups": 1, "elan": 8.0},
	"javelot_alizes": {"nom": "Javelot des alizés","element": "vent", "affinite": 1, "type": "arme", "famille": "hast",
		"sort": "Alizé", "recharge": 3.0, "degats": 7.0, "coups": 1, "perce": true, "alize": true},
	"sabre_rafale":   {"nom": "Sabre de rafale","element": "vent",  "affinite": 1, "type": "arme", "famille": "lame", "rarete": "rare",
		"sort": "Riposte", "riposte_esquive": true, "degats": 3.0, "coups": 3, "elan": 5.0},
	"lance_bourrasque": {"nom": "Lance de bourrasque","element": "vent", "affinite": 1, "type": "arme", "famille": "hast", "rarete": "epique",
		"sort": "Bourrasque", "recharge": 4.0, "degats": 10.0, "coups": 1, "apres_foudre": true},
	"rapiere":        {"nom": "Rapière des vents libres","element": "vent", "affinite": 2, "type": "arme", "famille": "lame", "rarete": "legendaire",
		"sort": "Vents libres", "recharge": 2.0, "degats": 6.0, "coups": 1, "elan": 6.0, "rapiere": true},
	# armes de la Tortue : Hache et Baton
	"hachette_schiste": {"nom": "Hachette de schiste","element": "terre", "affinite": 1, "type": "arme", "famille": "hache",
		"sort": "Schiste", "recharge": 5.0, "degats": 12.0, "coups": 1, "schiste": true},
	"baton_glaise":   {"nom": "Bâton de glaise","element": "terre", "affinite": 1, "type": "arme", "famille": "baton",
		"sort": "Glaise", "recharge": 3.0, "degats": 4.0, "coups": 1, "bouclier": 5.0, "par_affinite": 1.0, "echelle": "bouclier"},
	"baton_rempart":  {"nom": "Bâton du rempart","element": "terre", "affinite": 1, "type": "arme", "famille": "baton", "rarete": "rare",
		"sort": "Rempart", "recharge": 3.0, "degats": 4.0, "coups": 1, "rempart": true},
	"hache_fondations": {"nom": "Hache des fondations","element": "terre", "affinite": 1, "type": "arme", "famille": "hache", "rarete": "epique",
		"sort": "Fondations", "recharge": 7.0, "degats": 18.0, "coups": 1, "fondations": true},
	"baton_ages":     {"nom": "Bâton des âges enfouis","element": "terre", "affinite": 2, "type": "arme", "famille": "baton", "rarete": "legendaire",
		"sort": "Âges enfouis", "recharge": 3.0, "degats": 5.0, "coups": 1, "soin": 4.0, "ages": true},
	"arc_jardin":     {"nom": "Arc du Jardin interdit","element": "nature", "affinite": 2, "type": "arme", "famille": "tir", "rarete": "legendaire",
		"sort": "Flèche-graine", "recharge": 6.0, "degats": 12.0, "coups": 1, "graine": true},
}

# --- familles d'armes ------------------------------------------------------

# Chaque arme a une famille, partagee entre elements : les objets neutres
# viseront une famille (CONCEPTION.md, Familles d'armes).
const FAMILLES := {"tir": "Tir", "lame": "Lame", "hast": "Hast", "hache": "Hache", "baton": "Bâton", "faux": "Faux"}

# --- rarete ----------------------------------------------------------------

# Une relique sans champ "rarete" est commune.
# Les sept Cours (archetypes) et l'element qui les porte dans le code.
# L'Ete (lumiere) n'a pas encore d'objets.
const COURS := {"nature": "Cour du Printemps", "glace": "Cour de l'Hiver", "feu": "Cour de l'Automne",
	"nuit": "Cour de la Nuit", "aube": "Cour de l'Aube", "crepuscule": "Cour du Jour"}

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
