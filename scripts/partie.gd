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
const TAILLE_BOUTIQUE := 5

const PV_RUN := 60
# Une defaite coute selon le noeud, plus ce qui reste de vie a l'adversaire (comme TFT).
const PERTE := {"duel": 3, "elite": 6, "boss": 10}
const PERTE_RESTE := 8
const SOIN_FEU := 20
# Elites et boss : un fantome qui a joue quelques manches de plus.
const AVANCE := {"duel": 0, "elite": 2, "boss": 4}
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

var carte: Carte
var acte := 0
var position := -1       # noeud ou l'on est dans l'acte, -1 avant le premier
var chemin: Array = []   # noeuds deja visites dans l'acte
var pv_run := PV_RUN
var finie := false
var gagnee := false
var message := ""        # resultat du dernier noeud, affiche au Nid
var rencontre := {}      # rencontre en cours : {id, titre, texte, choix, ...}

func _init(g := 0) -> void:
	graine = g if g != 0 else randi()
	rng.seed = graine
	carte = Carte.new(graine)
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
	var ids := Data.RELIQUES.keys()
	offres.clear()
	for i in TAILLE_BOUTIQUE:
		offres.append(tirer_id(rng, ids, manche + (AVANCE_MARCHE if marche else 0)))
	if garde != "":
		offres[gratuite] = garde
	else:
		gratuite = -1

func prix_relance() -> int:
	return 0 if marche else PRIX_RELANCE

func relancer() -> bool:
	if bourse < prix_relance():
		return false
	bourse -= prix_relance()
	tirer()
	return true

# On achete en posant : l'offre va dans une case vide du Nid, ou sur une copie
# d'elle-meme si cela complete un trio (fusion).
func peut_acheter(i: int, c: Vector2i) -> bool:
	var id: String = offres[i]
	return id != "" and bourse >= prix_offre(i) and nid.peut_ajouter(c, id)

func acheter(i: int, c: Vector2i) -> bool:
	if not peut_acheter(i, c):
		return false
	var id: String = offres[i]
	nid.ajouter(c, id)
	bourse -= prix_offre(i)
	offres[i] = ""
	if i == gratuite:
		gratuite = -1
	return true

func vendre(c: Vector2i) -> void:
	if not nid.cases.has(c):
		return
	bourse += prix_revente(nid.cases[c], nid.niveau(c))
	nid.retirer(c)

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
			tirer()
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
	tirer()
	if recompense != "":
		offrir(recompense, element)

# Met une relique de cette rarete en premiere offre, gratuite. Element du Nid
# de preference, sinon n'importe lequel.
func offrir(rarete: String, element := "") -> void:
	if element == "":
		element = nid.forme()
	var ids := Data.RELIQUES.keys().filter(func(id): return Data.rarete(id) == rarete and (element == "" or Data.RELIQUES[id]["element"] == element))
	if ids.is_empty():
		ids = Data.RELIQUES.keys().filter(func(id): return Data.rarete(id) == rarete)
	offres[0] = ids[rng.randi() % ids.size()]
	gratuite = 0

# --- rencontres (hommages) -------------------------------------------------

func _preparer_rencontre() -> Dictionary:
	match RENCONTRES[rng.randi() % RENCONTRES.size()]:
		"heaume":
			var cours := Data.COURS.keys()
			var trois := []
			while trois.size() < 3:
				var c: String = cours[rng.randi() % cours.size()]
				if not c in trois:
					trois.append(c)
			return {"id": "heaume", "titre": "Le Heaume qui Juge",
				"texte": "Un vieux heaume posé sur une pierre murmure le nom de trois Cours.\nLaquelle écouter ? Elle t'offrira une relique rare.",
				"choix": trois.map(func(c): return Data.COURS[c]), "cours": trois}
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
			message = "Le Heaume a parlé : %s." % Data.COURS[element]
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
		var p := Partie.new(graine + (manche % FANTOMES + 1) * 7919 + avance * 104729)
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
