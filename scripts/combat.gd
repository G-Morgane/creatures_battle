class_name Combat
extends RefCounted

# Simulation deterministe par pas fixe : memes creatures, meme resultat.
# Indispensable pour rejouer un fantome asynchrone a l'identique.

var t := 0.0
var cotes: Array = []
var journal: Array[String] = []

func _init(a: Dictionary, b: Dictionary) -> void:
	cotes = [_etat(a), _etat(b)]

func _etat(cr: Dictionary) -> Dictionary:
	var sorts := []
	for s in cr["sorts"]:
		var copie: Dictionary = s.duplicate()
		copie["prochain"] = s["recharge"]
		sorts.append(copie)
	return {
		"cr": cr,
		"pv": cr["pv_max"],
		"prochaine_attaque": cr["intervalle"],
		"sorts": sorts,
		"brulure": 0.0,
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
		if morts[0] or morts[1]:
			if morts[0] and morts[1]:
				_noter("Les deux tombent ensemble.")
				return -1
			var v := 1 if morts[0] else 0
			_noter("%s l'emporte." % cotes[v]["cr"]["nom"])
			return v
	_noter("Temps écoulé.")
	return -1

func _agir(moi: Dictionary, cible: Dictionary) -> void:
	if t >= moi["prochaine_attaque"]:
		moi["prochaine_attaque"] += moi["cr"]["intervalle"]
		_frapper(moi, cible, moi["cr"]["attaque"], moi["cr"]["vol_de_vie"])
	for s in moi["sorts"]:
		if t < s["prochain"]:
			continue
		s["prochain"] += s["recharge"]
		if s["esquive"]:
			moi["esquive"] = true
			_noter("%s se voile." % moi["cr"]["nom"])
			continue
		var qui: String = moi["cr"]["nom"] + (" : le cavalier" if s["cavalier"] else "")
		_noter("%s lance %s." % [qui, s["nom"]])
		for k in s["coups"]:
			var degats: float = s["degats"]
			if s["execution"] and cible["pv"] < cible["cr"]["pv_max"] * Data.SEUIL_EXECUTION:
				degats *= 2.0
			_frapper(moi, cible, degats, s["vol_de_vie"], s["perce"])
		if s["brulure"]:
			cible["brulure"] = Data.BRULURE_DUREE

func _frapper(moi: Dictionary, cible: Dictionary, degats: float, vol: float, perce := false) -> void:
	if cible["esquive"] and not perce:
		cible["esquive"] = false
		_noter("%s esquive." % cible["cr"]["nom"])
		return
	cible["pv"] -= degats
	moi["pv"] = min(moi["pv"] + degats * vol, moi["cr"]["pv_max"])

func _subir(moi: Dictionary) -> void:
	if moi["brulure"] > 0.0:
		moi["brulure"] -= Data.PAS
		moi["pv"] -= Data.BRULURE_DPS * Data.PAS
	if t > Data.MORT_SUBITE:
		moi["pv"] -= (t - Data.MORT_SUBITE) * Data.PAS

func _mort(moi: Dictionary) -> bool:
	if moi["pv"] > 0.0:
		return false
	if moi["renaissance"]:
		moi["renaissance"] = false
		moi["pv"] = moi["cr"]["pv_max"] * Data.RENAISSANCE_PV
		_noter("%s renaît de ses cendres !" % moi["cr"]["nom"])
		return false
	return true

func _noter(texte: String) -> void:
	journal.append("[%5.1f s] %s" % [t, texte])
