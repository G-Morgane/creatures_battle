extends Node

# Test de fumee : formes, catalyseurs, determinisme, renaissance.
# Lancer : godot --headless --path . res://tests/smoke.tscn

func _ready() -> void:
	var ok := true
	ok = _formes() and ok
	ok = _catalyseurs() and ok
	ok = _signatures() and ok
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
	ok = _rarete() and ok
	ok = _familles() and ok
	ok = _glace() and ok
	ok = _phenix() and ok
	ok = _nuit() and ok
	ok = _aube() and ok
	ok = _crepuscule() and ok
	ok = _automne() and ok
	ok = _jour() and ok
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
	egal.placer(Vector2i(1, 0), "aiguille")
	ok = _verifier(egal.forme() == "", "egalite -> informe") and ok
	ok = _verifier(not egal.placer(Vector2i(0, 0), "tison"), "case occupee refusee") and ok
	return _verifier(not egal.placer(Vector2i(9, 0), "tison"), "hors grille refuse") and ok

func _catalyseurs() -> bool:
	var feu := Exemples.nid_feu().eclore()
	var nuit := Exemples.nid_nuit().eclore()
	var sceau: Dictionary = nuit["sorts"].filter(func(s): return s["nom"] == "Sceau")[0]
	# deux charbons : 1 brulure x 1,5 chacun (tison voisin)
	var ok := _verifier(is_equal_approx(feu["brulure_attaque"], 3.0), "tison voisin -> plus de brulure")
	ok = _verifier(sceau["malediction"] == "faiblesse", "sceau : pose faiblesse") and ok
	# baton de braise : 4 + 0,5 x affinite Ete (9) en degats, la brulure ne grandit pas
	var b := Exemples.nid_feu()
	b.placer(Vector2i(3, 3), "baton_braise")
	var boule: Dictionary = b.eclore()["sorts"].filter(func(s): return s["nom"] == "Boule de feu")[0]
	return _verifier(is_equal_approx(boule["degats"], 4.0 + 0.5 * 9) and boule["brulure"] == 2.0, "le bonus d'affinite va a la valeur principale") and ok

# Signature de dynastie : sur les sorts a chaque activation, sur l'attaque pour les essences.
func _signatures() -> bool:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "graine_brasier")
	var cr := n.eclore()
	var ok := _verifier(is_equal_approx(cr["sorts"][0]["signature"], 1.0), "signature de l'Ete sur le sort")
	var c := Combat.new(cr, Nid.new().eclore())
	c._signature(c.cotes[0], c.cotes[1], "feu", cr["sorts"][0]["signature"])
	ok = _verifier(is_equal_approx(c._brulure(c.cotes[1]), 1.0), "signature : 1 brulure posee") and ok
	c._signature(c.cotes[0], c.cotes[1], "jour", 3.0)
	ok = _verifier(is_equal_approx(c.cotes[0]["bouclier"], 3.0), "signature du Jour : bouclier") and ok
	c._signature(c.cotes[0], c.cotes[1], "automne", 3.0)
	ok = _verifier(is_equal_approx(c.cotes[1]["pv"], Data.PV_BASE - 3.0), "signature de l'Automne : griffe") and ok
	ok = _verifier(Data.DYNASTIES.keys().all(func(e): return Data.SIGNATURES.has(e) and Data.NOMS_SIGNATURE.has(e)), "une signature par dynastie") and ok
	# essences : un cinquieme de la signature a chaque attaque
	n = Nid.new()
	n.placer(Vector2i(0, 0), "cendre")
	n.placer(Vector2i(1, 0), "charbon")
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
	e.deposer(Vector2i(3, 0), "aiguille", null)
	e.deposer(Vector2i(4, 0), "sceau", null)
	ok = _verifier(e.nid.forme() == "nuit", "plus de nuit -> chauve-souris") and ok
	e.deposer(Vector2i(5, 3), "aiguille", Vector2i(3, 0))
	ok = _verifier(e.nid.cases.get(Vector2i(5, 3)) == "aiguille" and not e.nid.cases.has(Vector2i(3, 0)), "deplacer une relique") and ok
	e.deposer(Vector2i(2, 0), "aiguille", Vector2i(5, 3))
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
	n.placer(Vector2i(1, 0), "broche_soleil")
	var s: Dictionary = n.eclore()["sorts"][0]
	ok = _verifier(s["cavalier"] and s["nom"] == "Estoc" and is_equal_approx(s["degats"], 8.0 * 1.25), "sort du cavalier + catalyseur voisin") and ok
	# Estoc part en combat.
	var lance := Nid.new()
	lance.placer(Vector2i(0, 0), "lance_guet")
	var c := Combat.new(lance.eclore(), Exemples.nid_nuit().eclore())
	c.simuler()
	return _verifier(c.journal.any(func(l): return "Estoc" in l), "le cavalier lance Estoc") and ok

# L'ecran rejoue le combat jusqu'au bout sans rien recalculer.
func _combat_anime() -> bool:
	var feu := Exemples.nid_feu()
	feu.placer(Vector2i(3, 0), "baton_braise")
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
	# niveau : passe au 2 apres le deuxieme noeud, +PV et une case offerte
	var nv := Partie.new(7)
	ok = _verifier(nv.niveau() == 1 and nv._avancer() == 0 and nv._avancer() == 1 and nv.niveau() == 2, "niveau 2 au deuxieme noeud") and ok
	ok = _verifier(nv.cases_offertes == 1, "niveau : une case de sac offerte") and ok
	ok = _verifier(is_equal_approx(nv.creature_joueur()["pv_max"], Data.PV_BASE + Partie.PV_PAR_NIVEAU), "niveau : +PV a la monture") and ok
	ok = _verifier(Partie.niveau_pour(999) == Partie.XP_NIVEAUX.size(), "niveau plafonne") and ok
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
	m.placer(Vector2i(3, 0), "poupee")
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
		p.reserve[k] = {"id": "aiguille", "niv": 1}
	p.main = {"id": "tison", "niv": 1}
	p.poser_main()
	ok = _verifier(p.main.is_empty() and "tison" in p.nid.cases.values(), "reserve pleine : la main va dans le sac") and ok
	var or_avant := p.bourse
	ok = _verifier(p.vendre_source({"reserve": 0}) and p.bourse == or_avant + Partie.prix_revente("aiguille") and p.reserve[0].is_empty(), "revendre depuis la reserve") and ok
	# trio a cheval sur le sac et la reserve : la reserve compte, et se vide
	var q := Partie.new(31)
	q.bourse = 100
	q.offres[0] = "charbon"
	q.offres[1] = "charbon"
	q.offres[2] = "charbon"
	q.ranger({"offre": 0}, 0)
	q.acheter(1, Vector2i(2, 0))
	ok = _verifier(q.acheter(2, Vector2i(3, 0)) and q.nid.niveau(Vector2i(3, 0)) == 2 and q.nid.cases.size() == 1 and q.reserve[0].is_empty(), "trio sac + reserve : fusion dans le sac") and ok
	ok = _verifier(q.fusion.get("absorbees", []).size() == 2, "la fusion est notee pour l'animer") and ok
	var s := Partie.new(31)
	s.bourse = 100
	s.offres[0] = "charbon"
	s.offres[1] = "charbon"
	s.offres[2] = "charbon"
	s.acheter(0, Vector2i(2, 0))
	s.ranger({"offre": 1}, 0)
	ok = _verifier(s.acheter(2, Vector2i(2, 0)) and s.nid.niveau(Vector2i(2, 0)) == 2 and s.reserve[0].is_empty(), "offre sur une copie, la troisieme en reserve") and ok
	var u := Partie.new(31)
	u.bourse = 100
	u.offres[0] = "charbon"
	u.offres[1] = "charbon"
	u.offres[2] = "charbon"
	u.acheter(0, Vector2i(2, 0))
	u.ranger({"offre": 1}, 0)
	ok = _verifier(u.ranger({"offre": 2}, 1) and u.reserve[1].get("niv") == 2 and u.reserve[0].is_empty() and u.nid.cases.is_empty(), "trio complete en reserve : fusion en reserve") and ok
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
	n.placer(Vector2i(0, 0), "dague_feuille")
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
	ok = _verifier(p.ferveur == Partie.FERVEUR - Partie.PERTE["duel"] - 4 and p.manche == 2 and p.bourse == 20, "defaite : Ferveur perdue selon ce qui reste a l'adversaire, +10 or") and ok
	# feu de camp
	p.noeud()["type"] = "feu"
	var offres_avant := p.offres.duplicate()
	p.conclure()
	ok = _verifier(p.ferveur == Partie.FERVEUR and p.bourse == 20 and p.offres == offres_avant, "feu de camp : soin plafonne, ni or ni nouvelle boutique") and ok
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
	var pv := p.ferveur
	var bourse := p.bourse
	p.choisir(0)
	ok = _verifier(p.ferveur == pv - Partie.CHAUDRON_PV and p.bourse == bourse and Data.rarete(p.offres[p.gratuite]) == "legendaire", "chaudron : legendaire offerte en boutique contre de la Ferveur, sans or") and ok
	# boss : acte suivant, dernier boss : fin de run
	p.noeud()["type"] = "boss"
	var offertes := p.cases_offertes
	var niv := p.niveau()
	p.conclure_combat(0)
	ok = _verifier(p.acte == 1 and p.position == -1 and p.chemin.is_empty() and not p.terminee(), "boss battu : acte suivant") and ok
	# une case pour le boss, plus une par niveau gagne au passage
	ok = _verifier(p.cases_offertes == offertes + 1 + p.niveau() - niv and p.agrandir(Vector2i(1, 0)) and p.nid.places() == 17, "boss battu : une case offerte") and ok
	p.acte = Carte.ACTES - 1
	p.entrer(p.accessibles()[0])
	p.noeud()["type"] = "boss"
	p.conclure_combat(0)
	ok = _verifier(p.terminee() and p.gagnee, "dernier boss battu : run gagnee") and ok
	var q := Partie.new(12)
	q.entrer(q.accessibles()[0])
	q.ferveur = 2
	q.conclure_combat(1, 1.0)
	return _verifier(q.terminee() and not q.gagnee and q.accessibles().is_empty(), "0 Ferveur : run perdue") and ok

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
	# cascade : 2 niveaux 2 donnent un niveau 3
	var k := Nid.new()
	for i in 6:
		k.ajouter(Vector2i(i % 4, i / 4), "aiguille")
	ok = _verifier(k.cases.size() == 1 and k.niveau(k.cases.keys()[0]) == 3, "6 copies : niveau 3") and ok
	ok = _verifier(k.affinites()["nuit"] == 2 * 6 and Partie.prix_revente("aiguille", 3) == Partie.prix("aiguille") * 6 / 2, "niveau 3 : affinite et revente de 6 copies") and ok
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
	ok = _verifier(is_equal_approx(cr["epines"], Data.EPINES_CERF + 4.0) and cr["epines_poison"] == Data.EPINES_POISON_CERF, "epines : passif + 2 Epines de ronce") and ok
	var spore: Dictionary = cr["sorts"].filter(func(s): return s["id"] == "spore")[0]
	# spore : 3 + 0,2 x printemps 8, + 1 dose de l'Ortie voisine
	ok = _verifier(is_equal_approx(spore["poison"], 3.0 + 0.2 * 8 + 1.0), "nuage de spores : affinite et ortie") and ok
	# qui frappe le Cerf prend les epines et s'empoisonne
	var c := Combat.new(cr, Nid.new().eclore())
	c._frapper(c.cotes[1], c.cotes[0], 5.0)
	ok = _verifier(is_equal_approx(c.cotes[1]["pv"], Data.PV_BASE - cr["epines"]) and c.cotes[1]["poison"] == Data.EPINES_POISON_CERF, "riposte : epines et poison") and ok
	# poison : plafonne, passe le bouclier
	c.cotes[1]["bouclier"] = 30.0
	c._empoisonner(c.cotes[1], 150.0)
	ok = _verifier(c.cotes[1]["poison"] == Data.POISON_MAX, "poison plafonne a 100") and ok
	var pv: float = c.cotes[1]["pv"]
	c._subir(c.cotes[1], c.cotes[0])
	ok = _verifier(c.cotes[1]["bouclier"] == 30.0 and c.cotes[1]["pv"] < pv, "le poison passe le bouclier") and ok
	# belladone : un empoisonne ne se soigne plus
	var b := Nid.new()
	b.placer(Vector2i(0, 0), "belladone")
	var d := Combat.new(Exemples.nid_feu().eclore(), b.eclore())
	d.cotes[0]["pv"] = 100.0
	d._soigner(d.cotes[0], d.cotes[1], 10.0)
	ok = _verifier(is_equal_approx(d.cotes[0]["pv"], 110.0), "sans poison, on se soigne") and ok
	d._empoisonner(d.cotes[0], 1.0)
	d._soigner(d.cotes[0], d.cotes[1], 10.0)
	ok = _verifier(is_equal_approx(d.cotes[0]["pv"], 110.0), "belladone : empoisonne, plus de soin") and ok
	# Graine du Jardin : le poison de l'attaquant agit aussitot une seconde
	var g := Nid.new()
	g.placer(Vector2i(0, 0), "graine_jardin")
	var e := Combat.new(g.eclore(), Nid.new().eclore())
	e.cotes[1]["poison"] = 10.0
	e._frapper(e.cotes[1], e.cotes[0], 1.0)
	ok = _verifier(is_equal_approx(e.cotes[1]["pv"], Data.PV_BASE - Data.EPINES_CERF - 11.0 * Data.POISON_DPS_PAR_DOSE), "graine : une seconde de poison a chaque coup recu") and ok
	# Arc du Jardin : riposte tous les 2 coups recus, et empoisonne
	var k := Nid.new()
	k.placer(Vector2i(0, 0), "arc_jardin")
	var f := Combat.new(k.eclore(), Nid.new().eclore())
	for i in 4:
		f._frapper(f.cotes[1], f.cotes[0], 1.0)
	ok = _verifier(f.evenements.filter(func(ev): return ev["type"] == "sort" and ev["nom"] == "Flèche-graine").size() == 2, "arc du Jardin : tous les 2 coups recus") and ok
	ok = _verifier(f.cotes[1]["poison"] == 4 * Data.EPINES_POISON_CERF + 2 * 2.0, "arc du Jardin : la fleche empoisonne") and ok
	# Arc de saule : ajoute les epines a ses degats
	var a := Nid.new()
	a.placer(Vector2i(0, 0), "arc_saule")
	var h := Combat.new(a.eclore(), Nid.new().eclore())
	h.cotes[0]["sorts"][0]["prochain"] = 0.0
	h._agir(h.cotes[0], h.cotes[1])
	return _verifier(is_equal_approx(Data.PV_BASE - h.cotes[1]["pv"], 6.0 + Data.EPINES_CERF), "arc de saule : degats + epines") and ok

func _rarete() -> bool:
	var g := Nid.new()
	for x in 3:
		g.ajouter(Vector2i(x, 0), "graine_jardin")
	var ok := _verifier(g.cases.size() == 1 and g.niveau(Vector2i(2, 0)) == 2, "trois Graines du Jardin fusionnent")
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

# Chaque Dynastie : 7 objets de monture (3 communs, 2 rares, 1 epique,
# 1 legendaire) et 3 armes d'une seule famille.
func _familles() -> bool:
	var armes := Data.RELIQUES.keys().filter(func(id): return Data.RELIQUES[id]["type"] == "arme")
	var ok := _verifier(armes.all(func(id): return Data.RELIQUES[id].get("famille", "") in Data.FAMILLES), "chaque arme a une famille connue")
	for e in Data.DYNASTIES:
		var ids := Data.RELIQUES.keys().filter(func(id): return Data.RELIQUES[id]["element"] == e)
		var monture := ids.filter(func(id): return Data.RELIQUES[id]["type"] != "arme")
		var siennes := ids.filter(func(id): return Data.RELIQUES[id]["type"] == "arme")
		var raretes := monture.map(func(id): return Data.rarete(id))
		ok = _verifier(monture.size() == 7 and siennes.size() == 3, "%s : 7 objets et 3 armes" % e) and ok
		ok = _verifier(raretes.count("commun") == 3 and raretes.count("rare") == 2 and raretes.count("epique") == 1 and raretes.count("legendaire") == 1, "%s : 3 communs, 2 rares, 1 epique, 1 legendaire" % e) and ok
		var familles := {}
		for id in siennes:
			familles[Data.RELIQUES[id]["famille"]] = true
		ok = _verifier(familles.size() == 1, "%s : une seule famille d'armes" % e) and ok
		ok = _verifier(ids.all(func(id): return Descriptions.TEXTES.has(id)), "%s : chaque objet a sa description" % e) and ok
	return ok

func _glace() -> bool:
	var cr := Exemples.nid_glace().eclore()
	var ok := _verifier(cr["nom"] == "Ours", "glace -> ours")
	# givre par attaque : 1 (passif) + 2 Flocons x 1,5 (Croc voisin)
	ok = _verifier(is_equal_approx(cr["givre_attaque"], Data.OURS_GIVRE + 3.0) and cr["gel_duree"] == 0.5, "flocons, croc et fourrure") and ok
	var galet: Dictionary = cr["sorts"][0]
	ok = _verifier(is_equal_approx(galet["givre"], (3.0 + 0.2 * 8) * 1.5), "souffle glace : affinite et croc") and ok
	var c := Combat.new(cr, Nid.new().eclore())
	c._givrer(c.cotes[0], c.cotes[1], Data.GEL_SEUIL)
	ok = _verifier(c._gele(c.cotes[1]) and c.cotes[1]["givre"] == 0.0 and is_equal_approx(c.cotes[1]["gele_jusqu"], Data.GEL_DUREE + 0.5), "gel au seuil, plus long avec la fourrure") and ok
	# l'Ours frappe double une cible gelee
	var pv: float = c.cotes[1]["pv"]
	c._frapper(c.cotes[0], c.cotes[1], 10.0)
	ok = _verifier(is_equal_approx(pv - c.cotes[1]["pv"], 10.0 * Data.OURS_BONUS_GEL), "ours : x2 contre une cible gelee") and ok
	# Noyau, Cristal, Banquise
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "noyau_hiver")
	n.placer(Vector2i(1, 0), "cristal")
	n.placer(Vector2i(2, 0), "coeur_banquise")
	var d := Combat.new(n.eclore(), Nid.new().eclore())
	d._givrer(d.cotes[0], d.cotes[1], 6.0)
	ok = _verifier(d._gele(d.cotes[1]), "noyau : gel a 6 charges") and ok
	ok = _verifier(is_equal_approx(d.cotes[1]["pv"], Data.PV_BASE - 30.0) and d.cotes[1]["givre"] == 3.0, "cristal : 30 au gel ; banquise : la moitie du givre reste") and ok
	# Hache brise-glace : x2 contre une cible gelee, en plus du passif
	var h := Nid.new()
	h.placer(Vector2i(0, 0), "hache_glace")
	var e := Combat.new(h.eclore(), Nid.new().eclore())
	e.cotes[1]["gele_jusqu"] = 5.0
	e._lancer(e.cotes[0], e.cotes[1], e.cotes[0]["sorts"][0])
	ok = _verifier(is_equal_approx(Data.PV_BASE - e.cotes[1]["pv"], 12.0 * 2.0 * Data.OURS_BONUS_GEL), "brise-glace : x2 sur cible gelee") and ok
	# Hache du Grand Hiver : prolonge le gel
	var g := Nid.new()
	g.placer(Vector2i(0, 0), "hache_hiver")
	var f := Combat.new(g.eclore(), Nid.new().eclore())
	f.cotes[1]["gele_jusqu"] = 1.0
	f._lancer(f.cotes[0], f.cotes[1], f.cotes[0]["sorts"][0])
	return _verifier(is_equal_approx(f.cotes[1]["gele_jusqu"], 2.0), "grand hiver : gel prolonge de 1 s") and ok

func _phenix() -> bool:
	var cr := Exemples.nid_feu().eclore()
	var ok := _verifier(cr["nom"] == "Phénix" and cr["renaissances"] == 1, "feu -> phenix, une renaissance")
	# brulure par attaque : 2 Charbons x 1,5 (Tison voisin)
	ok = _verifier(is_equal_approx(cr["brulure_attaque"], 3.0), "tison : brulure des charbons") and ok
	var graine: Dictionary = cr["sorts"][0]
	ok = _verifier(is_equal_approx(graine["brulure"], (3.0 + 0.3 * 8) * 1.5), "embrasement : affinite et tison") and ok
	var c := Combat.new(cr, Nid.new().eclore())
	c._bruler(c.cotes[0], c.cotes[1], 1.0)
	ok = _verifier(is_equal_approx(c.cotes[1]["brulures"][0]["fin"], Data.BRULURE_DUREE + 1.0), "cendre : brulure plus longue") and ok
	# Oeuf : brulures eternelles, seconde renaissance
	var o := Nid.new()
	o.placer(Vector2i(0, 0), "oeuf_brasier")
	var co := o.eclore()
	var d := Combat.new(co, Nid.new().eclore())
	d._bruler(d.cotes[0], d.cotes[1], 1.0)
	ok = _verifier(co["renaissances"] == 2 and d.cotes[1]["brulures"][0]["fin"] == INF, "oeuf : brulures eternelles et deux renaissances") and ok
	# renaissance : combustion totale des brulures adverses
	d.cotes[1]["brulures"] = [{"fin": INF, "q": 10.0}]
	d.cotes[0]["pv"] = 0.0
	d._mort(d.cotes[0], d.cotes[1])
	ok = _verifier(d.cotes[1]["brulures"].is_empty() and is_equal_approx(d.cotes[1]["pv"], Data.PV_BASE - 10 * Data.COMBUSTION_PAR_CHARGE * Data.COMBUSTION_TOTALE_BONUS), "renaissance : combustion totale") and ok
	# Obsidienne : 8 brulures posees, combustion partielle
	var b := Nid.new()
	b.placer(Vector2i(0, 0), "obsidienne")
	var e := Combat.new(b.eclore(), Nid.new().eclore())
	e._bruler(e.cotes[0], e.cotes[1], 8.0)
	ok = _verifier(is_equal_approx(e._brulure(e.cotes[1]), 4.0), "obsidienne : combustion partielle a 8 brulures") and ok
	# Fournaise : la combustion laisse la moitie
	var f := Nid.new()
	f.placer(Vector2i(0, 0), "coeur_fournaise")
	var g := Combat.new(f.eclore(), Nid.new().eclore())
	g.cotes[1]["brulures"] = [{"fin": INF, "q": 10.0}]
	g._combustion(g.cotes[0], g.cotes[1], 1.0, true, 1.0)
	ok = _verifier(is_equal_approx(g._brulure(g.cotes[1]), 5.0), "fournaise : la moitie reste") and ok
	# Baton du Premier Brasier : combustion totale doublee
	var p := Nid.new()
	p.placer(Vector2i(0, 0), "baton_premier")
	var h := Combat.new(p.eclore(), Nid.new().eclore())
	h.cotes[1]["brulures"] = [{"fin": INF, "q": 10.0}]
	h._lancer(h.cotes[0], h.cotes[1], h.cotes[0]["sorts"][0])
	return _verifier(is_equal_approx(Data.PV_BASE - h.cotes[1]["pv"], 8.0 + 10 * Data.COMBUSTION_PAR_CHARGE * Data.COMBUSTION_TOTALE_BONUS * 2.0), "premier brasier : combustion totale x2") and ok

func _nuit() -> bool:
	var cr := Exemples.nid_nuit().eclore()
	var ok := _verifier(cr["nom"] == "Chauve-souris" and cr["stigmate_tous"] == 4 and cr["sablier"] == 2.0, "nuit : aiguille et sablier")
	var sceau: Dictionary = cr["sorts"][0]
	ok = _verifier(sceau["malediction"] == "faiblesse" and sceau["maudit_manquante"] == 1, "sceau et poupee voisine") and ok
	var c := Combat.new(cr, Nid.new().eclore())
	c._lancer(c.cotes[0], c.cotes[1], c.cotes[0]["sorts"][0])
	ok = _verifier(c._nb_maledictions(c.cotes[1]) == 2 and c._charges(c.cotes[1], "fletrissure") == 1, "sceau : faiblesse, poupee : la manquante") and ok
	ok = _verifier(is_equal_approx(c.cotes[1]["maledictions"]["faiblesse"]["fin"], Data.MALEDICTION_DUREE + 2.0), "sablier : +2 s") and ok
	# passif : +20 % par malediction ; Pacte : le double
	var pv: float = c.cotes[1]["pv"]
	c._frapper(c.cotes[0], c.cotes[1], 10.0)
	ok = _verifier(is_equal_approx(pv - c.cotes[1]["pv"], 10.0 * (1.0 + 2 * Data.NUIT_PAR_MALEDICTION)), "chauve-souris : bonus par malediction") and ok
	var p := Nid.new()
	p.placer(Vector2i(0, 0), "pacte")
	ok = _verifier(is_equal_approx(p.eclore()["par_malediction"], 2 * Data.NUIT_PAR_MALEDICTION), "pacte : passif double") and ok
	# Grimoire : 10 par nouvelle malediction ; Masque : les trois restent
	var m := Nid.new()
	m.placer(Vector2i(0, 0), "grimoire")
	m.placer(Vector2i(1, 0), "masque")
	var d := Combat.new(m.eclore(), Nid.new().eclore())
	var gr: float = Data.RELIQUES["grimoire"]["grimoire"]
	for nom in Data.MALEDICTIONS:
		d._maudire(d.cotes[0], d.cotes[1], nom)
	d._maudire(d.cotes[0], d.cotes[1], "stigmate")
	# le Stigmate pose en dernier grossit son propre coup de Grimoire
	ok = _verifier(is_equal_approx(Data.PV_BASE - d.cotes[1]["pv"], gr * 2 + gr * (1.0 + Data.STIGMATE)), "grimoire : degats par nouvelle malediction") and ok
	d.t = 100.0
	ok = _verifier(d._nb_maledictions(d.cotes[1]) == 3, "masque : les trois maledictions restent") and ok
	# Faux de la Nuit : consume ; Faux du festin : +25 % par malediction
	var fn := Nid.new()
	fn.placer(Vector2i(0, 0), "faux_nuit")
	var e := Combat.new(fn.eclore(), Nid.new().eclore())
	e._maudire(e.cotes[0], e.cotes[1], "faiblesse")
	e._maudire(e.cotes[0], e.cotes[1], "fletrissure")
	e._lancer(e.cotes[0], e.cotes[1], e.cotes[0]["sorts"][0])
	ok = _verifier(e._nb_maledictions(e.cotes[1]) == 0 and is_equal_approx(Data.PV_BASE - e.cotes[1]["pv"], 10.0 + 2 * Data.FESTIN_DEGATS + Data.SIGNATURES["nuit"]), "faux de la Nuit : consume") and ok
	var ff := Nid.new()
	ff.placer(Vector2i(0, 0), "faux_festin")
	var f := Combat.new(ff.eclore(), Nid.new().eclore())
	f._maudire(f.cotes[0], f.cotes[1], "faiblesse")
	f._lancer(f.cotes[0], f.cotes[1], f.cotes[0]["sorts"][0])
	# Faux du festin et passif de la Chauve-souris, pour une malediction
	var festin: Dictionary = Data.RELIQUES["faux_festin"]
	return _verifier(is_equal_approx(Data.PV_BASE - f.cotes[1]["pv"], festin["degats"] * (1.0 + festin["par_malediction"]) * (1.0 + Data.NUIT_PAR_MALEDICTION) + Data.SIGNATURES["nuit"]), "faux du festin : bonus par malediction") and ok

func _aube() -> bool:
	var cr := Exemples.nid_aube().eclore()
	var ok := _verifier(cr["nom"] == "Lion" and is_equal_approx(cr["regen"], Data.REGEN_LION + 1.0) and cr["miroir"] == 10.0, "aube : lion, bande, miroir")
	var meche: Dictionary = cr["sorts"][0]
	ok = _verifier(is_equal_approx(meche["soin"], 6.0 + 0.75 * 7 + 3.0), "veille : affinite et huile voisine") and ok
	# Eclat : l'excedent compte double, seuil 50 avec le Miroir
	var c := Combat.new(cr, Nid.new().eclore())
	c._soigner(c.cotes[0], c.cotes[1], 25.0)
	ok = _verifier(is_equal_approx(c.cotes[1]["pv"], Data.PV_BASE - Data.ECLAT_DEGATS) and is_zero_approx(c.cotes[0]["eclat_jauge"]), "eclat : 25 d'excedent x2 = 50") and ok
	# Carillon : chaque Eclat soigne ; Lanterne : les degats subis chargent
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "carillon")
	n.placer(Vector2i(1, 0), "lanterne")
	var d := Combat.new(n.eclore(), Nid.new().eclore())
	d.cotes[0]["pv"] = 100.0
	d._blesser(d.cotes[0], 40.0)
	ok = _verifier(is_equal_approx(d.cotes[0]["eclat_jauge"], 20.0), "lanterne : 40 subis, 20 d'Eclat") and ok
	d._eclat(d.cotes[0], d.cotes[1])
	ok = _verifier(is_equal_approx(d.cotes[0]["pv"], 60.0 + 20.0), "carillon : l'Eclat soigne de 20") and ok
	# Lance du Premier Matin : Eclat a mi-jauge
	var l := Nid.new()
	l.placer(Vector2i(0, 0), "lance_matin")
	var e := Combat.new(l.eclore(), Nid.new().eclore())
	e.cotes[0]["eclat_jauge"] = 30.0
	e._lancer(e.cotes[0], e.cotes[1], e.cotes[0]["sorts"][0])
	ok = _verifier(e.evenements.any(func(ev): return ev["type"] == "eclat"), "premier matin : Eclat a mi-jauge") and ok
	# Pique solaire : 10 % de la jauge en plus
	var ps := Nid.new()
	ps.placer(Vector2i(0, 0), "pique_solaire")
	var f := Combat.new(ps.eclore(), Nid.new().eclore())
	f.cotes[0]["eclat_jauge"] = 40.0
	f.cotes[0]["dans_eclat"] = true
	f._lancer(f.cotes[0], f.cotes[1], f.cotes[0]["sorts"][0])
	return _verifier(is_equal_approx(Data.PV_BASE - f.cotes[1]["pv"], 8.0 + 4.0), "pique solaire : +10 % de la jauge") and ok

func _crepuscule() -> bool:
	var cr := Exemples.nid_crepuscule().eclore()
	var ok := _verifier(cr["nom"] == "Papillon" and cr["illusions_depart"] == 1 and cr["arcane_bonus"] == 3.0, "crepuscule : papillon, cocon, poudre")
	ok = _verifier(is_equal_approx(cr["sorts"][0]["recharge"], Data.RELIQUES["battement"]["recharge"] / 1.15), "pollen : recharge plus rapide") and ok
	# une Illusion encaisse l'attaque et eclate en arcane
	var c := Combat.new(cr, Nid.new().eclore())
	ok = _verifier(not c._frapper(c.cotes[1], c.cotes[0], 50.0) and c.cotes[0]["illusions"] == 0 and c.cotes[0]["pv"] == cr["pv_max"], "illusion : encaisse le coup") and ok
	ok = _verifier(is_equal_approx(Data.PV_BASE - c.cotes[1]["pv"], Data.ILLUSION_ARCANE + 3.0), "illusion : eclate en arcane") and ok
	# chaque sort cree une Illusion, 3 au plus ; Battement : arcane selon l'affinite
	var pv: float = c.cotes[1]["pv"]
	c._lancer(c.cotes[0], c.cotes[1], c.cotes[0]["sorts"][0])
	ok = _verifier(c.cotes[0]["illusions"] == 1 and is_equal_approx(pv - c.cotes[1]["pv"], 10.0 + 0.5 * 7 + 3.0 + Data.SIGNATURES["crepuscule"] + 3.0), "battement : arcane et une illusion") and ok
	for i in 5:
		c._lancer(c.cotes[0], c.cotes[1], c.cotes[0]["sorts"][0])
	ok = _verifier(c.cotes[0]["illusions"] == Data.ILLUSIONS_MAX, "illusions : 3 au plus") and ok
	# la Lance du guet perce les Illusions
	var lg := Nid.new()
	lg.placer(Vector2i(0, 0), "lance_guet")
	var d := Combat.new(lg.eclore(), cr)
	d.cotes[1]["illusions"] = 2
	d._lancer(d.cotes[0], d.cotes[1], d.cotes[0]["sorts"][0])
	ok = _verifier(d.cotes[1]["illusions"] == 2 and d.cotes[1]["pv"] < cr["pv_max"], "lance du guet : perce les illusions") and ok
	# Mue : 4 Illusions, et le prochain sort avance
	var m := Nid.new()
	m.placer(Vector2i(0, 0), "mue")
	m.placer(Vector2i(1, 0), "battement")
	var e := Combat.new(m.eclore(), Nid.new().eclore())
	e._gagner_illusions(e.cotes[0], 10)
	var avant: float = e.cotes[0]["sorts"][0]["prochain"]
	e._frapper(e.cotes[1], e.cotes[0], 1.0)
	ok = _verifier(e.cotes[0]["illusions"] == Data.MUE_ILLUSIONS - 1 and is_equal_approx(e.cotes[0]["sorts"][0]["prochain"], avant - Data.MUE_AVANCE), "mue : 4 illusions, le sort avance") and ok
	# Chrysalide : chaque sort se repete
	var ch := Nid.new()
	ch.placer(Vector2i(0, 0), "chrysalide")
	ch.placer(Vector2i(1, 0), "battement")
	var f := Combat.new(ch.eclore(), Nid.new().eclore())
	f._lancer(f.cotes[0], f.cotes[1], f.cotes[0]["sorts"][0])
	ok = _verifier(f.stats[0]["battement"]["activations"] == 2.0 and f.cotes[0]["illusions"] == 1, "chrysalide : le sort se repete, sans illusion de plus") and ok
	# Baton de l'entre-deux : fait eclater les Illusions
	var be := Nid.new()
	be.placer(Vector2i(0, 0), "baton_entre")
	var g := Combat.new(be.eclore(), Nid.new().eclore())
	g.cotes[0]["illusions"] = 2
	g._lancer(g.cotes[0], g.cotes[1], g.cotes[0]["sorts"][0])
	return _verifier(g.cotes[0]["illusions"] == 0 and g.evenements.filter(func(ev): return ev["type"] == "arcane").size() == 3, "entre-deux : deux eclats (une arme ne cree pas d illusion)") and ok

func _automne() -> bool:
	var cr := Exemples.nid_automne().eclore()
	var ok := _verifier(cr["nom"] == "Renard" and is_equal_approx(cr["esquive"], Data.ESQUIVE_RENARD + 0.05), "automne : renard et feuille morte")
	# crit : 2 Crocs (8 %) + Pelage roux touche par 3 objets (3 x 8 %)
	ok = _verifier(is_equal_approx(cr["crit"], 0.16 + 0.24), "crit : crocs et pelage roux") and ok
	# esquive, puis crit garanti
	var c := Combat.new(cr, Nid.new().eclore())
	c.cotes[0]["esquive_prete"] = true
	ok = _verifier(not c._frapper(c.cotes[1], c.cotes[0], 50.0) and c.cotes[0]["pv"] == cr["pv_max"] and c.cotes[0]["feinte_prete"], "esquive : prepare une feinte") and ok
	c._frapper(c.cotes[0], c.cotes[1], 10.0)
	ok = _verifier(is_equal_approx(Data.PV_BASE - c.cotes[1]["pv"], 10.0 * Data.CRIT_MULT), "apres une esquive : crit garanti") and ok
	# Coutelas : x3 ; Queue : esquive apres un crit ; Bogue : contre-attaque
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "coutelas")
	n.placer(Vector2i(1, 0), "queue_renard")
	n.placer(Vector2i(2, 0), "bogue")
	var d := Combat.new(n.eclore(), Nid.new().eclore())
	d.cotes[0]["feinte_prete"] = true
	d._frapper(d.cotes[0], d.cotes[1], 10.0)
	ok = _verifier(is_equal_approx(Data.PV_BASE - d.cotes[1]["pv"], 10.0 * Data.COUTELAS_MULT) and d.cotes[0]["esquive_prete"], "coutelas x3, queue : esquive prete") and ok
	var pv: float = d.cotes[1]["pv"]
	d._frapper(d.cotes[1], d.cotes[0], 10.0)
	ok = _verifier(d.cotes[1]["pv"] < pv, "bogue : l'esquive contre-attaque") and ok
	# Bourrasque : +30 % d'esquive un moment
	var b := Combat.new(cr, Nid.new().eclore())
	var bourrasque: Dictionary = b.cotes[0]["sorts"].filter(func(s): return s["id"] == "bourrasque")[0]
	b._lancer(b.cotes[0], b.cotes[1], bourrasque)
	ok = _verifier(is_equal_approx(b._esquive(b.cotes[0]), cr["esquive"] + 0.3), "bourrasque : +30 % d'esquive") and ok
	# la Lance du guet perce l'esquive
	var lg := Nid.new()
	lg.placer(Vector2i(0, 0), "lance_guet")
	var e := Combat.new(lg.eclore(), cr)
	e.cotes[1]["esquive_prete"] = true
	e._lancer(e.cotes[0], e.cotes[1], e.cotes[0]["sorts"][0])
	return _verifier(e.cotes[1]["pv"] < cr["pv_max"], "lance du guet : perce l'esquive") and ok

func _jour() -> bool:
	var cr := Exemples.nid_jour().eclore()
	var ok := _verifier(cr["nom"] == "Paon" and cr["eventail"] and cr["eventail_depart"] == 2.0 and cr["ecu"] == Data.RELIQUES["ecu_dore"]["ecu"], "jour : paon, plume, ecu")
	var arc: Dictionary = cr["sorts"].filter(func(s): return s["id"] == "arc_plumes")[0]
	ok = _verifier(is_equal_approx(arc["degats"], 3.0 * 1.25), "broche : +25 % a l'arme voisine") and ok
	# une arme lancee : Eventail +1, bouclier de l'Ecu, degats selon l'Eventail
	var c := Combat.new(cr, Nid.new().eclore())
	c._lancer(c.cotes[0], c.cotes[1], c.cotes[0]["sorts"].filter(func(s): return s["id"] == "arc_plumes")[0])
	ok = _verifier(c.cotes[0]["eventail"] == 3.0 and is_equal_approx(c.cotes[0]["bouclier"], cr["ecu"] + Data.SIGNATURES["jour"]), "arme lancee : eventail et bouclier") and ok
	ok = _verifier(is_equal_approx(Data.PV_BASE - c.cotes[1]["pv"], 2 * 3.75 * (1.0 + 2 * Data.EVENTAIL_BONUS)), "eventail : +5 % de degats par charge") and ok
	ok = _verifier(is_equal_approx(c._recharge(c.cotes[0], arc), arc["recharge"] / (1.0 + 3 * Data.EVENTAIL_BONUS)), "eventail : armes plus rapides") and ok
	# La roue : les armes se rapprochent
	var roue: Dictionary = c.cotes[0]["sorts"].filter(func(s): return s["id"] == "roue")[0]
	var arme: Dictionary = c.cotes[0]["sorts"].filter(func(s): return s["id"] == "arc_plumes")[0]
	var avant: float = arme["prochain"]
	c._lancer(c.cotes[0], c.cotes[1], roue)
	ok = _verifier(is_equal_approx(arme["prochain"], avant - 1.0), "la roue : les armes avancent de 1 s") and ok
	# Oeil du Zenith : a 10 Eventail, l'arme part deux fois ; Arc du Zenith : une fleche par charge
	var z := Nid.new()
	z.placer(Vector2i(0, 0), "oeil_zenith")
	z.placer(Vector2i(1, 0), "arc_zenith")
	var d := Combat.new(z.eclore(), Nid.new().eclore())
	d.cotes[0]["eventail"] = 10.0
	d._lancer(d.cotes[0], d.cotes[1], d.cotes[0]["sorts"][0])
	ok = _verifier(d.stats[0]["arc_zenith"]["activations"] == 2.0, "zenith : l'arme part deux fois") and ok
	var coups: Array = d.evenements.filter(func(ev): return ev["type"] == "sort").map(func(ev): return ev["coups"])
	return _verifier(coups == [11, 11], "arc du Zenith : une fleche de plus par Eventail") and ok

func _vitesses() -> bool:
	var e := CombatScreen.new(Exemples.nid_feu().eclore(), Exemples.nid_nuit().eclore())
	add_child(e)
	var vues := []
	for i in 3:
		vues.append([e.vitesse, e.bouton_vitesse.text])
		e._changer_vitesse()
	e.queue_free()
	return _verifier(vues == [[1.0, "Vitesse x1"], [2.0, "Vitesse x2"], [1.0, "Vitesse x1"]], "vitesse x1, x2 puis x1")

