class_name Partie
extends RefCounted

# Une partie : manches successives, bourse, boutique, Nid du joueur.
# Le hasard passe par une graine : meme graine, meme boutique, meme adversaires.

const OR_PAR_MANCHE := 10
const PRIX := {"essence": 3, "sort": 4, "catalyseur": 4, "arme": 5}
const PRIX_RELANCE := 1
const TAILLE_BOUTIQUE := 5
const VICTOIRES_MAX := 7
const DEFAITES_MAX := 3

var graine := 0
var rng := RandomNumberGenerator.new()
var manche := 1
var bourse := OR_PAR_MANCHE
var victoires := 0
var defaites := 0
var nid := Nid.new()
var offres: Array = []   # ids, "" pour une offre deja achetee

func _init(g := 0) -> void:
	graine = g if g != 0 else randi()
	rng.seed = graine
	tirer()

static func prix(id: String) -> int:
	return PRIX[Data.RELIQUES[id]["type"]]

# La revente rend la moitie, jamais moins d'une piece.
static func prix_revente(id: String) -> int:
	return maxi(1, prix(id) / 2)

func tirer() -> void:
	var ids := Data.RELIQUES.keys()
	offres.clear()
	for i in TAILLE_BOUTIQUE:
		offres.append(ids[rng.randi() % ids.size()])

func relancer() -> bool:
	if bourse < PRIX_RELANCE:
		return false
	bourse -= PRIX_RELANCE
	tirer()
	return true

# On achete en posant : l'offre va directement dans une case vide du Nid.
func peut_acheter(i: int, c: Vector2i) -> bool:
	var id: String = offres[i]
	return id != "" and bourse >= prix(id) and not nid.cases.has(c) and nid.accepte(c, id, null)

func acheter(i: int, c: Vector2i) -> bool:
	if not peut_acheter(i, c):
		return false
	var id: String = offres[i]
	nid.placer(c, id)
	bourse -= prix(id)
	offres[i] = ""
	return true

func vendre(c: Vector2i) -> void:
	if not nid.cases.has(c):
		return
	bourse += prix_revente(nid.cases[c])
	nid.retirer(c)

# vainqueur : 0 le joueur, 1 l'adversaire, -1 egalite (ne compte pas).
func enregistrer(vainqueur: int) -> void:
	if vainqueur == 0:
		victoires += 1
	elif vainqueur == 1:
		defaites += 1
	manche += 1
	bourse += OR_PAR_MANCHE
	tirer()

func terminee() -> bool:
	return victoires >= VICTOIRES_MAX or defaites >= DEFAITES_MAX

# Adversaire fantome en attendant le PvP : un Nid tire au hasard avec tout l'or
# qu'un joueur aurait recu jusqu'ici, centre sur un element.
# Le Nid plafonne a 16 cases : passe la manche 6, l'or ne compte plus, seule la
# composition compte. L'adversaire joue donc de mieux en mieux (soin : 0 -> 1) :
# arme d'abord, pas plus de COPIES_MAX d'une meme relique, catalyseurs a cote d'un sort.
const SOIN_MANCHES := 6.0
const COPIES_MAX := 3
# Comme en PvP, on affronte des joueurs au meme palmares : chaque victoire
# donne de l'or en plus a l'adversaire.
const OR_PAR_VICTOIRE := 3

func adversaire() -> Nid:
	var r := RandomNumberGenerator.new()
	r.seed = graine + manche * 7919
	var soin := clampf((manche - 1) / SOIN_MANCHES, 0.0, 1.0)
	var elements := ["feu", "nuit"]
	var element: String = elements[r.randi() % elements.size()]
	var budget := OR_PAR_MANCHE * manche + OR_PAR_VICTOIRE * victoires
	var n := Nid.new()
	var ids := Data.RELIQUES.keys().filter(func(id): return Data.RELIQUES[id]["element"] in [element, ""])
	var libres := []
	for y in Data.NID_H:
		for x in Data.NID_L:
			libres.append(Vector2i(x, y))
	while not libres.is_empty():
		var possibles := ids.filter(func(id): return prix(id) <= budget and (Data.RELIQUES[id]["type"] != "arme" or n.arme() == null))
		if possibles.is_empty():
			break
		var soigne := r.randf() < soin
		if soigne:
			var armes := possibles.filter(func(id): return Data.RELIQUES[id]["type"] == "arme")
			var varies := possibles.filter(func(id): return n.cases.values().count(id) < COPIES_MAX)
			if not armes.is_empty():
				possibles = armes
			elif not varies.is_empty():
				possibles = varies
		var id: String = possibles[r.randi() % possibles.size()]
		var c: Vector2i = libres[r.randi() % libres.size()]
		if soigne and Data.RELIQUES[id]["type"] == "catalyseur":
			for l in libres:
				if n.voisins(l).any(func(v): return Data.RELIQUES[n.cases[v]]["type"] in ["sort", "arme"]):
					c = l
					break
		libres.erase(c)
		n.placer(c, id)
		budget -= prix(id)
	return n
