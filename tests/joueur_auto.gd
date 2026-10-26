class_name JoueurAuto
extends RefCounted

# Joueurs automatiques pour simuler des parties entieres.
#  simple    : choisit un element, achete dedans, pose les catalyseurs a cote
#              des sorts, relance quand rien ne lui sert. Un joueur moyen.
#  aleatoire : achete n'importe quoi d'abordable, le pose n'importe ou. Le plancher.

const RELANCES_MAX := 3

var style := "simple"
var rng := RandomNumberGenerator.new()
var element := ""

func _init(s: String, graine: int) -> void:
	style = s
	rng.seed = graine

func jouer_manche(p: Partie) -> void:
	if style == "aleatoire":
		_aleatoire(p)
	else:
		_simple(p)

func _aleatoire(p: Partie) -> void:
	for i in p.offres.size():
		var libres := _libres(p)
		if libres.is_empty():
			return
		var c: Vector2i = libres[rng.randi() % libres.size()]
		p.acheter(i, c)

func _simple(p: Partie) -> void:
	if element == "":
		element = _choisir_element(p)
	# Achete tout ce qui sert, puis relance tant qu'il reste de quoi acheter.
	for relances in RELANCES_MAX + 1:
		for i in _ordre(p):
			var c = _case_pour(p, p.offres[i])
			if c != null:
				p.acheter(i, c)
		if relances == RELANCES_MAX or _libres(p).is_empty() or p.bourse < 3 + Partie.PRIX_RELANCE:
			return
		p.relancer()

# L'element le plus present dans la premiere boutique.
func _choisir_element(p: Partie) -> String:
	var compte := {"feu": 0, "nuit": 0}
	for id in p.offres:
		if id != "" and Data.RELIQUES[id]["element"] in compte:
			compte[Data.RELIQUES[id]["element"]] += 1
	return "feu" if compte["feu"] >= compte["nuit"] else "nuit"

func _utile(id: String) -> bool:
	return id != "" and Data.RELIQUES[id]["element"] in [element, ""]

# Arme d'abord, puis sorts, essences, catalyseurs (qui veulent un sort deja pose).
func _ordre(p: Partie) -> Array:
	var rang := {"arme": 0, "sort": 1, "essence": 2, "catalyseur": 3}
	var idx := []
	for i in p.offres.size():
		if _utile(p.offres[i]):
			idx.append(i)
	idx.sort_custom(func(a, b): return rang[Data.RELIQUES[p.offres[a]]["type"]] < rang[Data.RELIQUES[p.offres[b]]["type"]])
	return idx

func _case_pour(p: Partie, id: String):
	if id == "":
		return null
	var libres := _libres(p)
	if libres.is_empty():
		return null
	if Data.RELIQUES[id]["type"] == "catalyseur":
		for c in libres:
			for v in p.nid.voisins(c):
				if Data.RELIQUES[p.nid.cases[v]]["type"] in ["sort", "arme"]:
					return c
	return libres[0]

func _libres(p: Partie) -> Array:
	var l := []
	for y in Data.NID_H:
		for x in Data.NID_L:
			if not p.nid.cases.has(Vector2i(x, y)):
				l.append(Vector2i(x, y))
	return l
