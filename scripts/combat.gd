class_name Combat
extends RefCounted

# Simulation deterministe par pas fixe : memes creatures, meme resultat.
# Indispensable pour rejouer un fantome asynchrone a l'identique.

var t := 0.0
var cotes: Array = []
var journal: Array[String] = []
# Pour rejouer le combat a l'ecran : un evenement par action, et les PV
# des deux cotes a chaque pas
# ([pv0, pv1, brule0, brule1, bouclier0, bouclier1, poison0, poison1,
#   givre0, givre1, gele0, gele1, illusions0, illusions1, maledictions0, maledictions1,
#   eclat0, eclat1, oeil0, oeil1, phase0, phase1, eventail0, eventail1]) ;
# brule = nombre de charges de brulure, maledictions = texte ("Faiblesse, Stigmate").
var evenements: Array = []
var images: Array = []
# Recharge des sorts a chaque pas, de 0 a 1 ([cote 0, cote 1], un par sort ;
# -1 pour un sort qui part sur coups recus).
var recharges: Array = []
# Recap : par cote, source -> {degats, soins, bouclier, activations}. La source
# est l'id d'une relique, ou une mecanique prefixee de ~ (~attaque, ~poison...).
var stats: Array = [{}, {}]
var origine := "~attaque"
# Critiques et esquives sont un tirage : graine fixe, donc toujours le meme combat.
var rng := RandomNumberGenerator.new()

func _init(a: Dictionary, b: Dictionary) -> void:
	rng.seed = 1
	cotes = [_etat(a, 0), _etat(b, 1)]
	# effets de debut de combat : Cocon (une Illusion), Plume d'ocelle (Eventail)
	for i in 2:
		if cotes[i]["cr"]["illusions_depart"] > 0:
			_relique(cotes[i], "cocon")
		if cotes[i]["cr"]["eventail_depart"] > 0.0:
			_relique(cotes[i], "plume_ocelle")

func _etat(cr: Dictionary, i: int) -> Dictionary:
	var sorts := []
	for s in cr["sorts"]:
		var copie: Dictionary = s.duplicate()
		# un sort de riposte ne part pas sur minuterie mais sur coups recus
		copie["prochain"] = INF if s["contre"] > 0 else s["recharge"]
		# Embuscade (l'Ombre) : les armes partent des le debut
		if cr.get("embuscade", false) and s["cavalier"] and s["contre"] == 0:
			copie["prochain"] = Data.EMBUSCADE_DELAI
		sorts.append(copie)
	return {
		"cr": cr,
		"cote": i,
		"flash": {},               # relique -> dernier allumage a l'ecran
		"pv": cr["pv_max"],
		"prochaine_attaque": cr["intervalle"],
		"sorts": sorts,
		"bouclier": cr["bouclier"],
		"horloge": 0.0,            # temps propre : ralenti par le givre, arrete par le gel
		"renaissances": cr["renaissances"],
		"brulures": [],            # charges de brulure : [{fin, q}], chacune s'eteint seule
		"brulures_posees": 0.0,    # Eclat d'obsidienne
		"maledictions": {},        # nom -> {n, debut, fin}
		"poison": 0.0,             # doses
		"coups_recus": 0,
		"givre": 0.0,              # charges de givre subies
		"gele_jusqu": 0.0,
		"gele_depuis": 0.0,
		"eclat_jauge": 0.0,
		"dans_eclat": false,       # un soin venu d'un Eclat ne recharge pas l'Eclat
		"illusions": cr["illusions_depart"],
		"esquive_temp_jusqu": 0.0, # Bourrasque
		"esquive_temp": 0.0,
		"feinte_prete": false,     # Renard : crit garanti apres une esquive
		"esquive_prete": false,    # Queue du Vieux Renard : esquive garantie apres un crit
		"dernier_crit": false,
		"eventail": cr["eventail_depart"],
		"elite_t": 0.0,            # elites : minuterie de leur regle
		"elite_t2": 0.0,
		"furie": false,            # Vouivre : entraves brisees
		"phase": "",               # Bastion : rempart, ouverture, resistance
		"oeil": 0.0,               # Bastion : bouclier absorbe par l'oeil
		"oeil_debit": 0.0,
		"sceaux": 0,               # Dernier Sceau : plaques brisees (0 a 2)
		"emprise_t": 0.0,          # Dernier Sceau : depuis quand l'Emprise dure
	}

# Renvoie 0 ou 1 pour le vainqueur, -1 pour un nul.
func simuler() -> int:
	while t < Data.DUREE_MAX:
		t += Data.PAS
		for i in 2:
			var v := _vitesse(cotes[i])
			cotes[i]["horloge"] += Data.PAS * v
			# givre et gel : le temps perdu par la cible, au compte de l'autre cote
			if v < 1.0 and cotes[i]["phase"] != "ouverture":
				_compter(1 - i, "impact", Data.PAS * (1.0 - v), "~gel" if _gele(cotes[i]) else "~givre")
		for i in 2:
			_agir(cotes[i], cotes[1 - i])
		for i in 2:
			_subir(cotes[i], cotes[1 - i])
		var morts := [_mort(cotes[0], cotes[1]), _mort(cotes[1], cotes[0])]
		images.append([cotes[0]["pv"], cotes[1]["pv"], _brulure(cotes[0]), _brulure(cotes[1]),
			cotes[0]["bouclier"], cotes[1]["bouclier"], cotes[0]["poison"], cotes[1]["poison"],
			cotes[0]["givre"], cotes[1]["givre"], _gele(cotes[0]), _gele(cotes[1]),
			cotes[0]["illusions"], cotes[1]["illusions"],
			_resume_maledictions(cotes[0]), _resume_maledictions(cotes[1]),
			cotes[0]["eclat_jauge"], cotes[1]["eclat_jauge"],
			_oeil(cotes[0]), _oeil(cotes[1]), cotes[0]["phase"], cotes[1]["phase"],
			cotes[0]["eventail"], cotes[1]["eventail"], _minuteurs(cotes[0]), _minuteurs(cotes[1])])
		recharges.append([_recharges(cotes[0]), _recharges(cotes[1])])
		if morts[0] or morts[1]:
			var v := 1 if morts[0] else 0
			# Chute simultanee : celui qui finit le moins en negatif tient debout.
			if morts[0] and morts[1]:
				if is_equal_approx(cotes[0]["pv"], cotes[1]["pv"]):
					_noter("Les deux tombent ensemble.")
					return -1
				v = 0 if cotes[0]["pv"] > cotes[1]["pv"] else 1
			_noter("%s l'emporte." % cotes[v]["cr"]["nom"])
			return v
	_noter("Temps écoulé.")
	return -1

func _recharges(moi: Dictionary) -> Array:
	var l := []
	for s in moi["sorts"]:
		if s["prochain"] == INF or s["recharge"] <= 0.0:
			l.append(-1.0)
		else:
			l.append(clampf(1.0 - (s["prochain"] - moi["horloge"]) / _recharge(moi, s), 0.0, 1.0))
	return l

# --- recap ---------------------------------------------------------------------

func _compter(cote: int, champ: String, v: float, source := "") -> void:
	if v <= 0.0:
		return
	var cle := source if source != "" else origine
	# impact : ce qu'un malus a fait a l'adversaire (degats evites ou ajoutes,
	# soins empeches, secondes de recharge volees), selon la cle ~faiblesse...
	var l: Dictionary = stats[cote].get(cle, {"degats": 0.0, "soins": 0.0, "bouclier": 0.0, "activations": 0.0, "impact": 0.0})
	l[champ] += v
	stats[cote][cle] = l

# Change la source courante, rend l'ancienne pour la remettre apres.
func _depuis(o: String) -> String:
	var avant := origine
	origine = o
	return avant

func _proteger(moi: Dictionary, b: float, source := "") -> void:
	if moi["phase"] == "resistance" or b <= 0.0:
		return
	moi["bouclier"] += b
	_compter(moi["cote"], "bouclier", b, source)

# Degats directs, qui passent le bouclier (brulure, poison, combustion...).
func _infliger(cible: Dictionary, d: float, source := "") -> void:
	_compter(1 - cible["cote"], "impact", d * (_stigmate(cible) - 1.0), "~stigmate")
	d *= _stigmate(cible)
	_rupture(cible, d)
	cible["pv"] -= d
	_compter(1 - cible["cote"], "degats", d, source)
	_lanterne(cible, d)

# Le givre ralentit le temps propre (attaques et recharges), le gel l'arrete.
func _vitesse(moi: Dictionary) -> float:
	if _gele(moi) or moi["phase"] == "ouverture":
		return 0.0
	return 1.0 - minf(moi["givre"] * Data.GIVRE_RALENTI, Data.RALENTI_MAX)

func _brulure(moi: Dictionary) -> float:
	var total := 0.0
	for b in moi["brulures"]:
		total += b["q"]
	return total

func _gele(moi: Dictionary) -> bool:
	return t < moi["gele_jusqu"]

# Temps restant des etats qui s'eteignent seuls, de 1 (tout frais) a 0 ; 1
# aussi pour ceux qui ne s'eteignent plus. Brulure : la charge la plus longue.
func _minuteurs(moi: Dictionary) -> Dictionary:
	var m := {}
	for b in moi["brulures"]:
		var f := _reste(b["debut"], b["fin"])
		m["brulure"] = maxf(m.get("brulure", 0.0), f)
	for nom in moi["maledictions"]:
		var x: Dictionary = moi["maledictions"][nom]
		if x["fin"] > t:
			m[nom] = _reste(x["debut"], x["fin"])
	if _gele(moi):
		m["gel"] = _reste(moi["gele_depuis"], moi["gele_jusqu"])
	return m

func _reste(debut: float, fin: float) -> float:
	return 1.0 if fin == INF else clampf((fin - t) / maxf(fin - debut, Data.PAS), 0.0, 1.0)

# Recharge d'un sort : l'Eventail accelere les armes.
func _recharge(moi: Dictionary, s: Dictionary) -> float:
	if s["cavalier"]:
		return s["recharge"] / (1.0 + moi["eventail"] * Data.EVENTAIL_BONUS)
	return s["recharge"]

func _agir(moi: Dictionary, cible: Dictionary) -> void:
	var h: float = moi["horloge"]
	# la Voix ne frappe pas pendant sa communion ni son silence
	if moi["phase"] in ["communion", "silence", "repit"]:
		moi["prochaine_attaque"] = maxf(moi["prochaine_attaque"], h + 0.5)
	if h >= moi["prochaine_attaque"]:
		moi["prochaine_attaque"] += moi["cr"]["intervalle"] / (Data.VOUIVRE_FURIE if moi["furie"] else 1.0) * (Data.BASTION_LENTEUR if moi["phase"] == "rempart" else 1.0) * (Data.SCEAU_LENTEUR if moi["cr"].get("elite", "") == "sceau" else 1.0)
		origine = "~attaque"
		_compter(moi["cote"], "activations", 1.0)
		_evenement(moi, {"type": "attaque"})
		moi["coups"] = moi.get("coups", 0) + 1
		if _frapper(moi, cible, moi["cr"]["attaque"]):
			var tous: int = moi["cr"]["stigmate_tous"]
			if tous > 0 and moi["coups"] % tous == 0:
				_maudire(moi, cible, "stigmate")
				_relique(moi, "aiguille")
			if moi["cr"]["brulure_attaque"] > 0.0:
				_bruler(moi, cible, moi["cr"]["brulure_attaque"])
				_relique(moi, "charbon")
			if moi["cr"]["poison_attaque"] > 0.0:
				_empoisonner(cible, moi["cr"]["poison_attaque"])
				_relique(moi, "baie")
			if moi["cr"]["givre_attaque"] > 0.0:
				_givrer(moi, cible, moi["cr"]["givre_attaque"])
				_relique(moi, "flocon")
			# signatures des essences
			var sig: Dictionary = moi["cr"].get("signatures", {})
			for e in sig:
				_signature(moi, cible, e, sig[e])
	for s in moi["sorts"]:
		if h < s["prochain"]:
			continue
		s["prochain"] += _recharge(moi, s)
		origine = s["id"]
		_lancer(moi, cible, s)

# Un sort qui part. renfort multiplie ses degats ; un echo (Chrysalide, Oeil du
# Zenith) ne se repete pas et ne cree pas d'Illusion.
func _lancer(moi: Dictionary, cible: Dictionary, s: Dictionary, renfort := 1.0, echo := false) -> void:
	_compter(moi["cote"], "activations", 1.0, s["id"])
	var qui: String = moi["cr"]["nom"] + (" : le cavalier" if s["cavalier"] else "")
	_noter("%s lance %s." % [qui, s["nom"]])
	var coups: int = s["coups"] + (int(moi["eventail"]) if s["coups_par_eventail"] else 0)
	_evenement(moi, {"type": "sort", "nom": s["nom"], "cavalier": s["cavalier"],
		"element": s["element"], "famille": s["famille"], "coups": coups})
	if s["bouclier"] > 0.0:
		_proteger(moi, s["bouclier"] * renfort)
		_evenement(moi, {"type": "bouclier", "valeur": s["bouclier"] * renfort})
	var etait_gele := _gele(cible)
	# Faux de la Nuit profonde : consume les maledictions de la cible
	var festin := 0.0
	if s["consume_maledictions"]:
		festin = _nb_maledictions(cible) * Data.FESTIN_DEGATS
		cible["maledictions"].clear()
	var touche := false
	moi["dernier_crit"] = false
	for k in coups:
		var degats: float = s["degats"] + festin + s["par_eclat"] * moi["eclat_jauge"]
		if s["degats_epines"]:
			degats += moi["cr"]["epines"]
		if s["cavalier"]:
			degats *= 1.0 + moi["eventail"] * Data.EVENTAIL_BONUS
		degats *= (1.0 + s["par_malediction"] * _nb_maledictions(cible)) * renfort
		if _gele(cible):
			degats *= s["contre_gel"]
		touche = _frapper(moi, cible, degats, s["perce"]) or touche
	# Lame rousse : un crit la rapproche
	if moi["dernier_crit"] and s["crit_recharge"] > 0.0:
		s["prochain"] -= s["crit_recharge"]
	if coups == 0 or touche:
		if s["poison"] > 0.0:
			_empoisonner(cible, s["poison"])
		if s["givre"] > 0.0:
			_givrer(moi, cible, s["givre"])
		if s["prolonge_gel"] > 0.0 and etait_gele and _gele(cible):
			cible["gele_jusqu"] += s["prolonge_gel"]
		if s["brulure"] > 0.0:
			_bruler(moi, cible, s["brulure"])
		if s["malediction"] != "":
			_maudire(moi, cible, s["malediction"])
		for n in s["maudit_manquante"]:
			var manquantes: Array = Data.MALEDICTIONS.filter(func(nom): return _charges(cible, nom) == 0)
			if not manquantes.is_empty():
				_maudire(moi, cible, manquantes[0])
		if s["soin"] > 0.0:
			_soigner(moi, cible, s["soin"])
			_evenement(moi, {"type": "soin"})
		if s["eclat_moitie"] and moi["cr"]["eclat"] and moi["eclat_jauge"] >= _seuil_eclat(moi) / 2.0:
			moi["eclat_jauge"] = 0.0
			_eclat(moi, cible)
	if s["arcane"] > 0.0:
		_arcane(moi, cible, s["arcane"] * renfort)
	if s["illusions"] > 0:
		_gagner_illusions(moi, s["illusions"])
	if s["eclate_illusions"] > 0.0:
		var n: int = moi["illusions"]
		moi["illusions"] = 0
		for k in n:
			_arcane(moi, cible, s["eclate_illusions"] * renfort)
	if s["esquive_temp"] > 0.0:
		moi["esquive_temp"] = s["esquive_temp"]
		moi["esquive_temp_jusqu"] = t + Data.BOURRASQUE_DUREE
		_evenement(moi, {"type": "bourrasque"})
	if s["roue"] > 0.0:
		for a in moi["sorts"]:
			if a["cavalier"] and a["prochain"] != INF:
				a["prochain"] -= s["roue"]
	if s["combustion"] > 0.0:
		_combustion(moi, cible, s["combustion"], s["combustion"] >= 1.0, s["combustion_mult"])
	if s["cavalier"]:
		_arme_lancee(moi, cible, s)
	_signature(moi, cible, s["element"], s.get("signature", 0.0))
	if echo:
		return
	# Papillon : chaque sort de la monture cree une Illusion ; Phalene : chacune tire avec lui
	if moi["cr"]["illusions"] and not s["cavalier"]:
		_gagner_illusions(moi, 1)
	if moi["cr"]["phalene"] and moi["illusions"] > 0:
		_relique(moi, "phalene")
		var av := _depuis("phalene")
		for k in moi["illusions"]:
			_arcane(moi, cible, Data.ILLUSION_ARCANE)
		origine = av
	if moi["cr"]["chrysalide"]:
		_relique(moi, "chrysalide")
		_lancer(moi, cible, s, renfort * Data.CHRYSALIDE_PART, true)
	elif s["cavalier"] and moi["cr"]["zenith"] and moi["eventail"] >= Data.ZENITH_SEUIL:
		_relique(moi, "oeil_zenith")
		_lancer(moi, cible, s, renfort, true)

# Paon : une arme lancee donne de l'Eventail. Ecu dore : du bouclier ; Miroir
# d'ocelle : des degats selon l'Eventail.
func _arme_lancee(moi: Dictionary, cible: Dictionary, s: Dictionary) -> void:
	var cr: Dictionary = moi["cr"]
	if cr["eventail"]:
		moi["eventail"] = minf(moi["eventail"] + s["eventail_gain"], cr["eventail_max"])
		# Couronne de midi : l'Eventail au-dessus de 10
		if moi["eventail"] > Data.EVENTAIL_MAX:
			_relique(moi, "couronne_midi")
	if cr["ecu"] > 0.0:
		_relique(moi, "ecu_dore")
		_proteger(moi, cr["ecu"], "ecu_dore")
	if cr["miroir_ocelle"] > 0.0 and moi["eventail"] > 0.0:
		_relique(moi, "miroir_ocelle")
		var avant := _depuis("miroir_ocelle")
		_blesser(cible, cr["miroir_ocelle"] * moi["eventail"], moi)
		origine = avant

# Signature de dynastie : le petit effet de l'element e (un sort qui part, ou
# les essences a chaque attaque).
func _signature(moi: Dictionary, cible: Dictionary, e: String, v: float) -> void:
	if v <= 0.0:
		return
	match e:
		"feu":
			_bruler(moi, cible, v)
		"nature":
			_empoisonner(cible, v)
		"glace":
			_givrer(moi, cible, v)
		"nuit":
			_infliger(cible, v)
			_soigner(moi, cible, v)
		"aube":
			_soigner(moi, cible, v)
		"crepuscule":
			_arcane(moi, cible, v)
		"automne":
			_blesser(cible, v, moi)
		"jour":
			_proteger(moi, v)

# --- Ete -----------------------------------------------------------------------

# Brulure : n charges qui s'eteignent seules (jamais avec l'Oeuf). Eclat
# d'obsidienne : toutes les N charges posees, une combustion partielle.
func _bruler(moi: Dictionary, cible: Dictionary, n: float) -> void:
	n = minf(n, Data.BRULURE_MAX - _brulure(cible))
	if n <= 0.0:
		return
	var fin: float = INF if moi["cr"]["oeuf"] else t + Data.BRULURE_DUREE + moi["cr"]["brulure_duree"]
	cible["brulures"].append({"debut": t, "fin": fin, "q": n})
	var seuil: float = moi["cr"]["obsidienne"]
	if seuil > 0.0:
		moi["brulures_posees"] += n
		if moi["brulures_posees"] >= seuil:
			moi["brulures_posees"] -= seuil
			_relique(moi, "obsidienne")
			var avant := _depuis("obsidienne")
			_combustion(moi, cible, 0.5, false, 1.0)
			origine = avant

# Combustion : consume une part des brulures de la cible pour des degats immediats
# (qui passent le bouclier, comme la brulure). Coeur de fournaise : la moitie des
# charges consumees reste en place.
func _combustion(moi: Dictionary, cible: Dictionary, part: float, totale: bool, mult: float) -> void:
	part = minf(part, 1.0)
	var consomme := _brulure(cible) * part
	if consomme <= 0.0:
		return
	var retire := part * (0.5 if moi["cr"]["fournaise"] else 1.0)
	if moi["cr"]["fournaise"]:
		# charges de brulure laissees en place
		_relique(moi, "coeur_fournaise", consomme * 0.5)
	for b in cible["brulures"]:
		b["q"] *= 1.0 - retire
	cible["brulures"] = cible["brulures"].filter(func(b): return b["q"] > 0.0)
	var degats := consomme * Data.COMBUSTION_PAR_CHARGE * (Data.COMBUSTION_TOTALE_BONUS if totale else 1.0) * mult
	_infliger(cible, degats, "~combustion")
	_evenement(cible, {"type": "combustion", "totale": totale, "valeur": degats})

# --- frapper, esquiver ------------------------------------------------------------

func _esquive(moi: Dictionary) -> float:
	var e: float = moi["cr"]["esquive"] + (moi["esquive_temp"] if t < moi["esquive_temp_jusqu"] else 0.0)
	return minf(e, Data.ESQUIVE_MAX)

# Une attaque de base ou un coup d'arme. Renvoie true si le coup a touche :
# une esquive ou une Illusion l'arrete (sauf s'il perce).
func _frapper(moi: Dictionary, cible: Dictionary, degats: float, perce := false) -> bool:
	if not perce:
		if cible["esquive_prete"] or (_esquive(cible) > 0.0 and rng.randf() < _esquive(cible)):
			cible["esquive_prete"] = false
			_esquiver(cible, moi)
			return false
		if cible["illusions"] > 0:
			_eclater_illusion(cible, moi)
			return false
	if _gele(cible):
		degats *= moi["cr"]["bonus_gel"]
	# Faiblesse : l'attaquant maudit frappe moins fort.
	# Chauve-souris : plus fort contre une cible maudite.
	var faible := minf(1.0, Data.FAIBLESSE * _charges(moi, "faiblesse"))
	_compter(cible["cote"], "impact", degats * faible, "~faiblesse")
	degats *= 1.0 - faible
	var bonus_nuit: float = moi["cr"]["par_malediction"] * _nb_maledictions(cible)
	# Pacte : la moitie du bonus vient de lui
	if moi["cr"]["pacte"] and bonus_nuit > 0.0:
		_relique(moi, "pacte", degats * bonus_nuit / 2.0)
	degats *= 1.0 + bonus_nuit
	if moi["cr"].get("elite", "") == "vouivre":
		degats *= 1.0 + minf(Data.VOUIVRE_PAR_MALUS * _malus_subis(moi), Data.VOUIVRE_MAX)
		if moi["furie"]:
			degats *= Data.VOUIVRE_FURIE
	# Renard : apres une esquive, crit garanti (x3 avec le Coutelas)
	var mult := 0.0
	if moi["feinte_prete"]:
		moi["feinte_prete"] = false
		mult = Data.COUTELAS_MULT if moi["cr"]["coutelas"] else moi["cr"]["crit_mult"]
	elif moi["cr"]["crit"] > 0.0 and rng.randf() < moi["cr"]["crit"]:
		mult = moi["cr"]["crit_mult"]
	if mult > 0.0:
		# Oeil du chasseur : la part du crit au-dela de x1,75
		if mult > Data.CRIT_MULT and moi["cr"]["crit_mult"] > Data.CRIT_MULT and mult == moi["cr"]["crit_mult"]:
			_relique(moi, "oeil_chasseur", degats * (mult - Data.CRIT_MULT))
		degats *= mult
		moi["dernier_crit"] = true
		_evenement(cible, {"type": "crit"})
		if moi["cr"]["queue"]:
			moi["esquive_prete"] = true
			_relique(moi, "queue_renard")
	_blesser(cible, degats, moi)
	_riposter(cible, moi)
	return true

# Renard : l'esquive prepare un crit ; Bogue de chataigne : contre-attaque.
func _esquiver(moi: Dictionary, attaquant: Dictionary) -> void:
	_evenement(moi, {"type": "esquive"})
	if moi["cr"]["feinte"]:
		moi["feinte_prete"] = true
	if moi["cr"]["bogue"]:
		_relique(moi, "bogue")
		var avant := _depuis("bogue")
		_frapper(moi, attaquant, moi["cr"]["attaque"], true)
		origine = avant

# --- Crepuscule -------------------------------------------------------------------

func _arcane(moi: Dictionary, cible: Dictionary, v: float) -> void:
	v += moi["cr"]["arcane_bonus"]
	_evenement(cible, {"type": "arcane", "valeur": v})
	_blesser(cible, v, moi)

func _gagner_illusions(moi: Dictionary, n: int) -> void:
	var avant: int = moi["illusions"]
	moi["illusions"] = mini(avant + n, moi["cr"]["illusions_max"])
	if moi["illusions"] > avant:
		_evenement(moi, {"type": "illusion", "n": moi["illusions"]})

# Une Illusion encaisse le coup, puis eclate en arcane. Mue : le prochain sort
# part plus tot.
func _eclater_illusion(moi: Dictionary, attaquant: Dictionary) -> void:
	moi["illusions"] -= 1
	var avant := _depuis("~illusion")
	_arcane(moi, attaquant, Data.ILLUSION_ARCANE)
	origine = avant
	if moi["cr"]["mue"]:
		_relique(moi, "mue")
		var proche = null
		for s in moi["sorts"]:
			if s["prochain"] != INF and (proche == null or s["prochain"] < proche["prochain"]):
				proche = s
		if proche != null:
			proche["prochain"] -= Data.MUE_AVANCE

# --- Eclat (Lion) ---------------------------------------------------------------

func _seuil_eclat(moi: Dictionary) -> float:
	return maxf(Data.ECLAT_SEUIL - moi["cr"]["miroir"], Data.ECLAT_SEUIL_MIN)

func _charger_eclat(moi: Dictionary, adverse: Dictionary, n: float) -> void:
	moi["eclat_jauge"] += n
	var seuil := _seuil_eclat(moi)
	while moi["eclat_jauge"] >= seuil:
		moi["eclat_jauge"] -= seuil
		_eclat(moi, adverse)

# Un coup de lumiere. Carillon : il soigne aussi.
func _eclat(moi: Dictionary, adverse: Dictionary) -> void:
	var avant := _depuis("~eclat")
	_evenement(adverse, {"type": "eclat", "valeur": Data.ECLAT_DEGATS})
	_blesser(adverse, Data.ECLAT_DEGATS, moi)
	if moi["cr"]["carillon"] > 0.0:
		_relique(moi, "carillon")
		# sinon, le soin relancait l'Eclat sans fin
		moi["dans_eclat"] = true
		origine = "carillon"
		_soigner(moi, adverse, moi["cr"]["carillon"])
		_evenement(moi, {"type": "soin"})
		moi["dans_eclat"] = false
	origine = avant

# Lanterne du Premier Matin : les degats subis chargent aussi l'Eclat.
func _lanterne(moi: Dictionary, d: float) -> void:
	if moi["cr"]["eclat"] and moi["cr"]["lanterne"] > 0.0 and d > 0.0 and not moi["dans_eclat"]:
		moi["dans_eclat"] = true
		_relique(moi, "lanterne", d * moi["cr"]["lanterne"], true)
		_charger_eclat(moi, cotes[1 - moi["cote"]], d * moi["cr"]["lanterne"])
		moi["dans_eclat"] = false

# --- maledictions -------------------------------------------------------------

func _charges(moi: Dictionary, nom: String) -> int:
	var m = moi["maledictions"].get(nom)
	return m["n"] if m != null and m["fin"] > t else 0

func _nb_maledictions(moi: Dictionary) -> int:
	return Data.MALEDICTIONS.filter(func(nom): return _charges(moi, nom) > 0).size()

# Le Sablier prolonge ; le Grimoire blesse a chaque nouvelle malediction ; le
# Masque rend permanentes les trois quand elles sont toutes posees.
func _maudire(moi: Dictionary, cible: Dictionary, nom: String) -> void:
	var nouvelle := _charges(cible, nom) == 0
	var fin: float = t + Data.MALEDICTION_DUREE + moi["cr"]["sablier"]
	var m = cible["maledictions"].get(nom)
	if m != null and m["fin"] == INF:
		fin = INF
	cible["maledictions"][nom] = {"n": 1, "debut": t, "fin": fin}
	if not nouvelle:
		return
	_evenement(cible, {"type": "malediction", "nom": nom, "n": 1})
	if moi["cr"]["grimoire"] > 0.0:
		_relique(moi, "grimoire")
		var avant := _depuis("grimoire")
		_blesser(cible, moi["cr"]["grimoire"], moi)
		origine = avant
	if moi["cr"]["masque"] and _nb_maledictions(cible) >= Data.MALEDICTIONS.size():
		_relique(moi, "masque")
		for k in cible["maledictions"]:
			cible["maledictions"][k]["fin"] = INF

func _resume_maledictions(moi: Dictionary) -> String:
	var l := []
	for nom in Data.MALEDICTIONS:
		if _charges(moi, nom) > 0:
			l.append(Data.NOMS_MALEDICTION[nom])
	return ", ".join(l)

# Belladone : un combattant empoisonne ne peut plus se soigner.
# Fletrissure : soins reduits.
# Lion : le soin prevu (meme bloque ou reduit) charge l'Eclat ; l'excedent compte double.
func _soigner(moi: Dictionary, adverse: Dictionary, soin: float) -> void:
	if soin <= 0.0:
		return
	if moi["cr"]["eclat"] and not moi["dans_eclat"]:
		var exces := maxf(0.0, soin - maxf(0.0, moi["cr"]["pv_max"] - moi["pv"]))
		_charger_eclat(moi, adverse, (soin - exces) * Data.ECLAT_PAR_SOIN
			+ exces * Data.ECLAT_PAR_EXCES * (1.0 + moi["cr"]["voile_aube"]))
	if moi["poison"] > 0.0 and adverse["cr"]["belladone"]:
		_relique(adverse, "belladone", soin, true)
		return
	var fletri := minf(1.0, Data.FLETRISSURE * _charges(moi, "fletrissure"))
	_compter(adverse["cote"], "impact", soin * fletri, "~fletrissure")
	soin *= 1.0 - fletri
	var applique := minf(soin, maxf(0.0, moi["cr"]["pv_max"] - moi["pv"]))
	moi["pv"] += applique
	_compter(moi["cote"], "soins", applique)

# --- Printemps --------------------------------------------------------------------

# Ce que declenche un coup recu : epines (qui empoisonnent), Graine du Jardin
# (le poison de l'attaquant agit aussitot), armes de riposte. Ces ripostes passent
# par _blesser : elles ne declenchent rien a leur tour.
func _riposter(moi: Dictionary, attaquant: Dictionary) -> void:
	moi["coups_recus"] += 1
	var avant := _depuis("~epines")
	var cr: Dictionary = moi["cr"]
	if cr["epines"] > 0.0:
		_blesser(attaquant, cr["epines"], moi)
		_evenement(moi, {"type": "epines"})
		if cr["epines_poison"] > 0.0:
			_empoisonner(attaquant, cr["epines_poison"])
			_relique(moi, "liane")
	if cr["graine"] and attaquant["poison"] > 0.0:
		_relique(moi, "graine_jardin")
		_infliger(attaquant, attaquant["poison"] * Data.POISON_DPS_PAR_DOSE, "graine_jardin")
	for s in moi["sorts"]:
		if s["contre"] > 0 and moi["coups_recus"] % s["contre"] == 0:
			origine = s["id"]
			_compter(moi["cote"], "activations", 1.0)
			_blesser(attaquant, s["degats"], moi)
			if s["poison"] > 0.0:
				_empoisonner(attaquant, s["poison"])
			_evenement(moi, {"type": "sort", "nom": s["nom"], "cavalier": true, "element": s["element"], "famille": s["famille"], "coups": 1})
	origine = avant

# Le poison s'empile, jusqu'au plafond.
func _empoisonner(cible: Dictionary, doses: float) -> void:
	cible["poison"] = minf(cible["poison"] + doses, Data.POISON_MAX)

# Stigmate : la cible recoit plus de degats, de toutes les sources.
func _stigmate(cible: Dictionary) -> float:
	return 1.0 + Data.STIGMATE * _charges(cible, "stigmate")

# Le bouclier encaisse avant les PV. Brulure, poison et fatigue passent a travers.
func _blesser(cible: Dictionary, degats: float, source = null) -> void:
	_compter(1 - cible["cote"], "impact", degats * (_stigmate(cible) - 1.0), "~stigmate")
	degats *= _stigmate(cible)
	if cible["phase"] == "resistance":
		degats *= Data.BASTION_RESISTANCE_FRAGILE
	if cible["phase"] == "silence":
		degats *= Data.VOIX_SILENCE_FRAGILE
	if cible["phase"] == "repit":
		degats *= Data.SCEAU_REPIT_FRAGILE
	_rupture(cible, degats)
	var absorbe := minf(cible["bouclier"], degats)
	cible["bouclier"] -= absorbe
	cible["pv"] -= degats - absorbe
	_compter(1 - cible["cote"], "degats", degats)
	_lanterne(cible, degats)

# --- Hiver ------------------------------------------------------------------------

# Givre : des charges qui ralentissent ; au seuil, la cible gele.
func _givrer(moi: Dictionary, cible: Dictionary, charges: float) -> void:
	if _gele(cible):
		return
	cible["givre"] += charges
	if cible["givre"] >= moi["cr"]["gel_seuil"]:
		# Noyau de l'Hiver : un gel qui ne serait pas venu au seuil normal
		if cible["givre"] < Data.GEL_SEUIL:
			_relique(moi, "noyau_hiver")
		_geler(moi, cible)

# Fourrure : gel plus long ; Coeur de banquise : la cible garde la moitie de son
# givre ; Cristal fele : le gel blesse.
func _geler(moi: Dictionary, cible: Dictionary) -> void:
	cible["gele_depuis"] = t
	cible["gele_jusqu"] = t + Data.GEL_DUREE + moi["cr"]["gel_duree"]
	cible["givre"] = cible["givre"] * 0.5 if moi["cr"]["banquise"] else 0.0
	if moi["cr"]["banquise"] and cible["givre"] > 0.0:
		_relique(moi, "coeur_banquise", cible["givre"])
	_evenement(cible, {"type": "gel"})
	_noter("%s gèle." % cible["cr"]["nom"])
	if moi["cr"]["gel_degats"] > 0.0:
		_relique(moi, "cristal")
		var avant := _depuis("cristal")
		_blesser(cible, moi["cr"]["gel_degats"], moi)
		origine = avant

# --- elites -------------------------------------------------------------------

# Charges de malus subis (Vouivre).
func _malus_subis(moi: Dictionary) -> float:
	return _brulure(moi) + moi["givre"] + moi["poison"] / 5.0 + _nb_maledictions(moi)

func _dissiper(moi: Dictionary) -> void:
	moi["poison"] = 0.0
	moi["brulures"].clear()
	moi["givre"] = 0.0
	moi["maledictions"].clear()

# La regle propre a l'elite, a chaque pas.
func _elite(moi: Dictionary, adverse: Dictionary) -> void:
	var e: String = moi["cr"].get("elite", "")
	if e == "":
		return
	var force: float = moi["cr"].get("elite_force", 1.0)
	moi["elite_t"] += Data.PAS
	moi["elite_t2"] += Data.PAS
	match e:
		"sanglier":
			_proteger(moi, Data.SANGLIER_RACINES * force * Data.PAS, "~racines")
			if moi["elite_t"] >= Data.SANGLIER_CHARGE_TOUS:
				moi["elite_t"] = 0.0
				var degats: float = moi["bouclier"] * Data.SANGLIER_CHARGE_MULT
				moi["bouclier"] = 0.0
				_evenement(adverse, {"type": "charge", "valeur": degats})
				var avant := _depuis("~charge")
				_blesser(adverse, degats, moi)
				origine = avant
		"phalene":
			if moi["elite_t"] >= Data.PHALENE_DISSIPE_TOUS:
				moi["elite_t"] = 0.0
				_dissiper(moi)
				_evenement(moi, {"type": "dissipe"})
			if moi["elite_t2"] >= Data.PHALENE_TRAIT_TOUS:
				moi["elite_t2"] = 0.0
				var degats: float = Data.PHALENE_TRAIT * force
				_evenement(adverse, {"type": "trait", "valeur": degats})
				_infliger(adverse, degats, "~trait")
		"bastion":
			_bastion(moi, adverse, force)
		"voix":
			_voix(moi, adverse, force)
		"sceau":
			_sceau(moi, adverse, force)
		"vouivre":
			if not moi["furie"] and moi["pv"] < moi["cr"]["pv_max"] * 0.5:
				moi["furie"] = true
				_dissiper(moi)
				_evenement(moi, {"type": "entraves"})

# Eclat de l'oeil, de 0 a 1 : l'absorbe rapporte au plafond du regard.
func _oeil(moi: Dictionary) -> float:
	if moi["phase"] == "":
		return 0.0
	if moi["cr"].get("elite", "") == "voix":
		return moi["oeil"] / Data.VOIX_YEUX_MAX
	if moi["cr"].get("elite", "") == "sceau":
		return moi["sceaux"] / 2.0
	var plafond: float = Data.BASTION_REGARD_MAX * moi["cr"].get("elite_force", 1.0) / Data.BASTION_REGARD_MULT
	var reserve: float = moi["oeil"] if moi["phase"] == "ouverture" else moi["bouclier"]
	return clampf(reserve / plafond, 0.0, 1.0)

func _bastion(moi: Dictionary, adverse: Dictionary, force: float) -> void:
	if moi["phase"] == "":
		moi["phase"] = "rempart"
		moi["elite_t"] = 0.0
	match moi["phase"]:
		"rempart":
			_proteger(moi, Data.BASTION_REMPART * force * Data.PAS, "~rempart")
			if moi["elite_t"] >= Data.BASTION_REMPART_DUREE:
				moi["phase"] = "ouverture"
				moi["elite_t"] = 0.0
				moi["oeil"] = 0.0
				moi["oeil_debit"] = moi["bouclier"] / Data.BASTION_OUVERTURE_DUREE * Data.PAS
				_evenement(moi, {"type": "ouverture"})
		"ouverture":
			# l'oeil boit le bouclier qui reste : l'entamer affaiblit le regard
			var bu := minf(moi["bouclier"], moi["oeil_debit"])
			moi["bouclier"] -= bu
			moi["oeil"] += bu
			if moi["elite_t"] >= Data.BASTION_OUVERTURE_DUREE:
				var degats := minf(moi["oeil"] * Data.BASTION_REGARD_MULT, Data.BASTION_REGARD_MAX * force)
				moi["oeil"] = 0.0
				_evenement(adverse, {"type": "regard", "valeur": degats})
				var avant := _depuis("~regard")
				_blesser(adverse, degats, moi)
				origine = avant
				moi["phase"] = "resistance"
				moi["elite_t"] = 0.0
				moi["bouclier"] = 0.0
				_evenement(moi, {"type": "resistance"})
		"resistance":
			if moi["elite_t"] >= Data.BASTION_RESISTANCE_DUREE:
				moi["phase"] = "rempart"
				moi["elite_t"] = 0.0

# Voix du Gouffre : nombre d'yeux ouverts rapporte au maximum (pour l'ecran).
# Les yeux sont dans "oeil", la jauge de rupture dans "oeil_debit".
func _voix(moi: Dictionary, adverse: Dictionary, force: float) -> void:
	if moi["phase"] == "":
		moi["phase"] = "eveil"
		moi["elite_t"] = 0.0
		moi["elite_t2"] = 0.0
	match moi["phase"]:
		"eveil":
			if moi["elite_t2"] >= Data.VOIX_OEIL_TOUS and moi["oeil"] < Data.VOIX_YEUX_MAX:
				moi["elite_t2"] = 0.0
				moi["oeil"] += 1.0
				_evenement(moi, {"type": "oeil_ouvert", "n": int(moi["oeil"])})
			if moi["elite_t"] >= Data.VOIX_EVEIL_DUREE:
				moi["phase"] = "communion"
				moi["elite_t"] = 0.0
				moi["oeil_debit"] = 0.0
				_evenement(moi, {"type": "communion"})
		"communion":
			if moi["elite_t"] >= Data.VOIX_COMMUNION_DUREE:
				# la maree noire : une frappe par oeil ouvert, plus une
				var frappes := int(moi["oeil"]) + 1
				_evenement(adverse, {"type": "maree", "n": frappes})
				var avant := _depuis("~maree")
				for k in frappes:
					_blesser(adverse, Data.VOIX_FRAPPE * force, moi)
				origine = avant
				moi["oeil"] = 0.0
				moi["phase"] = "silence"
				moi["elite_t"] = 0.0
				_evenement(moi, {"type": "silence"})
		"silence":
			if moi["elite_t"] >= Data.VOIX_SILENCE_DUREE:
				moi["phase"] = "eveil"
				moi["elite_t"] = 0.0
				moi["elite_t2"] = 0.0

# Dernier Sceau. La phase dit ce qui est libere (gardien, fissure, emprise),
# ou "repit" juste apres un sceau brise.
func _sceau(moi: Dictionary, adverse: Dictionary, force: float) -> void:
	var etats := ["gardien", "fissure", "emprise"]
	if moi["phase"] == "":
		moi["phase"] = "gardien"
		moi["elite_t"] = 0.0
	# un tiers de vie perdu : une plaque se brise, le serpent lutte un instant
	var part: float = moi["pv"] / moi["cr"]["pv_max"]
	if moi["sceaux"] < 2 and part < 1.0 - (moi["sceaux"] + 1) / 3.0:
		moi["sceaux"] += 1
		moi["phase"] = "repit"
		moi["elite_t2"] = 0.0
		moi["elite_t"] = 0.0
		_evenement(moi, {"type": "sceau_brise", "n": moi["sceaux"]})
		return
	if moi["phase"] == "repit":
		if moi["elite_t2"] >= Data.SCEAU_REPIT:
			moi["phase"] = etats[moi["sceaux"]]
			moi["elite_t"] = 0.0
			if moi["sceaux"] == 2:
				moi["emprise_t"] = t
			_evenement(moi, {"type": "sceau_libere", "nom": moi["phase"]})
		return
	# le grand coup, annonce puis porte
	if moi["elite_t"] >= Data.SCEAU_COUP_TOUS - Data.SCEAU_PREPARATION and moi["elite_t"] - Data.PAS < Data.SCEAU_COUP_TOUS - Data.SCEAU_PREPARATION:
		_evenement(moi, {"type": "prepare"})
	if moi["elite_t"] >= Data.SCEAU_COUP_TOUS:
		moi["elite_t"] = 0.0
		var avant := _depuis("~gardien")
		_evenement(adverse, {"type": "grand_coup", "valeur": Data.SCEAU_COUP * force})
		_blesser(adverse, Data.SCEAU_COUP * force, moi)
		if moi["sceaux"] >= 1:
			origine = "~fissure"
			_evenement(adverse, {"type": "fissure", "n": Data.SCEAU_FISSURE_FRAPPES})
			for k in Data.SCEAU_FISSURE_FRAPPES:
				_blesser(adverse, Data.SCEAU_FISSURE * force, moi)
		origine = avant
	# l'Emprise : la machoire etrangere frappe de plus en plus fort
	if moi["sceaux"] >= 2:
		var dps: float = (Data.SCEAU_EMPRISE + (t - moi["emprise_t"]) * Data.SCEAU_EMPRISE_RAMPE) * force
		_infliger(adverse, dps * Data.PAS, "~emprise")

# Pendant la communion, les degats recus remplissent la jauge de rupture :
# chaque palier ferme un oeil.
func _rupture(cible: Dictionary, degats: float) -> void:
	if cible["phase"] != "communion" or cible["oeil"] <= 0.0:
		return
	var palier: float = cible["cr"]["pv_max"] * Data.VOIX_RUPTURE
	cible["oeil_debit"] += degats
	while cible["oeil_debit"] >= palier and cible["oeil"] > 0.0:
		cible["oeil_debit"] -= palier
		cible["oeil"] -= 1.0
		_evenement(cible, {"type": "oeil_ferme", "n": int(cible["oeil"])})

func _subir(moi: Dictionary, adverse: Dictionary) -> void:
	_elite(moi, adverse)
	# regeneration : Lion, Bande de lin
	origine = "~regen"
	if moi["cr"]["regen"] > 0.0 and moi["pv"] > 0.0:
		_soigner(moi, adverse, moi["cr"]["regen"] * Data.PAS)
	if not moi["brulures"].is_empty():
		_infliger(moi, _brulure(moi) * Data.BRULURE_DPS_CHARGE * Data.PAS, "~brulure")
		moi["brulures"] = moi["brulures"].filter(func(b): return b["fin"] > t)
	if moi["poison"] > 0.0:
		_infliger(moi, moi["poison"] * Data.POISON_DPS_PAR_DOSE * Data.PAS, "~poison")
	# Fatigue (mort subite) : des degats croissants, a travers le bouclier
	if t > Data.MORT_SUBITE:
		moi["pv"] -= (t - Data.MORT_SUBITE) * Data.FATIGUE_RAMPE * Data.PAS

# Renaissance (Phenix, et une de plus avec l'Oeuf) : elle consume toutes les
# brulures adverses.
func _mort(moi: Dictionary, adverse: Dictionary) -> bool:
	if moi["pv"] > 0.0:
		return false
	if moi["renaissances"] > 0:
		moi["renaissances"] -= 1
		moi["pv"] = moi["cr"]["pv_max"] * Data.RENAISSANCE_PV
		_evenement(moi, {"type": "renaissance"})
		# Oeuf du Premier Brasier : la seconde renaissance est la sienne
		if moi["cr"]["oeuf"] and moi["renaissances"] == 0:
			_relique(moi, "oeuf_brasier")
		_noter("%s renaît de ses cendres !" % moi["cr"]["nom"])
		var avant := _depuis("~renaissance")
		_combustion(moi, adverse, 1.0, true, 1.0)
		origine = avant
		return false
	return true

# Une essence agit : elle compte une activation a son nom (et son effet si on
# le mesure, dans le champ "impact"), et sa case s'allume dans le Nid de
# l'arene, au plus une fois toutes les 0,3 s.
# continu : un effet de chaque instant (Belladone, Lanterne), sans activations.
func _relique(moi: Dictionary, id: String, impact := 0.0, continu := false) -> void:
	if not continu:
		_compter(moi["cote"], "activations", 1.0, id)
	_compter(moi["cote"], "impact", impact, id)
	if t - moi["flash"].get(id, -1.0) >= 0.3:
		moi["flash"][id] = t
		_evenement(moi, {"type": "relique", "id": id})

func _evenement(moi: Dictionary, e: Dictionary) -> void:
	e["t"] = t
	e["cote"] = moi["cote"]
	evenements.append(e)

func _noter(texte: String) -> void:
	journal.append("[%5.1f s] %s" % [t, texte])
