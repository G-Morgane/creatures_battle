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
	ok = _glace() and ok
	ok = _phenix() and ok
	ok = _nuit() and ok
	ok = _aube() and ok
	ok = _crepuscule() and ok
	ok = _vent() and ok
	ok = _vitesses() and ok
	ok = _terre() and ok
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
	egal.placer(Vector2i(0, 0), "charbon")
	egal.placer(Vector2i(1, 0), "ruban")
	ok = _verifier(egal.forme() == "", "egalite -> informe") and ok
	ok = _verifier(not egal.placer(Vector2i(0, 0), "tison"), "case occupee refusee") and ok
	return _verifier(not egal.placer(Vector2i(9, 0), "tison"), "hors grille refuse") and ok

func _catalyseurs() -> bool:
	var feu := Exemples.nid_feu().eclore()
	var nuit := Exemples.nid_nuit().eclore()
	var sceau: Dictionary = nuit["sorts"].filter(func(s): return s["nom"] == "Sceau")[0]
	# charbon : 1 brulure x 1,5 (plume voisine) ; embrasement : 1 Braise x 1,5 (tison voisin)
	var ok := _verifier(is_equal_approx(feu["brulure_attaque"], 1.5), "plume voisine -> plus de brulure")
	ok = _verifier(is_equal_approx(feu["sorts"][0]["braise"], 1.5), "tison voisin -> plus de braise") and ok
	ok = _verifier(sceau["malediction"] == "langueur", "sceau : pose langueur") and ok
	# baton de braise : 4 + 0,8 x affinite feu (7) en degats, la brulure ne grandit pas
	var b := Exemples.nid_feu()
	b.placer(Vector2i(3, 3), "baton_braise")
	var etincelle: Dictionary = b.eclore()["sorts"].filter(func(s): return s["nom"] == "Étincelle")[0]
	return _verifier(is_equal_approx(etincelle["degats"], 4.0 + 0.8 * 7) and etincelle["brulure"] == 1.0, "le bonus d'affinite va a la valeur principale") and ok

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
	e.deposer(Vector2i(0, 0), "charbon", null)
	var ok := _verifier(e.nid.forme() == "feu" and e.vue.forme == "feu", "poser une braise -> phenix")
	e.deposer(Vector2i(1, 0), "ruban", null)
	e.deposer(Vector2i(2, 0), "sceau", null)
	ok = _verifier(e.vue.forme == "nuit", "plus de nuit -> chauve-souris") and ok
	e.deposer(Vector2i(3, 3), "ruban", Vector2i(1, 0))
	ok = _verifier(e.nid.cases.get(Vector2i(3, 3)) == "ruban" and not e.nid.cases.has(Vector2i(1, 0)), "deplacer une relique") and ok
	e.deposer(Vector2i(0, 0), "ruban", Vector2i(3, 3))
	ok = _verifier(e.nid.cases.get(Vector2i(3, 3)) == "charbon", "echanger deux reliques") and ok
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
	n.placer(Vector2i(1, 0), "fourrure")
	var s: Dictionary = n.eclore()["sorts"][0]
	ok = _verifier(s["cavalier"] and s["nom"] == "Estoc" and s["bouclier"] > 0.0, "sort du cavalier + catalyseur voisin") and ok
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
	p.offres[0] = "charbon"
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
	n.ajouter(Vector2i(0, 0), "charbon")
	n.ajouter(Vector2i(1, 0), "charbon")
	var ok := _verifier(n.cases.size() == 2, "deux copies : pas de fusion")
	n.ajouter(Vector2i(2, 0), "charbon")
	ok = _verifier(n.cases.size() == 1 and n.niveau(Vector2i(2, 0)) == 2, "trois copies : niveau 2 a la derniere pose") and ok
	ok = _verifier(n.affinites()["feu"] == 6, "la fusion garde l'affinite") and ok
	ok = _verifier(is_equal_approx(n.eclore()["brulure_attaque"], 2.5), "niveau 2 : effet x2,5") and ok
	# pose sur une copie quand le Nid est plein
	var m := Nid.new()
	m.ajouter(Vector2i(0, 0), "sceau")
	m.ajouter(Vector2i(1, 0), "sceau")
	ok = _verifier(m.peut_ajouter(Vector2i(0, 0), "sceau") and not m.peut_ajouter(Vector2i(0, 0), "sablier"), "poser sur une copie qui complete un trio") and ok
	m.ajouter(Vector2i(0, 0), "sceau")
	ok = _verifier(m.cases.size() == 1 and m.niveau(Vector2i(0, 0)) == 2, "fusion sur place") and ok
	ok = _verifier(not m.peut_ajouter(Vector2i(0, 0), "sceau"), "une seule copie : pas de pose dessus") and ok
	# cascade : 3 niveaux 2 donnent un niveau 3
	var k := Nid.new()
	for i in 9:
		k.ajouter(Vector2i(i % 4, i / 4), "ruban")
	ok = _verifier(k.cases.size() == 1 and k.niveau(k.cases.keys()[0]) == 3, "9 copies : niveau 3") and ok
	# armes exclues
	var a := Nid.new()
	a.ajouter(Vector2i(0, 0), "lance_guet")
	ok = _verifier(not a.peut_ajouter(Vector2i(0, 0), "lance_guet") and not a.peut_ajouter(Vector2i(1, 0), "lance_guet"), "les armes ne fusionnent pas") and ok
	ok = _verifier(Partie.prix_revente("charbon", 2) == 4, "revente niveau 2 : 9 / 2 = 4") and ok
	n.deplacer(Vector2i(2, 0), Vector2i(3, 3))
	ok = _verifier(n.niveau(Vector2i(3, 3)) == 2 and not n.niveaux.has(Vector2i(2, 0)), "deplacer garde le niveau") and ok
	return ok

func _terre_vent() -> bool:
	var t := Exemples.nid_terre().eclore()
	var v := Exemples.nid_vent().eclore()
	var ok := _verifier(t["nom"] == "Tortue" and v["nom"] == "Cheval", "terre -> tortue, vent -> cheval")
	# briques : 0,06 chacune, celle a cote du fossile x1,5 ; cale (a cote du fossile) 0,08 x1,5
	ok = _verifier(is_equal_approx(t["reduction"], 0.06 * 1.5 + 0.06) and is_equal_approx(t["cale"], 0.12), "brique, cale et fossile") and ok
	var mortier: Dictionary = t["sorts"][0]
	# truelle : (15 + 1,5 x terre 8) x 1,5 (fossile voisin) ; aucun degat
	ok = _verifier(is_equal_approx(mortier["mortier"], (15.0 + 1.5 * 8) * 1.5) and mortier["degats"] == 0.0, "truelle : mortier selon affinite, fossile") and ok
	ok = _verifier(is_equal_approx(v["esquive"], Data.ESQUIVE_CHEVAL + 0.06), "cheval : esquive passive + duvet") and ok
	# combat : le bouclier encaisse, le cheval charge l'Elan et lance la Foudre
	var c := Combat.new(t, v)
	c.simuler()
	ok = _verifier(c.evenements.any(func(e): return e["type"] == "foudre"), "le cheval lance la foudre") and ok
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
	c.cotes[1]["bouclier"] = 30.0
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

func _glace() -> bool:
	var cr := Exemples.nid_glace().eclore()
	var ok := _verifier(cr["nom"] == "Loup", "glace -> loup")
	# givre par attaque : 1 (passif) + 1 x 1,5 (flocon a cote du croc)
	ok = _verifier(is_equal_approx(cr["givre_attaque"], 2.5), "croc du blizzard renforce le flocon voisin") and ok
	# armure de givre : (6 + 1 x glace 7) x 1,5 (fourrure voisine)
	ok = _verifier(is_equal_approx(cr["sorts"][0]["bouclier"], (6.0 + 1.0 * 7) * 1.5), "armure de givre et fourrure") and ok
	# givre : ralentit, puis gele au seuil
	var c := Combat.new(cr, Nid.new().eclore())
	c._givrer(c.cotes[0], c.cotes[1], 5.0)
	ok = _verifier(is_equal_approx(c._vitesse(c.cotes[1]), 1.0 - 5 * Data.GIVRE_RALENTI), "le givre ralentit") and ok
	c._givrer(c.cotes[0], c.cotes[1], 5.0)
	ok = _verifier(c._gele(c.cotes[1]) and c._vitesse(c.cotes[1]) == 0.0 and c.cotes[1]["givre"] == 0.0, "10 charges : gel, charges a zero") and ok
	# bris : eclat de givre blesse l'attaquant
	var d := Combat.new(cr, Nid.new().eclore())
	d.cotes[0]["bouclier"] = 5.0
	var pv: float = d.cotes[1]["pv"]
	d._frapper(d.cotes[1], d.cotes[0], 10.0, 0.0)
	ok = _verifier(d.evenements.any(func(e): return e["type"] == "bris") and d.cotes[1]["pv"] <= pv - 12.0, "bouclier brise : eclat de givre") and ok
	# ecorce, rose, noyau, coeur de banquise
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "ecorce")
	n.placer(Vector2i(1, 0), "rose_neiges")
	n.placer(Vector2i(2, 0), "noyau_hiver")
	n.placer(Vector2i(3, 0), "coeur_banquise")
	var e := Combat.new(n.eclore(), Nid.new().eclore())
	e.cotes[1]["givre"] = 2.0
	e.cotes[0]["bouclier"] = 1.0
	e._frapper(e.cotes[1], e.cotes[0], 5.0, 0.0)
	ok = _verifier(e._gele(e.cotes[1]), "noyau : nova qui gele une cible ralentie") and ok
	ok = _verifier(e.cotes[0]["bouclier"] >= 25.0, "coeur de banquise : bouclier au gel") and ok
	ok = _verifier(e.cotes[0]["reforme_a"] == e.t + Data.REFORME_DELAI, "ecorce : bouclier reforme plus tard") and ok
	var rose := Combat.new(n.eclore(), Nid.new().eclore())
	rose.cotes[0]["bouclier"] = 1.0
	rose._blesser(rose.cotes[0], 5.0, rose.cotes[1])
	rose.cotes[1]["gele_jusqu"] = 0.0
	rose.cotes[1]["givre"] = 0.0
	rose._givrer(rose.cotes[0], rose.cotes[1], Data.GEL_SEUIL - Data.ROSE_RABAIS)
	ok = _verifier(rose._gele(rose.cotes[1]), "rose des neiges : gel plus tot apres un bris") and ok
	# armes : fracas, brise-gel, hachette
	var f := Nid.new()
	f.placer(Vector2i(0, 0), "hache_glace")
	var g := Combat.new(f.eclore(), Nid.new().eclore())
	g.cotes[0]["bouclier"] = 30.0
	g.cotes[0]["sorts"][0]["prochain"] = 0.0
	var avant: float = g.cotes[1]["pv"]
	g._agir(g.cotes[0], g.cotes[1])
	ok = _verifier(g.cotes[0]["bouclier"] == 0.0 and avant - g.cotes[1]["pv"] >= 40.0 - 0.01, "fracas : bouclier ajoute aux degats") and ok
	var l := Nid.new()
	l.placer(Vector2i(0, 0), "lance_hiver")
	var h := Combat.new(l.eclore(), Nid.new().eclore())
	h.cotes[1]["gele_jusqu"] = 5.0
	h.cotes[0]["sorts"][0]["prochain"] = 0.0
	avant = h.cotes[1]["pv"]
	h._agir(h.cotes[0], h.cotes[1])
	ok = _verifier(avant - h.cotes[1]["pv"] >= 48.0 - 0.01 and not h._gele(h.cotes[1]), "brise-gel : x4 et fin du gel") and ok
	# un combat complet gele bien l'adversaire
	var k := Combat.new(cr, Exemples.nid_feu().eclore())
	k.simuler()
	return _verifier(k.evenements.any(func(ev): return ev["type"] == "gel"), "le loup gele en vrai combat") and ok

func _phenix() -> bool:
	var vide := Nid.new().eclore()
	var c := Combat.new(Exemples.nid_feu().eclore(), vide)
	# brulure : s'empile, chaque charge s'eteint au bout de 4 s
	c._bruler(c.cotes[0], c.cotes[1], 3.0)
	c._bruler(c.cotes[0], c.cotes[1], 2.0)
	var ok := _verifier(c._brulure(c.cotes[1]) == 5.0, "la brulure s'empile")
	c.t = Data.BRULURE_DUREE + 0.1
	c._subir(c.cotes[1], c.cotes[0])
	ok = _verifier(c._brulure(c.cotes[1]) == 0.0, "les charges s'eteignent") and ok
	# combustion partielle : la moitie, totale : tout x1,5 ; Braise et hate
	var d := Combat.new(Exemples.nid_feu().eclore(), vide)
	d._bruler(d.cotes[0], d.cotes[1], 10.0)
	var pv: float = d.cotes[1]["pv"]
	d._combustion(d.cotes[0], d.cotes[1], 0.5, false, 1.0)
	ok = _verifier(d._brulure(d.cotes[1]) == 5.0 and is_equal_approx(pv - d.cotes[1]["pv"], 5.0 * Data.COMBUSTION_PAR_CHARGE), "combustion partielle") and ok
	pv = d.cotes[1]["pv"]
	d._combustion(d.cotes[0], d.cotes[1], 1.0, true, 1.0)
	ok = _verifier(d._brulure(d.cotes[1]) == 0.0 and is_equal_approx(pv - d.cotes[1]["pv"], 5.0 * Data.COMBUSTION_PAR_CHARGE * Data.COMBUSTION_TOTALE_BONUS), "combustion totale") and ok
	ok = _verifier(d.cotes[0]["braise"] == 2.0 and is_equal_approx(d._vitesse(d.cotes[0]), 1.0 + 2 * Data.HATE_PAR_BRAISE), "braise : hate") and ok
	# cendre tiede : la combustion soigne (sauf belladone)
	d.cotes[0]["pv"] = 100.0
	d._bruler(d.cotes[0], d.cotes[1], 4.0)
	d._combustion(d.cotes[0], d.cotes[1], 1.0, false, 0.0)
	ok = _verifier(d.cotes[0]["pv"] > 100.0, "cendre tiede : soin a la combustion") and ok
	# resine : brulure doublee sous la moitie de sa vie
	var r := Nid.new()
	r.placer(Vector2i(0, 0), "resine")
	var e := Combat.new(r.eclore(), vide)
	e.cotes[0]["pv"] = 10.0
	e._bruler(e.cotes[0], e.cotes[1], 2.0)
	ok = _verifier(e._brulure(e.cotes[1]) == 4.0, "resine : brulure doublee vie basse") and ok
	# coeur de fournaise : une fois sous la moitie
	var f := Nid.new()
	f.placer(Vector2i(0, 0), "coeur_fournaise")
	var g := Combat.new(f.eclore(), vide)
	g._bruler(g.cotes[0], g.cotes[1], 6.0)
	g.cotes[0]["pv"] = 100.0
	g._subir(g.cotes[0], g.cotes[1])
	ok = _verifier(g.cotes[0]["fournaise_faite"] and g._brulure(g.cotes[1]) == 0.0 and g._braise(g.cotes[0]) >= Data.FOURNAISE_BRAISE, "coeur de fournaise") and ok
	# oeuf : seconde renaissance, chacune avec une combustion totale
	var o := Exemples.nid_feu()
	o.placer(Vector2i(3, 3), "oeuf_brasier")
	var h := Combat.new(o.eclore(), vide)
	ok = _verifier(h.cotes[0]["renaissances"] == 2, "oeuf : deux renaissances") and ok
	h._bruler(h.cotes[0], h.cotes[1], 6.0)
	h.cotes[0]["pv"] = -1.0
	ok = _verifier(not h._mort(h.cotes[0], h.cotes[1]) and h._brulure(h.cotes[1]) == 0.0, "oeuf : renaissance et combustion totale") and ok
	h.cotes[0]["pv"] = -1.0
	ok = _verifier(not h._mort(h.cotes[0], h.cotes[1]), "oeuf : seconde renaissance") and ok
	h.cotes[0]["pv"] = -1.0
	ok = _verifier(h._mort(h.cotes[0], h.cotes[1]), "plus de renaissance") and ok
	# baton du premier brasier : combustion au 4e tir, tir a la renaissance
	var p := Exemples.nid_feu()
	p.placer(Vector2i(3, 3), "baton_premier")
	var k := Combat.new(p.eclore(), vide)
	var baton: Dictionary = k.cotes[0]["sorts"].filter(func(s): return s["nom"] == "Premier brasier")[0]
	for i in 3:
		k._lancer(k.cotes[0], k.cotes[1], baton)
	ok = _verifier(not k.evenements.any(func(ev): return ev["type"] == "combustion"), "pas de combustion avant le 4e tir") and ok
	k._lancer(k.cotes[0], k.cotes[1], baton)
	ok = _verifier(k.evenements.any(func(ev): return ev["type"] == "combustion"), "combustion au 4e tir") and ok
	k.cotes[0]["pv"] = -1.0
	var n_sorts := k.evenements.filter(func(ev): return ev["type"] == "sort").size()
	k._mort(k.cotes[0], k.cotes[1])
	ok = _verifier(k.evenements.filter(func(ev): return ev["type"] == "sort").size() == n_sorts + 1, "tir a la renaissance") and ok
	# faux de tison : x1,5 sous la moitie ; faux des cendres : combustion contre une cible affaiblie
	var t := Nid.new()
	t.placer(Vector2i(0, 0), "faux_tison")
	var m := Combat.new(t.eclore(), vide)
	m.cotes[1]["pv"] = 100.0
	m._lancer(m.cotes[0], m.cotes[1], m.cotes[0]["sorts"][0])
	ok = _verifier(is_equal_approx(100.0 - m.cotes[1]["pv"], 8.0 * 1.5), "faux de tison : achever") and ok
	var fc := Nid.new()
	fc.placer(Vector2i(0, 0), "faux_cendres")
	var q := Combat.new(fc.eclore(), vide)
	q._bruler(q.cotes[0], q.cotes[1], 5.0)
	q.cotes[1]["pv"] = 100.0
	q._lancer(q.cotes[0], q.cotes[1], q.cotes[0]["sorts"][0])
	return _verifier(q._brulure(q.cotes[1]) == 0.0, "faux des cendres : combustion contre une cible affaiblie") and ok

func _nuit() -> bool:
	var vide := Nid.new().eclore()
	var nuit := Exemples.nid_nuit().eclore()
	var ok := _verifier(nuit["nom"] == "Chauve-souris" and nuit["faiblesse_tous"] == 3 and nuit["sablier"] == 3.0, "nuit : aiguille et sablier")
	# maledictions : une charge sans chapelet, 3 avec ; durees ; sablier
	var c := Combat.new(vide, vide)
	c._maudire(c.cotes[0], c.cotes[1], "faiblesse")
	c._maudire(c.cotes[0], c.cotes[1], "faiblesse")
	ok = _verifier(c._charges(c.cotes[1], "faiblesse") == 1, "sans chapelet : une charge") and ok
	c.t = Data.MALEDICTION_DUREE + 0.1
	ok = _verifier(c._charges(c.cotes[1], "faiblesse") == 0, "la malediction expire") and ok
	var ch := Nid.new()
	ch.placer(Vector2i(0, 0), "chapelet")
	var d := Combat.new(ch.eclore(), vide)
	for i in 5:
		d._maudire(d.cotes[0], d.cotes[1], "faiblesse")
	ok = _verifier(d._charges(d.cotes[1], "faiblesse") == 3, "chapelet : jusqu'a 3 charges") and ok
	var sb := Combat.new(nuit, vide)
	sb._maudire(sb.cotes[0], sb.cotes[1], "langueur")
	sb.t = Data.MALEDICTION_DUREE + 1.0
	ok = _verifier(sb._charges(sb.cotes[1], "langueur") == 1, "sablier : malediction prolongee") and ok
	# faiblesse : moins de degats ; fletrissure : moins de soins ; langueur : attaques plus lentes
	var e := Combat.new(vide, vide)
	e.cotes[0]["maledictions"]["faiblesse"] = {"n": 1, "fin": 99.0}
	var pv: float = e.cotes[1]["pv"]
	e._frapper(e.cotes[0], e.cotes[1], 10.0, 0.0)
	ok = _verifier(is_equal_approx(pv - e.cotes[1]["pv"], 10.0 * (1.0 - Data.FAIBLESSE)), "faiblesse : moins de degats") and ok
	e.cotes[0]["maledictions"]["fletrissure"] = {"n": 1, "fin": 99.0}
	e.cotes[0]["pv"] = 100.0
	e._soigner(e.cotes[0], e.cotes[1], 20.0)
	ok = _verifier(is_equal_approx(e.cotes[0]["pv"], 100.0 + 20.0 * (1.0 - Data.FLETRISSURE)), "fletrissure : moins de soins") and ok
	var l := Combat.new(vide, vide)
	l.cotes[0]["maledictions"]["langueur"] = {"n": 1, "fin": 99.0}
	l.simuler()
	var att := [0, 0]
	for ev in l.evenements:
		if ev["type"] == "attaque" and ev["t"] < 10.0:
			att[ev["cote"]] += 1
	ok = _verifier(att[0] < att[1], "langueur : moins d'attaques") and ok
	# crit : la Lame donne du crit, le Peigne pose Fletrissure, la Lame de la veuve une malediction
	var lame := Nid.new()
	lame.placer(Vector2i(0, 0), "lame_veuve")
	lame.placer(Vector2i(1, 0), "peigne")
	var lcr := lame.eclore()
	ok = _verifier(is_equal_approx(lcr["crit"], 0.15 + 0.08) and lcr["crit_malediction"] and lcr["crit_fletrissure"], "crit des lames et du peigne") and ok
	var dague := Nid.new()
	dague.placer(Vector2i(0, 0), "dague_epine")
	ok = _verifier(is_equal_approx(dague.eclore()["crit"], Data.CRIT_LAME), "les lames du cerf donnent aussi du crit") and ok
	var f := Combat.new(lcr, vide)
	for i in 60:
		f._frapper(f.cotes[0], f.cotes[1], 1.0, 0.0)
	ok = _verifier(f.evenements.any(func(ev): return ev["type"] == "crit") and f._charges(f.cotes[1], "fletrissure") > 0, "crit : fletrissure posee") and ok
	# poupee : renvoie a un adversaire maudit
	var po := Nid.new()
	po.placer(Vector2i(0, 0), "poupee")
	var g := Combat.new(po.eclore(), vide)
	pv = g.cotes[1]["pv"]
	g._frapper(g.cotes[1], g.cotes[0], 10.0, 0.0)
	ok = _verifier(g.cotes[1]["pv"] == pv, "poupee : rien sans malediction") and ok
	g.cotes[1]["maledictions"]["langueur"] = {"n": 1, "fin": 99.0}
	g._frapper(g.cotes[1], g.cotes[0], 10.0, 0.0)
	ok = _verifier(is_equal_approx(pv - g.cotes[1]["pv"], 3.0), "poupee : renvoie 30 %") and ok
	# masque, grimoire, pacte
	var mg := Nid.new()
	mg.placer(Vector2i(0, 0), "masque")
	mg.placer(Vector2i(1, 0), "grimoire")
	mg.placer(Vector2i(2, 0), "pacte")
	var h := Combat.new(mg.eclore(), vide)
	for nom in Data.MALEDICTIONS:
		h.cotes[1]["maledictions"][nom] = {"n": 1, "fin": 99.0}
	h.cotes[0]["pv"] = 100.0
	h._frapper(h.cotes[0], h.cotes[1], 10.0, 0.0)
	ok = _verifier(h.cotes[0]["pv"] > 100.0, "masque : vol de vie par malediction") and ok
	var gr := Combat.new(mg.eclore(), vide)
	gr.cotes[0]["pv"] = 10.0
	gr._soigner(gr.cotes[0], gr.cotes[1], 45.0)
	ok = _verifier(gr._nb_maledictions(gr.cotes[1]) == 1, "grimoire : malediction apres 40 PV voles") and ok
	h.cotes[0]["prochaine_attaque"] = 0.0
	pv = h.cotes[1]["pv"]
	h._agir(h.cotes[0], h.cotes[1])
	ok = _verifier(pv - h.cotes[1]["pv"] >= Data.ATTAQUE_BASE + 5.0 - 0.01, "pacte : drain sous trois maledictions") and ok
	# faux du festin : +35 % par malediction ; faux de la nuit profonde : consume
	var ff := Nid.new()
	ff.placer(Vector2i(0, 0), "faux_festin")
	var k := Combat.new(ff.eclore(), vide)
	k.cotes[1]["maledictions"]["faiblesse"] = {"n": 1, "fin": 99.0}
	k.cotes[1]["maledictions"]["langueur"] = {"n": 1, "fin": 99.0}
	pv = k.cotes[1]["pv"]
	k._lancer(k.cotes[0], k.cotes[1], k.cotes[0]["sorts"][0])
	# +35 % par malediction (faux) et +12 % par malediction (passif de la Chauve-souris)
	ok = _verifier(is_equal_approx(pv - k.cotes[1]["pv"], 10.0 * 1.7 * (1.0 + 2 * Data.NUIT_PAR_MALEDICTION)), "faux du festin") and ok
	var fn := Nid.new()
	fn.placer(Vector2i(0, 0), "faux_nuit")
	var n := Combat.new(fn.eclore(), vide)
	n.cotes[1]["maledictions"]["faiblesse"] = {"n": 2, "fin": 99.0}
	pv = n.cotes[1]["pv"]
	n._lancer(n.cotes[0], n.cotes[1], n.cotes[0]["sorts"][0])
	return _verifier(n._nb_maledictions(n.cotes[1]) == 0 and is_equal_approx(pv - n.cotes[1]["pv"], 10.0 + 2 * Data.FESTIN_DEGATS), "faux de la nuit profonde : consume") and ok

func _aube() -> bool:
	var vide := Nid.new().eclore()
	var cr := Exemples.nid_aube().eclore()
	var ok := _verifier(cr["nom"] == "Lion" and cr["eclat"] and cr["regen"] == Data.REGEN_LION, "aube -> lion")
	# meche : (8 + 1 x aube 7) x 1,5 (huile voisine)
	ok = _verifier(is_equal_approx(cr["sorts"][0]["soin"], (8.0 + 7.0) * 1.5), "meche et huile voisine") and ok
	# charge : soin a moitie, excedent double
	var c := Combat.new(cr, vide)
	c.cotes[0]["pv"] = c.cotes[0]["cr"]["pv_max"] - 10.0
	c._soigner(c.cotes[0], c.cotes[1], 20.0)
	ok = _verifier(is_equal_approx(c.cotes[0]["eclat_jauge"], 10.0 * Data.ECLAT_PAR_SOIN + 10.0 * Data.ECLAT_PAR_EXCES), "eclat : soin et excedent") and ok
	# seuil (60 - miroir 10) : l'Eclat part
	var pv: float = c.cotes[1]["pv"]
	c._charger_eclat(c.cotes[0], c.cotes[1], 30.0)
	ok = _verifier(c.cotes[1]["pv"] == pv - Data.ECLAT_DEGATS and c.cotes[0]["eclat_jauge"] < 50.0, "eclat au seuil, miroir") and ok
	# soin bloque par la belladone : charge quand meme
	var b := Nid.new()
	b.placer(Vector2i(0, 0), "belladone")
	var d := Combat.new(cr, b.eclore())
	d.cotes[0]["poison"] = 5.0
	d.cotes[0]["pv"] = 100.0
	d._soigner(d.cotes[0], d.cotes[1], 20.0)
	ok = _verifier(d.cotes[0]["pv"] == 100.0 and d.cotes[0]["eclat_jauge"] > 0.0, "soin bloque : charge quand meme") and ok
	# prisme, lanterne, encensoir, carillon, vasque
	var n := Exemples.nid_aube()
	n.placer(Vector2i(0, 2), "prisme")
	n.placer(Vector2i(1, 2), "lanterne")
	n.placer(Vector2i(2, 2), "encensoir")
	n.placer(Vector2i(3, 2), "carillon")
	n.placer(Vector2i(0, 3), "vasque")
	var e := Combat.new(n.eclore(), vide)
	e.cotes[0]["exces_accumule"] = 20.0
	pv = e.cotes[1]["pv"]
	e._eclat(e.cotes[0], e.cotes[1])
	ok = _verifier(is_equal_approx(pv - e.cotes[1]["pv"], Data.ECLAT_DEGATS + 15.0 + 20.0), "eclat : prisme et lanterne") and ok
	ok = _verifier(e.cotes[0]["encensoir_jusqu"] > e.t, "encensoir : regeneration renforcee") and ok
	e.cotes[0]["pv"] = 100.0
	e._eclat(e.cotes[0], e.cotes[1])
	e._eclat(e.cotes[0], e.cotes[1])
	ok = _verifier(e.cotes[0]["pv"] >= 140.0, "carillon : gros soin au 3e eclat") and ok
	var v := Combat.new(n.eclore(), vide)
	v._soigner(v.cotes[0], v.cotes[1], 20.0)
	ok = _verifier(is_equal_approx(v.cotes[0]["bouclier"], 10.0), "vasque : l'excedent devient bouclier") and ok
	# bande de lin : regeneration renforcee sous la moitie
	var w := Combat.new(cr, vide)
	w.cotes[0]["pv"] = 100.0
	w._subir(w.cotes[0], w.cotes[1])
	ok = _verifier(w.cotes[0]["pv"] > 100.0 + Data.REGEN_LION * Data.PAS + 0.01, "bande de lin : regeneration renforcee") and ok
	# armes : hachette charge, hache solaire double apres un eclat, sceptre : eclat tous les 4 tirs
	var h := Nid.new()
	h.placer(Vector2i(0, 0), "hachette_matin")
	h.placer(Vector2i(1, 0), "miroir")
	var k := Combat.new(h.eclore(), vide)
	k._lancer(k.cotes[0], k.cotes[1], k.cotes[0]["sorts"][0])
	ok = _verifier(k.cotes[0]["eclat_jauge"] >= 15.0, "hachette du matin : charge l'eclat") and ok
	var hs := Nid.new()
	hs.placer(Vector2i(0, 0), "hache_solaire")
	var m := Combat.new(hs.eclore(), vide)
	m.cotes[0]["eclat_pret"] = true
	pv = m.cotes[1]["pv"]
	m._lancer(m.cotes[0], m.cotes[1], m.cotes[0]["sorts"][0])
	ok = _verifier(is_equal_approx(pv - m.cotes[1]["pv"], 24.0) and not m.cotes[0]["eclat_pret"], "hache solaire : double apres un eclat") and ok
	var sp := Nid.new()
	sp.placer(Vector2i(0, 0), "sceptre_premier")
	var q := Combat.new(sp.eclore(), vide)
	for i in 4:
		q._lancer(q.cotes[0], q.cotes[1], q.cotes[0]["sorts"][0])
	return _verifier(q.evenements.filter(func(ev): return ev["type"] == "eclat").size() == 1, "sceptre du premier matin : eclat au 4e tir") and ok

func _crepuscule() -> bool:
	var vide := Nid.new().eclore()
	var cr := Exemples.nid_crepuscule().eclore()
	var ok := _verifier(cr["nom"] == "Papillon" and cr["arcane"], "crepuscule -> papillon")
	# poudres : 4 x 1,5 chacune (toutes deux a cote du pollen) ; battement : (10 + 0,5 x crepuscule 8) x 1,5
	ok = _verifier(is_equal_approx(cr["poudre"], 4.0 * 1.5 * 2), "pollen renforce les poudres voisines") and ok
	ok = _verifier(is_equal_approx(cr["sorts"][0]["puissance"], (10.0 + 0.5 * 8) * 1.5), "battement : puissance et pollen") and ok
	ok = _verifier(cr["bouclier"] == 20.0, "cocon : bouclier de depart") and ok
	# renvoyer le malus le plus lourd
	var c := Combat.new(cr, vide)
	c.cotes[0]["poison"] = 12.0
	c.cotes[0]["givre"] = 3.0
	c._transfert(c.cotes[0], c.cotes[1], "renvoyer", 10.0)
	ok = _verifier(c.cotes[0]["poison"] == 0.0 and c.cotes[1]["poison"] == 12.0 and c.cotes[0]["givre"] == 3.0, "renvoie le malus le plus lourd") and ok
	# rien a renvoyer : projectile d'arcane, et le Cocon rend du bouclier
	var pv: float = c.cotes[1]["pv"]
	c.cotes[0]["givre"] = 0.0
	var b0: float = c.cotes[0]["bouclier"]
	c._transfert(c.cotes[0], c.cotes[1], "renvoyer", 10.0)
	ok = _verifier(c.cotes[1]["pv"] == pv - 10.0 and c.evenements.any(func(e): return e["type"] == "arcane"), "rien a renvoyer : projectile d'arcane") and ok
	ok = _verifier(c.cotes[0]["bouclier"] == b0 + 3.0, "cocon : bouclier a chaque transfert") and ok
	# un non-Papillon ne tire pas d'arcane
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "poudre")
	n.placer(Vector2i(1, 0), "charbon")
	n.placer(Vector2i(2, 0), "charbon")
	var d := Combat.new(n.eclore(), vide)
	pv = d.cotes[1]["pv"]
	d._transfert(d.cotes[0], d.cotes[1], "renvoyer", 10.0)
	ok = _verifier(d.cotes[1]["pv"] == pv and d.cotes[0]["transferts"] == 0, "pas d'arcane hors Papillon") and ok
	# vol : bouclier, braise ; brume et aile de lune
	var v := Nid.new()
	v.placer(Vector2i(0, 0), "brume")
	v.placer(Vector2i(1, 0), "aile_lune")
	v.placer(Vector2i(2, 0), "battement")
	var e := Combat.new(v.eclore(), vide)
	e.cotes[1]["bouclier"] = 30.0
	e.cotes[1]["braise"] = 3.0
	e.cotes[0]["pv"] = 100.0
	e._transfert(e.cotes[0], e.cotes[1], "voler", 8.0)
	ok = _verifier(e.cotes[1]["bouclier"] == 22.0 and e.cotes[0]["bouclier"] == 8.0, "vole le bonus le plus lourd (bouclier)") and ok
	ok = _verifier(e.cotes[0]["pv"] > 100.0 and e._braise(e.cotes[0]) >= Data.AILE_BRAISE, "brume soigne, aile de lune accelere") and ok
	# mue : malus renvoye renforce
	var m := Nid.new()
	m.placer(Vector2i(0, 0), "mue")
	var f := Combat.new(m.eclore(), vide)
	f.cotes[0]["poison"] = 10.0
	f._transfert(f.cotes[0], f.cotes[1], "renvoyer", 5.0)
	ok = _verifier(f.cotes[1]["poison"] == 15.0, "mue : renvoi renforce") and ok
	# phalene : chaque transfert declenche une attaque
	var ph := Nid.new()
	ph.placer(Vector2i(0, 0), "phalene")
	var g := Combat.new(ph.eclore(), vide)
	pv = g.cotes[1]["pv"]
	g._transfert(g.cotes[0], g.cotes[1], "renvoyer", 5.0)
	ok = _verifier(is_equal_approx(pv - g.cotes[1]["pv"], 5.0 + Data.ATTAQUE_BASE), "phalene : arcane puis attaque") and ok
	# chrysalide : sous la moitie, renvoie tout et vole tout
	var ch := Nid.new()
	ch.placer(Vector2i(0, 0), "chrysalide")
	var h := Combat.new(ch.eclore(), vide)
	h.cotes[0]["poison"] = 5.0
	h.cotes[0]["givre"] = 2.0
	h.cotes[1]["bouclier"] = 40.0
	h.cotes[0]["pv"] = 100.0
	h._subir(h.cotes[0], h.cotes[1])
	ok = _verifier(h.cotes[0]["poison"] == 0.0 and h.cotes[0]["givre"] == 0.0 and h.cotes[0]["bouclier"] == 40.0, "chrysalide : tout renvoyer, tout voler") and ok
	# inversion : a 12 s, echange des pourcentages de vie
	var iv := Nid.new()
	iv.placer(Vector2i(0, 0), "inversion")
	var k := Combat.new(iv.eclore(), vide)
	k.cotes[0]["pv"] = 30.0
	k.cotes[1]["pv"] = 270.0
	k.t = Data.INVERSION_T
	k._subir(k.cotes[0], k.cotes[1])
	ok = _verifier(is_equal_approx(k.cotes[0]["pv"], 270.0) and is_equal_approx(k.cotes[1]["pv"], 30.0), "inversion : echange des pourcentages") and ok
	# arc des deux lunes : plus fort par transfert ; fleches tous les 3 tirs
	var al := Nid.new()
	al.placer(Vector2i(0, 0), "arc_lunes")
	var q := Combat.new(al.eclore(), vide)
	q.cotes[0]["transferts"] = 4
	pv = q.cotes[1]["pv"]
	q._lancer(q.cotes[0], q.cotes[1], q.cotes[0]["sorts"][0])
	ok = _verifier(is_equal_approx(pv - q.cotes[1]["pv"], 6.0 + 4 * 1.5), "arc des deux lunes") and ok
	var fl := Exemples.nid_crepuscule()
	fl.placer(Vector2i(3, 3), "flechettes")
	var r := Combat.new(fl.eclore(), vide)
	var fle: Dictionary = r.cotes[0]["sorts"].filter(func(s): return s["nom"] == "Fléchettes")[0]
	for i in 3:
		r._lancer(r.cotes[0], r.cotes[1], fle)
	return _verifier(r.cotes[0]["transferts"] == 1, "flechettes : transfert tous les 3 tirs") and ok

func _vent() -> bool:
	var vide := Nid.new().eclore()
	var cr := Exemples.nid_vent().eclore()
	var ok := _verifier(cr["elan"] and is_equal_approx(cr["ruban_criniere"], 6.0), "vent : elan et rubans")
	# grelot : 15 d'Elan x 1,5 (fer voisin)
	ok = _verifier(is_equal_approx(cr["sorts"][0]["elan"], 22.5), "fer voisin : plus d'elan") and ok
	# Elan : la Foudre part au seuil, ne s'esquive pas
	var c := Combat.new(cr, vide)
	var pv: float = c.cotes[1]["pv"]
	c._gagner_elan(c.cotes[0], c.cotes[1], 100.0)
	ok = _verifier(c.cotes[1]["pv"] == pv - Data.FOUDRE_DEGATS and c.cotes[0]["elan_jauge"] == 0.0, "foudre a 100 d'elan") and ok
	# esquive : de l'Elan et la hate du Ruban
	var d := Combat.new(cr, vide)
	d._esquive_reussie(d.cotes[0], d.cotes[1])
	ok = _verifier(d.cotes[0]["elan_jauge"] == Data.ELAN_PAR_ESQUIVE and d._braise(d.cotes[0]) == 6.0, "esquive : elan et hate") and ok
	# etrier : la serie donne plus d'Elan, un coup recu la casse
	var e_nid := Nid.new()
	e_nid.placer(Vector2i(0, 0), "etrier")
	e_nid.placer(Vector2i(1, 0), "duvet")
	var e := Combat.new(e_nid.eclore(), vide)
	e.cotes[0]["prochaine_attaque"] = 0.0
	e._agir(e.cotes[0], e.cotes[1])
	e.cotes[0]["prochaine_attaque"] = 0.0
	e._agir(e.cotes[0], e.cotes[1])
	ok = _verifier(e.cotes[0]["elan_jauge"] == 10.0 + 2.0 + 10.0 + 4.0, "etrier : elan de serie") and ok
	e.cotes[0]["cr"]["esquive"] = 0.0
	e._frapper(e.cotes[1], e.cotes[0], 1.0, 0.0)
	ok = _verifier(e.cotes[0]["serie"] == 0, "etrier : un coup recu casse la serie") and ok
	# manche, eventail, girouette, voile de cavale, bride
	var f_nid := Exemples.nid_vent()
	var libres := [Vector2i(2, 1), Vector2i(3, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
	for id in ["manche", "eventail", "girouette_indocile", "voile_cavale", "bride"]:
		f_nid.placer(libres.pop_front(), id)
	var f := Combat.new(f_nid.eclore(), vide)
	f._esquive_reussie(f.cotes[0], f.cotes[1])
	ok = _verifier(f.cotes[0]["girouette_bonus"] == 5.0, "girouette : la foudre grossit") and ok
	pv = f.cotes[1]["pv"]
	f._gagner_elan(f.cotes[0], f.cotes[1], 80.0 - f.cotes[0]["elan_jauge"])
	ok = _verifier(is_equal_approx(pv - f.cotes[1]["pv"], Data.FOUDRE_DEGATS + 15.0 + 5.0), "manche (seuil 80), eventail, girouette") and ok
	ok = _verifier(is_equal_approx(f._esquive(f.cotes[0]), minf(f.cotes[0]["cr"]["esquive"] + 0.3, Data.ESQUIVE_MAX_TEMP)), "voile de cavale : esquive renforcee") and ok
	ok = _verifier(f.cotes[0]["galop_jusqu"] > f.t, "bride : galop libre") and ok
	var fin: float = f.cotes[0]["galop_jusqu"]
	f._foudre(f.cotes[0], f.cotes[1])
	ok = _verifier(f.cotes[0]["galop_jusqu"] == fin, "bride : pas renouvele pendant le galop") and ok
	f.cotes[0]["elan_jauge"] = 0.0
	f._gagner_elan(f.cotes[0], f.cotes[1], 10.0)
	ok = _verifier(f.cotes[0]["elan_jauge"] == 20.0, "galop libre : elan double") and ok
	# sabre : riposte de 3 coups apres une esquive ; lance : double apres la foudre
	var sb := Nid.new()
	sb.placer(Vector2i(0, 0), "sabre_rafale")
	var g := Combat.new(sb.eclore(), vide)
	pv = g.cotes[1]["pv"]
	g._esquive_reussie(g.cotes[0], g.cotes[1])
	ok = _verifier(pv - g.cotes[1]["pv"] == 9.0, "sabre de rafale : riposte de 3 coups") and ok
	var lb := Nid.new()
	lb.placer(Vector2i(0, 0), "lance_bourrasque")
	var h := Combat.new(lb.eclore(), vide)
	h.cotes[0]["foudre_prete"] = true
	h.cotes[1]["esquive"] = true
	pv = h.cotes[1]["pv"]
	h._lancer(h.cotes[0], h.cotes[1], h.cotes[0]["sorts"][0])
	ok = _verifier(pv - h.cotes[1]["pv"] == 20.0 and not h.cotes[0]["foudre_prete"], "lance de bourrasque : perce et double") and ok
	# javelot : l'attaque suivante arrive plus tot
	var jv := Nid.new()
	jv.placer(Vector2i(0, 0), "javelot_alizes")
	var j := Combat.new(jv.eclore(), vide)
	var avant: float = j.cotes[0]["prochaine_attaque"]
	j._lancer(j.cotes[0], j.cotes[1], j.cotes[0]["sorts"][0])
	return _verifier(is_equal_approx(j.cotes[0]["prochaine_attaque"], avant - Data.ALIZE_AVANCE), "javelot des alizes") and ok

func _vitesses() -> bool:
	var e := CombatScreen.new(Exemples.nid_feu().eclore(), Exemples.nid_nuit().eclore())
	add_child(e)
	var vues := []
	for i in 4:
		vues.append([e.vitesse, e.bouton_vitesse.text])
		e._changer_vitesse()
	e.queue_free()
	return _verifier(vues == [[1.0, "Vitesse x1"], [2.0, "Vitesse x2"], [3.0, "Vitesse x3"], [1.0, "Vitesse x1"]], "vitesse x1, x2, x3 puis x1")

func _terre() -> bool:
	var vide := Nid.new().eclore()
	var cr := Exemples.nid_terre().eclore()
	# reduction : sur les coups, avant le bouclier ; la cale ne compte qu'avec du bouclier
	var c := Combat.new(vide, cr)
	var pv: float = c.cotes[1]["pv"]
	c._blesser(c.cotes[1], 100.0, c.cotes[0])
	var ok_reduc := is_equal_approx(pv - c.cotes[1]["pv"], 100.0 * (1.0 - cr["reduction"]))
	var ok := _verifier(ok_reduc, "reduction de degats")
	c.cotes[1]["bouclier"] = 500.0
	ok = _verifier(is_equal_approx(c._reduction(c.cotes[1]), cr["reduction"] + cr["cale"]), "cale : seulement avec du bouclier") and ok
	var plein := Nid.new()
	for i in 12:
		plein.placer(Vector2i(i % 4, i / 4), "brique")
	var d := Combat.new(plein.eclore(), vide)
	ok = _verifier(d._reduction(d.cotes[0]) == Data.REDUCTION_MAX, "reduction plafonnee a 50 %") and ok
	# truelle : renouvelle, la clef garde la moitie
	var e := Combat.new(cr, vide)
	var truelle: Dictionary = e.cotes[0]["sorts"][0]
	e._lancer(e.cotes[0], e.cotes[1], truelle)
	var b1: float = e.cotes[0]["bouclier"]
	e._lancer(e.cotes[0], e.cotes[1], truelle)
	ok = _verifier(is_equal_approx(e.cotes[0]["bouclier"], b1), "truelle : renouvelle au lieu d'ajouter") and ok
	var k := Exemples.nid_terre()
	k.placer(Vector2i(3, 3), "clef")
	var f := Combat.new(k.eclore(), vide)
	var tr: Dictionary = f.cotes[0]["sorts"][0]
	f._lancer(f.cotes[0], f.cotes[1], tr)
	f._lancer(f.cotes[0], f.cotes[1], tr)
	ok = _verifier(is_equal_approx(f.cotes[0]["bouclier"], tr["mortier"] * 1.5), "clef de voute : garde la moitie") and ok
	# fil a plomb, tuile, sablier
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "fil_plomb")
	n.placer(Vector2i(1, 0), "tuile")
	n.placer(Vector2i(2, 0), "sablier_ensable")
	var g := Combat.new(n.eclore(), vide)
	g.cotes[0]["bouclier"] = 20.0
	for i in 31:
		g._subir(g.cotes[0], g.cotes[1])
	ok = _verifier(g.cotes[0]["bouclier"] == 28.0, "fil a plomb : bouclier tenu renforce") and ok
	pv = g.cotes[0]["pv"] + g.cotes[0]["bouclier"]
	g._blesser(g.cotes[0], 10.0, g.cotes[1])
	ok = _verifier(is_equal_approx(pv - g.cotes[0]["pv"] - g.cotes[0]["bouclier"], 5.0), "tuile : premier coup reduit") and ok
	ok = _verifier(g.cotes[0]["fatigue_debut"] == Data.MORT_SUBITE + 5.0, "sablier ensable : fatigue retardee") and ok
	# urne : soigne au debut de la fatigue ; borne : survit une fois a 1 PV
	var u := Nid.new()
	u.placer(Vector2i(0, 0), "urne")
	u.placer(Vector2i(1, 0), "brique")
	u.placer(Vector2i(2, 0), "borne")
	var h := Combat.new(u.eclore(), vide)
	h._blesser(h.cotes[0], 100.0, h.cotes[1])
	pv = h.cotes[0]["pv"]
	h.t = h.cotes[0]["fatigue_debut"]
	h._subir(h.cotes[0], h.cotes[1])
	ok = _verifier(h.cotes[0]["pv"] > pv, "urne : soin au debut de la fatigue") and ok
	h.cotes[0]["pv"] = 0.1
	h.t += 1.0
	h._subir(h.cotes[0], h.cotes[1])
	ok = _verifier(h.cotes[0]["pv"] == 1.0 and h.cotes[0]["fatigue_suspendue_jusqu"] > h.t, "borne : reste a 1 PV") and ok
	# armes : schiste affaiblit, fondations donne du bouclier, rempart monte la reduction
	var hs := Nid.new()
	hs.placer(Vector2i(0, 0), "hachette_schiste")
	var m := Combat.new(hs.eclore(), vide)
	m._lancer(m.cotes[0], m.cotes[1], m.cotes[0]["sorts"][0])
	pv = m.cotes[0]["pv"]
	m._blesser(m.cotes[0], 10.0, m.cotes[1])
	ok = _verifier(is_equal_approx(pv - m.cotes[0]["pv"], 7.5), "hachette de schiste : la cible frappe moins fort") and ok
	var hf := Nid.new()
	hf.placer(Vector2i(0, 0), "hache_fondations")
	var q := Combat.new(hf.eclore(), vide)
	q._lancer(q.cotes[0], q.cotes[1], q.cotes[0]["sorts"][0])
	ok = _verifier(is_equal_approx(q.cotes[0]["bouclier"], 18.0 * Data.FONDATIONS), "hache des fondations : bouclier") and ok
	var br := Nid.new()
	br.placer(Vector2i(0, 0), "baton_rempart")
	var r := Combat.new(br.eclore(), vide)
	r.cotes[0]["bouclier"] = 50.0
	for i in 6:
		r._lancer(r.cotes[0], r.cotes[1], r.cotes[0]["sorts"][0])
	ok = _verifier(r.cotes[0]["rempart_bonus"] == Data.REMPART_MAX, "baton du rempart : reduction plafonnee") and ok
	r._blesser(r.cotes[0], 100.0, r.cotes[1])
	return _verifier(r.cotes[0]["rempart_bonus"] == 0.0, "baton du rempart : perdu au bris") and ok
