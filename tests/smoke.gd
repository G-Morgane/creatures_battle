extends Node

# Test de fumee : formes, catalyseurs, determinisme, renaissance.
# Lancer : godot --headless --path . res://tests/smoke.tscn

func _ready() -> void:
	var ok := true
	ok = _formes() and ok
	ok = _catalyseurs() and ok
	ok = _deterministe() and ok
	ok = _renaissance() and ok
	ok = _ecran() and ok
	ok = _armes() and ok
	ok = _combat_anime() and ok
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

# Glisser-deposer sans souris : on appelle ce que les cases appellent.
func _ecran() -> bool:
	var e := NidScreen.new()
	add_child(e)
	e.deposer(Vector2i(0, 0), "braise", null)
	var ok := _verifier(e.nid.forme() == "feu" and e.vue.forme == "feu", "poser une braise -> phenix")
	e.deposer(Vector2i(1, 0), "croc_noir", null)
	e.deposer(Vector2i(2, 0), "nuee", null)
	ok = _verifier(e.vue.forme == "ombre", "plus d'ombre -> chauve-souris") and ok
	e.deposer(Vector2i(3, 3), "croc_noir", Vector2i(1, 0))
	ok = _verifier(e.nid.cases.get(Vector2i(3, 3)) == "croc_noir" and not e.nid.cases.has(Vector2i(1, 0)), "deplacer une relique") and ok
	e.deposer(Vector2i(0, 0), "croc_noir", Vector2i(3, 3))
	ok = _verifier(e.nid.cases.get(Vector2i(3, 3)) == "braise", "echanger deux reliques") and ok
	e.vider_case(Vector2i(3, 3))
	ok = _verifier(e.vue.forme == "ombre" and e.nid.cases.size() == 2, "vider une case") and ok
	e.queue_free()
	return ok

func _armes() -> bool:
	var n := Nid.new()
	var ok := _verifier(n.placer(Vector2i(0, 0), "lance_guet"), "poser une arme")
	ok = _verifier(not n.placer(Vector2i(1, 0), "faux_lunaire"), "une seule arme") and ok
	ok = _verifier(n.accepte(Vector2i(0, 0), "faux_lunaire", null), "remplacer l'arme en place") and ok
	ok = _verifier(n.accepte(Vector2i(2, 2), "lance_guet", Vector2i(0, 0)), "deplacer l'arme") and ok
	ok = _verifier(n.affinites().is_empty(), "la lance n'a pas d'element") and ok
	n.placer(Vector2i(1, 0), "foyer")
	var s: Dictionary = n.eclore()["sorts"][0]
	ok = _verifier(s["cavalier"] and s["nom"] == "Estoc" and s["brulure"], "sort du cavalier + catalyseur voisin") and ok
	# Estoc perce le Voile : la chauve-souris ne doit jamais esquiver un Estoc.
	var lance := Nid.new()
	lance.placer(Vector2i(0, 0), "lance_guet")
	var c := Combat.new(lance.eclore(), Exemples.nid_ombre().eclore())
	c.simuler()
	ok = _verifier(c.journal.any(func(l): return "Estoc" in l), "le cavalier lance Estoc") and ok
	# Moisson double sous le seuil
	var faux := Nid.new()
	faux.placer(Vector2i(0, 0), "faux_lunaire")
	var cible := Nid.new().eclore()
	var m := Combat.new(faux.eclore(), cible)
	m.cotes[1]["pv"] = 30.0
	m.cotes[0]["sorts"][0]["prochain"] = 0.0
	m._agir(m.cotes[0], m.cotes[1])
	var attendu: float = 30.0 - 2.0 * faux.eclore()["sorts"][0]["degats"]
	return _verifier(is_equal_approx(m.cotes[1]["pv"], attendu), "moisson double sous 40 %% (pv %s, attendu %s)" % [m.cotes[1]["pv"], attendu]) and ok

# L'ecran rejoue le combat jusqu'au bout sans rien recalculer.
func _combat_anime() -> bool:
	var feu := Exemples.nid_feu()
	feu.placer(Vector2i(2, 0), "baton_braise")
	var e := CombatScreen.new(feu.eclore(), Exemples.nid_ombre().eclore())
	add_child(e)
	var ok := _verifier(e.combat.images.size() == roundi(e.combat.t / Data.PAS), "une image de PV par pas")
	ok = _verifier(e.combat.evenements.any(func(ev): return ev["type"] == "sort" and ev["cavalier"]), "evenement de sort du cavalier") and ok
	for i in 2000:
		e._process(0.05)
		if e.fini:
			break
	ok = _verifier(e.fini and e.prochain == e.combat.evenements.size(), "lecture jusqu'a la fin") and ok
	e.queue_free()
	return ok
