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
	"feu":   {"nom": "Phénix",        "passif": "Renaît une fois à 50 % de PV, et sa renaissance consume toutes les brûlures adverses"},
	"nuit":  {"nom": "Chauve-souris", "passif": "+30 % de dégâts par malédiction différente sur la cible"},
	"glace": {"nom": "Ours",          "passif": "Ses attaques posent du givre, +100 % de dégâts contre une cible gelée"},
	"aube":  {"nom": "Lion",          "passif": "Régénère, et ses soins chargent l'Éclat (un coup de lumière)"},
	"crepuscule": {"nom": "Papillon", "passif": "Chaque sort de la monture crée une Illusion, qui encaisse une attaque puis éclate en arcane"},
	"nature":{"nom": "Cerf",          "passif": "Épines : blesse qui le frappe (4 dégâts) et l'empoisonne (1 dose)"},
	"automne": {"nom": "Renard",      "passif": "15 % d'esquive ; après une esquive, son coup suivant est un critique"},
	"jour":  {"nom": "Paon",          "passif": "Chaque arme lancée donne 1 Éventail : +8 % de dégâts et de recharge des armes par charge"},
	"":      {"nom": "Informe",       "passif": "Aucun"},
}

# Une Dynastie, un principe (nid-vault/discussions/2026-10-29 Archétypes resserrés.md).

# Ete : allumer (brulure), puis consumer (combustion).
const RENAISSANCE_PV := 0.5
const BRULURE_DPS_CHARGE := 2.0
const BRULURE_DUREE := 5.0
const BRULURE_MAX := 50
const COMBUSTION_PAR_CHARGE := 4.0
const COMBUSTION_TOTALE_BONUS := 1.5
# Nuit : affaiblir avant de frapper. Malediction : un etat de 6 s sur l'adversaire,
# renouvele si on le reapplique.
const NUIT_PAR_MALEDICTION := 0.30  # degats de la Chauve-souris par malediction differente
const MALEDICTIONS := ["faiblesse", "fletrissure", "stigmate"]
const NOMS_MALEDICTION := {"faiblesse": "Faiblesse", "fletrissure": "Flétrissure", "stigmate": "Stigmate"}
const MALEDICTION_DUREE := 6.0
const FAIBLESSE := 0.15            # degats infliges en moins
const FLETRISSURE := 0.30          # soins recus en moins
const STIGMATE := 0.15             # degats recus en plus
const FESTIN_DEGATS := 15.0        # Faux de la Nuit profonde : par malediction consumee
# Lion : on stocke du soin pour frapper. Tous les soins chargent l'Eclat (aux trois quarts),
# les soins excedentaires (au-dela des PV max) comptent double. La charge se fait
# sur le soin prevu : un soin bloque (Belladone) ou reduit (Fletrissure) charge quand meme.
const REGEN_LION := 0.5            # PV par seconde
const ECLAT_SEUIL := 60.0
const ECLAT_SEUIL_MIN := 20.0
const ECLAT_DEGATS := 45.0
const ECLAT_PAR_SOIN := 0.75
const ECLAT_PAR_EXCES := 2.0
# Papillon : les sorts creent des Illusions ; une Illusion encaisse une attaque
# (attaque de base ou coup d'arme) et eclate en projectile d'arcane.
const ILLUSIONS_MAX := 2
const MUE_ILLUSIONS := 3
const ILLUSION_ARCANE := 5.0
const MUE_AVANCE := 1.0            # le prochain sort part plus tot quand une Illusion eclate
const CHRYSALIDE_PART := 0.5       # un sort se repete a cette puissance
# Cerf : qui le frappe s'empoisonne. Le poison s'empile, ne s'efface pas et passe
# a travers le bouclier.
const EPINES_CERF := 4.0
const EPINES_POISON_CERF := 1.0
const POISON_DPS_PAR_DOSE := 0.6
const POISON_MAX := 100
# Ours : chaque charge de givre ralentit attaques et recharges de sorts ;
# au seuil, la cible gele (plus rien ne part) et ses charges retombent a zero.
const OURS_GIVRE := 1.0
const OURS_BONUS_GEL := 2.0        # degats de l'Ours contre une cible gelee
const GIVRE_RALENTI := 0.03        # par charge
const RALENTI_MAX := 0.4
const GEL_SEUIL := 10.0
const GEL_DUREE := 1.5
# Renard : l'esquive ouvre la garde, le crit punit. Les Lames donnent du crit
# (CRIT_LAME, ou ce que l'arme precise) a toute la monture.
const ESQUIVE_RENARD := 0.15
const ESQUIVE_MAX := 0.6
const BOURRASQUE_DUREE := 2.0
const CRIT_MULT := 1.75
const CRIT_LAME := 0.10
const COUTELAS_MULT := 3.0         # crit apres une esquive, avec le Coutelas
# Paon : chaque arme lancee donne de l'Eventail, qui renforce les armes.
const EVENTAIL_MAX := 10.0
const EVENTAIL_BONUS := 0.08       # degats et vitesse de recharge des armes, par charge
const ZENITH_SEUIL := 10.0

# --- combat ----------------------------------------------------------------

const PAS := 0.1
const MORT_SUBITE := 30.0      # apres, degats croissants des deux cotes
const FATIGUE_RAMPE := 2.0     # degats par seconde gagnes chaque seconde de fatigue
const DUREE_MAX := 90.0

# --- reliques --------------------------------------------------------------

# type : essence (stats), sort (actif avec recharge), catalyseur (modifie ses voisins)
# Essences : attaque, vitesse, pv, bouclier (au depart).
# Un sort gagne `par_affinite` par point d'affinite dans son element, sur sa valeur
# principale : `echelle` si elle est donnee, sinon degats, bouclier, poison ou soin.
# Chaque Dynastie : 7 objets de monture (3 communs, 2 rares, 1 epique, 1 legendaire)
# et 3 armes d'une seule famille (commune, rare, legendaire).
# Catalyseurs : effet multiplicatif sur ses voisins (brulure, givre, degats,
# recharge), ou ajout a chaque activation (poison_ajout, soin_ajout, malediction).
const RELIQUES := {
	# ete : allumer puis consumer
	"charbon":        {"nom": "Charbon ardent", "element": "feu",   "affinite": 2, "type": "essence",
		"attaque": 3.0, "brulure_attaque": 1.0},
	"cendre":         {"nom": "Cendre tiède",   "element": "feu",   "affinite": 2, "type": "essence",
		"pv": 40.0, "brulure_duree": 1.0},
	"graine_brasier": {"nom": "Graine de brasier", "element": "feu", "affinite": 1, "type": "sort",
		"sort": "Embrasement", "recharge": 5.0, "brulure": 3.0, "par_affinite": 0.3},
	"tison":          {"nom": "Tison tenace",   "element": "feu",   "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "brulure", "valeur": 0.5},
	"obsidienne":     {"nom": "Éclat d'obsidienne", "element": "feu", "affinite": 1, "type": "essence", "rarete": "rare",
		"obsidienne": 8.0},
	"coeur_fournaise":{"nom": "Cœur de fournaise", "element": "feu", "affinite": 1, "type": "essence", "rarete": "epique",
		"fournaise": true},
	"oeuf_brasier":   {"nom": "Œuf du Premier Brasier", "element": "feu", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"oeuf": true},
	# nuit : affaiblir avant de frapper
	"aiguille":       {"nom": "Aiguille noire", "element": "nuit",  "affinite": 2, "type": "essence",
		"attaque": 5.0, "stigmate_tous": 4},
	"sablier":        {"nom": "Sablier vermeil","element": "nuit",  "affinite": 2, "type": "essence",
		"pv": 40.0, "sablier": 2.0},
	"sceau":          {"nom": "Sceau de cire",  "element": "nuit",  "affinite": 1, "type": "sort",
		"sort": "Sceau", "recharge": 4.0, "malediction": "faiblesse"},
	"poupee":         {"nom": "Poupée cousue",  "element": "nuit",  "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "malediction", "valeur": 1.0},
	"grimoire":       {"nom": "Grimoire des noms perdus","element": "nuit", "affinite": 1, "type": "essence", "rarete": "rare",
		"grimoire": 20.0},
	"masque":         {"nom": "Masque du festin","element": "nuit", "affinite": 1, "type": "essence", "rarete": "epique",
		"masque": true},
	"pacte":          {"nom": "Pacte de la Nuit profonde","element": "nuit", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"pacte": true},
	# printemps : qui me touche s'empoisonne
	"epine_ronce":    {"nom": "Épine de ronce", "element": "nature", "affinite": 2, "type": "essence",
		"pv": 40.0, "epines": 2.0},
	"baie":           {"nom": "Baie vénéneuse", "element": "nature", "affinite": 2, "type": "essence",
		"attaque": 3.0, "poison_attaque": 0.5},
	"spore":          {"nom": "Spore amère",    "element": "nature", "affinite": 1, "type": "sort",
		"sort": "Nuage de spores", "recharge": 6.0, "poison": 3.0, "par_affinite": 0.2},
	"ortie":          {"nom": "Feuille d'ortie","element": "nature", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "poison_ajout", "valeur": 1.0},
	"liane":          {"nom": "Liane barbelée", "element": "nature", "affinite": 1, "type": "essence", "rarete": "rare",
		"epines_poison": 1.0},
	"belladone":      {"nom": "Fleur de belladone","element": "nature", "affinite": 1, "type": "essence", "rarete": "epique",
		"belladone": true},
	"graine_jardin":  {"nom": "Graine du Jardin interdit","element": "nature", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"graine": true},
	# hiver : ralentir jusqu'au gel
	"flocon":         {"nom": "Flocon intact",  "element": "glace", "affinite": 2, "type": "essence",
		"attaque": 3.0, "givre_attaque": 1.0},
	"fourrure":       {"nom": "Fourrure hivernale","element": "glace", "affinite": 2, "type": "essence",
		"pv": 40.0, "gel_duree": 0.5},
	"galet":          {"nom": "Galet gelé",     "element": "glace", "affinite": 1, "type": "sort",
		"sort": "Souffle glacé", "recharge": 5.0, "givre": 3.0, "par_affinite": 0.2},
	"croc_blizzard":  {"nom": "Croc du blizzard","element": "glace", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "givre", "valeur": 0.5},
	"cristal":        {"nom": "Cristal fêlé",   "element": "glace", "affinite": 1, "type": "essence", "rarete": "rare",
		"gel_degats": 30.0},
	"coeur_banquise": {"nom": "Cœur de banquise","element": "glace", "affinite": 1, "type": "essence", "rarete": "epique",
		"banquise": true},
	"noyau_hiver":    {"nom": "Noyau de l'Hiver éternel","element": "glace", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"gel_seuil": 6.0},
	# aube : soigner pour frapper
	"bande":          {"nom": "Bande de lin",   "element": "aube",  "affinite": 2, "type": "essence",
		"pv": 40.0, "regen": 1.0},
	"miroir":         {"nom": "Miroir de poche","element": "aube",  "affinite": 2, "type": "essence",
		"attaque": 3.0, "miroir": 10.0},
	"meche":          {"nom": "Mèche de veille","element": "aube",  "affinite": 1, "type": "sort",
		"sort": "Veille", "recharge": 4.0, "soin": 6.0, "par_affinite": 0.75},
	"huile":          {"nom": "Huile de première lumière", "element": "aube", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "soin_ajout", "valeur": 3.0},
	"voile_aube":     {"nom": "Voile de l'aube","element": "aube",  "affinite": 1, "type": "essence", "rarete": "rare",
		"voile_aube": 1.0},
	"carillon":       {"nom": "Carillon du réveil","element": "aube", "affinite": 1, "type": "essence", "rarete": "epique",
		"carillon": 20.0},
	"lanterne":       {"nom": "Lanterne du Premier Matin","element": "aube", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"lanterne": 0.5},
	# crepuscule : lancer des sorts, semer des illusions
	"poudre":         {"nom": "Poudre d'écailles","element": "crepuscule", "affinite": 2, "type": "essence",
		"attaque": 3.0, "arcane_bonus": 3.0},
	"cocon":          {"nom": "Cocon",          "element": "crepuscule", "affinite": 2, "type": "essence",
		"pv": 40.0, "illusions_depart": 1},
	"battement":      {"nom": "Battement d'ailes","element": "crepuscule", "affinite": 1, "type": "sort",
		"sort": "Battement d'ailes", "recharge": 5.0, "arcane": 10.0, "par_affinite": 0.5, "echelle": "arcane"},
	"pollen":         {"nom": "Pollen doré",    "element": "crepuscule", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "recharge", "valeur": 0.15},
	"mue":            {"nom": "Mue",            "element": "crepuscule", "affinite": 1, "type": "essence", "rarete": "rare",
		"mue": true},
	"phalene":        {"nom": "Phalène",        "element": "crepuscule", "affinite": 1, "type": "essence", "rarete": "epique",
		"phalene": true},
	"chrysalide":     {"nom": "Chrysalide",     "element": "crepuscule", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"chrysalide": true},
	# automne : esquiver, puis frapper juste
	"croc_renard":    {"nom": "Croc de renard", "element": "automne", "affinite": 2, "type": "essence",
		"attaque": 3.0, "crit": 0.08},
	"feuille_morte":  {"nom": "Feuille morte",  "element": "automne", "affinite": 2, "type": "essence",
		"pv": 40.0, "esquive": 0.05},
	"bourrasque":     {"nom": "Bourrasque",     "element": "automne", "affinite": 1, "type": "sort",
		"sort": "Bourrasque", "recharge": 6.0, "esquive_temp": 0.3},
	"pelage_roux":    {"nom": "Pelage roux",    "element": "automne", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "crit", "valeur": 0.08},
	"bogue":          {"nom": "Bogue de châtaigne","element": "automne", "affinite": 1, "type": "essence", "rarete": "rare",
		"bogue": true},
	"oeil_chasseur":  {"nom": "Œil du chasseur","element": "automne", "affinite": 1, "type": "essence", "rarete": "epique",
		"crit_mult": 2.5},
	"queue_renard":   {"nom": "Queue du Vieux Renard","element": "automne", "affinite": 2, "type": "essence", "rarete": "legendaire",
		"queue": true},
	# jour : faire la roue, enchainer les armes
	"plume_ocelle":   {"nom": "Plume d'ocelle", "element": "jour",  "affinite": 2, "type": "essence",
		"attaque": 3.0, "eventail_depart": 2.0},
	"ecu_dore":       {"nom": "Écu doré",       "element": "jour",  "affinite": 2, "type": "essence",
		"pv": 40.0, "ecu": 6.0},
	"roue":           {"nom": "Faire la roue",  "element": "jour",  "affinite": 1, "type": "sort",
		"sort": "La roue", "recharge": 6.0, "roue": 1.0},
	"broche_soleil":  {"nom": "Broche de soleil","element": "jour", "affinite": 1, "type": "catalyseur", "rarete": "rare",
		"effet": "degats", "valeur": 0.25},
	"miroir_ocelle":  {"nom": "Miroir d'ocelle","element": "jour",  "affinite": 1, "type": "essence", "rarete": "rare",
		"miroir_ocelle": 1.0},
	"couronne_midi":  {"nom": "Couronne de midi","element": "jour", "affinite": 1, "type": "essence", "rarete": "epique",
		"eventail_max": 20.0},
	"oeil_zenith":    {"nom": "Œil du Zénith",  "element": "jour",  "affinite": 2, "type": "essence", "rarete": "legendaire",
		"zenith": true},
	# armes : le cavalier les tient toutes, chacune lance son propre sort.
	# Les catalyseurs voisins s'appliquent aussi a ce sort.
	# Ete : Baton
	"baton_braise":   {"nom": "Bâton de braise","element": "feu",   "affinite": 1, "type": "arme", "famille": "baton",
		"sort": "Boule de feu", "recharge": 3.0, "degats": 4.0, "par_affinite": 0.5, "coups": 1, "brulure": 2.0},
	"baton_brasier":  {"nom": "Bâton du brasier","element": "feu",  "affinite": 1, "type": "arme", "famille": "baton", "rarete": "rare",
		"sort": "Brasier", "recharge": 5.0, "degats": 6.0, "coups": 1, "combustion": 0.5},
	"baton_premier":  {"nom": "Bâton du Premier Brasier","element": "feu", "affinite": 2, "type": "arme", "famille": "baton", "rarete": "legendaire",
		"sort": "Premier brasier", "recharge": 7.0, "degats": 8.0, "coups": 1, "combustion": 1.0, "combustion_mult": 2.0},
	"lance_guet":     {"nom": "Lance du guet",  "element": "",      "affinite": 0, "type": "arme", "famille": "hast",
		"sort": "Estoc", "recharge": 2.5, "degats": 8.0, "coups": 1, "perce": true},
	# Nuit : Faux
	"faux_lunaire":   {"nom": "Faux lunaire",   "element": "nuit",  "affinite": 1, "type": "arme", "famille": "faux",
		"sort": "Fauche lunaire", "recharge": 3.0, "degats": 10.0, "coups": 1, "malediction": "fletrissure"},
	"faux_festin":    {"nom": "Faux du festin", "element": "nuit",  "affinite": 1, "type": "arme", "famille": "faux", "rarete": "rare",
		"sort": "Festin", "recharge": 4.0, "degats": 12.0, "coups": 1, "par_malediction": 0.35},
	"faux_nuit":      {"nom": "Faux de la Nuit profonde","element": "nuit", "affinite": 2, "type": "arme", "famille": "faux", "rarete": "legendaire",
		"sort": "Nuit profonde", "recharge": 7.0, "degats": 10.0, "coups": 1, "consume_maledictions": true},
	# Printemps : Tir
	"sarbacane":      {"nom": "Sarbacane de roseau","element": "nature", "affinite": 1, "type": "arme", "famille": "tir",
		"sort": "Fléchette", "recharge": 2.0, "degats": 2.0, "coups": 1, "poison": 2.0},
	"arc_saule":      {"nom": "Arc de saule",   "element": "nature", "affinite": 1, "type": "arme", "famille": "tir", "rarete": "rare",
		"sort": "Flèche de ronce", "recharge": 4.0, "degats": 6.0, "coups": 1, "degats_epines": true},
	"arc_jardin":     {"nom": "Arc du Jardin interdit","element": "nature", "affinite": 2, "type": "arme", "famille": "tir", "rarete": "legendaire",
		"sort": "Flèche-graine", "contre": 2, "degats": 4.0, "coups": 1, "poison": 2.0},
	# Hiver : Hache
	"hachette":       {"nom": "Hachette de givre","element": "glace", "affinite": 1, "type": "arme", "famille": "hache",
		"sort": "Taille", "recharge": 6.0, "degats": 18.0, "coups": 1, "givre": 2.0},
	"hache_glace":    {"nom": "Hache brise-glace","element": "glace", "affinite": 1, "type": "arme", "famille": "hache", "rarete": "rare",
		"sort": "Fracas", "recharge": 5.0, "degats": 12.0, "coups": 1, "contre_gel": 2.0},
	"hache_hiver":    {"nom": "Hache du Grand Hiver","element": "glace", "affinite": 2, "type": "arme", "famille": "hache", "rarete": "legendaire",
		"sort": "Grand Hiver", "recharge": 5.0, "degats": 14.0, "coups": 1, "givre": 3.0, "prolonge_gel": 1.0},
	# Aube : Hast
	"lance_aurore":   {"nom": "Lance de l'aurore","element": "aube", "affinite": 1, "type": "arme", "famille": "hast",
		"sort": "Rayon", "recharge": 3.0, "degats": 6.0, "coups": 1, "perce": true, "soin": 5.0, "echelle": "soin", "par_affinite": 0.3},
	"pique_solaire":  {"nom": "Pique solaire",  "element": "aube",  "affinite": 1, "type": "arme", "famille": "hast", "rarete": "rare",
		"sort": "Pique solaire", "recharge": 4.0, "degats": 8.0, "coups": 1, "perce": true, "par_eclat": 0.1},
	"lance_matin":    {"nom": "Lance du Premier Matin","element": "aube", "affinite": 2, "type": "arme", "famille": "hast", "rarete": "legendaire",
		"sort": "Premier matin", "recharge": 4.0, "degats": 10.0, "coups": 1, "perce": true, "eclat_moitie": true},
	# Crepuscule : Baton
	"sceptre_ecailles":{"nom": "Sceptre d'écailles","element": "crepuscule", "affinite": 1, "type": "arme", "famille": "baton",
		"sort": "Trait d'arcane", "recharge": 3.0, "arcane": 8.0, "par_affinite": 0.5, "echelle": "arcane"},
	"baton_brume":    {"nom": "Bâton de brume", "element": "crepuscule", "affinite": 1, "type": "arme", "famille": "baton", "rarete": "rare",
		"sort": "Brume", "recharge": 5.0, "degats": 4.0, "coups": 1, "illusions": 2},
	"baton_entre":    {"nom": "Bâton de l'entre-deux","element": "crepuscule", "affinite": 2, "type": "arme", "famille": "baton", "rarete": "legendaire",
		"sort": "Entre-deux", "recharge": 6.0, "eclate_illusions": 25.0},
	# Automne : Lame
	"dague_feuille":  {"nom": "Dague de feuille","element": "automne", "affinite": 1, "type": "arme", "famille": "lame",
		"sort": "Entaille", "recharge": 1.5, "degats": 4.0, "coups": 1, "crit": 0.2},
	"lame_rousse":    {"nom": "Lame rousse",    "element": "automne", "affinite": 1, "type": "arme", "famille": "lame", "rarete": "rare",
		"sort": "Coup roux", "recharge": 3.0, "degats": 7.0, "coups": 1, "crit_recharge": 1.0},
	"coutelas":       {"nom": "Coutelas du Vieux Renard","element": "automne", "affinite": 2, "type": "arme", "famille": "lame", "rarete": "legendaire",
		"sort": "Coup du renard", "recharge": 4.0, "degats": 10.0, "coups": 1, "coutelas": true},
	# Jour : Tir
	"arc_plumes":     {"nom": "Arc à plumes",   "element": "jour",  "affinite": 1, "type": "arme", "famille": "tir",
		"sort": "Volée", "recharge": 2.5, "degats": 3.0, "coups": 2},
	"arbalete_doree": {"nom": "Arbalète dorée", "element": "jour",  "affinite": 1, "type": "arme", "famille": "tir", "rarete": "rare",
		"sort": "Carreau doré", "recharge": 3.5, "degats": 8.0, "coups": 1, "eventail_gain": 2.0},
	"arc_zenith":     {"nom": "Arc du Zénith",  "element": "jour",  "affinite": 2, "type": "arme", "famille": "tir", "rarete": "legendaire",
		"sort": "Pluie du Zénith", "recharge": 4.0, "degats": 3.0, "coups": 1, "coups_par_eventail": true},
}

# --- familles d'armes ------------------------------------------------------

# Chaque arme a une famille, partagee entre elements : les objets neutres
# viseront une famille (CONCEPTION.md, Familles d'armes).
const FAMILLES := {"tir": "Tir", "lame": "Lame", "hast": "Hast", "hache": "Hache", "baton": "Bâton", "faux": "Faux"}

# --- rarete ----------------------------------------------------------------

# Une relique sans champ "rarete" est commune.
# Les huit Dynasties (archetypes) et l'element qui les porte dans le code, dans
# l'ordre du choix en debut de partie. Une Dynastie sans objets se met dans
# DYNASTIES_A_VENIR : on ne peut pas la choisir.
const DYNASTIES := {"nature": "Dynastie du Printemps", "feu": "Dynastie de l'Été", "automne": "Dynastie de l'Automne",
	"glace": "Dynastie de l'Hiver", "aube": "Dynastie de l'Aube", "jour": "Dynastie du Jour",
	"crepuscule": "Dynastie du Crépuscule", "nuit": "Dynastie de la Nuit"}
const DYNASTIES_A_VENIR := []
# Ce qu'on explique au survol, au moment de les choisir : le principe, en une phrase.
const IDENTITES := {
	"nature": "Qui me touche s'empoisonne. Les épines ripostent, et chaque riposte empoisonne.",
	"feu": "Allumer puis consumer. Les brûlures s'empilent, la combustion les consume d'un coup.",
	"automne": "Esquiver, puis frapper juste. Chaque esquive prépare un coup critique.",
	"glace": "Ralentir jusqu'au gel. Le givre ralentit, le gel arrête tout et ouvre une fenêtre d'attaque.",
	"aube": "Soigner pour frapper. Les soins se stockent dans l'Éclat, qui frappe quand la jauge est pleine.",
	"jour": "Faire la roue. Chaque arme lancée donne de l'Éventail, qui renforce les armes suivantes.",
	"crepuscule": "Lancer des sorts, semer des illusions. Chaque Illusion encaisse un coup puis éclate en arcane.",
	"nuit": "Affaiblir avant de frapper. Chaque malédiction différente rend la Chauve-souris plus forte.",
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

# Fusion : 3 copies de niveau 1 donnent un niveau 2, puis 2 niveaux 2 donnent
# le niveau 3 (6 copies en tout). FUSION_COPIES[niv] : copies de ce niveau a reunir.
# Multiplicateur des stats par niveau (index 0 inutilise) : un peu moins que
# les copies reunies (x2,5 pour 3, x5 pour 6), mais des cases liberees.
const NIVEAU_MAX := 3
const FUSION_COPIES := [0, 3, 2]
const NIVEAU_MULT := [0.0, 1.0, 2.5, 5.0]

# Copies de niveau 1 que contient une relique de niveau niv (1, 3, 6).
static func copies_niveau(niv: int) -> int:
	var n := 1
	for k in range(1, niv):
		n *= FUSION_COPIES[k]
	return n

# Signature de dynastie : a chaque activation, un sort ou une arme ajoute un
# petit effet de son element (x niveau). Brulure, poison et givre en charges,
# drain (passe le bouclier et soigne), soin, projectile d'arcane, griffe (degats
# directs), bouclier.
const SIGNATURES := {"feu": 1.0, "nature": 1.0, "glace": 1.0, "nuit": 5.0, "aube": 3.0, "crepuscule": 4.0,
	"automne": 3.0, "jour": 3.0}
const NOMS_SIGNATURE := {"feu": "%s brûlure", "nature": "%s dose de poison", "glace": "%s givre",
	"nuit": "draine %s PV", "aube": "soigne %s PV", "crepuscule": "projectile d'arcane de %s",
	"automne": "griffe de %s", "jour": "%s de bouclier"}
# Une essence n'a pas d'activation : elle donne cette part de sa signature a
# chaque attaque de la monture (5 essences de l'Ete : 1 brulure par attaque).
const SIGNATURE_ESSENCE := 0.2
