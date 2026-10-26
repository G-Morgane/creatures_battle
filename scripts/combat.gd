class_name Combat
extends RefCounted

# Simulation deterministe par pas fixe : memes creatures, meme resultat.
# Indispensable pour rejouer un fantome asynchrone a l'identique.

var t := 0.0
var cotes: Array = []
var journal: Array[String] = []
# Pour rejouer le combat a l'ecran : un evenement par action, et les PV
# des deux cotes a chaque pas ([pv0, pv1, brule0, brule1, bouclier0, bouclier1]).
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
		copie["prochain"] = s["recharge"]
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
		"esquive": false,
		"renaissance": cr["renaissance"],
	}

# Renvoie 0 ou 1 pour le vainqueur, -1 pour un nul.
func simuler() -> int:
	while t < Data.DUREE_MAX:
		t += Data.PAS
		for i in 2:
			_agir(cotes[i], cotes[1 - i])
		for i in 2:
			_subir(cotes[i])
		var morts := [_mort(cotes[0]), _mort(cotes[1])]
		images.append([cotes[0]["pv"], cotes[1]["pv"], cotes[0]["brulure"] > 0.0, cotes[1]["brulure"] > 0.0,
			cotes[0]["bouclier"], cotes[1]["bouclier"]])
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

func _agir(moi: Dictionary, cible: Dictionary) -> void:
	if t >= moi["prochaine_attaque"]:
		moi["prochaine_attaque"] += moi["cr"]["intervalle"]
		_evenement(moi, {"type": "attaque"})
		_frapper(moi, cible, moi["cr"]["attaque"], moi["cr"]["vol_de_vie"])
	for s in moi["sorts"]:
		if t < s["prochain"]:
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
		for k in s["coups"]:
			var degats: float = s["degats"]
			if s["execution"] and cible["pv"] < cible["cr"]["pv_max"] * Data.SEUIL_EXECUTION:
				degats *= 2.0
			_frapper(moi, cible, degats, s["vol_de_vie"], s["perce"])
		if s["brulure"] > 0.0:
			cible["brulure"] = Data.BRULURE_DUREE
			cible["brulure_force"] = maxf(cible["brulure_force"], s["brulure"])

func _frapper(moi: Dictionary, cible: Dictionary, degats: float, vol: float, perce := false) -> void:
	if cible["esquive"] and not perce:
		cible["esquive"] = false
		_evenement(cible, {"type": "esquive"})
		_noter("%s esquive." % cible["cr"]["nom"])
		return
	if not perce and cible["cr"]["esquive"] > 0.0 and rng.randf() < cible["cr"]["esquive"]:
		_evenement(cible, {"type": "esquive"})
		if cible["cr"]["eclair"]:
			# le Cheval riposte : l'eclair ne s'esquive pas
			_blesser(moi, Data.ECLAIR_DEGATS)
			_evenement(cible, {"type": "eclair"})
		return
	_blesser(cible, degats)
	moi["pv"] = min(moi["pv"] + degats * vol, moi["cr"]["pv_max"])

# Le bouclier encaisse avant les PV. Brulure et fatigue passent a travers.
func _blesser(cible: Dictionary, degats: float) -> void:
	var absorbe := minf(cible["bouclier"], degats)
	cible["bouclier"] -= absorbe
	cible["pv"] -= degats - absorbe

func _subir(moi: Dictionary) -> void:
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
