class_name Carte
extends RefCounted

# Carte d'une run, comme dans Slay the Spire : trois actes, chacun une suite
# d'etages relies par des chemins qui se croisent, un boss au dernier etage.
# Tout vient de la graine : meme graine, meme carte.

const ACTES := 3
const ETAGES := 10        # par acte, boss compris
const COLONNES := 4
const CHEMINS := 4
# Tirage des types hors premier etage, feu avant le boss et boss.
const POIDS := {"duel": 50, "rencontre": 22, "elite": 12, "marche": 8, "feu": 8}
# Pas d'elite trop tot dans le premier acte, pas de repos dans les premiers etages.
const ELITE_DES := 4
const FEU_DES := 4

# Par acte : liste de noeuds {etage, col, type, suivants: [index]}.
var actes: Array = []

func _init(graine: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = graine
	for a in ACTES:
		actes.append(_generer(rng, a))

func _generer(rng: RandomNumberGenerator, acte: int) -> Array:
	var noeuds := []
	var index := {}   # Vector2i(etage, col) -> index
	for k in CHEMINS:
		# les deux premiers chemins partent de colonnes differentes
		var col := (k * 2 + rng.randi() % 2) % COLONNES if k < 2 else rng.randi() % COLONNES
		var prec := -1
		for e in ETAGES - 1:
			if e > 0:
				var essai := clampi(col + rng.randi_range(-1, 1), 0, COLONNES - 1)
				# on refuse un pas qui croiserait un lien deja trace
				var croise: bool = index.has(Vector2i(e - 1, essai)) and index.has(Vector2i(e, col)) \
					and index[Vector2i(e, col)] in noeuds[index[Vector2i(e - 1, essai)]]["suivants"]
				if not croise:
					col = essai
			var cle := Vector2i(e, col)
			if not index.has(cle):
				index[cle] = noeuds.size()
				noeuds.append({"etage": e, "col": float(col), "type": "", "suivants": []})
			var i: int = index[cle]
			if prec >= 0 and not i in noeuds[prec]["suivants"]:
				noeuds[prec]["suivants"].append(i)
			prec = i
	var boss := noeuds.size()
	noeuds.append({"etage": ETAGES - 1, "col": (COLONNES - 1) / 2.0, "type": "boss", "suivants": []})
	for n in noeuds:
		n["suivants"].sort()
		if n["etage"] == ETAGES - 2:
			n["suivants"] = [boss]
	for n in noeuds:
		if n["type"] == "":
			n["type"] = _type(rng, acte, n["etage"])
	return noeuds

func _type(rng: RandomNumberGenerator, acte: int, etage: int) -> String:
	if etage == 0:
		return "duel"
	if etage == ETAGES - 2:
		return "feu"
	var poids := POIDS.duplicate()
	if acte == 0 and etage < ELITE_DES:
		poids.erase("elite")
	if etage < FEU_DES:
		poids.erase("feu")
	var total := 0
	for t in poids:
		total += poids[t]
	var x := rng.randi() % total
	for t in poids:
		if x < poids[t]:
			return t
		x -= poids[t]
	return "duel"

# Noeuds du premier etage d'un acte : les points de depart.
func departs(acte: int) -> Array:
	var l := []
	for i in actes[acte].size():
		if actes[acte][i]["etage"] == 0:
			l.append(i)
	return l
