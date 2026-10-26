extends Node

# Test de fumee : formes, catalyseurs, determinisme, renaissance.
# Lancer : godot --headless --path . res://tests/smoke.tscn

func _ready() -> void:
	var ok := true
	ok = _formes() and ok
	ok = _catalyseurs() and ok
	ok = _deterministe() and ok
	ok = _renaissance() and ok
	print("SMOKE: ", "OK" if ok else "ECHEC")
	get_tree().quit(0 if ok else 1)

func _verifier(cond: bool, msg: String) -> bool:
	if not cond:
		print("  echec : ", msg)
	return cond

func _formes() -> bool:
	var ok := _verifier(Exemples.nid_feu().forme() == "feu", "nid feu -> phenix")
	ok = _verifier(Exemples.nid_ombre().forme() == "ombre", "nid ombre -> chauve-souris") and ok
	ok = _verifier(Nid.new().forme() == "", "nid vide -> informe") and ok
	var egal := Nid.new()
	egal.placer(Vector2i(0, 0), "braise")
	egal.placer(Vector2i(1, 0), "croc_noir")
	ok = _verifier(egal.forme() == "", "egalite -> informe") and ok
	ok = _verifier(not egal.placer(Vector2i(0, 0), "foyer"), "case occupee refusee") and ok
	return _verifier(not egal.placer(Vector2i(9, 0), "foyer"), "hors grille refuse") and ok

func _catalyseurs() -> bool:
	var feu := Exemples.nid_feu().eclore()
	var ombre := Exemples.nid_ombre().eclore()
	var nuee: Dictionary = ombre["sorts"].filter(func(s): return s["nom"] == "Nuée")[0]
	var ok := _verifier(feu["sorts"][0]["brulure"], "foyer voisin -> brulure")
	ok = _verifier(nuee["vol_de_vie"] > 0.0, "lune creuse voisine -> vol de vie") and ok
	# souffle ardent : 10 + 2 x affinite feu (2+2+1+1+1 = 7)
	return _verifier(is_equal_approx(feu["sorts"][0]["degats"], 24.0), "degats selon affinite") and ok

func _deterministe() -> bool:
	var r := []
	for i in 2:
		var c := Combat.new(Exemples.nid_feu().eclore(), Exemples.nid_ombre().eclore())
		r.append([c.simuler(), c.journal])
	var ok := _verifier(r[0][0] == r[1][0] and r[0][1] == r[1][1], "meme combat, meme resultat")
	return _verifier(r[0][0] != -1, "le combat se termine par un vainqueur") and ok

func _renaissance() -> bool:
	# Le phenix part a 1 PV : le test ne depend pas de l'equilibrage.
	var c := Combat.new(Exemples.nid_feu().eclore(), Exemples.nid_ombre().eclore())
	c.cotes[0]["pv"] = 1.0
	c.simuler()
	var renait := c.journal.any(func(l): return "renaît" in l)
	return _verifier(renait, "le phenix renait au moins une fois")
