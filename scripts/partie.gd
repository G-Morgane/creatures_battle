class_name Partie
extends RefCounted

# Une partie : manches successives, bourse, boutique, Nid du joueur.
# Le hasard passe par une graine : meme graine, meme boutique, meme adversaires.

const OR_PAR_MANCHE := 10
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
	return PRIX[Data.RELIQUES[id]["type"]] + BONUS_RARETE[Data.rarete(id)]

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

func tirer() -> void:
	var ids := Data.RELIQUES.keys()
	offres.clear()
	for i in TAILLE_BOUTIQUE:
		offres.append(tirer_id(rng, ids, manche))

func relancer() -> bool:
	if bourse < PRIX_RELANCE:
		return false
	bourse -= PRIX_RELANCE
	tirer()
	return true

# On achete en posant : l'offre va dans une case vide du Nid, ou sur une copie
# d'elle-meme si cela complete un trio (fusion).
func peut_acheter(i: int, c: Vector2i) -> bool:
	var id: String = offres[i]
	return id != "" and bourse >= prix(id) and nid.peut_ajouter(c, id)

func acheter(i: int, c: Vector2i) -> bool:
	if not peut_acheter(i, c):
		return false
	var id: String = offres[i]
	nid.ajouter(c, id)
	bourse -= prix(id)
	offres[i] = ""
	return true

func vendre(c: Vector2i) -> void:
	if not nid.cases.has(c):
		return
	bourse += prix_revente(nid.cases[c], nid.niveau(c))
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

# Comme en PvP, on affronte des joueurs au meme palmares : chaque victoire
# peut donner de l'or en plus a l'adversaire. A 0 : avec la fusion, tout bonus
# rendait la partie trop dure (voir tests/simulation.gd).
const OR_PAR_VICTOIRE := 0

# Adversaire fantome en attendant le PvP : un joueur automatique qui a joue
# toutes les manches jusqu'ici, avec ses propres boutiques. Memes regles que
# le joueur : il ne choisit que parmi ses offres, fusionne, relance.
func adversaire() -> Nid:
	var fantome := Partie.new(graine + manche * 7919)
	fantome.bourse += OR_PAR_VICTOIRE * victoires
	var j := JoueurAuto.new("simple", fantome.graine)
	for m in manche:
		j.jouer_manche(fantome)
		if m < manche - 1:
			fantome.manche += 1
			fantome.bourse += OR_PAR_MANCHE
			fantome.tirer()
	return fantome.nid
