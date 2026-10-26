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
#   givre0, givre1, gele0, gele1]).
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
		"brulure": 0.0,
		"brulure_force": 0.0,
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
		"renaissance": cr["renaissance"],
	}

# Renvoie 0 ou 1 pour le vainqueur, -1 pour un nul.
func simuler() -> int:
	while t < Data.DUREE_MAX:
		t += Data.PAS
		for i in 2:
			cotes[i]["horloge"] += Data.PAS * _vitesse(cotes[i])
		for i in 2:
			_agir(cotes[i], cotes[1 - i])
		for i in 2:
			_subir(cotes[i], cotes[1 - i])
		var morts := [_mort(cotes[0]), _mort(cotes[1])]
		images.append([cotes[0]["pv"], cotes[1]["pv"], cotes[0]["brulure"] > 0.0, cotes[1]["brulure"] > 0.0,
			cotes[0]["bouclier"], cotes[1]["bouclier"], cotes[0]["poison"], cotes[1]["poison"],
			cotes[0]["givre"], cotes[1]["givre"], _gele(cotes[0]), _gele(cotes[1])])
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

# Le givre ralentit le temps propre (attaques et recharges), le gel l'arrete.
func _vitesse(moi: Dictionary) -> float:
	if _gele(moi):
		return 0.0
	return 1.0 - minf(moi["givre"] * Data.GIVRE_RALENTI, Data.RALENTI_MAX)

func _gele(moi: Dictionary) -> bool:
	return t < moi["gele_jusqu"]

func _agir(moi: Dictionary, cible: Dictionary) -> void:
	var h: float = moi["horloge"]
	if h >= moi["prochaine_attaque"]:
		moi["prochaine_attaque"] += moi["cr"]["intervalle"]
		_evenement(moi, {"type": "attaque"})
		if _frapper(moi, cible, moi["cr"]["attaque"], moi["cr"]["vol_de_vie"]):
			if moi["cr"]["poison_attaque"] > 0.0:
				_empoisonner(cible, moi["cr"]["poison_attaque"])
			if moi["cr"]["givre_attaque"] > 0.0:
				_givrer(moi, cible, moi["cr"]["givre_attaque"])
	for s in moi["sorts"]:
		if h < s["prochain"]:
			continue
		s["prochain"] += s["recharge"]
		if s["esquive"]:
			moi["esquive"] = true
			_evenement(moi, {"type": "voile"})
			_noter("%s se voile." % moi["cr"]["nom"])
			continue
		var qui: String = moi["cr"]["nom"] + (" : le cavalier" if s["cavalier"] else "")
		_noter("%s lance %s." % [qui, s["nom"]])
		_evenement(moi, {"type": "sort", "nom": s["nom"], "cavalier": s["cavalier"],
			"element": s["element"], "coups": s["coups"]})
		if s["bouclier"] > 0.0:
			moi["bouclier"] += s["bouclier"]
			_evenement(moi, {"type": "bouclier", "valeur": s["bouclier"]})
		var touche := false
		if s["fracas"] and moi["bouclier"] > 0.0:
			# Fracas : le Loup brise son propre bouclier et frappe avec
			s["bonus_fracas"] = moi["bouclier"]
			moi["bouclier"] = 0.0
			_briser(moi, cible)
		for k in s["coups"]:
			var degats: float = s["degats"]
			if s["execution"] and cible["pv"] < cible["cr"]["pv_max"] * Data.SEUIL_EXECUTION:
				degats *= 2.0
			if s["degats_epines"]:
				degats += moi["cr"]["epines"] * moi["epines_bonus"]
			degats += s["par_poison"] * cible["poison"] + s.get("bonus_fracas", 0.0)
			if s["double_ralenti"] and (cible["givre"] > 0.0 or _gele(cible)):
				degats *= 2.0
			if s["brise_gel"] and _gele(cible):
				degats *= 4.0
				cible["gele_jusqu"] = t
				_evenement(cible, {"type": "brise_gel"})
			touche = _frapper(moi, cible, degats, s["vol_de_vie"], s["perce"]) or touche
		s.erase("bonus_fracas")
		if s["coups"] == 0 or touche:
			if s["poison"] > 0.0:
				_empoisonner(cible, s["poison"])
			if s["graine"]:
				cible["graine_plantee"] = true
			if s["givre"] > 0.0:
				_givrer(moi, cible, s["givre"])
		if s["brulure"] > 0.0:
			cible["brulure"] = Data.BRULURE_DUREE
			cible["brulure_force"] = maxf(cible["brulure_force"], s["brulure"])

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
	_blesser(cible, degats, moi)
	_soigner(moi, cible, degats * vol)
	_riposter(cible, moi)
	return true

# Belladone : un combattant empoisonne ne peut plus se soigner.
func _soigner(moi: Dictionary, adverse: Dictionary, soin: float) -> void:
	if soin <= 0.0 or (moi["poison"] > 0.0 and adverse["cr"]["belladone"]):
		return
	moi["pv"] = min(moi["pv"] + soin, moi["cr"]["pv_max"])

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
	if t >= moi["reforme_a"]:
		moi["reforme_a"] = INF
		moi["bouclier"] += moi["cr"]["reforme"]
		_evenement(moi, {"type": "bouclier", "valeur": moi["cr"]["reforme"]})
	if moi["poison"] > 0.0:
		moi["pv"] -= moi["poison"] * Data.POISON_DPS_PAR_DOSE * Data.PAS
		# Graine : tant que l'adversaire est empoisonne, les epines poussent
		if adverse["cr"]["graine"]:
			adverse["epines_bonus"] = minf(adverse["epines_bonus"] + Data.GRAINE_POUSSE * Data.PAS, Data.EPINES_BONUS_MAX)
	if moi["brulure"] > 0.0:
		moi["brulure"] -= Data.PAS
		moi["pv"] -= Data.BRULURE_DPS * moi["brulure_force"] * Data.PAS
		if moi["brulure"] <= 0.0:
			moi["brulure_force"] = 0.0
	if t > moi["fatigue_debut"]:
		moi["pv"] -= (t - moi["fatigue_debut"]) * Data.FATIGUE_RAMPE * moi["fatigue_mult"] * Data.PAS

func _mort(moi: Dictionary) -> bool:
	if moi["pv"] > 0.0:
		return false
	if moi["renaissance"]:
		moi["renaissance"] = false
		moi["pv"] = moi["cr"]["pv_max"] * Data.RENAISSANCE_PV
		_evenement(moi, {"type": "renaissance"})
		_noter("%s renaît de ses cendres !" % moi["cr"]["nom"])
		return false
	return true

func _evenement(moi: Dictionary, e: Dictionary) -> void:
	e["t"] = t
	e["cote"] = moi["cote"]
	evenements.append(e)

func _noter(texte: String) -> void:
	journal.append("[%5.1f s] %s" % [t, texte])
