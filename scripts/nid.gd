class_name Nid
extends RefCounted

# Grille de reliques. Le Nid ne se bat pas : il eclot une creature
# (un Dictionary de stats + sorts) que Combat fait se battre.

const VOISINAGE := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var cases := {}     # ancre (coin haut gauche) -> id de relique
var niveaux := {}   # ancre -> niveau, absent = 1
var rotations := {} # ancre -> quarts de tour, absent = 0
# true : chaque relique occupe sa forme (en partie). false : une case chacune,
# pour les Nids d'exemple et les tests de mecanique.
var encombrement := false
# Cases du damier ou l'on peut poser. Toutes par defaut ; une partie
# commence au centre et en ouvre d'autres, une a une.
var ouvertes: Array = Nid.toutes()

static func toutes() -> Array:
	var l := []
	for y in Data.NID_H:
		for x in Data.NID_L:
			l.append(Vector2i(x, y))
	return l

func ouverte(c: Vector2i) -> bool:
	return c in ouvertes

func places() -> int:
	return ouvertes.size()

# Cases fermees du damier qui touchent le sac : celles qu'on peut ouvrir.
func bordure() -> Array:
	var b := []
	for c in ouvertes:
		for d in VOISINAGE:
			var k: Vector2i = c + d
			if k.x >= 0 and k.x < Data.NID_L and k.y >= 0 and k.y < Data.NID_H and not k in ouvertes and not k in b:
				b.append(k)
	return b

func niveau(c: Vector2i) -> int:
	return niveaux.get(c, 1)

func rotation(c: Vector2i) -> int:
	return rotations.get(c, 0)

# --- formes ------------------------------------------------------------------

# Cases couvertes par id pose en ancre c, tourne de rot.
func empreinte(c: Vector2i, id: String, rot := 0) -> Array:
	if not encombrement:
		return [c]
	return Data.empreinte(id, rot).map(func(d): return c + d)

func cases_de(a: Vector2i) -> Array:
	return empreinte(a, cases[a], rotation(a))

# Case -> ancre de la relique qui la couvre.
func occupation() -> Dictionary:
	var o := {}
	for a in cases:
		for c in cases_de(a):
			o[c] = a
	return o

# Ancre de la relique qui couvre c, null si c est vide.
func ancre(c: Vector2i):
	return occupation().get(c)

func dupliquer() -> Nid:
	var n := Nid.new()
	n.cases = cases.duplicate()
	n.niveaux = niveaux.duplicate()
	n.rotations = rotations.duplicate()
	n.ouvertes = ouvertes.duplicate()
	n.encombrement = encombrement
	return n

func placer(c: Vector2i, id: String, niv := 1, rot := 0) -> bool:
	if not Data.RELIQUES.has(id):
		return false
	var occ := occupation()
	for k in empreinte(c, id, rot):
		if not ouverte(k) or occ.has(k):
			return false
	cases[c] = id
	if niv > 1:
		niveaux[c] = niv
	if rot % 4 != 0 and encombrement:
		rotations[c] = rot % 4
	return true

# --- fusion ----------------------------------------------------------------
# Des copies d'une relique au meme niveau (3 au niveau 1, 2 au niveau 2,
# Data.FUSION_COPIES) fusionnent en une seule, niveau +1, a la place de celle
# qu'on vient de poser.

func copies(id: String, niv: int) -> Array:
	return cases.keys().filter(func(c): return cases[c] == id and niveau(c) == niv)

func peut_fusionner(id: String, niv: int) -> bool:
	return niv < Data.NIVEAU_MAX

# Fusionne en cascade a partir de c. Renvoie true si au moins une fusion a eu lieu.
func fusionner(c: Vector2i) -> bool:
	var fusion := false
	while cases.has(c) and peut_fusionner(cases[c], niveau(c)):
		var autres := copies(cases[c], niveau(c)).filter(func(a): return a != c)
		var besoin: int = Data.FUSION_COPIES[niveau(c)] - 1
		if autres.size() < besoin:
			break
		for a in autres.slice(0, besoin):
			retirer(a)
		niveaux[c] = niveau(c) + 1
		fusion = true
	return fusion

# Poser id en c (tourne de rot) : sur des cases libres, ou sur une case d'une
# copie de niveau 1 si cette pose complete un trio (utile quand le sac est plein).
func peut_ajouter(c: Vector2i, id: String, rot := 0) -> bool:
	var a = ancre(c)
	if a != null:
		return _complete_trio(a, id)
	return dupliquer().placer(c, id, 1, rot)

func _complete_trio(a: Vector2i, id: String) -> bool:
	return cases[a] == id and niveau(a) == 1 and peut_fusionner(id, 1) and copies(id, 1).size() >= 2

func ajouter(c: Vector2i, id: String, rot := 0) -> bool:
	if not peut_ajouter(c, id, rot):
		return false
	var a = ancre(c)
	if a == null:
		placer(c, id, 1, rot)
		fusionner(c)
		return true
	# la pose sur une copie compte comme la troisieme : on en retire une autre
	retirer(copies(id, 1).filter(func(k): return k != a)[0])
	niveaux[a] = 2
	fusionner(a)
	return true

# Deplace la relique d'ancre a vers l'ancre b (tournee de rot, -1 : sans la
# tourner). Si la place est prise par une seule autre relique, les deux
# s'echangent quand l'autre tient a la place laissee. Renvoie false sinon,
# sans rien changer.
func deplacer(a: Vector2i, b: Vector2i, rot := -1) -> bool:
	if not cases.has(a):
		return false
	var id: String = cases[a]
	var na := niveau(a)
	var ra := rotation(a) if rot < 0 else rot
	var occ := occupation()
	var autres := {}
	for k in empreinte(b, id, ra):
		if not ouverte(k):
			return false
		if occ.has(k) and occ[k] != a:
			autres[occ[k]] = true
	if autres.size() > 1:
		return false
	var avant := dupliquer()
	retirer(a)
	if autres.is_empty():
		if placer(b, id, na, ra):
			return true
	else:
		var o: Vector2i = autres.keys()[0]
		var ido: String = cases[o]
		var no := niveau(o)
		var ro := rotation(o)
		retirer(o)
		if placer(b, id, na, ra) and placer(a, ido, no, ro):
			return true
	cases = avant.cases
	niveaux = avant.niveaux
	rotations = avant.rotations
	return false

func peut_deplacer(a: Vector2i, b: Vector2i, rot := -1) -> bool:
	return dupliquer().deplacer(a, b, rot)

# Deposer id en c, venant de depuis (ou du reliquaire si null), est-il permis ?
func accepte(c: Vector2i, id: String, depuis) -> bool:
	if not ouverte(c):
		return false
	return true

# Armes du sac, sans limite : toutes lancent leur sort. Dans l'ordre du sac (de
# haut en bas, puis de gauche a droite) ; le cavalier montre les deux premieres.
func armes() -> Array:
	var ancres := cases.keys().filter(func(a): return Data.RELIQUES[cases[a]]["type"] == "arme")
	ancres.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return ancres.map(func(a): return cases[a])

func arme():
	var l := armes()
	return null if l.is_empty() else l[0]

func retirer(c: Vector2i) -> void:
	cases.erase(c)
	niveaux.erase(c)
	rotations.erase(c)

# Ancres des reliques qui touchent celle d'ancre c (ou la case vide c) par un cote.
func voisins(c: Vector2i) -> Array:
	var occ := occupation()
	var v := []
	for k in (cases_de(c) if cases.has(c) else [c]):
		for d in VOISINAGE:
			var o = occ.get(k + d)
			if o != null and o != c and not o in v:
				v.append(o)
	return v

# Catalyseurs qui agissent sur la relique d'ancre c : ceux qui la touchent.
func influents(c: Vector2i) -> Array:
	return voisins(c).filter(func(v): return Data.RELIQUES[cases[v]]["type"] == "catalyseur")

# Multiplicateur d'une relique : son niveau.
func mult(c: Vector2i) -> float:
	return Data.NIVEAU_MULT[niveau(c)]

func affinites() -> Dictionary:
	var a := {}
	for c in cases:
		var r: Dictionary = Data.RELIQUES[cases[c]]
		if r["element"] == "":
			continue
		# une relique fusionnee garde l'affinite des trois copies
		a[r["element"]] = a.get(r["element"], 0) + r["affinite"] * Data.copies_niveau(niveau(c))
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

# Hybride : la dynastie principale (la plus d'affinite) et une autre dont le
# sac contient au moins HYBRIDE_OBJETS objets ; s'il y en a plusieurs, celle qui
# a le plus d'objets. Cle "a_b" (elements tries), "" sinon. Le passif reste
# celui de la dynastie dominante (forme()).
const HYBRIDE_OBJETS := 2

func hybride() -> String:
	var aff := affinites()
	if aff.is_empty():
		return ""
	var ordre := aff.keys()
	ordre.sort_custom(func(a, b): return aff[a] > aff[b] or (aff[a] == aff[b] and a < b))
	var principale: String = ordre[0]
	var objets := {}
	for c in cases:
		var e: String = Data.RELIQUES[cases[c]]["element"]
		if e != "" and e != principale:
			objets[e] = objets.get(e, 0) + 1
	var seconde := ""
	for e in objets:
		if objets[e] < HYBRIDE_OBJETS:
			continue
		if seconde == "" or objets[e] > objets[seconde] or (objets[e] == objets[seconde] and aff.get(e, 0) > aff.get(seconde, 0)):
			seconde = e
	if seconde == "":
		return ""
	var deux := [principale, seconde]
	deux.sort()
	var cle := "%s_%s" % deux
	return cle if ResourceLoader.exists("res://images/montures/hybrides/%s.png" % cle) else ""

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
		"bouclier": 0.0,
		# Ete
		"renaissances": 1 if f == "feu" else 0,
		"brulure_attaque": 0.0,
		"brulure_duree": 0.0,
		"obsidienne": 0.0,
		"fournaise": false,
		"oeuf": false,
		# Nuit
		"par_malediction": Data.NUIT_PAR_MALEDICTION if f == "nuit" else 0.0,
		"stigmate_tous": 0,
		"sablier": 0.0,
		"grimoire": 0.0,
		"masque": false,
		"pacte": false,
		# Printemps
		"epines": Data.EPINES_CERF if f == "nature" else 0.0,
		"epines_poison": Data.EPINES_POISON_CERF if f == "nature" else 0.0,
		"poison_attaque": 0.0,
		"belladone": false,
		"graine": false,
		# Hiver
		"givre_attaque": Data.OURS_GIVRE if f == "glace" else 0.0,
		"bonus_gel": Data.OURS_BONUS_GEL if f == "glace" else 1.0,
		"gel_duree": 0.0,
		"gel_degats": 0.0,
		"banquise": false,
		"gel_seuil": Data.GEL_SEUIL,
		# Aube
		"eclat": f == "aube",
		"regen": Data.REGEN_LION if f == "aube" else 0.0,
		"miroir": 0.0,
		"voile_aube": 0.0,
		"carillon": 0.0,
		"lanterne": 0.0,
		# Crepuscule
		"illusions": f == "crepuscule",
		"illusions_depart": 0,
		"illusions_max": Data.ILLUSIONS_MAX,
		"arcane_bonus": 0.0,
		"mue": false,
		"phalene": false,
		"chrysalide": false,
		# Automne
		"feinte": f == "automne",
		"esquive": Data.ESQUIVE_RENARD if f == "automne" else 0.0,
		"crit": 0.0,
		"crit_mult": Data.CRIT_MULT,
		"bogue": false,
		"queue": false,
		"coutelas": false,
		# Jour
		"eventail": f == "jour",
		"eventail_depart": 0.0,
		"eventail_max": Data.EVENTAIL_MAX,
		"ecu": 0.0,
		"miroir_ocelle": 0.0,
		"zenith": false,
		"arme": arme(),
		"armes": armes(),
		"hybride": hybride(),
		"sorts": [],
		"signatures": {},   # element -> signature ajoutee a chaque attaque (essences)
	}
	var vitesse := 0.0
	for c in cases:
		var r: Dictionary = Data.RELIQUES[cases[c]]
		var m := mult(c)
		match r["type"]:
			"essence":
				vitesse += _essence(cr, c, r, m)
				# signature de dynastie, portee par l'attaque de base
				if Data.SIGNATURES.has(r["element"]):
					cr["signatures"][r["element"]] = cr["signatures"].get(r["element"], 0.0) + Data.SIGNATURES[r["element"]] * Data.SIGNATURE_ESSENCE * m
			"sort", "arme":
				cr["sorts"].append(_sort(c, r, aff))
				# une Lame donne du crit a toute la monture
				if r.get("famille", "") == "lame":
					cr["crit"] += r.get("crit", Data.CRIT_LAME) * m
				cr["coutelas"] = cr["coutelas"] or r.get("coutelas", false)
			"catalyseur":
				# Pelage roux : du crit pour chaque relique qui le touche
				if r["effet"] == "crit":
					cr["crit"] += r["valeur"] * m * voisins(c).size()
	cr["intervalle"] = Data.INTERVALLE_BASE / (1.0 + vitesse)
	# l'Oeuf du Premier Brasier donne une renaissance de plus
	if cr["oeuf"]:
		cr["renaissances"] += 1
	# Pacte : le passif de la Chauve-souris compte double
	if cr["pacte"]:
		cr["par_malediction"] *= 2.0
	if cr["mue"]:
		cr["illusions_max"] = Data.MUE_ILLUSIONS
	# pour l'arene : le Nid tel qu'il etait, et ses niveaux
	if cr["hybride"] != "":
		var deux: PackedStringArray = cr["hybride"].split("_")
		# la dynastie dominante d'abord
		if deux[1] == f:
			deux = PackedStringArray([deux[1], deux[0]])
		cr["nom"] = "%s-%s" % [Data.FORMES[deux[0]]["nom"], Data.FORMES[deux[1]]["nom"]]
	cr["cases"] = cases.duplicate()
	cr["niveaux"] = niveaux.duplicate()
	cr["ouvertes"] = ouvertes.duplicate()
	cr["rotations"] = rotations.duplicate()
	cr["encombrement"] = encombrement
	return cr

# Ajoute a cr les stats d'une essence (ancre c, multiplicateur m). Renvoie sa vitesse.
func _essence(cr: Dictionary, c: Vector2i, r: Dictionary, m: float) -> float:
	cr["pv_max"] += r.get("pv", 0.0) * m
	for champ in ["attaque", "bouclier", "brulure_duree", "obsidienne", "sablier", "grimoire",
			"epines", "epines_poison", "gel_duree", "gel_degats", "regen", "miroir", "voile_aube",
			"carillon", "lanterne", "arcane_bonus", "esquive", "crit", "eventail_depart", "ecu", "miroir_ocelle"]:
		cr[champ] += r.get(champ, 0.0) * m
	# Tison et Croc du blizzard renforcent aussi les essences voisines
	cr["brulure_attaque"] += r.get("brulure_attaque", 0.0) * m * _renfort(c, "brulure")
	cr["givre_attaque"] += r.get("givre_attaque", 0.0) * m * _renfort(c, "givre")
	cr["poison_attaque"] += r.get("poison_attaque", 0.0) * m
	cr["illusions_depart"] += roundi(r.get("illusions_depart", 0) * m)
	if r.has("stigmate_tous"):
		cr["stigmate_tous"] = r["stigmate_tous"] if cr["stigmate_tous"] == 0 else mini(cr["stigmate_tous"], r["stigmate_tous"])
	# valeurs qui remplacent celles de base : la meilleure l'emporte
	if r.has("gel_seuil"):
		cr["gel_seuil"] = minf(cr["gel_seuil"], r["gel_seuil"])
	if r.has("crit_mult"):
		cr["crit_mult"] = maxf(cr["crit_mult"], r["crit_mult"])
	if r.has("eventail_max"):
		cr["eventail_max"] = maxf(cr["eventail_max"], r["eventail_max"])
	for drapeau in ["fournaise", "oeuf", "masque", "pacte", "belladone", "graine", "banquise",
			"mue", "phalene", "chrysalide", "bogue", "queue", "zenith"]:
		cr[drapeau] = cr[drapeau] or r.get(drapeau, false)
	return r.get("vitesse", 0.0) * m

# Un sort lit ses catalyseurs voisins au moment de l'eclosion.
# Multiplicateur apporte par les catalyseurs d'un effet donne.
func _renfort(c: Vector2i, effet: String) -> float:
	var k := 1.0
	for v in influents(c):
		var cat: Dictionary = Data.RELIQUES[cases[v]]
		if cat["effet"] == effet:
			k *= 1.0 + cat["valeur"] * Data.NIVEAU_MULT[niveau(v)]
	return k

# Somme apportee par les catalyseurs d'un effet d'ajout (Ortie, Huile, Poupee).
func _ajout(c: Vector2i, effet: String) -> float:
	var n := 0.0
	for v in influents(c):
		var cat: Dictionary = Data.RELIQUES[cases[v]]
		if cat["effet"] == effet:
			n += cat["valeur"] * Data.NIVEAU_MULT[niveau(v)]
	return n

# Le niveau multiplie les effets.
func _sort(c: Vector2i, r: Dictionary, aff: Dictionary) -> Dictionary:
	var m := mult(c)
	var s := {
		"nom": r.get("sort", r["nom"]),
		"id": cases[c],
		"case": c,
		"cavalier": r["type"] == "arme",
		"element": r["element"],
		"perce": r.get("perce", false),
		"recharge": r.get("recharge", 0.0) / _renfort(c, "recharge"),
		"contre": r.get("contre", 0),
		"degats": _puissance(r, "degats", aff) * m * _renfort(c, "degats"),
		"coups": r.get("coups", 0),
		"bouclier": _puissance(r, "bouclier", aff) * m,
		"brulure": _puissance(r, "brulure", aff) * m * _renfort(c, "brulure"),
		"combustion": r.get("combustion", 0.0),
		"combustion_mult": r.get("combustion_mult", 1.0) * m,
		"malediction": r.get("malediction", ""),
		"maudit_manquante": roundi(_ajout(c, "malediction")),
		"par_malediction": r.get("par_malediction", 0.0) * m,
		"consume_maledictions": r.get("consume_maledictions", false),
		"poison": _puissance(r, "poison", aff) * m + _ajout(c, "poison_ajout"),
		"degats_epines": r.get("degats_epines", false),
		"givre": _puissance(r, "givre", aff) * m * _renfort(c, "givre"),
		"contre_gel": r.get("contre_gel", 1.0),
		"prolonge_gel": r.get("prolonge_gel", 0.0) * m,
		"soin": _puissance(r, "soin", aff) * m + _ajout(c, "soin_ajout"),
		"par_eclat": r.get("par_eclat", 0.0) * m,
		"eclat_moitie": r.get("eclat_moitie", false),
		"arcane": _puissance(r, "arcane", aff) * m,
		"illusions": roundi(r.get("illusions", 0) * m),
		"eclate_illusions": r.get("eclate_illusions", 0.0) * m,
		"esquive_temp": r.get("esquive_temp", 0.0) * m,
		"crit_recharge": r.get("crit_recharge", 0.0),
		"roue": r.get("roue", 0.0) * m,
		"eventail_gain": r.get("eventail_gain", 1.0),
		"coups_par_eventail": r.get("coups_par_eventail", false),
		"signature": Data.SIGNATURES.get(r["element"], 0.0) * m,
	}
	return s

# Le bonus par point d'affinite va a la valeur principale du sort : `echelle`
# si elle est donnee, sinon degats, bouclier, poison, soin, brulure ou givre
# (le premier present).
func _puissance(r: Dictionary, champ: String, aff: Dictionary) -> float:
	if not r.has(champ):
		return 0.0
	var echelle: String = r.get("echelle", "")
	if echelle == "":
		for k in ["degats", "bouclier", "poison", "soin", "brulure", "givre"]:
			if r.has(k):
				echelle = k
				break
	var bonus: float = r.get("par_affinite", 0.0) * aff.get(r["element"], 0) if champ == echelle else 0.0
	return r[champ] + bonus
