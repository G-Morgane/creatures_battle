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
#   givre0, givre1, gele0, gele1, braise0, braise1, maledictions0, maledictions1,
#   eclat0, eclat1]) ;
# brule = nombre de charges de brulure, maledictions = texte ("Faiblesse x2, Langueur").
var evenements: Array = []
var images: Array = []
# L'esquive du Vent est un tirage : graine fixe, donc toujours le meme combat.
var rng := RandomNumberGenerator.new()

func _init(a: Dictionary, b: Dictionary) -> void:
	rng.seed = 1
	cotes = [_etat(a, 0), _etat(b, 1)]
	# La Tortue fait venir la fatigue plus tot chez l'adversaire, et la subit moins.
	for i in 2:
		var moi: Dictionary = cotes[i]
		var autre: Dictionary = cotes[1 - i]
		moi["fatigue_debut"] = Data.MORT_SUBITE - (Data.TORTUE_AVANCE_FATIGUE if autre["cr"]["tortue"] else 0.0)
		moi["fatigue_mult"] = Data.TORTUE_FATIGUE_MULT if moi["cr"]["tortue"] else 1.0

func _etat(cr: Dictionary, i: int) -> Dictionary:
	var sorts := []
	for s in cr["sorts"]:
		var copie: Dictionary = s.duplicate()
		# un Contre ne part pas sur minuterie mais sur coups recus
		copie["prochain"] = INF if s["contre"] > 0 else s["recharge"]
		sorts.append(copie)
	return {
		"cr": cr,
		"cote": i,
		"pv": cr["pv_max"],
		"prochaine_attaque": cr["intervalle"],
		"sorts": sorts,
		"brulures": [],            # charges de brulure : [{fin, q}], chacune s'eteint seule
		"braise": 0.0,
		"braise_temp": 0.0,        # Coeur de fournaise
		"braise_temp_jusqu": 0.0,
		"fournaise_faite": false,
		"maledictions": {},        # nom -> {n, fin}
		"horloge_attaque": 0.0,    # comme horloge, mais la Langueur ne ralentit que les attaques
		"attaques": 0,             # Aiguille noire
		"vole": 0.0,               # Grimoire : vie volee depuis la derniere malediction
		"eclat_jauge": 0.0,
		"exces_accumule": 0.0,     # Lanterne : soins excedentaires depuis le dernier Eclat
		"eclats": 0,               # Carillon
		"encensoir_jusqu": 0.0,
		"eclat_pret": false,       # Hache solaire
		"bouclier": cr["bouclier"],
		"poison": 0.0,             # doses
		"epines_bonus": 1.0,       # Coeur de roncier, Graine
		"coups_recus": 0,
		"graine_plantee": false,   # Fleche-graine
		"horloge": 0.0,            # temps propre : ralenti par le givre, arrete par le gel
		"givre": 0.0,              # charges de givre subies
		"gele_jusqu": 0.0,
		"rabais_gel": 0.0,         # Rose des neiges : charges en moins pour geler l'adversaire
		"reforme_a": INF,          # Ecorce de pergelisol
		"esquive": false,
		"renaissances": cr["renaissances"],
	}

# Renvoie 0 ou 1 pour le vainqueur, -1 pour un nul.
func simuler() -> int:
	while t < Data.DUREE_MAX:
		t += Data.PAS
		for i in 2:
			cotes[i]["horloge"] += Data.PAS * _vitesse(cotes[i])
			cotes[i]["horloge_attaque"] += Data.PAS * _vitesse(cotes[i]) * (1.0 - Data.LANGUEUR * _charges(cotes[i], "langueur"))
		for i in 2:
			_agir(cotes[i], cotes[1 - i])
		for i in 2:
			_subir(cotes[i], cotes[1 - i])
		var morts := [_mort(cotes[0], cotes[1]), _mort(cotes[1], cotes[0])]
		images.append([cotes[0]["pv"], cotes[1]["pv"], _brulure(cotes[0]), _brulure(cotes[1]),
			cotes[0]["bouclier"], cotes[1]["bouclier"], cotes[0]["poison"], cotes[1]["poison"],
			cotes[0]["givre"], cotes[1]["givre"], _gele(cotes[0]), _gele(cotes[1]), _braise(cotes[0]), _braise(cotes[1]),
			_resume_maledictions(cotes[0]), _resume_maledictions(cotes[1]),
			cotes[0]["eclat_jauge"], cotes[1]["eclat_jauge"]])
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

# Le givre ralentit le temps propre (attaques et recharges), le gel l'arrete,
# la Braise (hate) l'accelere.
func _vitesse(moi: Dictionary) -> float:
	if _gele(moi):
		return 0.0
	return (1.0 - minf(moi["givre"] * Data.GIVRE_RALENTI, Data.RALENTI_MAX)) * (1.0 + _braise(moi) * Data.HATE_PAR_BRAISE)

func _braise(moi: Dictionary) -> float:
	return moi["braise"] + (moi["braise_temp"] if t < moi["braise_temp_jusqu"] else 0.0)

func _brulure(moi: Dictionary) -> float:
	var total := 0.0
	for b in moi["brulures"]:
		total += b["q"]
	return total

func _gele(moi: Dictionary) -> bool:
	return t < moi["gele_jusqu"]

func _agir(moi: Dictionary, cible: Dictionary) -> void:
	var h: float = moi["horloge"]
	if moi["horloge_attaque"] >= moi["prochaine_attaque"]:
		moi["prochaine_attaque"] += moi["cr"]["intervalle"]
		_evenement(moi, {"type": "attaque"})
		var degats: float = moi["cr"]["attaque"]
		if _brulure(cible) > 0.0:
			degats += moi["cr"]["degats_en_feu"]
		moi["attaques"] += 1
		if _frapper(moi, cible, degats, moi["cr"]["vol_de_vie"]):
			var tous: int = moi["cr"]["faiblesse_tous"]
			if tous > 0 and moi["attaques"] % tous == 0:
				_maudire(moi, cible, "faiblesse")
			# Pacte : sous trois maledictions, chaque attaque draine en plus (passe le bouclier)
			if moi["cr"]["pacte"] > 0.0 and _nb_maledictions(cible) == Data.MALEDICTIONS.size():
				cible["pv"] -= moi["cr"]["pacte"]
				_soigner(moi, cible, moi["cr"]["pacte"])
			if moi["cr"]["brulure_attaque"] > 0.0:
				_bruler(moi, cible, moi["cr"]["brulure_attaque"])
			if moi["cr"]["poison_attaque"] > 0.0:
				_empoisonner(cible, moi["cr"]["poison_attaque"])
			if moi["cr"]["givre_attaque"] > 0.0:
				_givrer(moi, cible, moi["cr"]["givre_attaque"])
	for s in moi["sorts"]:
		if h < s["prochain"]:
			continue
		s["prochain"] += s["recharge"]
		_lancer(moi, cible, s)

# Un sort qui part. renfort multiplie ses degats (tir de renaissance).
func _lancer(moi: Dictionary, cible: Dictionary, s: Dictionary, renfort := 1.0) -> void:
	if s["esquive"]:
		moi["esquive"] = true
		_evenement(moi, {"type": "voile"})
		_noter("%s se voile." % moi["cr"]["nom"])
		return
	var qui: String = moi["cr"]["nom"] + (" : le cavalier" if s["cavalier"] else "")
	_noter("%s lance %s." % [qui, s["nom"]])
	_evenement(moi, {"type": "sort", "nom": s["nom"], "cavalier": s["cavalier"],
		"element": s["element"], "coups": s["coups"]})
	if s["bouclier"] > 0.0:
		moi["bouclier"] += s["bouclier"]
		_evenement(moi, {"type": "bouclier", "valeur": s["bouclier"]})
	var touche := false
	# Faux de la Nuit profonde : consume les maledictions de la cible
	var festin := 0.0
	if s["consume_maledictions"]:
		for nom in cible["maledictions"]:
			festin += _charges(cible, nom) * Data.FESTIN_DEGATS
		cible["maledictions"].clear()
	if s["fracas"] and moi["bouclier"] > 0.0:
		# Fracas : le Loup brise son propre bouclier et frappe avec
		s["bonus_fracas"] = moi["bouclier"]
		moi["bouclier"] = 0.0
		_briser(moi, cible)
	for k in s["coups"]:
		var degats: float = s["degats"] * renfort
		if s["apres_eclat"] and moi["eclat_pret"]:
			degats *= 2.0
		if s["achever_seuil"] > 0.0 and cible["pv"] < cible["cr"]["pv_max"] * s["achever_seuil"]:
			degats *= s["achever_mult"]
		if s["execution"] and cible["pv"] < cible["cr"]["pv_max"] * Data.SEUIL_EXECUTION:
			degats *= 2.0
		if s["degats_epines"]:
			degats += moi["cr"]["epines"] * moi["epines_bonus"]
		degats += s["par_poison"] * cible["poison"] + s.get("bonus_fracas", 0.0) + festin
		degats *= 1.0 + s["par_malediction"] * _nb_maledictions(cible)
		if s["double_ralenti"] and (cible["givre"] > 0.0 or _gele(cible)):
			degats *= 2.0
		if s["brise_gel"] and _gele(cible):
			degats *= 4.0
			cible["gele_jusqu"] = t
			_evenement(cible, {"type": "brise_gel"})
		touche = _frapper(moi, cible, degats, s["vol_de_vie"] + (0.5 if festin > 0.0 else 0.0), s["perce"]) or touche
	s.erase("bonus_fracas")
	if s["coups"] == 0 or touche:
		if s["poison"] > 0.0:
			_empoisonner(cible, s["poison"])
		if s["graine"]:
			cible["graine_plantee"] = true
		if s["givre"] > 0.0:
			_givrer(moi, cible, s["givre"])
		if s["brulure"] > 0.0:
			_bruler(moi, cible, s["brulure"])
		if s["malediction"] != "":
			_maudire(moi, cible, s["malediction"])
		if s["soin"] > 0.0:
			_soigner(moi, cible, s["soin"])
		if s["charge_eclat"] > 0.0 and moi["cr"]["eclat"]:
			_charger_eclat(moi, cible, s["charge_eclat"])
	if s["apres_eclat"]:
		moi["eclat_pret"] = false
	if s["eclat_tous"] > 0:
		s["tirs"] = s.get("tirs", 0) + 1
		if s["tirs"] % s["eclat_tous"] == 0:
			_eclat(moi, cible)
	if s["combustion"] > 0.0:
		_combustion(moi, cible, s["combustion"], false, s["braise"])
	if s["combustion_affaiblie"] and cible["pv"] < cible["cr"]["pv_max"] * 0.5:
		_combustion(moi, cible, 1.0, true, 1.0)
	if s["combustion_tous"] > 0:
		s["tirs"] = s.get("tirs", 0) + 1
		if s["tirs"] % s["combustion_tous"] == 0:
			_combustion(moi, cible, 1.0, true, 1.0)

# Brulure : n charges qui s'eteignent seules ; la Resine les double quand on va mal.
func _bruler(moi: Dictionary, cible: Dictionary, n: float) -> void:
	if moi["cr"]["resine"] and moi["pv"] < moi["cr"]["pv_max"] * Data.RESINE_SEUIL:
		n *= 2.0
	n = minf(n, Data.BRULURE_MAX - _brulure(cible))
	if n > 0.0:
		cible["brulures"].append({"fin": t + Data.BRULURE_DUREE, "q": n})

# Combustion : consume une part des brulures de la cible pour des degats immediats
# (qui passent le bouclier, comme la brulure), donne de la Braise et soigne
# avec la Cendre tiede et la Fleur des cendres.
func _combustion(moi: Dictionary, cible: Dictionary, part: float, totale: bool, braise: float) -> void:
	var consomme := _brulure(cible) * part
	if consomme <= 0.0:
		return
	if part >= 1.0:
		cible["brulures"].clear()
	else:
		for b in cible["brulures"]:
			b["q"] *= 1.0 - part
	var degats := consomme * Data.COMBUSTION_PAR_CHARGE * (Data.COMBUSTION_TOTALE_BONUS if totale else 1.0)
	cible["pv"] -= degats
	moi["braise"] = minf(moi["braise"] + braise, Data.BRAISE_MAX)
	_soigner(moi, cible, moi["cr"]["combustion_soin"] + moi["cr"]["soin_par_charge"] * consomme)
	_evenement(cible, {"type": "combustion", "totale": totale, "valeur": degats})

# Renvoie true si le coup a touche.
func _frapper(moi: Dictionary, cible: Dictionary, degats: float, vol: float, perce := false) -> bool:
	if cible["esquive"] and not perce:
		cible["esquive"] = false
		_evenement(cible, {"type": "esquive"})
		_noter("%s esquive." % cible["cr"]["nom"])
		return false
	if not perce and cible["cr"]["esquive"] > 0.0 and rng.randf() < cible["cr"]["esquive"]:
		_evenement(cible, {"type": "esquive"})
		if cible["cr"]["eclair"]:
			# le Cheval riposte : l'eclair ne s'esquive pas
			_blesser(moi, Data.ECLAIR_DEGATS, cible)
			_evenement(cible, {"type": "eclair"})
		return false
	if _gele(cible):
		degats *= moi["cr"]["bonus_gel"]
	# Faiblesse : l'attaquant maudit frappe moins fort.
	# Chauve-souris : plus fort contre une cible maudite.
	degats *= maxf(0.0, 1.0 - Data.FAIBLESSE * _charges(moi, "faiblesse"))
	degats *= 1.0 + moi["cr"]["par_malediction"] * _nb_maledictions(cible)
	if moi["cr"]["crit"] > 0.0 and rng.randf() < moi["cr"]["crit"]:
		degats *= Data.CRIT_MULT
		_evenement(cible, {"type": "crit"})
		if moi["cr"]["crit_fletrissure"]:
			_maudire(moi, cible, "fletrissure")
		if moi["cr"]["crit_malediction"]:
			_maudire(moi, cible, Data.MALEDICTIONS[rng.randi() % Data.MALEDICTIONS.size()])
	_blesser(cible, degats, moi)
	# Masque du festin : plus de vol de vie par malediction differente
	vol += moi["cr"]["vol_par_malediction"] * _nb_maledictions(cible)
	_soigner(moi, cible, degats * vol)
	_riposter(cible, moi)
	return true

# --- Eclat (Lion) ---------------------------------------------------------------

func _charger_eclat(moi: Dictionary, adverse: Dictionary, n: float) -> void:
	moi["eclat_jauge"] += n
	var seuil := maxf(Data.ECLAT_SEUIL - moi["cr"]["miroir"], Data.ECLAT_SEUIL_MIN)
	while moi["eclat_jauge"] >= seuil:
		moi["eclat_jauge"] -= seuil
		_eclat(moi, adverse)

# Un coup de lumiere. Prisme : plus fort ; Lanterne : ajoute l'excedent accumule ;
# Encensoir : regeneration renforcee un moment ; Carillon : un gros soin tous les 3.
func _eclat(moi: Dictionary, adverse: Dictionary) -> void:
	var degats: float = Data.ECLAT_DEGATS + moi["cr"]["prisme"] + moi["cr"]["lanterne"] * moi["exces_accumule"]
	moi["exces_accumule"] = 0.0
	_evenement(adverse, {"type": "eclat", "valeur": degats})
	_blesser(adverse, degats, moi)
	moi["eclats"] += 1
	moi["eclat_pret"] = true
	if moi["cr"]["encensoir"] > 0.0:
		moi["encensoir_jusqu"] = t + Data.ENCENSOIR_DUREE
	if moi["cr"]["carillon"] > 0.0 and moi["eclats"] % Data.CARILLON_TOUS == 0:
		_soigner(moi, adverse, moi["cr"]["carillon"])

# --- maledictions -------------------------------------------------------------

func _charges(moi: Dictionary, nom: String) -> int:
	var m = moi["maledictions"].get(nom)
	return m["n"] if m != null and m["fin"] > t else 0

func _nb_maledictions(moi: Dictionary) -> int:
	return Data.MALEDICTIONS.filter(func(nom): return _charges(moi, nom) > 0).size()

# Le Sablier prolonge, le Chapelet permet d'empiler jusqu'a 3 charges.
func _maudire(moi: Dictionary, cible: Dictionary, nom: String) -> void:
	var fin: float = t + Data.MALEDICTION_DUREE + moi["cr"]["sablier"]
	var maxi_n := Data.CHAPELET_CHARGES if moi["cr"]["chapelet"] else 1
	var avant := _charges(cible, nom)
	var n := mini(avant + 1, maxi_n)
	cible["maledictions"][nom] = {"n": n, "fin": fin}
	# un simple renouvellement ne s'affiche pas
	if n > avant:
		_evenement(cible, {"type": "malediction", "nom": nom, "n": n})

func _resume_maledictions(moi: Dictionary) -> String:
	var l := []
	for nom in Data.MALEDICTIONS:
		var n := _charges(moi, nom)
		if n > 0:
			l.append(Data.NOMS_MALEDICTION[nom] + (" x%d" % n if n > 1 else ""))
	return ", ".join(l)

# Belladone : un combattant empoisonne ne peut plus se soigner.
# Fletrissure : soins reduits. Grimoire : la vie volee finit par maudire.
# Lion : le soin prevu (meme bloque ou reduit) charge l'Eclat ; l'excedent compte double.
# Vasque de rosee : l'excedent reel devient du bouclier.
func _soigner(moi: Dictionary, adverse: Dictionary, soin: float) -> void:
	if soin <= 0.0:
		return
	if moi["cr"]["eclat"]:
		var exces := maxf(0.0, soin - maxf(0.0, moi["cr"]["pv_max"] - moi["pv"]))
		moi["exces_accumule"] += exces
		_charger_eclat(moi, adverse, (soin - exces) * Data.ECLAT_PAR_SOIN
			+ exces * Data.ECLAT_PAR_EXCES * (1.0 + moi["cr"]["voile_aube"]))
	if moi["poison"] > 0.0 and adverse["cr"]["belladone"]:
		return
	soin *= maxf(0.0, 1.0 - Data.FLETRISSURE * _charges(moi, "fletrissure"))
	var applique := minf(soin, maxf(0.0, moi["cr"]["pv_max"] - moi["pv"]))
	moi["pv"] += applique
	if moi["cr"]["vasque"] > 0.0 and soin > applique:
		moi["bouclier"] += (soin - applique) * moi["cr"]["vasque"]
	if moi["cr"]["grimoire"] > 0.0:
		moi["vole"] += soin
		if moi["vole"] >= moi["cr"]["grimoire"]:
			moi["vole"] -= moi["cr"]["grimoire"]
			var manquantes: Array = Data.MALEDICTIONS.filter(func(nom): return _charges(adverse, nom) == 0)
			if not manquantes.is_empty():
				_maudire(moi, adverse, manquantes[0])

# Ce que declenche un coup recu : epines (et Liane, Graine, Coeur), Gousse, Contre.
# Ces ripostes passent par _blesser : elles ne declenchent rien a leur tour.
func _riposter(moi: Dictionary, attaquant: Dictionary) -> void:
	moi["coups_recus"] += 1
	var cr: Dictionary = moi["cr"]
	if cr["epines"] > 0.0:
		_blesser(attaquant, cr["epines"] * moi["epines_bonus"], moi)
		_evenement(moi, {"type": "epines"})
		if cr["epines_poison"] > 0.0:
			_empoisonner(attaquant, cr["epines_poison"])
		if cr["graine"]:
			_empoisonner(attaquant, 1.0)
		if cr["coeur"]:
			moi["epines_bonus"] = minf(moi["epines_bonus"] + Data.COEUR_PAR_RIPOSTE, Data.EPINES_BONUS_MAX)
	if cr["gousse"] > 0.0 and moi["coups_recus"] % Data.GOUSSE_COUPS == 0:
		_blesser(attaquant, cr["gousse"] * moi["epines_bonus"], moi)
		_evenement(moi, {"type": "salve"})
	for s in moi["sorts"]:
		if s["contre"] > 0 and moi["coups_recus"] % s["contre"] == 0:
			_blesser(attaquant, s["degats"] + s["par_epine"] * cr["epines"] * moi["epines_bonus"], moi)
			_evenement(moi, {"type": "sort", "nom": s["nom"], "cavalier": true, "element": s["element"], "coups": 1})

# Le poison s'empile (plafond) ; une Fleche-graine plantee blesse a chaque dose recue.
func _empoisonner(cible: Dictionary, doses: float) -> void:
	cible["poison"] = minf(cible["poison"] + doses, Data.POISON_MAX)
	if cible["graine_plantee"]:
		_blesser(cible, doses * Data.GRAINE_DEGATS_PAR_DOSE)

# Le bouclier encaisse avant les PV. Brulure et fatigue passent a travers.
# source : qui frappe ; un bouclier brise par un coup declenche les effets de bris.
func _blesser(cible: Dictionary, degats: float, source = null) -> void:
	var avant: float = cible["bouclier"]
	var absorbe := minf(avant, degats)
	cible["bouclier"] -= absorbe
	cible["pv"] -= degats - absorbe
	# Poupee cousue : renvoie une part des degats a un adversaire maudit
	if source != null and cible["cr"]["renvoi"] > 0.0 and _nb_maledictions(source) > 0:
		source["pv"] -= degats * cible["cr"]["renvoi"]
	if avant > 0.0 and cible["bouclier"] <= 0.0 and source != null:
		_briser(cible, source)

# Bouclier brise : Eclat de givre, Cristal fele, Ecorce, Rose des neiges, Noyau.
# Ces ripostes peuvent briser le bouclier adverse a leur tour : la chaine
# s'arrete d'elle-meme, un bouclier brise vaut zero.
func _briser(moi: Dictionary, source: Dictionary) -> void:
	var cr: Dictionary = moi["cr"]
	_evenement(moi, {"type": "bris"})
	if cr["bris_degats"] > 0.0:
		_blesser(source, cr["bris_degats"], moi)
	if cr["bris_givre"] > 0.0:
		_givrer(moi, source, cr["bris_givre"])
	if cr["reforme"] > 0.0:
		moi["reforme_a"] = t + Data.REFORME_DELAI
	if cr["rose"]:
		moi["rabais_gel"] = minf(moi["rabais_gel"] + Data.ROSE_RABAIS, Data.GEL_SEUIL - Data.GEL_SEUIL_MIN)
	if cr["nova"] > 0.0:
		_evenement(moi, {"type": "nova"})
		_blesser(source, cr["nova"], moi)
		if source["givre"] > 0.0 and not _gele(source):
			_geler(moi, source)

# Givre : des charges qui ralentissent ; au seuil (moins la Rose), la cible gele.
func _givrer(moi: Dictionary, cible: Dictionary, charges: float) -> void:
	if _gele(cible):
		return
	cible["givre"] += charges
	if cible["givre"] >= maxf(Data.GEL_SEUIL - moi["rabais_gel"], Data.GEL_SEUIL_MIN):
		_geler(moi, cible)

func _geler(moi: Dictionary, cible: Dictionary) -> void:
	cible["gele_jusqu"] = t + Data.GEL_DUREE
	cible["givre"] = 0.0
	moi["rabais_gel"] = 0.0
	_evenement(cible, {"type": "gel"})
	_noter("%s gèle." % cible["cr"]["nom"])
	if moi["cr"]["gel_bouclier"] > 0.0:
		moi["bouclier"] += moi["cr"]["gel_bouclier"]
		_evenement(moi, {"type": "bouclier", "valeur": moi["cr"]["gel_bouclier"]})

# Brulure, poison et fatigue passent a travers le bouclier.
func _subir(moi: Dictionary, adverse: Dictionary) -> void:
	# regeneration : Lion, Bande de lin sous la moitie de sa vie, Encensoir apres un Eclat
	var regen: float = moi["cr"]["regen"]
	if moi["pv"] < moi["cr"]["pv_max"] * Data.BANDE_SEUIL:
		regen += moi["cr"]["bande"]
	if t < moi["encensoir_jusqu"]:
		regen += moi["cr"]["encensoir"]
	if regen > 0.0 and moi["pv"] > 0.0:
		_soigner(moi, adverse, regen * Data.PAS)
	if not moi["brulures"].is_empty():
		moi["pv"] -= _brulure(moi) * Data.BRULURE_DPS_CHARGE * Data.PAS
		moi["brulures"] = moi["brulures"].filter(func(b): return b["fin"] > t)
	# Coeur de fournaise : une fois, en passant sous la moitie de sa vie
	if moi["cr"]["fournaise"] and not moi["fournaise_faite"] and moi["pv"] < moi["cr"]["pv_max"] * Data.FOURNAISE_SEUIL:
		moi["fournaise_faite"] = true
		_combustion(moi, adverse, 1.0, true, 1.0)
		moi["braise_temp"] = Data.FOURNAISE_BRAISE
		moi["braise_temp_jusqu"] = t + Data.FOURNAISE_DUREE
	if t >= moi["reforme_a"]:
		moi["reforme_a"] = INF
		moi["bouclier"] += moi["cr"]["reforme"]
		_evenement(moi, {"type": "bouclier", "valeur": moi["cr"]["reforme"]})
	if moi["poison"] > 0.0:
		moi["pv"] -= moi["poison"] * Data.POISON_DPS_PAR_DOSE * Data.PAS
		# Graine : tant que l'adversaire est empoisonne, les epines poussent
		if adverse["cr"]["graine"]:
			adverse["epines_bonus"] = minf(adverse["epines_bonus"] + Data.GRAINE_POUSSE * Data.PAS, Data.EPINES_BONUS_MAX)
	if t > moi["fatigue_debut"]:
		moi["pv"] -= (t - moi["fatigue_debut"]) * Data.FATIGUE_RAMPE * moi["fatigue_mult"] * Data.PAS

# Renaissance : l'Oeuf en ajoute une et la fait suivre d'une combustion totale ;
# le Baton du Premier Brasier tire aussitot, renforce.
func _mort(moi: Dictionary, adverse: Dictionary) -> bool:
	if moi["pv"] > 0.0:
		return false
	if moi["renaissances"] > 0:
		moi["renaissances"] -= 1
		moi["pv"] = moi["cr"]["pv_max"] * Data.RENAISSANCE_PV
		_evenement(moi, {"type": "renaissance"})
		_noter("%s renaît de ses cendres !" % moi["cr"]["nom"])
		if moi["cr"]["oeuf"]:
			_combustion(moi, adverse, 1.0, true, 1.0)
		for s in moi["sorts"]:
			if s["tir_renaissance"]:
				_lancer(moi, adverse, s, 2.0)
		return false
	return true

func _evenement(moi: Dictionary, e: Dictionary) -> void:
	e["t"] = t
	e["cote"] = moi["cote"]
	evenements.append(e)

func _noter(texte: String) -> void:
	journal.append("[%5.1f s] %s" % [t, texte])
