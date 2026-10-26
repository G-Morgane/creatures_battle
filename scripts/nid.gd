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
	cases[c] = id
	return true

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
		"nom": Data.FORMES[f]["nom"],
		"pv_max": Data.PV_BASE,
		"attaque": Data.ATTAQUE_BASE,
		"intervalle": Data.INTERVALLE_BASE,
		"vol_de_vie": Data.VOL_DE_VIE_OMBRE if f == "ombre" else 0.0,
		"renaissance": f == "feu",
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
			"sort":
				cr["sorts"].append(_sort(c, r, aff))
	cr["intervalle"] = Data.INTERVALLE_BASE / (1.0 + vitesse)
	return cr

# Un sort lit ses catalyseurs voisins au moment de l'eclosion.
func _sort(c: Vector2i, r: Dictionary, aff: Dictionary) -> Dictionary:
	var s := {
		"nom": r["nom"],
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
