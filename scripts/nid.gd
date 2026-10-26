class_name Nid
extends RefCounted

# Grille de reliques. Le Nid ne se bat pas : il eclot une creature
# (un Dictionary de stats + sorts) que Combat fait se battre.

const VOISINAGE := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var cases := {}     # Vector2i -> id de relique
var niveaux := {}   # Vector2i -> niveau, absent = 1

func niveau(c: Vector2i) -> int:
	return niveaux.get(c, 1)

func placer(c: Vector2i, id: String, niv := 1) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= Data.NID_L or c.y >= Data.NID_H:
		return false
	if cases.has(c) or not Data.RELIQUES.has(id):
		return false
	if Data.RELIQUES[id]["type"] == "arme" and arme() != null:
		return false
	cases[c] = id
	if niv > 1:
		niveaux[c] = niv
	return true

# --- fusion ----------------------------------------------------------------
# 3 copies d'une relique au meme niveau fusionnent en une seule, niveau +1,
# a la place de celle qu'on vient de poser. Les armes ne fusionnent pas
# (une seule par Nid).

func copies(id: String, niv: int) -> Array:
	return cases.keys().filter(func(c): return cases[c] == id and niveau(c) == niv)

func peut_fusionner(id: String, niv: int) -> bool:
	return Data.RELIQUES[id]["type"] != "arme" and niv < Data.NIVEAU_MAX

# Fusionne en cascade a partir de c. Renvoie true si au moins une fusion a eu lieu.
func fusionner(c: Vector2i) -> bool:
	var fusion := false
	while cases.has(c) and peut_fusionner(cases[c], niveau(c)):
		var autres := copies(cases[c], niveau(c)).filter(func(a): return a != c)
		if autres.size() < 2:
			break
		for a in autres.slice(0, 2):
			retirer(a)
		niveaux[c] = niveau(c) + 1
		fusion = true
	return fusion

# Poser id en c : case vide, ou case qui porte deja la meme relique au niveau 1
# si cette pose complete un trio (utile quand le Nid est plein).
func peut_ajouter(c: Vector2i, id: String) -> bool:
	if not cases.has(c):
		return accepte(c, id, null) and c.x >= 0 and c.y >= 0 and c.x < Data.NID_L and c.y < Data.NID_H
	return cases[c] == id and niveau(c) == 1 and peut_fusionner(id, 1) and copies(id, 1).size() >= 2

func ajouter(c: Vector2i, id: String) -> bool:
	if not peut_ajouter(c, id):
		return false
	if not cases.has(c):
		placer(c, id)
		fusionner(c)
		return true
	# la pose sur une copie compte comme la troisieme : on en retire une autre
	retirer(copies(id, 1).filter(func(a): return a != c)[0])
	niveaux[c] = 2
	fusionner(c)
	return true

# Echange deux cases (ou deplace si b est vide), niveaux compris.
func deplacer(a: Vector2i, b: Vector2i) -> void:
	var ida = cases.get(a)
	var idb = cases.get(b)
	var na := niveau(a)
	var nb := niveau(b)
	retirer(a)
	retirer(b)
	if ida != null:
		placer(b, ida, na)
	if idb != null:
		placer(a, idb, nb)

# Deposer id en c, venant de depuis (ou du reliquaire si null), est-il permis ?
func accepte(c: Vector2i, id: String, depuis) -> bool:
	if Data.RELIQUES[id]["type"] != "arme":
		return true
	for a in cases:
		if Data.RELIQUES[cases[a]]["type"] == "arme" and a != c and a != depuis:
			return false
	return true

# Le cavalier n'a que deux mains : une seule arme dans le Nid.
func arme():
	for c in cases:
		if Data.RELIQUES[cases[c]]["type"] == "arme":
			return cases[c]
	return null

func retirer(c: Vector2i) -> void:
	cases.erase(c)
	niveaux.erase(c)

func voisins(c: Vector2i) -> Array:
	var v := []
	for d in VOISINAGE:
		if cases.has(c + d):
			v.append(c + d)
	return v

func affinites() -> Dictionary:
	var a := {}
	for c in cases:
		var r: Dictionary = Data.RELIQUES[cases[c]]
		if r["element"] == "":
			continue
		# une relique fusionnee garde l'affinite des trois copies
		a[r["element"]] = a.get(r["element"], 0) + r["affinite"] * int(pow(3, niveau(c) - 1))
	return a

# Element dominant, "" si vide ou egalite (en attendant les hybrides).
func forme() -> String:
	var meilleur := ""
	var max_a := 0
	var egalite := false
	for e in affinites():
		var v: int = affinites()[e]
		if v > max_a:
			meilleur = e
			max_a = v
			egalite = false
		elif v == max_a:
			egalite = true
	return "" if egalite else meilleur

func eclore() -> Dictionary:
	var aff := affinites()
	var f := forme()
	var cr := {
		"forme": f,
		"affinite": aff.values().reduce(func(s, v): return s + v, 0),
		"nom": Data.FORMES[f]["nom"],
		"pv_max": Data.PV_BASE,
		"attaque": Data.ATTAQUE_BASE,
		"intervalle": Data.INTERVALLE_BASE,
		"vol_de_vie": Data.VOL_DE_VIE_NUIT if f == "nuit" else 0.0,
		"renaissance": f == "feu",
		"tortue": f == "terre",
		"eclair": f == "vent",
		"bouclier": 0.0,
		"esquive": Data.ESQUIVE_CHEVAL if f == "vent" else 0.0,
		"arme": arme(),
		"sorts": [],
	}
	var vitesse := 0.0
	for c in cases:
		var r: Dictionary = Data.RELIQUES[cases[c]]
		var m: float = Data.NIVEAU_MULT[niveau(c)]
		match r["type"]:
			"essence":
				cr["attaque"] += r.get("attaque", 0.0) * m
				cr["vol_de_vie"] += r.get("vol_de_vie", 0.0) * m
				cr["pv_max"] += r.get("pv", 0.0) * m
				cr["bouclier"] += r.get("bouclier", 0.0) * m
				cr["esquive"] += r.get("esquive", 0.0) * m
				vitesse += r.get("vitesse", 0.0) * m
			"sort", "arme":
				cr["sorts"].append(_sort(c, r, aff))
	cr["intervalle"] = Data.INTERVALLE_BASE / (1.0 + vitesse)
	cr["esquive"] = minf(cr["esquive"], Data.ESQUIVE_MAX)
	return cr

# Un sort lit ses catalyseurs voisins au moment de l'eclosion.
# Le niveau multiplie les degats ; un sort sans degats (Voile) recharge plus vite.
func _sort(c: Vector2i, r: Dictionary, aff: Dictionary) -> Dictionary:
	var m: float = Data.NIVEAU_MULT[niveau(c)]
	var s := {
		"nom": r.get("sort", r["nom"]),
		"cavalier": r["type"] == "arme",
		"element": r["element"],
		"perce": r.get("perce", false),
		"execution": r.get("execution", false),
		"recharge": r["recharge"] / (1.0 + 0.5 * (niveau(c) - 1)) if r.get("esquive", false) else r["recharge"],
		"degats": _puissance(r, "degats", aff) * m,
		"bouclier": _puissance(r, "bouclier", aff) * m,
		"coups": r.get("coups", 0),
		"esquive": r.get("esquive", false),
		"brulure": 0.0,   # force de la brulure, 0 = aucune
		"vol_de_vie": 0.0,
	}
	for v in voisins(c):
		var cat: Dictionary = Data.RELIQUES[cases[v]]
		if cat["type"] != "catalyseur":
			continue
		match cat["effet"]:
			"brulure":
				s["brulure"] = maxf(s["brulure"], Data.NIVEAU_MULT[niveau(v)])
			"vol_de_vie":
				s["vol_de_vie"] += cat["valeur"] * Data.NIVEAU_MULT[niveau(v)]
			"bouclier":
				# un Socle donne un bouclier a chaque lancer, selon les degats du sort
				# ou le bouclier qu'il donne deja (Rempart)
				var k: float = cat["valeur"] * Data.NIVEAU_MULT[niveau(v)]
				s["bouclier"] += (s["degats"] * maxi(s["coups"], 1) + s["bouclier"]) * k
			"recharge":
				s["recharge"] /= 1.0 + cat["valeur"] * Data.NIVEAU_MULT[niveau(v)]
	return s

# Le bonus par point d'affinite va a ce que fait le sort : degats, ou bouclier
# pour un sort de protection (Rempart).
func _puissance(r: Dictionary, champ: String, aff: Dictionary) -> float:
	if not r.has(champ):
		return 0.0
	return r[champ] + r.get("par_affinite", 0.0) * aff.get(r["element"], 0)
