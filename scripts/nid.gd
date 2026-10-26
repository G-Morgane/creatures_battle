class_name Nid
extends RefCounted

# Grille de reliques. Le Nid ne se bat pas : il eclot une creature
# (un Dictionary de stats + sorts) que Combat fait se battre.

const VOISINAGE := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var cases := {}   # Vector2i -> id de relique

func placer(c: Vector2i, id: String) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= Data.NID_L or c.y >= Data.NID_H:
		return false
	if cases.has(c) or not Data.RELIQUES.has(id):
		return false
	if Data.RELIQUES[id]["type"] == "arme" and arme() != null:
		return false
	cases[c] = id
	return true

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

func voisins(c: Vector2i) -> Array:
	var v := []
	for d in VOISINAGE:
		if cases.has(c + d):
			v.append(c + d)
	return v

func affinites() -> Dictionary:
	var a := {}
	for id in cases.values():
		var r: Dictionary = Data.RELIQUES[id]
		if r["element"] == "":
			continue
		a[r["element"]] = a.get(r["element"], 0) + r["affinite"]
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
		"vol_de_vie": Data.VOL_DE_VIE_OMBRE if f == "ombre" else 0.0,
		"renaissance": f == "feu",
		"arme": arme(),
		"sorts": [],
	}
	var vitesse := 0.0
	for c in cases:
		var r: Dictionary = Data.RELIQUES[cases[c]]
		match r["type"]:
			"essence":
				cr["attaque"] += r.get("attaque", 0.0)
				cr["vol_de_vie"] += r.get("vol_de_vie", 0.0)
				vitesse += r.get("vitesse", 0.0)
			"sort", "arme":
				cr["sorts"].append(_sort(c, r, aff))
	cr["intervalle"] = Data.INTERVALLE_BASE / (1.0 + vitesse)
	return cr

# Un sort lit ses catalyseurs voisins au moment de l'eclosion.
func _sort(c: Vector2i, r: Dictionary, aff: Dictionary) -> Dictionary:
	var s := {
		"nom": r.get("sort", r["nom"]),
		"cavalier": r["type"] == "arme",
		"element": r["element"],
		"perce": r.get("perce", false),
		"execution": r.get("execution", false),
		"recharge": r["recharge"],
		"degats": r.get("degats", 0.0) + r.get("par_affinite", 0.0) * aff.get(r["element"], 0),
		"coups": r.get("coups", 0),
		"esquive": r.get("esquive", false),
		"brulure": false,
		"vol_de_vie": 0.0,
	}
	for v in voisins(c):
		var cat: Dictionary = Data.RELIQUES[cases[v]]
		if cat["type"] != "catalyseur":
			continue
		match cat["effet"]:
			"brulure":
				s["brulure"] = true
			"vol_de_vie":
				s["vol_de_vie"] += cat["valeur"]
	return s
