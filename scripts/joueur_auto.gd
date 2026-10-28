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
	if style == "aleatoire":
		_aleatoire(p)
	else:
		_simple(p)

func _aleatoire(p: Partie) -> void:
	for i in p.offres.size():
		var ok := _cases_ok(p, p.offres[i])
		if not ok.is_empty():
			p.acheter(i, ok[rng.randi() % ok.size()])

func _simple(p: Partie) -> void:
	if element == "":
		element = _choisir_element(p)
	# Achete tout ce qui sert, puis relance tant qu'il reste de quoi acheter.
	for relances in RELANCES_MAX + 1:
		for i in _ordre(p):
			var c = _case_pour(p, p.offres[i])
			if c != null:
				p.acheter(i, c)
		if relances == RELANCES_MAX or p.bourse < 3 + p.prix_relance():
			return
		p.relancer()

# Sur la carte : un feu de camp quand la vie baisse, sinon au hasard.
func choisir_noeud(p: Partie) -> int:
	var acc := p.accessibles()
	if p.pv_run < Partie.PV_RUN / 2:
		for i in acc:
			if p.noeuds()[i]["type"] == "feu":
				return i
	return acc[rng.randi() % acc.size()]

# Rencontres : sa propre Cour au Heaume, et pas de risque quand la vie baisse.
func choisir_rencontre(p: Partie) -> int:
	match p.rencontre["id"]:
		"heaume":
			return maxi(0, p.rencontre["cours"].find(element))
		"chaudron":
			return 0 if p.pv_run > 2 * Partie.CHAUDRON_PV else 1
		_:
			return 0 if p.pv_run > 2 * Partie.PONT_PV else 1

# L'element le plus present dans la premiere boutique.
func _choisir_element(p: Partie) -> String:
	var compte := {"feu": 0, "nuit": 0, "terre": 0, "vent": 0, "nature": 0, "glace": 0, "aube": 0, "crepuscule": 0}
	for id in p.offres:
		if id != "" and Data.RELIQUES[id]["element"] in compte:
			compte[Data.RELIQUES[id]["element"]] += 1
	var meilleur := "feu"
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
		for c in ok:
			for v in p.nid.voisins(c):
				if Data.RELIQUES[p.nid.cases[v]]["type"] in ["sort", "arme"]:
					return c
	return ok[0]

# Cases ou l'on peut poser id : vides, ou copie qui complete un trio.
func _cases_ok(p: Partie, id: String) -> Array:
	var l := []
	if id == "":
		return l
	for y in Data.NID_H:
		for x in Data.NID_L:
			if p.nid.peut_ajouter(Vector2i(x, y), id):
				l.append(Vector2i(x, y))
	return l
