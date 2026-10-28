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
#   eclat0, eclat1, elan0, elan1]) ;
# brule = nombre de charges de brulure, maledictions = texte ("Faiblesse x2, Langueur").
var evenements: Array = []
var images: Array = []
# Recharge des sorts a chaque pas, de 0 a 1 ([cote 0, cote 1], un par sort ;
# -1 pour un sort qui part sur coups recus).
var recharges: Array = []
# Recap : par cote, source -> {degats, soins, bouclier, activations}. La source
# est l'id d'une relique, ou une mecanique prefixee de ~ (~attaque, ~poison...).
var stats: Array = [{}, {}]
var origine := "~attaque"
# L'esquive du Vent est un tirage : graine fixe, donc toujours le meme combat.
var rng := RandomNumberGenerator.new()

func _init(a: Dictionary, b: Dictionary) -> void:
	rng.seed = 1
	cotes = [_etat(a, 0), _etat(b, 1)]
	# La Tortue fait venir la fatigue plus tot chez l'adversaire, et la subit moins.
	for i in 2:
		var moi: Dictionary = cotes[i]
		var autre: Dictionary = cotes[1 - i]
		moi["fatigue_debut"] = Data.MORT_SUBITE - (Data.TORTUE_AVANCE_FATIGUE if autre["cr"]["tortue"] else 0.0) + moi["cr"]["sablier_ensable"]
		moi["fatigue_mult"] = Data.TORTUE_FATIGUE_MULT if moi["cr"]["tortue"] else 1.0

func _etat(cr: Dictionary, i: int) -> Dictionary:
	var sorts := []
	for s in cr["sorts"]:
		var copie: Dictionary = s.duplicate()
		# un Contre ne part pas sur minuterie mais sur coups recus
		copie["prochain"] = INF if s["contre"] > 0 or s["riposte_esquive"] else s["recharge"]
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
		"dans_eclat": false,       # un soin venu d'un Eclat ne recharge pas l'Eclat
		"encensoir_jusqu": 0.0,
		"eclat_pret": false,       # Hache solaire
		"transferts": 0,           # Arc des deux lunes
		"chrysalide_faite": false,
		"inversion_faite": false,
		"elan_jauge": 0.0,
		"serie": 0,                # Etrier : attaques sans etre touche
		"girouette_bonus": 0.0,    # degats ajoutes a la prochaine Foudre
		"esquive_bonus_jusqu": 0.0,
		"galop_jusqu": 0.0,
		"foudre_prete": false,     # Lance de bourrasque
		"mortier": 0.0,            # part du bouclier venant de la Truelle (renouvelee)
		"bouclier_avant": cr["bouclier"],
		"fil_temps": 0.0,          # Fil a plomb : bouclier tenu sans bris
		"tuile_prete": cr["bouclier"] > 0.0,
		"urne_reserve": 0.0,
		"urne_faite": false,
		"borne_faite": false,
		"fatigue_suspendue_jusqu": 0.0,
		"schiste_jusqu": 0.0,      # Hachette de schiste : degats infliges reduits
		"rempart_bonus": 0.0,
		"bouclier": cr["bouclier"],
		"poison": 0.0,             # doses
		"epines_bonus": 1.0,       # Coeur de roncier, Graine
		"coups_recus": 0,
		"elite_t": 0.0,            # elites : minuterie de leur regle
		"elite_t2": 0.0,
		"furie": false,            # Vouivre : entraves brisees
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
			cotes[0]["eclat_jauge"], cotes[1]["eclat_jauge"], cotes[0]["elan_jauge"], cotes[1]["elan_jauge"]])
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
			l.append(clampf(1.0 - (s["prochain"] - moi["horloge"]) / s["recharge"], 0.0, 1.0))
	return l

# --- recap ---------------------------------------------------------------------

func _compter(cote: int, champ: String, v: float, source := "") -> void:
	if v <= 0.0:
		return
	var cle := source if source != "" else origine
	var l: Dictionary = stats[cote].get(cle, {"degats": 0.0, "soins": 0.0, "bouclier": 0.0, "activations": 0.0})
	l[champ] += v
	stats[cote][cle] = l

# Change la source courante, rend l'ancienne pour la remettre apres.
func _depuis(o: String) -> String:
	var avant := origine
	origine = o
	return avant

func _proteger(moi: Dictionary, b: float, source := "") -> void:
	moi["bouclier"] += b
	_compter(moi["cote"], "bouclier", b, source)

# Degats directs, qui passent le bouclier (brulure, poison, combustion...).
func _infliger(cible: Dictionary, d: float, source := "") -> void:
	cible["pv"] -= d
	_compter(1 - cible["cote"], "degats", d, source)

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
		moi["prochaine_attaque"] += moi["cr"]["intervalle"] / (Data.VOUIVRE_FURIE if moi["furie"] else 1.0)
		origine = "~attaque"
		_compter(moi["cote"], "activations", 1.0)
		_evenement(moi, {"type": "attaque"})
		var degats: float = moi["cr"]["attaque"]
		if _brulure(cible) > 0.0:
			degats += moi["cr"]["degats_en_feu"]
		moi["attaques"] += 1
		var touche_base := _frapper(moi, cible, degats, moi["cr"]["vol_de_vie"])
		# Rapiere, pendant le Galop libre : une seconde touche plus faible, qui charge aussi
		if moi["cr"]["rapiere"] and t < moi["galop_jusqu"]:
			if _frapper(moi, cible, degats * 0.5, moi["cr"]["vol_de_vie"]):
				_gagner_elan(moi, cible, Data.ELAN_PAR_ATTAQUE * 0.5)
		if touche_base:
			moi["serie"] += 1
			_gagner_elan(moi, cible, Data.ELAN_PAR_ATTAQUE + minf(moi["cr"]["etrier"] * moi["serie"], Data.ETRIER_MAX))
			var tous: int = moi["cr"]["faiblesse_tous"]
			if tous > 0 and moi["attaques"] % tous == 0:
				_maudire(moi, cible, "faiblesse")
			# Pacte : sous trois maledictions, chaque attaque draine en plus (passe le bouclier)
			if moi["cr"]["pacte"] > 0.0 and _nb_maledictions(cible) == Data.MALEDICTIONS.size():
				_infliger(cible, moi["cr"]["pacte"], "pacte")
				_soigner(moi, cible, moi["cr"]["pacte"])
			if moi["cr"]["brulure_attaque"] > 0.0:
				_bruler(moi, cible, moi["cr"]["brulure_attaque"])
			if moi["cr"]["poudre"] > 0.0:
				_transfert(moi, cible, "bouclier", moi["cr"]["poudre"])
			if moi["cr"]["poison_attaque"] > 0.0:
				_empoisonner(cible, moi["cr"]["poison_attaque"])
			if moi["cr"]["givre_attaque"] > 0.0:
				_givrer(moi, cible, moi["cr"]["givre_attaque"])
	for s in moi["sorts"]:
		if h < s["prochain"]:
			continue
		s["prochain"] += s["recharge"]
		origine = s["id"]
		_lancer(moi, cible, s)

# Un sort qui part. renfort multiplie ses degats (tir de renaissance).
func _lancer(moi: Dictionary, cible: Dictionary, s: Dictionary, renfort := 1.0) -> void:
	_compter(moi["cote"], "activations", 1.0, s["id"])
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
		_proteger(moi, s["bouclier"])
		_evenement(moi, {"type": "bouclier", "valeur": s["bouclier"]})
	# Truelle : le bouclier de mortier remplace le precedent (la Clef en garde la moitie)
	if s["mortier"] > 0.0:
		var ancien := minf(moi["bouclier"], moi["mortier"])
		var garde: float = ancien * Data.CLEF if moi["cr"]["clef"] else 0.0
		_proteger(moi, s["mortier"] - (ancien - garde))
		moi["mortier"] = s["mortier"] + garde
		_evenement(moi, {"type": "bouclier", "valeur": s["mortier"]})
	if s["rempart"] and moi["bouclier"] > 0.0:
		moi["rempart_bonus"] = minf(moi["rempart_bonus"] + Data.REMPART_PAS, Data.REMPART_MAX)
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
		var degats: float = (s["degats"] + s["par_transfert"] * moi["transferts"]) * renfort
		if s["apres_eclat"] and moi["eclat_pret"]:
			degats *= 2.0
		var perce: bool = s["perce"]
		if s["apres_foudre"] and moi["foudre_prete"]:
			degats *= 2.0
			perce = true
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
		var touche_coup := _frapper(moi, cible, degats, s["vol_de_vie"] + (0.5 if festin > 0.0 else 0.0), perce)
		touche = touche_coup or touche
		if touche_coup and s["fondations"]:
			var b: float = degats * Data.FONDATIONS * (1.5 if moi["pv"] < moi["cr"]["pv_max"] * 0.5 else 1.0)
			_proteger(moi, b)
			_evenement(moi, {"type": "bouclier", "valeur": b})
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
		if s["schiste"]:
			cible["schiste_jusqu"] = t + Data.SCHISTE_DUREE
		if s["soin"] > 0.0:
			# Baton des ages : soigne plus fort une fois la fatigue commencee
			var bonus := minf((t - moi["fatigue_debut"]) * Data.AGES_PAR_SECONDE, Data.AGES_MAX) if s["ages"] and t > moi["fatigue_debut"] else 0.0
			_soigner(moi, cible, s["soin"] + bonus)
		if s["charge_eclat"] > 0.0 and moi["cr"]["eclat"]:
			_charger_eclat(moi, cible, s["charge_eclat"])
		if s["transfert"] != "":
			if s["transfert_tous"] > 0:
				s["tirs_transfert"] = s.get("tirs_transfert", 0) + 1
				if s["tirs_transfert"] % s["transfert_tous"] == 0:
					_transfert(moi, cible, s["transfert"], s["puissance"])
			else:
				_transfert(moi, cible, s["transfert"], s["puissance"])
	if s["apres_eclat"]:
		moi["eclat_pret"] = false
	if s["apres_foudre"]:
		moi["foudre_prete"] = false
	if touche and s["elan"] > 0.0:
		_gagner_elan(moi, cible, s["elan"])
	# Javelot des alizes : l'attaque suivante arrive plus tot
	if s["alize"]:
		moi["prochaine_attaque"] -= Data.ALIZE_AVANCE
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
	_infliger(cible, degats, "~combustion")
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
	var esquive := _esquive(cible)
	if not perce and esquive > 0.0 and rng.randf() < esquive:
		_evenement(cible, {"type": "esquive"})
		_esquive_reussie(cible, moi)
		return false
	cible["serie"] = 0
	if _gele(cible):
		degats *= moi["cr"]["bonus_gel"]
	# Faiblesse : l'attaquant maudit frappe moins fort.
	# Chauve-souris : plus fort contre une cible maudite.
	degats *= maxf(0.0, 1.0 - Data.FAIBLESSE * _charges(moi, "faiblesse"))
	degats *= 1.0 + moi["cr"]["par_malediction"] * _nb_maledictions(cible)
	if moi["cr"].get("elite", "") == "vouivre":
		degats *= 1.0 + minf(Data.VOUIVRE_PAR_MALUS * _malus_subis(moi), Data.VOUIVRE_MAX)
		if moi["furie"]:
			degats *= Data.VOUIVRE_FURIE
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
	var avant := _depuis("~eclat")
	var degats: float = Data.ECLAT_DEGATS + moi["cr"]["prisme"] + moi["cr"]["lanterne"] * moi["exces_accumule"]
	moi["exces_accumule"] = 0.0
	_evenement(adverse, {"type": "eclat", "valeur": degats})
	_blesser(adverse, degats, moi)
	moi["eclats"] += 1
	moi["eclat_pret"] = true
	if moi["cr"]["encensoir"] > 0.0:
		moi["encensoir_jusqu"] = t + Data.ENCENSOIR_DUREE
	if moi["cr"]["carillon"] > 0.0 and moi["eclats"] % Data.CARILLON_TOUS == 0:
		# sinon, avec des reliques fusionnees, le soin relancait l'Eclat sans fin
		moi["dans_eclat"] = true
		origine = "carillon"
		_soigner(moi, adverse, moi["cr"]["carillon"])
		moi["dans_eclat"] = false
	origine = avant

# --- Elan et Foudre (Cheval) -------------------------------------------------------

# Voile de cavale : forte esquive un moment apres la Foudre (plafond releve).
func _esquive(moi: Dictionary) -> float:
	if t < moi["esquive_bonus_jusqu"]:
		return minf(moi["cr"]["esquive"] + moi["cr"]["voile_cavale"], Data.ESQUIVE_MAX_TEMP)
	return moi["cr"]["esquive"]

# Une esquive : de l'Elan, la hate du Ruban, la Girouette, la riposte du Sabre.
func _esquive_reussie(moi: Dictionary, attaquant: Dictionary) -> void:
	_gagner_elan(moi, attaquant, Data.ELAN_PAR_ESQUIVE + moi["cr"]["girouette"] * 2.0)
	moi["girouette_bonus"] += moi["cr"]["girouette"]
	if moi["cr"]["ruban_criniere"] > 0.0:
		moi["braise_temp"] = maxf(moi["braise_temp"] if t < moi["braise_temp_jusqu"] else 0.0, moi["cr"]["ruban_criniere"])
		moi["braise_temp_jusqu"] = maxf(moi["braise_temp_jusqu"], t + Data.RUBAN_DUREE)
	for s in moi["sorts"]:
		if s["riposte_esquive"]:
			_evenement(moi, {"type": "sort", "nom": s["nom"], "cavalier": true, "element": s["element"], "coups": s["coups"]})
			for k in s["coups"]:
				_blesser(attaquant, s["degats"], moi)
				_gagner_elan(moi, attaquant, s["elan"])

# Le Galop libre (Bride) double les gains ; la Manche a air abaisse le seuil.
func _gagner_elan(moi: Dictionary, adverse: Dictionary, n: float) -> void:
	if not moi["cr"]["elan"] or n <= 0.0:
		return
	if t < moi["galop_jusqu"]:
		n *= 2.0
	moi["elan_jauge"] += n
	var seuil := maxf(Data.ELAN_SEUIL - moi["cr"]["manche"], Data.ELAN_SEUIL_MIN)
	while moi["elan_jauge"] >= seuil:
		moi["elan_jauge"] -= seuil
		_foudre(moi, adverse)

# La Foudre ne s'esquive pas. Eventail, Girouette : plus fort ; Voile de cavale :
# esquive ; Bride : Galop libre (pas renouvele s'il est deja actif) ; Lance : coup suivant.
func _foudre(moi: Dictionary, adverse: Dictionary) -> void:
	var avant := _depuis("~foudre")
	var degats: float = Data.FOUDRE_DEGATS + moi["cr"]["eventail"] + moi["girouette_bonus"]
	moi["girouette_bonus"] = 0.0
	_evenement(adverse, {"type": "foudre", "valeur": degats})
	_blesser(adverse, degats, moi)
	moi["foudre_prete"] = true
	if moi["cr"]["voile_cavale"] > 0.0:
		moi["esquive_bonus_jusqu"] = t + Data.VOILE_CAVALE_DUREE
	if moi["cr"]["bride"] and t >= moi["galop_jusqu"]:
		moi["galop_jusqu"] = t + Data.GALOP_DUREE
		moi["braise_temp"] = Data.GALOP_HATE
		moi["braise_temp_jusqu"] = moi["galop_jusqu"]
		_evenement(moi, {"type": "galop"})
	origine = avant

# --- Transfert (Papillon) --------------------------------------------------------

# mode : renvoyer (un malus), voler (un bonus), bouclier (voler du bouclier),
# echange (voler et renvoyer), tout (Chrysalide). p : puissance de la source.
# Rien a deplacer : le Papillon tire un projectile d'arcane, qui compte comme Transfert
# pour la Phalene et l'Arc des deux lunes, pas pour la Brume ni l'Aile de lune.
func _transfert(moi: Dictionary, adverse: Dictionary, mode: String, p: float) -> void:
	var fait := false
	if mode in ["renvoyer", "echange", "tout"]:
		var types := _malus(moi)
		if mode != "tout" and not types.is_empty():
			types = [types[0]]
		for type in types:
			_renvoyer(moi, adverse, type)
			fait = true
	if mode in ["voler", "echange", "tout", "bouclier"]:
		var vols := ["bouclier"] if mode == "bouclier" else _bonus(adverse)
		if mode != "tout" and not vols.is_empty():
			vols = [vols[0]]
		for type in vols:
			if _voler(moi, adverse, type, p, mode == "tout"):
				fait = true
	if not fait:
		if not moi["cr"]["arcane"]:
			return
		_evenement(adverse, {"type": "arcane", "valeur": p * Data.ARCANE_PAR_PUISSANCE})
		_blesser(adverse, p * Data.ARCANE_PAR_PUISSANCE, moi)
	moi["transferts"] += 1
	if moi["cr"]["cocon"] > 0.0:
		_proteger(moi, moi["cr"]["cocon"], "cocon")
	if moi["cr"]["phalene"]:
		_frapper(moi, adverse, moi["cr"]["attaque"], moi["cr"]["vol_de_vie"])

# Malus portes, du plus lourd au plus leger.
func _malus(moi: Dictionary) -> Array:
	var poids := {"poison": moi["poison"], "brulure": _brulure(moi), "givre": moi["givre"],
		"maledictions": 3.0 * _nb_maledictions(moi)}
	var l := poids.keys().filter(func(k): return poids[k] > 0.0)
	l.sort_custom(func(a, b): return poids[a] > poids[b])
	return l

func _bonus(moi: Dictionary) -> Array:
	var poids := {"bouclier": moi["bouclier"], "braise": moi["braise"] * 10.0,
		"eclat": moi["eclat_jauge"], "epines": (moi["epines_bonus"] - 1.0) * 50.0}
	var l := poids.keys().filter(func(k): return poids[k] > 0.0)
	l.sort_custom(func(a, b): return poids[a] > poids[b])
	return l

# Le malus quitte le Papillon et arrive chez l'adversaire (renforce par la Mue).
func _renvoyer(moi: Dictionary, adverse: Dictionary, type: String) -> void:
	var k: float = Data.MUE if moi["cr"]["mue"] else 1.0
	match type:
		"poison":
			adverse["poison"] = minf(adverse["poison"] + moi["poison"] * k, Data.POISON_MAX)
			moi["poison"] = 0.0
		"brulure":
			for b in moi["brulures"]:
				adverse["brulures"].append({"fin": b["fin"], "q": b["q"] * k})
			moi["brulures"].clear()
		"givre":
			var g: float = moi["givre"] * k
			moi["givre"] = 0.0
			_givrer(moi, adverse, g)
		"maledictions":
			for nom in moi["maledictions"]:
				var n := _charges(moi, nom)
				if n > 0:
					adverse["maledictions"][nom] = {"n": mini(ceili(n * k), Data.CHAPELET_CHARGES), "fin": t + Data.MALEDICTION_DUREE}
			moi["maledictions"].clear()
	_evenement(adverse, {"type": "renvoi", "malus": type})

# Vole un bonus (la part p, ou tout). Brume : soigne ; Aile de lune : hate volee.
func _voler(moi: Dictionary, adverse: Dictionary, type: String, p: float, tout: bool) -> bool:
	match type:
		"bouclier":
			var v: float = adverse["bouclier"] if tout else minf(adverse["bouclier"], p)
			if v <= 0.0:
				return false
			adverse["bouclier"] -= v
			_proteger(moi, v)
		"braise":
			var v: float = adverse["braise"] if tout else minf(adverse["braise"], 1.0)
			adverse["braise"] -= v
			moi["braise"] = minf(moi["braise"] + v, Data.BRAISE_MAX)
		"eclat":
			var v: float = adverse["eclat_jauge"] if tout else minf(adverse["eclat_jauge"], p * 2.0)
			adverse["eclat_jauge"] -= v
			if moi["cr"]["eclat"]:
				_charger_eclat(moi, adverse, v)
		"epines":
			var v: float = adverse["epines_bonus"] - 1.0 if tout else minf(adverse["epines_bonus"] - 1.0, 0.2)
			adverse["epines_bonus"] -= v
			moi["epines_bonus"] = minf(moi["epines_bonus"] + v, Data.EPINES_BONUS_MAX)
	_evenement(adverse, {"type": "vol", "bonus": type})
	if moi["cr"]["brume"]:
		_soigner(moi, adverse, Data.BRUME_SOIN)
	if moi["cr"]["aile_lune"]:
		moi["braise_temp"] = Data.AILE_BRAISE
		moi["braise_temp_jusqu"] = t + Data.AILE_DUREE
	return true

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
	if moi["cr"]["eclat"] and not moi["dans_eclat"]:
		var exces := maxf(0.0, soin - maxf(0.0, moi["cr"]["pv_max"] - moi["pv"]))
		moi["exces_accumule"] += exces
		_charger_eclat(moi, adverse, (soin - exces) * Data.ECLAT_PAR_SOIN
			+ exces * Data.ECLAT_PAR_EXCES * (1.0 + moi["cr"]["voile_aube"]))
	if moi["poison"] > 0.0 and adverse["cr"]["belladone"]:
		return
	soin *= maxf(0.0, 1.0 - Data.FLETRISSURE * _charges(moi, "fletrissure"))
	var applique := minf(soin, maxf(0.0, moi["cr"]["pv_max"] - moi["pv"]))
	moi["pv"] += applique
	_compter(moi["cote"], "soins", applique)
	if moi["cr"]["vasque"] > 0.0 and soin > applique:
		_proteger(moi, (soin - applique) * moi["cr"]["vasque"], "vasque")
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
	var avant := _depuis("~epines")
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
			origine = s["id"]
			_compter(moi["cote"], "activations", 1.0)
			_blesser(attaquant, s["degats"] + s["par_epine"] * cr["epines"] * moi["epines_bonus"], moi)
			_evenement(moi, {"type": "sort", "nom": s["nom"], "cavalier": true, "element": s["element"], "coups": 1})
	origine = avant

# Le poison s'empile (plafond) ; une Fleche-graine plantee blesse a chaque dose recue.
func _empoisonner(cible: Dictionary, doses: float) -> void:
	cible["poison"] = minf(cible["poison"] + doses, Data.POISON_MAX)
	if cible["graine_plantee"]:
		_blesser(cible, doses * Data.GRAINE_DEGATS_PAR_DOSE)

# Le bouclier encaisse avant les PV. Brulure et fatigue passent a travers.
# source : qui frappe ; un bouclier brise par un coup declenche les effets de bris.
func _blesser(cible: Dictionary, degats: float, source = null) -> void:
	# Hachette de schiste : un attaquant affaibli frappe moins fort
	if source != null and t < source["schiste_jusqu"]:
		degats *= 1.0 - Data.SCHISTE
	# Reduction de degats (l'Urne garde ce qui est evite), puis la Tuile
	var reduit := degats * _reduction(cible)
	cible["urne_reserve"] += reduit if cible["cr"]["urne"] else 0.0
	degats -= reduit
	if cible["tuile_prete"] and cible["cr"]["tuile"]:
		degats *= 1.0 - Data.TUILE
	cible["tuile_prete"] = false
	var avant: float = cible["bouclier"]
	var absorbe := minf(avant, degats)
	cible["bouclier"] -= absorbe
	cible["mortier"] = minf(cible["mortier"], cible["bouclier"])
	cible["pv"] -= degats - absorbe
	_compter(1 - cible["cote"], "degats", degats)
	if avant > 0.0 and cible["bouclier"] <= 0.0:
		cible["fil_temps"] = 0.0
		cible["rempart_bonus"] = 0.0
	# Poupee cousue : renvoie une part des degats a un adversaire maudit
	if source != null and cible["cr"]["renvoi"] > 0.0 and _nb_maledictions(source) > 0:
		_infliger(source, degats * cible["cr"]["renvoi"], "poupee")
	if avant > 0.0 and cible["bouclier"] <= 0.0 and source != null:
		_briser(cible, source)

# Brique, Cale (tant que le bouclier tient), Baton du rempart ; plafond 50 %.
func _reduction(moi: Dictionary) -> float:
	var r: float = moi["cr"]["reduction"] + moi["rempart_bonus"]
	if moi["bouclier"] > 0.0:
		r += moi["cr"]["cale"]
	return minf(r, Data.REDUCTION_MAX)

# Bouclier brise : Eclat de givre, Cristal fele, Ecorce, Rose des neiges, Noyau.
# Ces ripostes peuvent briser le bouclier adverse a leur tour : la chaine
# s'arrete d'elle-meme, un bouclier brise vaut zero.
func _briser(moi: Dictionary, source: Dictionary) -> void:
	var cr: Dictionary = moi["cr"]
	var avant := _depuis("~bris")
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
	origine = avant

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
		_proteger(moi, moi["cr"]["gel_bouclier"], "coeur_banquise")
		_evenement(moi, {"type": "bouclier", "valeur": moi["cr"]["gel_bouclier"]})

# Brulure, poison et fatigue passent a travers le bouclier.
# --- elites -------------------------------------------------------------------

# Charges de malus subis (Vouivre).
func _malus_subis(moi: Dictionary) -> float:
	var n := 0
	for nom in moi["maledictions"]:
		n += _charges(moi, nom)
	return _brulure(moi) + moi["givre"] + moi["poison"] / 5.0 + n

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
		"vouivre":
			if not moi["furie"] and moi["pv"] < moi["cr"]["pv_max"] * 0.5:
				moi["furie"] = true
				_dissiper(moi)
				_evenement(moi, {"type": "entraves"})

func _subir(moi: Dictionary, adverse: Dictionary) -> void:
	_elite(moi, adverse)
	# regeneration : Lion, Bande de lin sous la moitie de sa vie, Encensoir apres un Eclat
	var regen: float = moi["cr"]["regen"]
	if moi["pv"] < moi["cr"]["pv_max"] * Data.BANDE_SEUIL:
		regen += moi["cr"]["bande"]
	if t < moi["encensoir_jusqu"]:
		regen += moi["cr"]["encensoir"]
	origine = "~regen"
	if regen > 0.0 and moi["pv"] > 0.0:
		_soigner(moi, adverse, regen * Data.PAS)
	if not moi["brulures"].is_empty():
		_infliger(moi, _brulure(moi) * Data.BRULURE_DPS_CHARGE * Data.PAS, "~brulure")
		moi["brulures"] = moi["brulures"].filter(func(b): return b["fin"] > t)
	# Chrysalide : une fois, sous la moitie de sa vie, tout renvoyer et tout voler
	if moi["cr"]["chrysalide"] and not moi["chrysalide_faite"] and moi["pv"] < moi["cr"]["pv_max"] * Data.CHRYSALIDE_SEUIL:
		moi["chrysalide_faite"] = true
		origine = "chrysalide"
		_transfert(moi, adverse, "tout", 0.0)
	# Inversion : une fois, au milieu du combat, on echange les pourcentages de vie
	if moi["cr"]["inversion"] and not moi["inversion_faite"] and t >= Data.INVERSION_T:
		moi["inversion_faite"] = true
		var a: float = moi["pv"] / moi["cr"]["pv_max"]
		var b: float = adverse["pv"] / adverse["cr"]["pv_max"]
		moi["pv"] = b * moi["cr"]["pv_max"]
		adverse["pv"] = a * adverse["cr"]["pv_max"]
		_evenement(moi, {"type": "inversion"})
	# Coeur de fournaise : une fois, en passant sous la moitie de sa vie
	if moi["cr"]["fournaise"] and not moi["fournaise_faite"] and moi["pv"] < moi["cr"]["pv_max"] * Data.FOURNAISE_SEUIL:
		moi["fournaise_faite"] = true
		origine = "coeur_fournaise"
		_combustion(moi, adverse, 1.0, true, 1.0)
		moi["braise_temp"] = Data.FOURNAISE_BRAISE
		moi["braise_temp_jusqu"] = t + Data.FOURNAISE_DUREE
	if t >= moi["reforme_a"]:
		moi["reforme_a"] = INF
		_proteger(moi, moi["cr"]["reforme"], "ecorce")
		_evenement(moi, {"type": "bouclier", "valeur": moi["cr"]["reforme"]})
	if moi["poison"] > 0.0:
		_infliger(moi, moi["poison"] * Data.POISON_DPS_PAR_DOSE * Data.PAS, "~poison")
		# Graine : tant que l'adversaire est empoisonne, les epines poussent
		if adverse["cr"]["graine"]:
			adverse["epines_bonus"] = minf(adverse["epines_bonus"] + Data.GRAINE_POUSSE * Data.PAS, Data.EPINES_BONUS_MAX)
	# Terre : Fil a plomb (bouclier tenu), Tuile (nouveau bouclier), Urne (au debut de la fatigue)
	if moi["bouclier"] > moi["bouclier_avant"]:
		moi["tuile_prete"] = true
	moi["bouclier_avant"] = moi["bouclier"]
	if moi["bouclier"] > 0.0 and moi["cr"]["fil_plomb"] > 0.0:
		moi["fil_temps"] += Data.PAS
		if moi["fil_temps"] >= Data.FIL_PLOMB_DELAI:
			moi["fil_temps"] = 0.0
			_proteger(moi, moi["cr"]["fil_plomb"], "fil_plomb")
			moi["bouclier_avant"] = moi["bouclier"]
	if moi["cr"]["urne"] and not moi["urne_faite"] and t >= moi["fatigue_debut"]:
		moi["urne_faite"] = true
		origine = "urne"
		_soigner(moi, adverse, moi["urne_reserve"])
		_evenement(moi, {"type": "urne", "valeur": moi["urne_reserve"]})
	if t > moi["fatigue_debut"] and t >= moi["fatigue_suspendue_jusqu"]:
		var fatigue: float = (t - moi["fatigue_debut"]) * Data.FATIGUE_RAMPE * moi["fatigue_mult"] * Data.PAS
		# Borne de l'Eternite : une fois, la fatigue qui tuerait laisse a 1 PV et s'arrete un moment
		if moi["cr"]["borne"] and not moi["borne_faite"] and moi["pv"] - fatigue <= 0.0:
			moi["borne_faite"] = true
			moi["pv"] = 1.0
			moi["fatigue_suspendue_jusqu"] = t + Data.BORNE_DUREE
			_evenement(moi, {"type": "borne"})
		else:
			moi["pv"] -= fatigue

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
