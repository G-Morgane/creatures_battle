class_name Partie
extends RefCounted

# Une run : carte de trois actes, Ferveur, bourse, boutique, Nid du joueur.
# Apres chaque combat la boutique est ouverte, sans obligation d'acheter ; un
# feu de camp ou une rencontre ne donne ni or ni boutique, on reste sur la carte.
# Le hasard passe par une graine : meme graine, meme carte, memes boutiques,
# memes adversaires.

const OR_PAR_MANCHE := 10   # une manche = un noeud franchi
const PRIX := {"essence": 3, "sort": 4, "catalyseur": 4, "arme": 5}
const BONUS_RARETE := {"commun": 0, "rare": 2, "epique": 4, "legendaire": 7}
# Chances de tirage par rarete (commun, rare, epique, legendaire), en % par
# offre, a quelques manches reperes ; entre deux, on interpole. On ne voit
# d'abord que des communs, et un legendaire reste un evenement en acte 1 (le
# boss en offre deja un a la fin de l'acte). Au plus un legendaire par boutique.
const CHANCES_RARETE := [
	[1, [100.0, 0.0, 0.0, 0.0]],
	[3, [80.0, 20.0, 0.0, 0.0]],
	[6, [64.9, 28.0, 7.0, 0.1]],
	[10, [55.7, 30.0, 14.0, 0.3]],
	[20, [38.0, 33.0, 25.0, 4.0]],
	[30, [25.0, 33.0, 32.0, 10.0]],
]
# Relance : 1 or, +1 a chaque relance payee dans la meme boutique (1, 2, 3...).
const PRIX_RELANCE := 1
# Soldes : chaque offre tiree a cette chance d'etre a moitie prix (arrondi au-dessus).
const SOLDE_CHANCE := 0.10
# Le sac commence sur les 4 colonnes du centre du damier et s'agrandit d'une
# case a la fois, au choix du joueur, collee au sac : en boutique (2 or, puis
# +1 a chaque case achetee) ou gratuitement (boss battu, Croissance).
const COLONNES_DEPART := [2, 3, 4, 5]
const RANGEES_DEPART := [1, 2, 3, 4]
const PRIX_CASE := 2
const CROISSANCE_CASES := 4
const TAILLE_BOUTIQUE := 9   # un carre de 3 x 3 sur le comptoir
# Niveau : l'experience monte d'un point par noeud franchi, sans rien faire.
# XP_NIVEAUX[k] : experience totale pour atteindre le niveau k + 1. Chaque
# niveau gagne donne PV_PAR_NIVEAU a la monture et une case de sac offerte.
const XP_NIVEAUX := [0, 2, 5, 8, 12, 16, 21, 26]
const PV_PAR_NIVEAU := 40.0
# Elites et boss : plus de PV des deux cotes, pour des combats qui durent.
const PV_NOEUD := {"elite": 1.75, "boss": 2.0}

const FERVEUR := 60
# Une defaite coute selon le noeud, plus ce qui reste de vie a l'adversaire (comme TFT).
const PERTE := {"duel": 3, "elite": 6, "boss": 10}
const PERTE_RESTE := 8
const SOIN_FEU := 20
# Elites et boss : un fantome qui a joue quelques manches de plus.
# Les elites ont deja leur regle : pas de manche d'avance.
const AVANCE := {"duel": 1, "elite": 3, "boss": 5}
# Recompense d'une victoire : une relique offerte de cette rarete.
const RECOMPENSE := {"elite": "epique", "boss": "legendaire"}
const CHAUDRON_PV := 15
const PONT_OR := 15
const PONT_PV := 10
const RENCONTRES := ["heaume", "chaudron", "pont"]

var graine := 0
var rng := RandomNumberGenerator.new()
var manche := 1
var bourse := OR_PAR_MANCHE
var victoires := 0
var nid := Nid.new()
var offres: Array = []   # ids, "" pour une offre deja achetee
var gratuite := -1       # index de l'offre offerte, -1 sans
var cases_achetees := 0   # fixe le prix de la prochaine case du sac
var cases_offertes := 0   # cases du sac gratuites, encore a placer
# Offres verrouillees : elles restent aux relances et a la boutique suivante.
var verrous: Array = []
var soldes: Array = []   # offres a moitie prix
var relances := 0        # relances payees dans la boutique en cours
# Reserve : des emplacements hors du sac, sans effet, pour garder des reliques.
const TAILLE_RESERVE := 8
var reserve: Array = []  # par emplacement : {} vide, ou {id, niv}
# Relique delogee par une pose, tenue par le joueur : {id, niv}, {} sinon.
var main := {}

var carte: Carte
var acte := 0
var position := -1       # noeud ou l'on est dans l'acte, -1 avant le premier
var chemin: Array = []   # noeuds deja visites dans l'acte
var ferveur := FERVEUR
var finie := false
var gagnee := false
var victoire_comptee := false   # deja comptee dans la Progression
var message := ""        # resultat du dernier noeud, affiche au Nid
var rencontre := {}      # rencontre en cours : {id, titre, texte, choix, ...}

# Dynasties de la partie : la boutique, les recompenses et le Heaume ne
# tirent que dans celles-ci (jamais d'objet neutre).
var dynasties: Array = []
var cavalier := ""          # choisi a l ecran de depart ; vide : pas de talent
# Erudit : la premiere relance de la boutique en cours est encore gratuite.
var relance_offerte := true

func _init(g := 0, dyn := []) -> void:
	dynasties = dyn.duplicate() if not dyn.is_empty() else Data.dynasties_jouables()
	graine = g if g != 0 else randi()
	rng.seed = graine
	carte = Carte.new(graine)
	nid.ouvertes = Nid.toutes().filter(func(c): return c.x in COLONNES_DEPART and c.y in RANGEES_DEPART)
	nid.encombrement = true
	for k in TAILLE_RESERVE:
		reserve.append({})
	tirer()

# Experience : les noeuds franchis (la manche commence a 1).
func xp() -> int:
	return manche - 1

static func niveau_pour(x: int) -> int:
	var n := 1
	for k in XP_NIVEAUX.size():
		if x >= XP_NIVEAUX[k]:
			n = k + 1
	return n

func niveau() -> int:
	return Partie.niveau_pour(xp())

# Experience qu'il faut au total pour le niveau suivant, -1 au niveau maximum.
func xp_suivant() -> int:
	return XP_NIVEAUX[niveau()] if niveau() < XP_NIVEAUX.size() else -1

# Les PV que le niveau ajoute a une creature.
static func avec_niveau(cr: Dictionary, n: int) -> Dictionary:
	cr["pv_max"] += PV_PAR_NIVEAU * (n - 1)
	cr["niveau"] = n
	return cr

# La manche avance d'un noeud ; chaque niveau gagne offre une case de sac.
# Renvoie le nombre de niveaux gagnes.
func _avancer() -> int:
	var avant := niveau()
	manche += 1
	cases_offertes += niveau() - avant
	return niveau() - avant

static func prix(id: String) -> int:
	return PRIX[Data.RELIQUES[id]["type"]] + BONUS_RARETE[Data.rarete(id)]

func prix_offre(i: int) -> int:
	if i == gratuite:
		return 0
	return ceili(prix(offres[i]) / 2.0) if soldes[i] else prix(offres[i])

static func chances(m: int) -> Array:
	var avant: Array = CHANCES_RARETE[0]
	for palier in CHANCES_RARETE:
		if m <= palier[0]:
			var t: float = 0.0 if palier[0] == avant[0] else float(m - avant[0]) / (palier[0] - avant[0])
			var c := []
			for k in 4:
				c.append(lerpf(avant[1][k], palier[1][k], t))
			return c
		avant = palier
	return avant[1]

# Tire une rarete selon la manche, puis une relique de cette rarete parmi ids.
# Si aucune relique de cette rarete n'est dans ids, on descend d'un cran.
# sans_legendaire : la boutique en a deja un, on tire un epique a la place.
static func tirer_id(r: RandomNumberGenerator, ids: Array, m: int, sans_legendaire := false) -> String:
	var c := chances(m)
	var x := r.randf() * 100.0
	var k := 0
	while k < c.size() - 1 and x >= c[k]:
		x -= c[k]
		k += 1
	# arrondis : jamais une rarete a 0 %
	while k > 0 and c[k] <= 0.0:
		k -= 1
	if sans_legendaire and k == 3:
		k = 2
	while k >= 0:
		var lot := ids.filter(func(id): return Data.rarete(id) == Data.RARETES[k])
		if not lot.is_empty():
			return lot[r.randi() % lot.size()]
		k -= 1
	return ids[r.randi() % ids.size()]

# La revente rend la moitie de ce que la relique a coute (Data.copies_niveau),
# jamais moins d'une piece.
static func prix_revente(id: String, niv := 1) -> int:
	return maxi(1, prix(id) * Data.copies_niveau(niv) / 2)

# Nouvelles offres. Les offres verrouillees et l'offre offerte restent.
func tirer() -> void:
	var ids := pool()
	if offres.size() != TAILLE_BOUTIQUE:
		offres.resize(TAILLE_BOUTIQUE)
		offres.fill("")
		verrous.resize(TAILLE_BOUTIQUE)
		verrous.fill(false)
		soldes.resize(TAILLE_BOUTIQUE)
		soldes.fill(false)
	var garde := []
	for i in TAILLE_BOUTIQUE:
		garde.append(offres[i] != "" and (verrous[i] or i == gratuite))
		if not garde[i]:
			offres[i] = ""
	for i in TAILLE_BOUTIQUE:
		if garde[i]:
			continue
		offres[i] = tirer_id(rng, ids, manche, _a_legendaire())
		verrous[i] = false
		soldes[i] = rng.randf() < SOLDE_CHANCE
	if gratuite >= 0 and offres[gratuite] == "":
		gratuite = -1

func _a_legendaire() -> bool:
	return offres.any(func(id): return id != "" and Data.rarete(id) == "legendaire")

# Reliques que la partie peut tirer : celles des dynasties choisies, sans neutres.
func pool() -> Array:
	return Data.RELIQUES.keys().filter(func(id): return Data.RELIQUES[id]["element"] in dynasties)

func prix_relance() -> int:
	if cavalier == "capuchon" and relance_offerte:
		return 0
	return PRIX_RELANCE + relances

# Le cavalier se choisit une fois, en debut de partie. Croissance : des cases
# de sac offertes, a placer (les suivantes coutent comme si de rien n'etait).
func choisir_cavalier(c: String) -> void:
	cavalier = c
	if c == "pousse":
		cases_offertes += CROISSANCE_CASES

# Le talent du cavalier qui joue en combat, ajoute a la creature eclose.
static func avec_cavalier(cr: Dictionary, c: String) -> Dictionary:
	cr["cavalier"] = c if c != "" else "capuchon"
	if c == "coquille":
		cr["bouclier"] += Data.ECLOSION_BOUCLIER
	cr["embuscade"] = c == "ombre"
	return cr

func creature_joueur() -> Dictionary:
	return _pv_noeud(Partie.avec_niveau(Partie.avec_cavalier(nid.eclore(), cavalier), niveau()))

# PV des deux combattants selon le noeud en cours (elite, boss).
func _pv_noeud(cr: Dictionary) -> Dictionary:
	if position >= 0:
		cr["pv_max"] *= PV_NOEUD.get(noeud()["type"], 1.0)
	return cr

func relancer() -> bool:
	if bourse < prix_relance():
		return false
	var cout := prix_relance()
	bourse -= cout
	if cout > 0:
		relances += 1
	if cavalier == "capuchon":
		relance_offerte = false
	tirer()
	return true

# Verrouiller une offre : elle reste aux relances et a la boutique suivante.
func verrouiller(i: int) -> void:
	if offres[i] != "":
		verrous[i] = not verrous[i]

# On achete en posant : l'offre va dans une case vide du Nid, ou sur une copie
# d'elle-meme si cela complete un trio (fusion, reserve comprise).
func peut_acheter(i: int, c: Vector2i, rot := 0) -> bool:
	var id: String = offres[i]
	if id == "" or bourse < prix_offre(i):
		return false
	var a = nid.ancre(c)
	if a == null:
		return nid.peut_ajouter(c, id, rot)
	return nid.cases[a] == id and nid.niveau(a) == 1 and nid.peut_fusionner(id, 1) \
		and not _copies(id, 1, {"depuis": a}).is_empty()

func acheter(i: int, c: Vector2i, rot := 0) -> bool:
	if not peut_acheter(i, c, rot):
		return false
	var id: String = offres[i]
	var a = nid.ancre(c)
	_prendre({"offre": i})
	if a == null:
		nid.placer(c, id, 1, rot)
		_fusionner({"depuis": c})
	else:
		# l'offre posee sur une copie compte comme la deuxieme du trio
		_fusionner({"depuis": a}, 1)
	return true

# --- fusion : le sac et la reserve comptent ----------------------------------
# Derniere fusion, pour l'animer : {lieu, niv, absorbees : [{lieu, id}]}, ou
# {} une fois montree. Un lieu est une source : {"depuis": ancre} ou {"reserve": k}.
var fusion := {}

# Les autres copies (id, niv) que lieu, en reserve d'abord (sans effet), puis dans le sac.
func _copies(id: String, niv: int, lieu: Dictionary) -> Array:
	var l := []
	for k in reserve.size():
		var r: Dictionary = reserve[k]
		if not r.is_empty() and r["id"] == id and r["niv"] == niv and lieu.get("reserve", -1) != k:
			l.append({"reserve": k})
	for a in nid.copies(id, niv):
		if lieu.get("depuis") != a:
			l.append({"depuis": a})
	return l

# Fusionne en cascade la relique de lieu avec les autres copies de son niveau.
# offertes : copies deja absorbees (une offre lachee sur la relique).
func _fusionner(lieu: Dictionary, offertes := 0) -> void:
	var absorbees := []
	while true:
		var r := relique_de(lieu)
		if r.is_empty() or not nid.peut_fusionner(r["id"], r["niv"]):
			break
		var autres := _copies(r["id"], r["niv"], lieu)
		var besoin: int = Data.FUSION_COPIES[r["niv"]] - 1 - offertes
		if autres.size() < besoin:
			break
		offertes = 0
		for s in autres.slice(0, besoin):
			var cases := nid.cases_de(s["depuis"]) if s.has("depuis") else []
			absorbees.append({"lieu": s, "id": r["id"], "cases": cases})
			_prendre(s)
		if lieu.has("depuis"):
			nid.niveaux[lieu["depuis"]] = r["niv"] + 1
		else:
			reserve[lieu["reserve"]] = {"id": r["id"], "niv": r["niv"] + 1}
	if not absorbees.is_empty():
		fusion = {"lieu": lieu, "niv": relique_de(lieu)["niv"], "absorbees": absorbees}

# Prix de la prochaine case du sac (0 si offerte), -1 quand le damier est entier.
func prix_agrandir() -> int:
	if nid.bordure().is_empty():
		return -1
	return 0 if cases_offertes > 0 else PRIX_CASE + cases_achetees

# Ouvre la case c, qui doit toucher le sac.
func agrandir(c: Vector2i) -> bool:
	var prix := prix_agrandir()
	if prix < 0 or bourse < prix or not c in nid.bordure():
		return false
	if cases_offertes > 0:
		cases_offertes -= 1
	else:
		# un achat ouvre deux cases : la seconde est offerte, a placer
		bourse -= prix
		cases_achetees += 1
		cases_offertes += 1
	nid.ouvertes.append(c)
	if nid.bordure().is_empty():
		cases_offertes = 0
	return true

# Premier emplacement libre de la reserve, -1 s'il n'y en a pas.
func reserve_libre() -> int:
	return reserve.find({})

# --- glisser-deposer : sources et destinations --------------------------------
# Une source est le dictionnaire du glisser : {"offre": i}, {"depuis": ancre du
# sac}, {"reserve": k} ou {"main": true}.

func relique_de(src: Dictionary) -> Dictionary:
	if src.has("offre"):
		return {} if offres[src["offre"]] == "" else {"id": offres[src["offre"]], "niv": 1}
	if src.has("depuis"):
		return {"id": nid.cases[src["depuis"]], "niv": nid.niveau(src["depuis"])} if nid.cases.has(src["depuis"]) else {}
	if src.has("reserve"):
		return reserve[src["reserve"]]
	return main

func _payable(src: Dictionary) -> bool:
	return not src.has("offre") or bourse >= prix_offre(src["offre"])

# Retire la relique de sa source ; une offre se paie.
func _prendre(src: Dictionary) -> void:
	if src.has("offre"):
		var i: int = src["offre"]
		bourse -= prix_offre(i)
		offres[i] = ""
		verrous[i] = false
		soldes[i] = false
		if i == gratuite:
			gratuite = -1
	elif src.has("depuis"):
		nid.retirer(src["depuis"])
	elif src.has("reserve"):
		reserve[src["reserve"]] = {}
	else:
		main = {}

# Poser la relique de src dans le sac, ancre b, tournee de rot. cellule : la
# case visee. Une offre lachee sur une copie qui complete un trio fusionne.
# Sur une autre relique, elle prend sa place et l'autre passe dans la main.
# essai : ne change rien, dit seulement si c'est possible et ou ca tombe.
# Renvoie {ok, cases}.
func poser(src: Dictionary, cellule: Vector2i, b: Vector2i, rot: int, essai := false) -> Dictionary:
	var r := relique_de(src)
	if r.is_empty() or not _payable(src):
		return {"ok": false, "cases": []}
	var copie = nid.ancre(cellule)
	if src.has("offre") and copie != null and nid.cases[copie] == r["id"]:
		var ok := peut_acheter(src["offre"], cellule, rot)
		if ok and not essai:
			acheter(src["offre"], cellule, rot)
		return {"ok": ok, "cases": nid.cases_de(copie)}
	var n := nid.dupliquer()
	if src.has("depuis"):
		n.retirer(src["depuis"])
	var cases := n.empreinte(b, r["id"], rot)
	var occ := n.occupation()
	var autres := {}
	for k in cases:
		if not n.ouverte(k):
			return {"ok": false, "cases": cases}
		if occ.has(k):
			autres[occ[k]] = true
	if autres.size() > 1:
		return {"ok": false, "cases": cases}
	if essai:
		return {"ok": true, "cases": cases}
	_prendre(src)
	if not autres.is_empty():
		var o: Vector2i = autres.keys()[0]
		main = {"id": nid.cases[o], "niv": nid.niveau(o), "rot": nid.rotation(o)}
		nid.retirer(o)
	nid.placer(b, r["id"], r["niv"], rot)
	_fusionner({"depuis": b})
	return {"ok": true, "cases": cases}

# Ranger la relique de src dans l'emplacement k de la reserve. S'il est pris,
# son occupant passe dans la main.
func ranger(src: Dictionary, k: int, essai := false) -> bool:
	if k < 0 or k >= TAILLE_RESERVE or (src.has("reserve") and src["reserve"] == k):
		return false
	var r := relique_de(src)
	if r.is_empty() or not _payable(src):
		return false
	if essai:
		return true
	var occupant: Dictionary = reserve[k]
	var copie := {"id": r["id"], "niv": r["niv"]}
	_prendre(src)
	reserve[k] = copie
	if not occupant.is_empty():
		main = occupant
	_fusionner({"reserve": k})
	return true

# Revendre depuis le sac, la reserve ou la main (pas une offre).
func vendre_source(src: Dictionary) -> bool:
	if src.has("depuis"):
		vendre(src["depuis"])
		return true
	if src.has("offre"):
		return false
	var r := relique_de(src)
	if r.is_empty():
		return false
	bourse += prix_revente(r["id"], r["niv"])
	_prendre(src)
	return true

# La main lachee nulle part : la relique va en reserve, sinon a la premiere
# place libre du sac, sinon elle est revendue.
func poser_main() -> void:
	if main.is_empty():
		return
	var vide := reserve.find({})
	if vide >= 0:
		ranger({"main": true}, vide)
		return
	for rot in [0, 1]:
		for y in Data.NID_H:
			for x in Data.NID_L:
				if nid.dupliquer().placer(Vector2i(x, y), main["id"], 1, rot):
					poser({"main": true}, Vector2i(x, y), Vector2i(x, y), rot)
					return
	vendre_source({"main": true})
	message = "Plus de place : la relique en main est revendue."

# c : n'importe quelle case de la relique.
func vendre(c: Vector2i) -> void:
	var a = nid.ancre(c)
	if a == null:
		return
	bourse += prix_revente(nid.cases[a], nid.niveau(a))
	nid.retirer(a)

# --- carte -----------------------------------------------------------------

func noeuds() -> Array:
	return carte.actes[acte]

func noeud() -> Dictionary:
	return noeuds()[position]

func accessibles() -> Array:
	if finie:
		return []
	return carte.departs(acte) if position == -1 else noeud()["suivants"]

func terminee() -> bool:
	return finie

# Entre dans un noeud accessible. Une rencontre se prepare ici, ses choix
# se jouent avec choisir().
func entrer(i: int) -> bool:
	if not i in accessibles():
		return false
	position = i
	chemin.append(i)
	message = ""
	if noeud()["type"] == "rencontre":
		rencontre = _preparer_rencontre()
	return true

func combat() -> bool:
	return noeud()["type"] in AVANCE

func adversaire_noeud() -> Nid:
	return adversaire(AVANCE[noeud()["type"]])

# L'elite qui garde le noeud i de l'acte (fixe pour la carte).
func elite_de(i: int) -> String:
	var ids := Data.ELITES.keys()
	return ids[(acte * 7 + i * 3 + graine) % ids.size()]

# La creature affrontee au noeud courant : un fantome, et pour une elite, sa
# regle, son nom et son image.
func creature_adverse() -> Dictionary:
	var cr := adversaire_noeud().eclore()
	# le cavalier d'en face change d'un noeud a l'autre
	var cavs := Data.CAVALIERS.keys()
	Partie.avec_cavalier(cr, cavs[(manche + graine) % cavs.size()])
	# le fantome a le niveau de ses manches jouees
	_pv_noeud(Partie.avec_niveau(cr, Partie.niveau_pour(xp() + AVANCE[noeud()["type"]])))
	if noeud()["type"] == "boss" and acte < Data.GARDIEN_ACTE.size():
		var g: String = Data.GARDIEN_ACTE[acte]
		cr["elite"] = g
		cr["elite_force"] = 1.0 + Data.ELITE_PAR_MANCHE * manche
		cr["nom"] = Data.GARDIENS[g]["nom"]
		cr["hybride"] = ""
	elif noeud()["type"] == "elite":
		var e := elite_de(position)
		cr["elite"] = e
		cr["elite_force"] = 1.0 + Data.ELITE_PAR_MANCHE * manche
		cr["nom"] = Data.ELITES[e]["nom"]
		cr["hybride"] = ""
	return cr

# vainqueur : 0 le joueur, 1 l'adversaire, -1 egalite (ne coute rien).
# reste : part de vie (0 a 1) qu'il restait a l'adversaire.
func conclure_combat(vainqueur: int, reste := 0.0) -> void:
	var type: String = noeud()["type"]
	var recompense := ""
	if vainqueur == 0:
		victoires += 1
		recompense = RECOMPENSE.get(type, "")
		message = "Victoire." if recompense == "" else "Victoire : relique %s offerte." % Data.NOMS_RARETE[recompense].to_lower()
	elif vainqueur == 1:
		var perte: int = PERTE[type] + ceili(PERTE_RESTE * clampf(reste, 0.0, 1.0))
		ferveur -= perte
		message = "Défaite : -%d Ferveur." % perte
	else:
		message = "Égalité."
	if type == "boss" and acte == Carte.ACTES - 1:
		finie = true
		gagnee = vainqueur == 0
	elif type == "boss" and vainqueur == 0 and not nid.bordure().is_empty():
		cases_offertes += 1
		message += " Une case de sac offerte."
	_suivant(recompense)

# Feu de camp : rien a choisir.
func conclure() -> void:
	match noeud()["type"]:
		"feu":
			var avant := ferveur
			ferveur = mini(FERVEUR, ferveur + SOIN_FEU)
			message = "Feu de camp : +%d Ferveur." % (ferveur - avant)
			_suivant()

func _suivant(recompense := "", element := "") -> void:
	if ferveur <= 0:
		finie = true
	if noeud()["type"] == "boss" and not finie:
		acte += 1
		position = -1
		chemin.clear()
	if _avancer() > 0 and not finie:
		message += " Niveau %d : +%d PV, une case de sac offerte." % [niveau(), PV_PAR_NIVEAU]
	# feu de camp et rencontre : ni or ni nouvelle boutique, la recompense
	# attend dans la boutique en cours
	if not combat():
		if recompense != "":
			offrir(recompense, element)
			message += " Relique %s offerte dans la boutique du Nid." % Data.NOMS_RARETE[recompense].to_lower()
		return
	nouvelle_boutique()
	if recompense != "":
		offrir(recompense, element)

# Apres un combat : l'or de la manche, des offres neuves (les verrouillees
# restent), la relance remise a son prix de depart.
func nouvelle_boutique() -> void:
	bourse += OR_PAR_MANCHE
	relance_offerte = true
	relances = 0
	tirer()

# Met une relique de cette rarete en premiere offre, gratuite. Element du Nid
# de preference, sinon n'importe lequel.
func offrir(rarete: String, element := "") -> void:
	if element == "":
		element = nid.forme()
	var ids := pool().filter(func(id): return Data.rarete(id) == rarete and (element == "" or Data.RELIQUES[id]["element"] == element))
	if ids.is_empty():
		ids = pool().filter(func(id): return Data.rarete(id) == rarete)
	# la relique offerte prend une place vide, sinon une offre non verrouillee
	var i := offres.find("")
	if i < 0:
		i = maxi(0, verrous.find(false))
	offres[i] = ids[rng.randi() % ids.size()]
	verrous[i] = false
	soldes[i] = false
	gratuite = i

# --- rencontres (hommages) -------------------------------------------------

func _preparer_rencontre() -> Dictionary:
	match RENCONTRES[rng.randi() % RENCONTRES.size()]:
		"heaume":
			var cours := dynasties.duplicate()
			var trois := []
			while trois.size() < mini(3, cours.size()):
				var c: String = cours[rng.randi() % cours.size()]
				if not c in trois:
					trois.append(c)
			return {"id": "heaume", "titre": "Le Heaume qui Juge",
				"texte": "Un vieux heaume posé sur une pierre murmure le nom de trois dynasties.\nLaquelle écouter ? Elle t'offrira une relique rare.",
				"choix": trois.map(func(c): return Data.DYNASTIES[c]), "cours": trois}
		"chaudron":
			return {"id": "chaudron", "titre": "Le Grand Chaudron",
				"texte": "Le chaudron bouillonne. Il offre une relique légendaire,\ncontre un peu de ta vie.",
				"choix": ["Boire (-%d Ferveur, relique légendaire offerte)" % CHAUDRON_PV, "Passer son chemin"]}
		_:
			return {"id": "pont", "titre": "Le Pont des Lames",
				"texte": "Un pont étroit hérissé de lames. De l'autre côté, un coffre.",
				"choix": ["Traverser (une chance sur deux : +%d or, sinon -%d Ferveur)" % [PONT_OR, PONT_PV], "Contourner"]}

func choisir(k: int) -> void:
	var recompense := ""
	var element := ""
	match rencontre["id"]:
		"heaume":
			element = rencontre["cours"][k]
			recompense = "rare"
			message = "Le Heaume a parlé : %s." % Data.DYNASTIES[element]
		"chaudron":
			if k == 0:
				ferveur -= CHAUDRON_PV
				recompense = "legendaire"
				message = "Le Chaudron prend %d de Ferveur." % CHAUDRON_PV
			else:
				message = "Tu laisses le Chaudron bouillonner."
		"pont":
			if k == 1:
				message = "Tu contournes le pont."
			elif rng.randi() % 2 == 0:
				bourse += PONT_OR
				message = "Traversée réussie : +%d or." % PONT_OR
			else:
				ferveur -= PONT_PV
				message = "Les lames te blessent : -%d Ferveur." % PONT_PV
	rencontre = {}
	_suivant(recompense, element)

# --- adversaire ------------------------------------------------------------

# Adversaire fantome en attendant le PvP : un joueur automatique qui a joue
# toutes les manches jusqu'ici, avec ses propres boutiques. Memes regles que
# le joueur : il ne choisit que parmi ses offres, fusionne, relance.
# avance : manches jouees en plus (elites et boss).
# Quelques fantomes tournent a tour de role et avancent d'une manche a la fois :
# les rejouer depuis la premiere manche a chaque combat coutait trop cher sur une run.
const FANTOMES := 4
var fantomes := {}   # "k:avance" -> {partie, joueur, joues}

func adversaire(avance := 0) -> Nid:
	var total := manche + avance
	var cle := "%d:%d" % [manche % FANTOMES, avance]
	var f: Dictionary = fantomes.get(cle, {})
	if f.is_empty() or f["joues"] > total:
		var p := Partie.new(graine + (manche % FANTOMES + 1) * 7919 + avance * 104729, dynasties)
		f = {"partie": p, "joueur": JoueurAuto.new("simple", p.graine), "joues": 0}
		fantomes[cle] = f
	var fantome: Partie = f["partie"]
	while f["joues"] < total:
		if f["joues"] > 0:
			fantome._avancer()
			# une manche sur trois est un feu de camp ou une rencontre (environ un
			# tiers des noeuds de la carte) : ni or ni boutique, comme le joueur
			if f["joues"] % 3 != 0:
				fantome.nouvelle_boutique()
		f["joueur"].jouer_manche(fantome)
		f["joues"] += 1
	return fantome.nid
