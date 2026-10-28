class_name Partie
extends RefCounted

# Une run : carte de trois actes, PV de run, bourse, boutique, Nid du joueur.
# Apres chaque noeud la boutique est ouverte, sans obligation d'acheter.
# Le hasard passe par une graine : meme graine, meme carte, memes boutiques,
# memes adversaires.

const OR_PAR_MANCHE := 10   # une manche = un noeud franchi
const PRIX := {"essence": 3, "sort": 4, "catalyseur": 4, "arme": 5}
const BONUS_RARETE := {"commun": 0, "rare": 2, "epique": 4, "legendaire": 7}
# Chances de tirage par rarete (commun, rare, epique, legendaire) a partir
# d'une manche donnee : on ne voit d'abord que des communs.
const CHANCES_RARETE := [
	[1, [100, 0, 0, 0]],
	[2, [75, 25, 0, 0]],
	[4, [55, 30, 15, 0]],
	[6, [40, 30, 20, 10]],
]
const PRIX_RELANCE := 1
# Le sac commence sur les 4 colonnes du centre du damier et s'agrandit d'une
# colonne a la fois, en alternant les cotes : en boutique (prix croissant, comme
# l'experience de TFT) ou gratuitement apres un boss battu.
const COLONNES_DEPART := [2, 3, 4, 5]
const ORDRE_AGRANDIR := [1, 6, 0, 7]
const PRIX_AGRANDIR := [8, 12, 16, 20]
const TAILLE_BOUTIQUE := 5

const PV_RUN := 60
# Une defaite coute selon le noeud, plus ce qui reste de vie a l'adversaire (comme TFT).
const PERTE := {"duel": 3, "elite": 6, "boss": 10}
const PERTE_RESTE := 8
const SOIN_FEU := 20
# Elites et boss : un fantome qui a joue quelques manches de plus.
# Les elites ont deja leur regle : pas de manche d'avance.
const AVANCE := {"duel": 0, "elite": 0, "boss": 4}
# Marche : raretes en avance et relances gratuites jusqu'au noeud suivant.
const AVANCE_MARCHE := 3
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
var marche := false
# Boutique gelee : ses offres restent au noeud suivant (les achetees restent vides).
# Une relance la degele.
var gelee := false
# Reserve : des emplacements hors du sac, sans effet, pour garder des reliques.
const TAILLE_RESERVE := 8
var reserve: Array = []  # par emplacement : {} vide, ou {id, niv}
# Relique delogee par une pose, tenue par le joueur : {id, niv}, {} sinon.
var main := {}

var carte: Carte
var acte := 0
var position := -1       # noeud ou l'on est dans l'acte, -1 avant le premier
var chemin: Array = []   # noeuds deja visites dans l'acte
var pv_run := PV_RUN
var finie := false
var gagnee := false
var message := ""        # resultat du dernier noeud, affiche au Nid
var rencontre := {}      # rencontre en cours : {id, titre, texte, choix, ...}

# Dynasties de la partie : la boutique, les recompenses et le Heaume ne
# tirent que dans celles-ci (et les objets neutres).
var dynasties: Array = []

func _init(g := 0, dyn := []) -> void:
	dynasties = dyn.duplicate() if not dyn.is_empty() else Data.dynasties_jouables()
	graine = g if g != 0 else randi()
	rng.seed = graine
	carte = Carte.new(graine)
	nid.colonnes = COLONNES_DEPART.duplicate()
	nid.encombrement = true
	for k in TAILLE_RESERVE:
		reserve.append({})
	tirer()

static func prix(id: String) -> int:
	return PRIX[Data.RELIQUES[id]["type"]] + BONUS_RARETE[Data.rarete(id)]

func prix_offre(i: int) -> int:
	return 0 if i == gratuite else prix(offres[i])

static func chances(m: int) -> Array:
	var c: Array = CHANCES_RARETE[0][1]
	for palier in CHANCES_RARETE:
		if m >= palier[0]:
			c = palier[1]
	return c

# Tire une rarete selon la manche, puis une relique de cette rarete parmi ids.
# Si aucune relique de cette rarete n'est dans ids, on descend d'un cran.
static func tirer_id(r: RandomNumberGenerator, ids: Array, m: int) -> String:
	var c := chances(m)
	var x := r.randi() % 100
	var k := 0
	while k < c.size() - 1 and x >= c[k]:
		x -= c[k]
		k += 1
	while k >= 0:
		var lot := ids.filter(func(id): return Data.rarete(id) == Data.RARETES[k])
		if not lot.is_empty():
			return lot[r.randi() % lot.size()]
		k -= 1
	return ids[r.randi() % ids.size()]

# La revente rend la moitie de ce que la relique a coute (3 copies par niveau),
# jamais moins d'une piece.
static func prix_revente(id: String, niv := 1) -> int:
	return maxi(1, prix(id) * int(pow(3, niv - 1)) / 2)

# L'offre offerte survit aux relances.
func tirer() -> void:
	var garde: String = offres[gratuite] if gratuite >= 0 and gratuite < offres.size() else ""
	var ids := pool()
	offres.clear()
	for i in TAILLE_BOUTIQUE:
		offres.append(tirer_id(rng, ids, manche + (AVANCE_MARCHE if marche else 0)))
	if garde != "":
		offres[gratuite] = garde
	else:
		gratuite = -1

# Reliques que la partie peut tirer : celles des dynasties choisies, et les neutres.
func pool() -> Array:
	return Data.RELIQUES.keys().filter(func(id): return Data.RELIQUES[id]["element"] in dynasties or Data.RELIQUES[id]["element"] == "")

func prix_relance() -> int:
	return 0 if marche else PRIX_RELANCE

func relancer() -> bool:
	if bourse < prix_relance():
		return false
	bourse -= prix_relance()
	gelee = false
	tirer()
	return true

func geler() -> void:
	gelee = not gelee

# On achete en posant : l'offre va dans une case vide du Nid, ou sur une copie
# d'elle-meme si cela complete un trio (fusion).
func peut_acheter(i: int, c: Vector2i, rot := 0) -> bool:
	var id: String = offres[i]
	return id != "" and bourse >= prix_offre(i) and nid.peut_ajouter(c, id, rot)

func acheter(i: int, c: Vector2i, rot := 0) -> bool:
	if not peut_acheter(i, c, rot):
		return false
	var id: String = offres[i]
	nid.ajouter(c, id, rot)
	bourse -= prix_offre(i)
	offres[i] = ""
	if i == gratuite:
		gratuite = -1
	return true

# Prix de la prochaine colonne, -1 quand le damier est entier.
func prix_agrandir() -> int:
	var n := nid.colonnes.size() - COLONNES_DEPART.size()
	return PRIX_AGRANDIR[n] if n < PRIX_AGRANDIR.size() else -1

func agrandir(gratuit := false) -> bool:
	var prix := prix_agrandir()
	if prix < 0 or (not gratuit and bourse < prix):
		return false
	if not gratuit:
		bourse -= prix
	nid.colonnes.append(ORDRE_AGRANDIR[nid.colonnes.size() - COLONNES_DEPART.size()])
	return true

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
		var ok := nid.peut_ajouter(cellule, r["id"], rot)
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
	nid.fusionner(b)
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
	if noeud()["type"] == "elite":
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
		pv_run -= perte
		message = "Défaite : -%d PV de run." % perte
	else:
		message = "Égalité."
	if type == "boss" and acte == Carte.ACTES - 1:
		finie = true
		gagnee = vainqueur == 0
	elif type == "boss" and vainqueur == 0 and agrandir(true):
		message += " Le sac s'agrandit."
	_suivant(recompense)

# Feu de camp et marche : rien a choisir.
func conclure() -> void:
	match noeud()["type"]:
		"feu":
			var avant := pv_run
			pv_run = mini(PV_RUN, pv_run + SOIN_FEU)
			message = "Feu de camp : +%d PV de run." % (pv_run - avant)
			_suivant()
		"marche":
			_suivant()
			marche = true
			if not gelee:
				tirer()
			else:
				_completer()
			message = "Marché : raretés en avance, relances gratuites."

func _suivant(recompense := "", element := "") -> void:
	if pv_run <= 0:
		finie = true
	if noeud()["type"] == "boss" and not finie:
		acte += 1
		position = -1
		chemin.clear()
	manche += 1
	bourse += OR_PAR_MANCHE
	marche = false
	if not gelee:
		tirer()
	if recompense != "":
		offrir(recompense, element)
	if gelee:
		_completer()

# Boutique gelee : les offres gardees restent, les places vides (achetees) se
# remplissent.
func _completer() -> void:
	var ids := pool()
	for i in offres.size():
		if offres[i] == "":
			offres[i] = tirer_id(rng, ids, manche + (AVANCE_MARCHE if marche else 0))

# Met une relique de cette rarete en premiere offre, gratuite. Element du Nid
# de preference, sinon n'importe lequel.
func offrir(rarete: String, element := "") -> void:
	if element == "":
		element = nid.forme()
	var ids := pool().filter(func(id): return Data.rarete(id) == rarete and (element == "" or Data.RELIQUES[id]["element"] == element))
	if ids.is_empty():
		ids = pool().filter(func(id): return Data.rarete(id) == rarete)
	# boutique gelee : la relique offerte prend une place vide si possible
	var i := maxi(0, offres.find(""))
	offres[i] = ids[rng.randi() % ids.size()]
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
				"choix": ["Boire (-%d PV de run, relique légendaire offerte)" % CHAUDRON_PV, "Passer son chemin"]}
		_:
			return {"id": "pont", "titre": "Le Pont des Lames",
				"texte": "Un pont étroit hérissé de lames. De l'autre côté, un coffre.",
				"choix": ["Traverser (une chance sur deux : +%d or, sinon -%d PV de run)" % [PONT_OR, PONT_PV], "Contourner"]}

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
				pv_run -= CHAUDRON_PV
				recompense = "legendaire"
				message = "Le Chaudron prend %d PV de run." % CHAUDRON_PV
			else:
				message = "Tu laisses le Chaudron bouillonner."
		"pont":
			if k == 1:
				message = "Tu contournes le pont."
			elif rng.randi() % 2 == 0:
				bourse += PONT_OR
				message = "Traversée réussie : +%d or." % PONT_OR
			else:
				pv_run -= PONT_PV
				message = "Les lames te blessent : -%d PV de run." % PONT_PV
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
			fantome.manche += 1
			fantome.bourse += OR_PAR_MANCHE
			fantome.tirer()
		f["joueur"].jouer_manche(fantome)
		f["joues"] += 1
	return fantome.nid
