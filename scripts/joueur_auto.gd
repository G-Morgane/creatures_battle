class_name JoueurAuto
extends RefCounted

# Joueurs automatiques : simulation de parties (tests/simulation.gd) et
# adversaire fantome (Partie.adversaire).
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
	while p.cases_offertes > 0 and p.agrandir(JoueurAuto.case_agrandir(p)):
		pass
	if style == "aleatoire":
		_aleatoire(p)
	else:
		_simple(p)

func _aleatoire(p: Partie) -> void:
	for i in p.offres.size():
		var ok := _cases_ok(p, p.offres[i])
		if not ok.is_empty():
			var pose: Array = ok[rng.randi() % ok.size()]
			p.acheter(i, pose[0], pose[1])

func _simple(p: Partie) -> void:
	if element == "":
		element = _choisir_element(p)
	# sac plein : on l'agrandit si l'on peut, avant d'acheter
	if p.nid.occupation().size() >= p.nid.places() - 1 and p.prix_agrandir() >= 0 and p.bourse >= p.prix_agrandir() + 3:
		p.agrandir(JoueurAuto.case_agrandir(p))
		# l'achat ouvre deux cases : la seconde, offerte
		while p.cases_offertes > 0 and p.agrandir(JoueurAuto.case_agrandir(p)):
			pass
	# Achete tout ce qui sert, puis relance tant qu'il reste de quoi acheter.
	for relances in RELANCES_MAX + 1:
		for i in _ordre(p):
			var pose = _case_pour(p, p.offres[i])
			if pose != null:
				p.acheter(i, pose[0], pose[1])
		if relances == RELANCES_MAX or p.bourse < 3 + p.prix_relance():
			return
		p.relancer()

# Sur la carte : un feu de camp quand la vie baisse, sinon au hasard.
func choisir_noeud(p: Partie) -> int:
	var acc := p.accessibles()
	if p.ferveur < Partie.FERVEUR / 2:
		for i in acc:
			if p.noeuds()[i]["type"] == "feu":
				return i
	return acc[rng.randi() % acc.size()]

# Rencontres : sa propre dynastie au Heaume, et pas de risque quand la vie baisse.
func choisir_rencontre(p: Partie) -> int:
	match p.rencontre["id"]:
		"heaume":
			return maxi(0, p.rencontre["cours"].find(element))
		"chaudron":
			return 0 if p.ferveur > 2 * Partie.CHAUDRON_PV else 1
		_:
			return 0 if p.ferveur > 2 * Partie.PONT_PV else 1

# L'element le plus present dans la premiere boutique.
func _choisir_element(p: Partie) -> String:
	var compte := {}
	for e in p.dynasties:
		compte[e] = 0
	for id in p.offres:
		if id != "" and Data.RELIQUES[id]["element"] in compte:
			compte[Data.RELIQUES[id]["element"]] += 1
	var meilleur: String = p.dynasties[0]
	for e in compte:
		if compte[e] > compte[meilleur]:
			meilleur = e
	return meilleur

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
	var ok := _cases_ok(p, id)
	if ok.is_empty():
		return null
	if Data.RELIQUES[id]["type"] == "catalyseur":
		for pose in ok:
			for v in p.nid.voisins(pose[0]):
				if Data.RELIQUES[p.nid.cases[v]]["type"] in ["sort", "arme"]:
					return pose
	return ok[0]

# Poses [ancre, rotation] ou l'on peut mettre id : cases libres (droit ou
# couche), ou copie qui complete un trio.
func _cases_ok(p: Partie, id: String) -> Array:
	var l := []
	if id == "":
		return l
	for rot in [0, 1]:
		for y in Data.NID_H:
			for x in Data.NID_L:
				if p.nid.peut_ajouter(Vector2i(x, y), id, rot):
					l.append([Vector2i(x, y), rot])
	return l

# Case du sac a ouvrir : celle qui touche le plus de cases ouvertes, pour
# garder le sac compact.
static func case_agrandir(p: Partie) -> Vector2i:
	var meilleure := Vector2i(-1, -1)
	var score := -1
	for c in p.nid.bordure():
		var n := 0
		for d in Nid.VOISINAGE:
			if p.nid.ouverte(c + d):
				n += 1
		if n > score:
			meilleure = c
			score = n
	return meilleure
