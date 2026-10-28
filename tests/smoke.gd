extends Node

# Test de fumee : formes, catalyseurs, determinisme, renaissance.
# Lancer : godot --headless --path . res://tests/smoke.tscn

func _ready() -> void:
	var ok := true
	ok = _formes() and ok
	ok = _catalyseurs() and ok
	ok = _placement() and ok
	ok = _deterministe() and ok
	ok = _renaissance() and ok
	ok = _ecran() and ok
	ok = _armes() and ok
	ok = _combat_anime() and ok
	ok = _partie() and ok
	ok = _sac() and ok
	ok = _formes_sac() and ok
	ok = _armes_sans_limite() and ok
	ok = _hybrides() and ok
	ok = _gel() and ok
	ok = _dynasties() and ok
	ok = _reserve() and ok
	ok = _elites() and ok
	ok = _cavaliers() and ok
	ok = _carte() and ok
	ok = _run() and ok
	ok = _fusion() and ok
	ok = _nature() and ok
	ok = _familles() and ok
	ok = _glace() and ok
	ok = _phenix() and ok
	ok = _nuit() and ok
	ok = _aube() and ok
	ok = _crepuscule() and ok
	ok = _vitesses() and ok
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

# Reliques qui lisent leur placement (une case chacune hors partie).
func _placement() -> bool:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "sceau")
	n.placer(Vector2i(1, 0), "calice")
	n.placer(Vector2i(0, 1), "cadran")
	var sceau: Dictionary = n.eclore()["sorts"][0]
	var ok := _verifier(is_equal_approx(sceau["vol_de_vie"], 0.10), "calice : vol de vie au sort voisin")
	ok = _verifier(is_equal_approx(sceau["recharge"], 6.0 / 1.25), "cadran : recharge plus rapide") and ok
	n = Nid.new()
	n.placer(Vector2i(0, 0), "mousse")
	n.placer(Vector2i(1, 0), "epine_ronce")
	n.placer(Vector2i(0, 1), "baie")
	n.placer(Vector2i(0, 2), "ruban")
	ok = _verifier(is_equal_approx(n.eclore()["pv_max"], Data.PV_BASE + 10 + 15 * 2 + 40), "mousse : +15 PV par voisine du Printemps") and ok
	n = Nid.new()
	n.placer(Vector2i(0, 0), "stalagmite")
	ok = _verifier(is_equal_approx(n.eclore()["bouclier"], 40.0), "stalagmite seule : bouclier") and ok
	n.placer(Vector2i(1, 0), "flocon")
	ok = _verifier(is_equal_approx(n.eclore()["bouclier"], 0.0), "stalagmite touchee : rien") and ok
	n = Nid.new()
	n.placer(Vector2i(0, 0), "charbon")
	n.placer(Vector2i(5, 0), "trainee")
	ok = _verifier(is_equal_approx(n.eclore()["brulure_attaque"], 1.3), "trainee : toute sa rangee") and ok
	n.deplacer(Vector2i(5, 0), Vector2i(5, 1))
	ok = _verifier(is_equal_approx(n.eclore()["brulure_attaque"], 1.0), "trainee : pas les autres rangees") and ok
	n = Nid.new()
	n.placer(Vector2i(0, 0), "ruban")
	n.placer(Vector2i(1, 0), "reflet")
	ok = _verifier(is_equal_approx(n.eclore()["attaque"], Data.ATTAQUE_BASE + 2.0 * 1.75), "reflet : copie 75 % du ruban") and ok
	n = Nid.new()
	n.placer(Vector2i(0, 0), "ruban")
	n.placer(Vector2i(1, 0), "terreau")
	n.saisons = 5
	ok = _verifier(is_equal_approx(n.eclore()["attaque"], Data.ATTAQUE_BASE + 2.0 * 1.2), "terreau : +4 % par saison aux voisines") and ok
	# signature : un sort de l'Ete pose 1 brulure de plus a chaque activation
	n = Nid.new()
	n.placer(Vector2i(0, 0), "graine_brasier")
	var cr := n.eclore()
	ok = _verifier(is_equal_approx(cr["sorts"][0]["signature"], 1.0), "signature de l'Ete sur le sort") and ok
	var c := Combat.new(cr, Nid.new().eclore())
	c._signature(c.cotes[0], c.cotes[1], "feu", cr["sorts"][0]["signature"])
	ok = _verifier(is_equal_approx(c._brulure(c.cotes[1]), 1.0), "signature : 1 brulure posee") and ok
	# essences : un cinquieme de la signature a chaque attaque
	n = Nid.new()
	n.placer(Vector2i(0, 0), "cendre")
	n.placer(Vector2i(1, 0), "resine")
	cr = n.eclore()
	return _verifier(is_equal_approx(cr["signatures"].get("feu", 0.0), 2 * Data.SIGNATURE_ESSENCE), "signature des essences sur l'attaque") and ok

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
	e.deposer(Vector2i(2, 0), "charbon", null)
	var ok := _verifier(e.nid.forme() == "feu", "poser une braise -> phenix")
	e.deposer(Vector2i(3, 0), "ruban", null)
	e.deposer(Vector2i(4, 0), "sceau", null)
	ok = _verifier(e.nid.forme() == "nuit", "plus de nuit -> chauve-souris") and ok
	e.deposer(Vector2i(5, 3), "ruban", Vector2i(3, 0))
	ok = _verifier(e.nid.cases.get(Vector2i(5, 3)) == "ruban" and not e.nid.cases.has(Vector2i(3, 0)), "deplacer une relique") and ok
	e.deposer(Vector2i(2, 0), "ruban", Vector2i(5, 3))
	ok = _verifier(e.nid.cases.get(Vector2i(5, 3)) == "charbon", "echanger deux reliques") and ok
	e.deposer(Vector2i(0, 0), "sceau", null)
	ok = _verifier(not e.nid.cases.has(Vector2i(0, 0)), "case fermee : on ne pose pas") and ok
	ok = _verifier(e.vente._can_drop_data(Vector2.ZERO, {"id": "charbon", "depuis": Vector2i(5, 3)}), "le comptoir accepte une relique du sac") and ok
	e.vente._drop_data(Vector2.ZERO, {"id": "charbon", "depuis": Vector2i(5, 3)})
	ok = _verifier(e.nid.forme() == "nuit" and e.nid.cases.size() == 2, "revendre une case") and ok
	e.choix_case = true
	e.ouvrir(Vector2i(1, 2))
	ok = _verifier(e.nid.ouverte(Vector2i(1, 2)) and not e.choix_case and e.cases_ui[Vector2i(1, 2)].visible, "agrandir : un clic ouvre la case choisie") and ok
	e.queue_free()
	return ok

func _armes() -> bool:
	var n := Nid.new()
	var ok := _verifier(n.placer(Vector2i(0, 0), "lance_guet"), "poser une arme")
	ok = _verifier(n.placer(Vector2i(1, 0), "faux_nuit") and n.armes() == ["lance_guet", "faux_nuit"], "deux armes : toutes deux tenues") and ok
	n.retirer(Vector2i(1, 0))
	ok = _verifier(n.affinites().is_empty(), "la lance n'a pas d'element") and ok
	n.placer(Vector2i(1, 0), "fourrure")
	var s: Dictionary = n.eclore()["sorts"][0]
	ok = _verifier(s["cavalier"] and s["nom"] == "Estoc" and s["bouclier"] > 0.0, "sort du cavalier + catalyseur voisin") and ok
	# Estoc part en combat.
	var lance := Nid.new()
	lance.placer(Vector2i(0, 0), "lance_guet")
	var c := Combat.new(lance.eclore(), Exemples.nid_nuit().eclore())
	c.simuler()
	ok = _verifier(c.journal.any(func(l): return "Estoc" in l), "le cavalier lance Estoc") and ok
	# Sentence de la Hache du bourreau : double sous le seuil
	var faux := Nid.new()
	faux.placer(Vector2i(0, 0), "hache_bourreau")
	var cible := Nid.new().eclore()
	var m := Combat.new(faux.eclore(), cible)
	m.cotes[1]["pv"] = 30.0
	m.cotes[0]["sorts"][0]["prochain"] = 0.0
	m._agir(m.cotes[0], m.cotes[1])
	var attendu: float = 30.0 - 2.0 * faux.eclore()["sorts"][0]["degats"] - Data.SIGNATURES["nuit"]
	return _verifier(is_equal_approx(m.cotes[1]["pv"], attendu), "sentence double sous 40 %% (pv %s, attendu %s)" % [m.cotes[1]["pv"], attendu]) and ok

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
	ok = _verifier(p.offres.size() == Partie.TAILLE_BOUTIQUE and p.bourse == Partie.OR_PAR_MANCHE, "depart : 9 offres, 10 or") and ok
	p.offres[0] = "charbon"
	p.offres[1] = "baton_braise"
	ok = _verifier(p.acheter(0, Vector2i(2, 0)) and p.bourse == 7 and p.offres[0] == "", "acheter : -3 or, offre vendue") and ok
	ok = _verifier(not p.acheter(0, Vector2i(3, 0)), "offre deja vendue") and ok
	ok = _verifier(not p.acheter(1, Vector2i(2, 0)), "case occupee") and ok
	p.bourse = 4
	ok = _verifier(not p.acheter(1, Vector2i(3, 0)), "pas assez d'or") and ok
	p.vendre(Vector2i(2, 0))
	ok = _verifier(p.bourse == 5 and p.nid.cases.is_empty(), "revendre : moitie du prix") and ok
	ok = _verifier(p.relancer() and p.bourse == 4, "relancer coute 1 or") and ok
	var a := p.adversaire()
	var cout := 0
	for id in a.cases.values():
		cout += Partie.prix(id)
	ok = _verifier(cout <= Partie.OR_PAR_MANCHE * p.manche and cout > 0, "adversaire dans le budget de la manche") and ok
	ok = _verifier(a.cases == p.adversaire().cases, "adversaire deterministe") and ok
	return ok

func _sac() -> bool:
	var p := Partie.new(3)
	var ok := _verifier(p.nid.places() == 16 and not p.nid.ouverte(Vector2i(0, 0)) and p.nid.ouverte(Vector2i(2, 0)), "sac de depart : 4 colonnes au centre")
	p.offres[0] = "charbon"
	ok = _verifier(not p.acheter(0, Vector2i(0, 0)), "case fermee : pas d'achat") and ok
	p.bourse = 30
	ok = _verifier(not p.agrandir(Vector2i(0, 0)) and p.bourse == 30, "agrandir : seulement une case collee au sac") and ok
	ok = _verifier(p.prix_agrandir() == 2 and p.agrandir(Vector2i(1, 3)) and p.bourse == 28 and p.nid.ouverte(Vector2i(1, 3)), "agrandir : 2 or, la case choisie") and ok
	ok = _verifier(p.prix_agrandir() == 3 and p.agrandir(Vector2i(0, 3)) and p.bourse == 25, "puis +1 or par case, collee a la nouvelle") and ok
	p.bourse = 1000
	while not p.nid.bordure().is_empty():
		p.agrandir(p.nid.bordure()[0])
	ok = _verifier(p.nid.places() == 32 and p.prix_agrandir() == -1 and not p.agrandir(Vector2i(0, 0)), "damier entier : plus d'agrandissement") and ok
	ok = _verifier(p.nid.eclore()["ouvertes"].size() == 32, "la creature garde les cases ouvertes") and ok
	return ok

func _premier(rarete: String, type := "") -> String:
	for id in Data.RELIQUES:
		var r: Dictionary = Data.RELIQUES[id]
		if Data.rarete(id) == rarete and r["type"] != "arme" and (type == "" or r["type"] == type):
			return id
	return ""

func _formes_sac() -> bool:
	var rare := _premier("rare")
	var epique := _premier("epique")
	var legende := _premier("legendaire")
	var ok := _verifier(Data.empreinte("charbon") == [Vector2i(0, 0)], "commun : 1 case")
	ok = _verifier(Data.empreinte(rare) == [Vector2i(0, 0), Vector2i(1, 0)], "rare : 2 cases couchees") and ok
	ok = _verifier(Data.empreinte(rare, 1) == [Vector2i(0, 0), Vector2i(0, 1)], "un quart de tour : debout") and ok
	ok = _verifier(Data.empreinte(epique).size() == 3 and Data.empreinte(legende).size() == 4, "epique 3 cases, legendaire 4") and ok
	ok = _verifier(Data.empreinte("lance_guet") == [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], "hast : 1 x 3") and ok
	var p := Partie.new(9)
	p.bourse = 100
	p.offres[0] = rare
	ok = _verifier(not p.peut_acheter(0, Vector2i(5, 0)) and p.acheter(0, Vector2i(5, 0), 1), "colonne 6 fermee : on la pose debout") and ok
	ok = _verifier(p.nid.ancre(Vector2i(5, 1)) == Vector2i(5, 0) and p.nid.occupation().size() == 2, "la relique couvre ses 2 cases") and ok
	p.offres[1] = "charbon"
	ok = _verifier(not p.peut_acheter(1, Vector2i(5, 1)), "pas de pose sur une case prise") and ok
	ok = _verifier(p.acheter(1, Vector2i(4, 1)), "pose a cote") and ok
	ok = _verifier(p.nid.voisins(Vector2i(4, 1)) == [Vector2i(5, 0)], "voisine par sa deuxieme case") and ok
	# deplacer : refuse si ca deborde, echange avec une relique qui tient a la place laissee
	ok = _verifier(not p.nid.deplacer(Vector2i(5, 0), Vector2i(5, 3)), "deplacer hors du sac : refuse") and ok
	ok = _verifier(p.nid.deplacer(Vector2i(5, 0), Vector2i(2, 0), 0) and p.nid.ancre(Vector2i(3, 0)) == Vector2i(2, 0), "deplacer et coucher") and ok
	ok = _verifier(p.nid.deplacer(Vector2i(4, 1), Vector2i(2, 0)) and p.nid.cases.get(Vector2i(2, 0)) == "charbon" and p.nid.cases.get(Vector2i(4, 1)) == rare, "echange : le charbon prend la place, la rare tient en (4, 1)") and ok
	# fusion : la troisieme copie posee sur une copie
	var q := Partie.new(10)
	q.bourse = 100
	for k in 3:
		q.offres[k] = rare
	q.acheter(0, Vector2i(2, 0))
	q.acheter(1, Vector2i(2, 1))
	ok = _verifier(q.acheter(2, Vector2i(3, 1)) and q.nid.cases.size() == 1 and q.nid.niveau(Vector2i(2, 1)) == 2, "trois rares : fusion sur la copie visee") and ok
	q.vendre(Vector2i(3, 1))
	ok = _verifier(q.nid.cases.is_empty(), "revendre par n'importe quelle case") and ok
	# copies sans limite : trois lances fusionnent
	for k in 3:
		q.offres[k] = "lance_guet"
	q.acheter(0, Vector2i(2, 0))
	ok = _verifier(q.acheter(1, Vector2i(3, 0)) and q.nid.armes().size() == 2, "deuxieme lance : active aussi") and ok
	ok = _verifier(q.acheter(2, Vector2i(4, 0)) and q.nid.cases.size() == 1 and q.nid.niveau(Vector2i(4, 0)) == 2, "trois lances : lance etoilee") and ok
	return ok

func _famille(f: String, rang := 0) -> String:
	var l := Data.RELIQUES.keys().filter(func(id): return Data.RELIQUES[id].get("famille", "") == f)
	l.sort()
	return l[rang]

func _armes_sans_limite() -> bool:
	var n := Nid.new()
	for k in 4:
		n.placer(Vector2i(k, 0), _famille("lame", k % 2))
	n.placer(Vector2i(0, 1), "lance_guet")
	var cr := n.eclore()
	var ok := _verifier(cr["armes"].size() == 5, "cinq armes : toutes tenues")
	ok = _verifier(cr["sorts"].filter(func(s): return s["cavalier"]).size() == 5, "cinq armes : cinq sorts du cavalier") and ok
	return ok

func _hybrides() -> bool:
	var ok := _verifier(Nid.new().hybride() == "", "nid vide : pas d'hybride")
	# un seul objet d'une autre dynastie : monture pure
	var m := Nid.new()
	m.placer(Vector2i(0, 0), "charbon")
	m.placer(Vector2i(1, 0), "tison")
	m.placer(Vector2i(2, 0), "sceau")
	ok = _verifier(m.hybride() == "" and m.eclore()["nom"] == "Phénix", "un seul objet de la Nuit : Phenix pur") and ok
	# deux objets de la Nuit : hybride, passif du Phenix
	m.placer(Vector2i(3, 0), "sablier")
	var cm := m.eclore()
	ok = _verifier(cm["forme"] == "feu" and cm["hybride"] == "feu_nuit" and cm["nom"] == "Phénix-Chauve-souris", "deux objets de la Nuit : Phenix-Chauve-souris") and ok
	return ok

func _gel() -> bool:
	var p := Partie.new(21)
	p.entrer(p.accessibles()[0])
	var avant := p.offres.duplicate()
	p.offres[1] = ""
	avant[1] = ""
	p.geler()
	p.conclure_combat(0)
	var ok := _verifier(p.offres[0] == avant[0] and p.offres[2] == avant[2] and p.offres[1] != "", "boutique gelee : offres gardees, la place achetee se remplit")
	ok = _verifier(p.relancer() and not p.gelee, "une relance degele") and ok
	p.geler()
	p.noeud()["type"] = "elite"
	p.offres[2] = ""
	p.conclure_combat(0)
	return _verifier(p.gratuite == 2 and not "" in p.offres, "gelee : la relique offerte prend la place vide, le reste se remplit") and ok

func _dynasties() -> bool:
	var p := Partie.new(5, ["feu", "nuit", "aube"])
	var ok := true
	for k in 20:
		for id in p.offres:
			ok = ok and (id == "" or Data.RELIQUES[id]["element"] in ["feu", "nuit", "aube", ""])
		p.tirer()
	ok = _verifier(ok, "boutique : seulement les dynasties choisies et les neutres")
	ok = _verifier(p.adversaire().cases.values().all(func(id): return Data.RELIQUES[id]["element"] in ["feu", "nuit", "aube", ""]), "le fantome joue les memes dynasties") and ok
	var c := ChoixScreen.new()
	add_child(c)
	c.basculer("automne")
	ok = _verifier(c.choisies.is_empty(), "une dynastie a venir ne se choisit pas") and ok
	c.basculer("feu")
	c.basculer("nuit")
	ok = _verifier(c.bouton.disabled, "moins de 3 : on ne commence pas") and ok
	c.basculer("aube")
	ok = _verifier(not c.bouton.disabled, "3 dynasties : on peut commencer") and ok
	c._aleatoire()
	ok = _verifier(c.choisies.size() == 4 and c.choisies.all(func(d): return not d in Data.DYNASTIES_A_VENIR), "aleatoire : 4 dynasties jouables") and ok
	c.queue_free()
	ok = _verifier(Glossaire.contenu().contains("Flétrissure") and Glossaire.contenu().contains("Dynastie de la Nuit"), "glossaire : etats et dynasties") and ok
	return ok

func _reserve() -> bool:
	var p := Partie.new(31)
	p.bourse = 100
	p.offres[0] = "charbon"
	p.offres[1] = "sceau"
	var ok := _verifier(p.ranger({"offre": 0}, 0) and p.reserve[0]["id"] == "charbon" and p.bourse == 100 - Partie.prix("charbon"), "acheter vers la reserve")
	ok = _verifier(p.nid.eclore()["affinite"] == 0, "la reserve n'a pas d'effet") and ok
	ok = _verifier(p.poser({"reserve": 0}, Vector2i(2, 0), Vector2i(2, 0), 0)["ok"] and p.nid.cases.get(Vector2i(2, 0)) == "charbon" and p.reserve[0].is_empty(), "reserve vers le sac") and ok
	# lacher sur une autre relique : elle prend la place, l'autre passe en main
	ok = _verifier(p.poser({"offre": 1}, Vector2i(2, 0), Vector2i(2, 0), 0)["ok"] and p.nid.cases.get(Vector2i(2, 0)) == "sceau" and p.main["id"] == "charbon", "echange : l'ancienne passe en main") and ok
	ok = _verifier(p.ranger({"main": true}, 3) and p.main.is_empty() and p.reserve[3]["id"] == "charbon", "la main se range") and ok
	# reserve pleine : la main lachee nulle part va dans le sac
	for k in Partie.TAILLE_RESERVE:
		p.reserve[k] = {"id": "ruban", "niv": 1}
	p.main = {"id": "tison", "niv": 1}
	p.poser_main()
	ok = _verifier(p.main.is_empty() and "tison" in p.nid.cases.values(), "reserve pleine : la main va dans le sac") and ok
	var or_avant := p.bourse
	ok = _verifier(p.vendre_source({"reserve": 0}) and p.bourse == or_avant + Partie.prix_revente("ruban") and p.reserve[0].is_empty(), "revendre depuis la reserve") and ok
	return ok

func _elites() -> bool:
	var ok := true
	var base := Exemples.nid_feu().eclore()
	for e in Data.ELITES:
		var cr := Exemples.nid_aube().eclore()
		cr["elite"] = e
		var c := Combat.new(cr, base)
		c.simuler()
		var types := c.evenements.map(func(x): return x["type"])
		var attendu: String = {"sanglier": "charge", "phalene": "trait", "vouivre": "entraves"}[e]
		ok = _verifier(attendu in types, "%s : %s" % [e, attendu]) and ok
	# phalene : ses malus disparaissent
	var ph := Exemples.nid_aube().eclore()
	ph["elite"] = "phalene"
	var d := Combat.new(ph, base)
	d.cotes[0]["poison"] = 20.0
	d.cotes[0]["elite_t"] = Data.PHALENE_DISSIPE_TOUS
	d._elite(d.cotes[0], d.cotes[1])
	ok = _verifier(d.cotes[0]["poison"] == 0.0, "phalene : dissipe le poison") and ok
	# partie : une elite a son nom et sa regle
	var p := Partie.new(17)
	p.entrer(p.accessibles()[0])
	p.noeud()["type"] = "elite"
	var adv := p.creature_adverse()
	ok = _verifier(adv["elite"] in Data.ELITES and adv["nom"] == Data.ELITES[adv["elite"]]["nom"], "noeud elite : creature d'elite") and ok
	p.noeud()["type"] = "boss"
	ok = _verifier(p.creature_adverse()["elite"] == "bastion", "boss de l'acte I : le Bastion endormi") and ok
	var b := Exemples.nid_aube().eclore()
	b["elite"] = "bastion"
	var cb := Combat.new(b, Exemples.nid_feu().eclore())
	cb.simuler()
	var tb := cb.evenements.map(func(x): return x["type"])
	ok = _verifier("ouverture" in tb and "regard" in tb and "resistance" in tb, "Bastion : rempart, ouverture, regard, resistance") and ok
	return ok

func _cavaliers() -> bool:
	var p := Partie.new(41)
	p.choisir_cavalier("pousse")
	var ok := _verifier(p.cases_offertes == Partie.CROISSANCE_CASES and p.prix_agrandir() == 0 and p.agrandir(Vector2i(1, 0)) and p.bourse == Partie.OR_PAR_MANCHE, "Croissance : cases offertes a placer")
	var q := Partie.new(42)
	q.choisir_cavalier("capuchon")
	var b := q.bourse
	q.relancer()
	q.relancer()
	ok = _verifier(q.bourse == b - Partie.PRIX_RELANCE, "Erudit : premiere relance gratuite, la suivante payante") and ok
	var co := Partie.avec_cavalier(Nid.new().eclore(), "coquille")
	ok = _verifier(co["bouclier"] == Data.ECLOSION_BOUCLIER, "Eclosion : bouclier de 40") and ok
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "dague_minuit")
	var c := Combat.new(Partie.avec_cavalier(n.eclore(), "ombre"), Nid.new().eclore())
	ok = _verifier(is_equal_approx(c.cotes[0]["sorts"][0]["prochain"], Data.EMBUSCADE_DELAI), "Embuscade : l'arme part tout de suite") and ok
	return ok

func _carte() -> bool:
	var c := Carte.new(7)
	var ok := _verifier(Carte.new(7).actes == c.actes, "meme graine, meme carte")
	for a in Carte.ACTES:
		var n: Array = c.actes[a]
		var boss := n.filter(func(x): return x["type"] == "boss")
		ok = _verifier(boss.size() == 1 and boss[0]["etage"] == Carte.ETAGES - 1, "un boss au dernier etage") and ok
		ok = _verifier(c.departs(a).size() >= 2, "au moins deux departs") and ok
		# tout noeud est atteignable depuis un depart et mene au boss
		var vus := {}
		var pile: Array = c.departs(a).duplicate()
		while not pile.is_empty():
			var i: int = pile.pop_back()
			if vus.has(i):
				continue
			vus[i] = true
			pile.append_array(n[i]["suivants"])
		ok = _verifier(vus.size() == n.size(), "acte %d : tout noeud atteignable" % a) and ok
		for x in n:
			ok = _verifier(x["type"] == "boss" or not x["suivants"].is_empty(), "pas de cul-de-sac") and ok
			ok = _verifier(x["etage"] != 0 or x["type"] == "duel", "premier etage : duels") and ok
			ok = _verifier(x["etage"] != Carte.ETAGES - 2 or x["type"] == "feu", "feu de camp avant le boss") and ok
			ok = _verifier(a > 0 or x["etage"] >= Carte.ELITE_DES or x["type"] != "elite", "pas d'elite trop tot") and ok
	return ok

func _run() -> bool:
	var p := Partie.new(11)
	var ok := _verifier(not p.entrer(999) and p.entrer(p.accessibles()[0]) and p.combat(), "entrer dans un duel de depart")
	p.conclure_combat(1, 0.5)
	ok = _verifier(p.pv_run == Partie.PV_RUN - Partie.PERTE["duel"] - 4 and p.manche == 2 and p.bourse == 20, "defaite : PV de run perdus selon ce qui reste a l'adversaire, +10 or") and ok
	# feu de camp
	p.noeud()["type"] = "feu"
	p.conclure()
	ok = _verifier(p.pv_run == Partie.PV_RUN, "feu de camp : soin plafonne") and ok
	# victoire contre une elite : relique epique offerte, qui survit a la relance
	p.noeud()["type"] = "elite"
	p.conclure_combat(0)
	ok = _verifier(p.gratuite == 0 and Data.rarete(p.offres[0]) == "epique" and p.prix_offre(0) == 0, "elite battue : epique offerte") and ok
	var offerte: String = p.offres[0]
	p.relancer()
	ok = _verifier(p.offres[0] == offerte and p.prix_offre(0) == 0, "l'offre offerte survit a la relance") and ok
	ok = _verifier(p.acheter(0, Vector2i(2, 0)) and p.gratuite == -1, "acheter l'offre offerte ne coute rien") and ok
	# rencontre
	p.position = -1
	p.entrer(p.accessibles()[0])
	p.noeud()["type"] = "rencontre"
	p.rencontre = {"id": "chaudron"}
	var pv := p.pv_run
	p.choisir(0)
	ok = _verifier(p.pv_run == pv - Partie.CHAUDRON_PV and Data.rarete(p.offres[0]) == "legendaire", "chaudron : legendaire contre des PV") and ok
	# boss : acte suivant, dernier boss : fin de run
	p.noeud()["type"] = "boss"
	p.conclure_combat(0)
	ok = _verifier(p.acte == 1 and p.position == -1 and p.chemin.is_empty() and not p.terminee(), "boss battu : acte suivant") and ok
	ok = _verifier(p.cases_offertes == 1 and p.agrandir(Vector2i(1, 0)) and p.nid.places() == 17, "boss battu : une case offerte") and ok
	p.acte = Carte.ACTES - 1
	p.entrer(p.accessibles()[0])
	p.noeud()["type"] = "boss"
	p.conclure_combat(0)
	ok = _verifier(p.terminee() and p.gagnee, "dernier boss battu : run gagnee") and ok
	var q := Partie.new(12)
	q.entrer(q.accessibles()[0])
	q.pv_run = 2
	q.conclure_combat(1, 1.0)
	return _verifier(q.terminee() and not q.gagnee and q.accessibles().is_empty(), "0 PV de run : run perdue") and ok

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
	# armes et legendaires fusionnent aussi
	var a := Nid.new()
	for x in 3:
		a.ajouter(Vector2i(x, 0), "lance_guet")
	ok = _verifier(a.cases.size() == 1 and a.niveau(Vector2i(2, 0)) == 2, "trois lances fusionnent") and ok
	var leg := Nid.new()
	for x in 3:
		leg.ajouter(Vector2i(x, 0), "lanterne")
	ok = _verifier(leg.cases.size() == 1 and leg.niveau(Vector2i(2, 0)) == 2, "trois legendaires fusionnent") and ok
	ok = _verifier(Partie.prix_revente("charbon", 2) == 4, "revente niveau 2 : 9 / 2 = 4") and ok
	n.deplacer(Vector2i(2, 0), Vector2i(3, 3))
	ok = _verifier(n.niveau(Vector2i(3, 3)) == 2 and not n.niveaux.has(Vector2i(2, 0)), "deplacer garde le niveau") and ok
	return ok

func _nature() -> bool:
	var cr := Exemples.nid_nature().eclore()
	var ok := _verifier(cr["nom"] == "Cerf", "nature -> cerf")
	# epines : 3 (passif) + 2 x 1,5 (ortie voisine) ; poison par attaque : 0,5 x 1,5 (amanite voisine)
	ok = _verifier(is_equal_approx(cr["epines"], Data.EPINES_CERF + 3.0) and is_equal_approx(cr["poison_attaque"], 0.75), "ortie et amanite renforcent leurs voisines") and ok
	var spore: Dictionary = cr["sorts"][0]
	# spore : (2 + 0,2 x nature 7) x 1,5 amanite
	ok = _verifier(is_equal_approx(spore["poison"], (2.0 + 0.2 * 7) * 1.5), "nuage de spores : poison selon affinite") and ok
	# poison : s'empile, plafonne, passe le bouclier ; epines : ripostent
	var tortue := Exemples.nid_glace().eclore()
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
	ok = _verifier(g.cases.size() == 1 and g.niveau(Vector2i(2, 0)) == 2, "trois Graines du Jardin fusionnent") and ok
	# rarete : manche 1 que des communs ; prix
	var p := Partie.new(5)
	ok = _verifier(p.offres.all(func(id): return Data.rarete(id) == "commun"), "manche 1 : que des communs") and ok
	var c8 := Partie.chances(8)
	ok = _verifier(Partie.chances(3)[3] == 0.0 and c8[3] > 0.1 and c8[3] < 0.3 and is_equal_approx(c8.reduce(func(a, b): return a + b), 100.0), "chances interpolees entre deux manches reperes") and ok
	p.manche = 30
	p.bourse = 1000
	var plafond := true
	for i in 200:
		p.relancer()
		plafond = plafond and p.offres.filter(func(id): return Data.rarete(id) == "legendaire").size() <= 1
	ok = _verifier(plafond, "au plus un legendaire par boutique") and ok
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
	var ok := _verifier(cr["nom"] == "Ours", "glace -> ours")
	# givre par attaque : 1 (passif) + 1 x 1,5 (flocon a cote du croc)
	ok = _verifier(is_equal_approx(cr["givre_attaque"], 2.5), "croc du blizzard renforce le flocon voisin") and ok
	# armure de givre : (5 + 0,5 x glace 7) x 1,5 (fourrure voisine)
	ok = _verifier(is_equal_approx(cr["sorts"][0]["bouclier"], (5.0 + 0.5 * 7) * 1.5), "armure de givre et fourrure") and ok
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
	# (la signature de l'Ete repose ensuite 1 brulure)
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
	return _verifier(q._brulure(q.cotes[1]) == Data.SIGNATURES["feu"], "faux des cendres : combustion contre une cible affaiblie") and ok

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
	# crit : la Lame donne du crit, le Peigne pose Fletrissure, la Lame de la veuve Stigmate
	var lame := Nid.new()
	lame.placer(Vector2i(0, 0), "lame_veuve")
	lame.placer(Vector2i(1, 0), "peigne")
	var lcr := lame.eclore()
	ok = _verifier(is_equal_approx(lcr["crit"], 0.15 + 0.08) and lcr["crit_stigmate"] and lcr["crit_fletrissure"], "crit des lames et du peigne") and ok
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
	# hache du bourreau : +35 % par malediction ; faux de la nuit profonde : consume
	var ff := Nid.new()
	ff.placer(Vector2i(0, 0), "hache_bourreau")
	var k := Combat.new(ff.eclore(), vide)
	k.cotes[1]["maledictions"]["faiblesse"] = {"n": 1, "fin": 99.0}
	k.cotes[1]["maledictions"]["langueur"] = {"n": 1, "fin": 99.0}
	pv = k.cotes[1]["pv"]
	k._lancer(k.cotes[0], k.cotes[1], k.cotes[0]["sorts"][0])
	# +35 % par malediction (faux) et +12 % par malediction (passif de la Chauve-souris)
	ok = _verifier(is_equal_approx(pv - k.cotes[1]["pv"], 14.0 * 1.7 * (1.0 + 2 * Data.NUIT_PAR_MALEDICTION) + Data.SIGNATURES["nuit"]), "hache du bourreau") and ok
	# stigmate : +10 % de degats recus ; l'arc de l'echo le pose, la lame de la veuve aussi sur crit
	var st := Combat.new(Nid.new().eclore(), Nid.new().eclore())
	st.cotes[1]["maledictions"]["stigmate"] = {"n": 1, "fin": 99.0}
	var pv_s: float = st.cotes[1]["pv"]
	st._blesser(st.cotes[1], 20.0)
	ok = _verifier(is_equal_approx(pv_s - st.cotes[1]["pv"], 22.0), "stigmate : +10 % de degats recus") and ok
	var arc := Nid.new()
	arc.placer(Vector2i(0, 0), "arc_echo")
	var ae := Combat.new(arc.eclore(), vide)
	ae._lancer(ae.cotes[0], ae.cotes[1], ae.cotes[0]["sorts"][0])
	ok = _verifier(ae._charges(ae.cotes[1], "stigmate") == 1, "arc de l'echo : pose Stigmate") and ok
	var fn := Nid.new()
	fn.placer(Vector2i(0, 0), "faux_nuit")
	var n := Combat.new(fn.eclore(), vide)
	n.cotes[1]["maledictions"]["faiblesse"] = {"n": 2, "fin": 99.0}
	pv = n.cotes[1]["pv"]
	n._lancer(n.cotes[0], n.cotes[1], n.cotes[0]["sorts"][0])
	return _verifier(n._nb_maledictions(n.cotes[1]) == 0 and is_equal_approx(pv - n.cotes[1]["pv"], 10.0 + 2 * Data.FESTIN_DEGATS + Data.SIGNATURES["nuit"]), "faux de la nuit profonde : consume") and ok

func _aube() -> bool:
	var vide := Nid.new().eclore()
	var cr := Exemples.nid_aube().eclore()
	var ok := _verifier(cr["nom"] == "Lion" and cr["eclat"] and cr["regen"] == Data.REGEN_LION, "aube -> lion")
	# meche : (6 + 0,75 x aube 7) x 1,5 (huile voisine)
	ok = _verifier(is_equal_approx(cr["sorts"][0]["soin"], (6.0 + 0.75 * 7.0) * 1.5), "meche et huile voisine") and ok
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
	# reliques fusionnees : le soin du Carillon ne relance pas l'Eclat sans fin
	var lion := Nid.new()
	var poses := {Vector2i(0, 0): "sceptre_aurore", Vector2i(1, 0): "huile", Vector2i(2, 0): "miroir",
		Vector2i(3, 0): "vasque", Vector2i(1, 1): "meche", Vector2i(2, 1): "bande", Vector2i(0, 2): "voile_aube",
		Vector2i(0, 1): "carillon", Vector2i(3, 1): "voile_aube", Vector2i(2, 2): "encensoir",
		Vector2i(3, 2): "encensoir", Vector2i(1, 3): "vasque", Vector2i(1, 2): "meche"}
	for k in poses:
		lion.placer(k, poses[k])
	for k in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(1, 1), Vector2i(2, 1)]:
		lion.niveaux[k] = 2
	var boucle := Combat.new(lion.eclore(), Exemples.nid_crepuscule().eclore())
	boucle.simuler()
	ok = _verifier(boucle.evenements.size() < 1000, "carillon fusionne : pas de boucle d'Eclat") and ok
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
	ok = _verifier(is_equal_approx(pv - q.cotes[1]["pv"], 6.0 + 4 * 1.5 + Data.SIGNATURES["crepuscule"]), "arc des deux lunes") and ok
	var fl := Exemples.nid_crepuscule()
	fl.placer(Vector2i(3, 3), "flechettes")
	var r := Combat.new(fl.eclore(), vide)
	var fle: Dictionary = r.cotes[0]["sorts"].filter(func(s): return s["nom"] == "Fléchettes")[0]
	for i in 3:
		r._lancer(r.cotes[0], r.cotes[1], fle)
	return _verifier(r.cotes[0]["transferts"] == 1, "flechettes : transfert tous les 3 tirs") and ok

func _vitesses() -> bool:
	var e := CombatScreen.new(Exemples.nid_feu().eclore(), Exemples.nid_nuit().eclore())
	add_child(e)
	var vues := []
	for i in 4:
		vues.append([e.vitesse, e.bouton_vitesse.text])
		e._changer_vitesse()
	e.queue_free()
	return _verifier(vues == [[1.0, "Vitesse x1"], [2.0, "Vitesse x2"], [3.0, "Vitesse x3"], [1.0, "Vitesse x1"]], "vitesse x1, x2, x3 puis x1")

