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
# Colonnes du damier ou l'on peut poser. Toutes par defaut ; une partie
# commence au centre et en ouvre d'autres.
var colonnes: Array = range(Data.NID_L)

func ouverte(c: Vector2i) -> bool:
	return c.y >= 0 and c.y < Data.NID_H and c.x in colonnes

func places() -> int:
	return colonnes.size() * Data.NID_H

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
	n.colonnes = colonnes.duplicate()
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
# 3 copies d'une relique au meme niveau fusionnent en une seule, niveau +1,
# a la place de celle qu'on vient de poser. Les armes ne fusionnent pas
# (une seule par Nid).

func copies(id: String, niv: int) -> Array:
	return cases.keys().filter(func(c): return cases[c] == id and niveau(c) == niv)

func peut_fusionner(id: String, niv: int) -> bool:
	return niv < Data.NIVEAU_MAX

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
		"vol_de_vie": Data.VOL_DE_VIE_NUIT if f == "nuit" else 0.0,
		"bouclier": 0.0,
		"epines": Data.EPINES_CERF if f == "nature" else 0.0,
		"epines_poison": 0.0,
		"poison_attaque": 0.0,
		"gousse": 0.0,
		"belladone": false,
		"coeur": false,
		"graine": false,
		"givre_attaque": Data.LOUP_GIVRE if f == "glace" else 0.0,
		"bonus_gel": Data.LOUP_BONUS_GEL if f == "glace" else 1.0,
		"par_malediction": Data.NUIT_PAR_MALEDICTION if f == "nuit" else 0.0,
		"bris_degats": 0.0,
		"bris_givre": 0.0,
		"reforme": 0.0,
		"gel_bouclier": 0.0,
		"rose": false,
		"nova": 0.0,
		"brulure_attaque": 0.0,
		"combustion_soin": 0.0,
		"soin_par_charge": 0.0,
		"degats_en_feu": 0.0,
		"resine": false,
		"fournaise": false,
		"renaissances": 1 if f == "feu" else 0,
		"oeuf": false,
		"crit": 0.0,
		"faiblesse_tous": 0,
		"sablier": 0.0,
		"renvoi": 0.0,
		"crit_fletrissure": false,
		"crit_malediction": false,
		"chapelet": false,
		"vol_par_malediction": 0.0,
		"grimoire": 0.0,
		"pacte": 0.0,
		"eclat": f == "aube",
		"regen": Data.REGEN_LION if f == "aube" else 0.0,
		"miroir": 0.0,
		"bande": 0.0,
		"encensoir": 0.0,
		"vasque": 0.0,
		"prisme": 0.0,
		"voile_aube": 0.0,
		"carillon": 0.0,
		"lanterne": 0.0,
		"arcane": f == "crepuscule",
		"poudre": 0.0,
		"cocon": 0.0,
		"mue": false,
		"brume": false,
		"phalene": false,
		"chrysalide": false,
		"aile_lune": false,
		"inversion": false,
		"arme": arme(),
		"armes": armes(),
		"hybride": hybride(),
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
				vitesse += r.get("vitesse", 0.0) * m
				# Ortie et Amanite renforcent aussi les essences voisines
				cr["epines"] += r.get("epines", 0.0) * m * _renfort(c, "epines")
				cr["poison_attaque"] += r.get("poison_attaque", 0.0) * m * _renfort(c, "poison")
				cr["epines_poison"] += r.get("epines_poison", 0.0) * m * _renfort(c, "poison")
				cr["gousse"] += r.get("gousse", 0.0) * m
				# Huile de premiere lumiere renforce aussi la regeneration voisine
				cr["bande"] += r.get("bande", 0.0) * m * _renfort(c, "soin")
				# Croc du blizzard renforce le givre pose par ses voisines
				cr["givre_attaque"] += r.get("givre_attaque", 0.0) * m * _renfort(c, "givre")
				cr["bris_givre"] += r.get("bris_givre", 0.0) * m * _renfort(c, "givre")
				for champ in ["bris_degats", "reforme", "gel_bouclier", "nova", "combustion_soin", "soin_par_charge", "degats_en_feu"]:
					cr[champ] += r.get(champ, 0.0) * m
				# Plume incandescente renforce la brulure posee par ses voisines
				cr["brulure_attaque"] += r.get("brulure_attaque", 0.0) * m * _renfort(c, "brulure")
				for drapeau in ["resine", "fournaise", "oeuf"]:
					cr[drapeau] = cr[drapeau] or r.get(drapeau, false)
				for champ in ["crit", "sablier", "renvoi", "vol_par_malediction", "grimoire", "pacte",
						"miroir", "encensoir", "vasque", "prisme", "voile_aube", "carillon", "lanterne"]:
					cr[champ] += r.get(champ, 0.0) * m
				if r.has("faiblesse_tous"):
					cr["faiblesse_tous"] = r["faiblesse_tous"] if cr["faiblesse_tous"] == 0 else mini(cr["faiblesse_tous"], r["faiblesse_tous"])
				cr["poudre"] += r.get("poudre", 0.0) * m * _renfort(c, "transfert")
				cr["cocon"] += r.get("cocon", 0.0) * m
				for drapeau in ["mue", "brume", "phalene", "chrysalide", "aile_lune", "inversion"]:
					cr[drapeau] = cr[drapeau] or r.get(drapeau, false)
				for drapeau in ["crit_fletrissure", "chapelet"]:
					cr[drapeau] = cr[drapeau] or r.get(drapeau, false)
				for drapeau in ["belladone", "coeur", "graine", "rose"]:
					cr[drapeau] = cr[drapeau] or r.get(drapeau, false)
			"sort", "arme":
				cr["sorts"].append(_sort(c, r, aff))
				# une Lame donne du crit a toute la monture
				if r.get("famille", "") == "lame":
					cr["crit"] += r.get("crit", Data.CRIT_LAME)
				cr["crit_malediction"] = cr["crit_malediction"] or r.get("crit_malediction", false)
	cr["intervalle"] = Data.INTERVALLE_BASE / (1.0 + vitesse)
	# l'Oeuf du Premier Brasier donne une renaissance de plus
	if cr["oeuf"]:
		cr["renaissances"] += 1
	# pour l'arene : le Nid tel qu'il etait, et ses niveaux
	if cr["hybride"] != "":
		var deux: PackedStringArray = cr["hybride"].split("_")
		# la dynastie dominante d'abord
		if deux[1] == f:
			deux = PackedStringArray([deux[1], deux[0]])
		cr["nom"] = "%s-%s" % [Data.FORMES[deux[0]]["nom"], Data.FORMES[deux[1]]["nom"]]
	cr["cases"] = cases.duplicate()
	cr["niveaux"] = niveaux.duplicate()
	cr["colonnes"] = colonnes.duplicate()
	cr["rotations"] = rotations.duplicate()
	cr["encombrement"] = encombrement
	return cr

# Un sort lit ses catalyseurs voisins au moment de l'eclosion.
# Multiplicateur apporte par les catalyseurs voisins d'un effet donne.
func _renfort(c: Vector2i, effet: String) -> float:
	var k := 1.0
	for v in voisins(c):
		var cat: Dictionary = Data.RELIQUES[cases[v]]
		if cat["type"] == "catalyseur" and cat["effet"] == effet:
			k *= 1.0 + cat["valeur"] * Data.NIVEAU_MULT[niveau(v)]
	return k

# Le niveau multiplie les degats.
func _sort(c: Vector2i, r: Dictionary, aff: Dictionary) -> Dictionary:
	var m: float = Data.NIVEAU_MULT[niveau(c)]
	var s := {
		"nom": r.get("sort", r["nom"]),
		"id": cases[c],
		"case": c,
		"cavalier": r["type"] == "arme",
		"element": r["element"],
		"perce": r.get("perce", false),
		"execution": r.get("execution", false),
		"recharge": r.get("recharge", 0.0),
		"poison": _puissance(r, "poison", aff) * m * _renfort(c, "poison"),
		"par_poison": r.get("par_poison", 0.0) * m,
		"degats_epines": r.get("degats_epines", false),
		"graine": r.get("graine", false),
		"contre": r.get("contre", 0),
		"givre": r.get("givre", 0.0) * m * _renfort(c, "givre"),
		"double_ralenti": r.get("double_ralenti", false),
		"fracas": r.get("fracas", false),
		"brise_gel": r.get("brise_gel", false),
		"brulure": _puissance(r, "brulure", aff) * m * _renfort(c, "brulure"),
		"combustion": r.get("combustion", 0.0),
		"braise": r.get("braise", 0.0) * m * _renfort(c, "braise"),
		"achever_seuil": r.get("achever_seuil", 0.0),
		"achever_mult": r.get("achever_mult", 1.0),
		"combustion_affaiblie": r.get("combustion_affaiblie", false),
		"combustion_tous": r.get("combustion_tous", 0),
		"tir_renaissance": r.get("tir_renaissance", false),
		"malediction": r.get("malediction", ""),
		"par_malediction": r.get("par_malediction", 0.0),
		"consume_maledictions": r.get("consume_maledictions", false),
		"soin": _puissance(r, "soin", aff) * m * _renfort(c, "soin"),
		"charge_eclat": r.get("charge_eclat", 0.0) * m,
		"apres_eclat": r.get("apres_eclat", false),
		"eclat_tous": r.get("eclat_tous", 0),
		"transfert": r.get("transfert", ""),
		"puissance": _puissance(r, "puissance", aff) * m * _renfort(c, "transfert"),
		"transfert_tous": r.get("transfert_tous", 0),
		"par_transfert": r.get("par_transfert", 0.0) * m,
		"par_epine": r.get("par_epine", 0.0) * m,
		"degats": _puissance(r, "degats", aff) * m,
		"bouclier": _puissance(r, "bouclier", aff) * m,
		"coups": r.get("coups", 0),
		"vol_de_vie": r.get("vol_de_vie", 0.0) * m,
	}
	for v in voisins(c):
		var cat: Dictionary = Data.RELIQUES[cases[v]]
		if cat["type"] != "catalyseur":
			continue
		match cat["effet"]:
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

# Le bonus par point d'affinite va a la valeur principale du sort : `echelle`
# si elle est donnee, sinon degats, bouclier ou poison (le premier present).
func _puissance(r: Dictionary, champ: String, aff: Dictionary) -> float:
	if not r.has(champ):
		return 0.0
	var echelle: String = r.get("echelle", "")
	if echelle == "":
		for k in ["degats", "bouclier", "poison", "soin"]:
			if r.has(k):
				echelle = k
				break
	var bonus: float = r.get("par_affinite", 0.0) * aff.get(r["element"], 0) if champ == echelle else 0.0
	return r[champ] + bonus
