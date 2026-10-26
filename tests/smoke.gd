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
	ok = _partie() and ok
	ok = _fusion() and ok
	ok = _terre_vent() and ok
	ok = _nature() and ok
	ok = _familles() and ok
	print("SMOKE: ", "OK" if ok else "ECHEC")
	get_tree().quit(0 if ok else 1)

func _verifier(cond: bool, msg: String) -> bool:
	if not cond:
		print("  echec : ", msg)
	return cond

func _formes() -> bool:
	var ok := _verifier(Exemples.nid_feu().forme() == "feu", "nid feu -> phenix")
	ok = _verifier(Exemples.nid_nuit().forme() == "nuit", "nid nuit -> chauve-souris") and ok
	ok = _verifier(Nid.new().forme() == "", "nid vide -> informe") and ok
	var egal := Nid.new()
	egal.placer(Vector2i(0, 0), "braise")
	egal.placer(Vector2i(1, 0), "croc_noir")
	ok = _verifier(egal.forme() == "", "egalite -> informe") and ok
	ok = _verifier(not egal.placer(Vector2i(0, 0), "foyer"), "case occupee refusee") and ok
	return _verifier(not egal.placer(Vector2i(9, 0), "foyer"), "hors grille refuse") and ok

func _catalyseurs() -> bool:
	var feu := Exemples.nid_feu().eclore()
	var nuit := Exemples.nid_nuit().eclore()
	var nuee: Dictionary = nuit["sorts"].filter(func(s): return s["nom"] == "Nuée")[0]
	var ok := _verifier(feu["sorts"][0]["brulure"] > 0.0, "foyer voisin -> brulure")
	ok = _verifier(nuee["vol_de_vie"] > 0.0, "lune creuse voisine -> vol de vie") and ok
	# souffle ardent : 10 + 1,5 x affinite feu (2+2+1+1+1 = 7)
	return _verifier(is_equal_approx(feu["sorts"][0]["degats"], 20.5), "degats selon affinite") and ok

func _deterministe() -> bool:
	var r := []
	for i in 2:
		var c := Combat.new(Exemples.nid_feu().eclore(), Exemples.nid_nuit().eclore())
		r.append([c.simuler(), c.journal])
	var ok := _verifier(r[0][0] == r[1][0] and r[0][1] == r[1][1], "meme combat, meme resultat")
	return _verifier(r[0][0] != -1, "le combat se termine par un vainqueur") and ok

func _renaissance() -> bool:
	# Le phenix part a 1 PV : le test ne depend pas de l'equilibrage.
	var c := Combat.new(Exemples.nid_feu().eclore(), Exemples.nid_nuit().eclore())
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
	ok = _verifier(e.vue.forme == "nuit", "plus de nuit -> chauve-souris") and ok
	e.deposer(Vector2i(3, 3), "croc_noir", Vector2i(1, 0))
	ok = _verifier(e.nid.cases.get(Vector2i(3, 3)) == "croc_noir" and not e.nid.cases.has(Vector2i(1, 0)), "deplacer une relique") and ok
	e.deposer(Vector2i(0, 0), "croc_noir", Vector2i(3, 3))
	ok = _verifier(e.nid.cases.get(Vector2i(3, 3)) == "braise", "echanger deux reliques") and ok
	e.vendre(Vector2i(3, 3))
	ok = _verifier(e.vue.forme == "nuit" and e.nid.cases.size() == 2, "revendre une case") and ok
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
	ok = _verifier(s["cavalier"] and s["nom"] == "Estoc" and s["brulure"] > 0.0, "sort du cavalier + catalyseur voisin") and ok
	# Estoc perce le Voile : la chauve-souris ne doit jamais esquiver un Estoc.
	var lance := Nid.new()
	lance.placer(Vector2i(0, 0), "lance_guet")
	var c := Combat.new(lance.eclore(), Exemples.nid_nuit().eclore())
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
	var e := CombatScreen.new(feu.eclore(), Exemples.nid_nuit().eclore())
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

func _partie() -> bool:
	var p := Partie.new(42)
	var ok := _verifier(Partie.new(42).offres == p.offres, "meme graine, meme boutique")
	ok = _verifier(p.offres.size() == Partie.TAILLE_BOUTIQUE and p.bourse == Partie.OR_PAR_MANCHE, "depart : 5 offres, 10 or") and ok
	p.offres[0] = "braise"
	p.offres[1] = "baton_braise"
	ok = _verifier(p.acheter(0, Vector2i(0, 0)) and p.bourse == 7 and p.offres[0] == "", "acheter : -3 or, offre vendue") and ok
	ok = _verifier(not p.acheter(0, Vector2i(1, 0)), "offre deja vendue") and ok
	ok = _verifier(not p.acheter(1, Vector2i(0, 0)), "case occupee") and ok
	p.bourse = 4
	ok = _verifier(not p.acheter(1, Vector2i(1, 0)), "pas assez d'or") and ok
	p.vendre(Vector2i(0, 0))
	ok = _verifier(p.bourse == 5 and p.nid.cases.is_empty(), "revendre : moitie du prix") and ok
	ok = _verifier(p.relancer() and p.bourse == 4, "relancer coute 1 or") and ok
	p.enregistrer(0)
	ok = _verifier(p.manche == 2 and p.victoires == 1 and p.bourse == 14, "victoire : manche 2, +10 or") and ok
	p.enregistrer(-1)
	ok = _verifier(p.victoires == 1 and p.defaites == 0 and p.manche == 3, "egalite : ne compte pas") and ok
	var a := p.adversaire()
	var cout := 0
	for id in a.cases.values():
		cout += Partie.prix(id)
	ok = _verifier(cout <= Partie.OR_PAR_MANCHE * p.manche + Partie.OR_PAR_VICTOIRE * p.victoires and cout > 0, "adversaire dans le budget de la manche") and ok
	ok = _verifier(a.cases == p.adversaire().cases, "adversaire deterministe") and ok
	for i in 3:
		p.enregistrer(1)
	return _verifier(p.terminee(), "3 defaites : partie terminee") and ok

func _fusion() -> bool:
	var n := Nid.new()
	n.ajouter(Vector2i(0, 0), "braise")
	n.ajouter(Vector2i(1, 0), "braise")
	var ok := _verifier(n.cases.size() == 2, "deux copies : pas de fusion")
	n.ajouter(Vector2i(2, 0), "braise")
	ok = _verifier(n.cases.size() == 1 and n.niveau(Vector2i(2, 0)) == 2, "trois copies : niveau 2 a la derniere pose") and ok
	ok = _verifier(n.affinites()["feu"] == 6, "la fusion garde l'affinite") and ok
	ok = _verifier(is_equal_approx(n.eclore()["attaque"], Data.ATTAQUE_BASE + 2.0 * 2.5), "niveau 2 : attaque x2,5") and ok
	# pose sur une copie quand le Nid est plein
	var m := Nid.new()
	m.ajouter(Vector2i(0, 0), "nuee")
	m.ajouter(Vector2i(1, 0), "nuee")
	ok = _verifier(m.peut_ajouter(Vector2i(0, 0), "nuee") and not m.peut_ajouter(Vector2i(0, 0), "voile"), "poser sur une copie qui complete un trio") and ok
	m.ajouter(Vector2i(0, 0), "nuee")
	ok = _verifier(m.cases.size() == 1 and m.niveau(Vector2i(0, 0)) == 2, "fusion sur place") and ok
	ok = _verifier(not m.peut_ajouter(Vector2i(0, 0), "nuee"), "une seule copie : pas de pose dessus") and ok
	# cascade : 3 niveaux 2 donnent un niveau 3
	var k := Nid.new()
	for i in 9:
		k.ajouter(Vector2i(i % 4, i / 4), "croc_noir")
	ok = _verifier(k.cases.size() == 1 and k.niveau(k.cases.keys()[0]) == 3, "9 copies : niveau 3") and ok
	# armes exclues
	var a := Nid.new()
	a.ajouter(Vector2i(0, 0), "lance_guet")
	ok = _verifier(not a.peut_ajouter(Vector2i(0, 0), "lance_guet") and not a.peut_ajouter(Vector2i(1, 0), "lance_guet"), "les armes ne fusionnent pas") and ok
	ok = _verifier(Partie.prix_revente("braise", 2) == 4, "revente niveau 2 : 9 / 2 = 4") and ok
	n.deplacer(Vector2i(2, 0), Vector2i(3, 3))
	ok = _verifier(n.niveau(Vector2i(3, 3)) == 2 and not n.niveaux.has(Vector2i(2, 0)), "deplacer garde le niveau") and ok
	return ok

func _terre_vent() -> bool:
	var t := Exemples.nid_terre().eclore()
	var v := Exemples.nid_vent().eclore()
	var ok := _verifier(t["nom"] == "Tortue" and v["nom"] == "Cheval", "terre -> tortue, vent -> cheval")
	ok = _verifier(is_equal_approx(t["pv_max"], Data.PV_BASE + 80.0) and is_equal_approx(t["bouclier"], 30.0), "pierre +PV, ecaille bouclier") and ok
	var rempart: Dictionary = t["sorts"][0]
	# rempart : 15 + 3 x terre (2+2+1+1+1 = 7) = 36, socle voisin +40 % = 50,4 ; aucun degat
	ok = _verifier(is_equal_approx(rempart["bouclier"], 36.0 * 1.4) and rempart["degats"] == 0.0, "rempart : bouclier selon affinite, socle") and ok
	ok = _verifier(is_equal_approx(v["esquive"], Data.ESQUIVE_CHEVAL + 0.06), "cheval : esquive passive + crin") and ok
	ok = _verifier(is_equal_approx(v["sorts"][0]["recharge"], 3.0 / 1.25), "girouette : recharge plus rapide") and ok
	# combat : le bouclier encaisse, le cheval esquive et riposte
	var c := Combat.new(t, v)
	c.simuler()
	ok = _verifier(c.evenements.any(func(e): return e["type"] == "eclair"), "le cheval lance des eclairs") and ok
	ok = _verifier(c.evenements.any(func(e): return e["type"] == "bouclier"), "la tortue gagne du bouclier") and ok
	ok = _verifier(c.cotes[1]["fatigue_debut"] == Data.MORT_SUBITE - Data.TORTUE_AVANCE_FATIGUE and c.cotes[0]["fatigue_mult"] == Data.TORTUE_FATIGUE_MULT, "fatigue de la tortue") and ok
	var c2 := Combat.new(t, v)
	c2.simuler()
	return _verifier(c2.journal == c.journal, "esquive au hasard mais deterministe") and ok

func _nature() -> bool:
	var cr := Exemples.nid_nature().eclore()
	var ok := _verifier(cr["nom"] == "Cerf", "nature -> cerf")
	# epines : 2 (passif) + 2 x 1,5 (ortie voisine) ; poison par attaque : 0,5 x 1,5 (amanite voisine)
	ok = _verifier(is_equal_approx(cr["epines"], 2.0 + 3.0) and is_equal_approx(cr["poison_attaque"], 0.75), "ortie et amanite renforcent leurs voisines") and ok
	var spore: Dictionary = cr["sorts"][0]
	# spore : (2 + 0,2 x nature 7) x 1,5 amanite
	ok = _verifier(is_equal_approx(spore["poison"], (2.0 + 0.2 * 7) * 1.5), "nuage de spores : poison selon affinite") and ok
	# poison : s'empile, plafonne, passe le bouclier ; epines : ripostent
	var tortue := Exemples.nid_terre().eclore()
	var c := Combat.new(cr, tortue)
	c._empoisonner(c.cotes[1], 150.0)
	ok = _verifier(c.cotes[1]["poison"] == Data.POISON_MAX, "poison plafonne a 100") and ok
	var pv: float = c.cotes[1]["pv"]
	c._subir(c.cotes[1], c.cotes[0])
	ok = _verifier(c.cotes[1]["bouclier"] == 30.0 and c.cotes[1]["pv"] < pv, "le poison passe le bouclier") and ok
	var vie_tortue: float = c.cotes[1]["pv"] + c.cotes[1]["bouclier"]
	c._frapper(c.cotes[1], c.cotes[0], 5.0, 0.0)
	ok = _verifier(c.cotes[1]["pv"] + c.cotes[1]["bouclier"] < vie_tortue, "les epines blessent l'attaquant") and ok
	# belladone : un empoisonne ne se soigne plus
	var b := Nid.new()
	b.placer(Vector2i(0, 0), "belladone")
	var nuit := Exemples.nid_nuit().eclore()
	var d := Combat.new(nuit, b.eclore())
	d.cotes[0]["pv"] = 100.0
	d._frapper(d.cotes[0], d.cotes[1], 10.0, 0.5)
	ok = _verifier(d.cotes[0]["pv"] > 100.0, "sans poison, le vol de vie soigne") and ok
	d.cotes[0]["pv"] = 100.0
	d._empoisonner(d.cotes[0], 1.0)
	d._frapper(d.cotes[0], d.cotes[1], 10.0, 0.5)
	# la belladone donne un Cerf : ses epines blessent, mais aucun soin ne compense
	ok = _verifier(is_equal_approx(d.cotes[0]["pv"], 100.0 - Data.EPINES_CERF), "belladone : empoisonne, plus de soin") and ok
	# coeur de roncier plafonne, dague : contre au 4e coup recu
	var k := Nid.new()
	k.placer(Vector2i(0, 0), "coeur_roncier")
	k.placer(Vector2i(1, 0), "dague_epine")
	var e := Combat.new(k.eclore(), Nid.new().eclore())
	for i in 30:
		e._frapper(e.cotes[1], e.cotes[0], 1.0, 0.0)
	ok = _verifier(e.cotes[0]["epines_bonus"] == Data.EPINES_BONUS_MAX, "coeur de roncier : x2 au plus") and ok
	ok = _verifier(e.evenements.filter(func(ev): return ev["type"] == "sort" and ev["nom"] == "Contre").size() == 7, "contre tous les 4 coups recus") and ok
	# arc de saule : plus fort selon le poison ; legendaires : pas de fusion
	var a := Nid.new()
	a.placer(Vector2i(0, 0), "arc_saule")
	var f := Combat.new(a.eclore(), Nid.new().eclore())
	f.cotes[1]["poison"] = 10.0
	var avant: float = f.cotes[1]["pv"]
	f.cotes[0]["sorts"][0]["prochain"] = 0.0
	f._agir(f.cotes[0], f.cotes[1])
	ok = _verifier(avant - f.cotes[1]["pv"] > 10.0 + 9.0, "fleche de chasse : +1 par dose") and ok
	var g := Nid.new()
	g.ajouter(Vector2i(0, 0), "graine_jardin")
	g.ajouter(Vector2i(1, 0), "graine_jardin")
	g.ajouter(Vector2i(2, 0), "graine_jardin")
	ok = _verifier(g.cases.size() == 3, "les legendaires ne fusionnent pas") and ok
	# rarete : manche 1 que des communs ; prix
	var p := Partie.new(5)
	ok = _verifier(p.offres.all(func(id): return Data.rarete(id) == "commun"), "manche 1 : que des communs") and ok
	ok = _verifier(Partie.prix("graine_jardin") == 3 + 7 and Partie.prix("arc_saule") == 5 + 2, "prix selon type et rarete") and ok
	return ok

func _familles() -> bool:
	var armes := Data.RELIQUES.keys().filter(func(id): return Data.RELIQUES[id]["type"] == "arme")
	var ok := _verifier(armes.all(func(id): return Data.RELIQUES[id].get("famille", "") in Data.FAMILLES), "chaque arme a une famille connue")
	var cerf := armes.filter(func(id): return Data.RELIQUES[id]["element"] == "nature")
	var familles := {}
	for id in cerf:
		familles[Data.RELIQUES[id]["famille"]] = true
	return _verifier(familles.keys().size() <= 2, "le Cerf n'utilise qu'une ou deux familles") and ok
