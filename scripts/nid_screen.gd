class_name NidScreen
extends Control

# Ecran du Nid : boutique a gauche, grille au centre, creature a droite.
# Glisser une offre dans une case vide l'achete, glisser une case vers une
# autre echange, la ramener sur le comptoir la revend.

signal continuer
signal nouvelle_partie

const TUILE := Vector2(124, 64)
const CASE_TAILLE := Vector2(104, 104)

var partie := Partie.new()
var nid: Nid:
	get: return partie.nid
var cases_ui := {}   # Vector2i -> CaseNid
var vue: CreatureVue
var infos: RichTextLabel
var barre: Label
var compteurs := {}     # vie, victoires, or -> Label
var message_ui: Label
var offres_ui: Array = []
var relance: Button
var agrandir: Button
var geler: Button
var bouton_combat: Button
var sac: Control
var haut: Control
var boutique_ui: Control
var monture_ui: Control
var aide_ui: Control
var vente: Control
var reserve_ui: Control
var reserve_cases: Array = []
var revente := -1        # prix de revente de la relique tenue depuis le sac, -1 sinon
var bandeau_vente: Label
# Relique tenue : rotation (R ou molette) et case saisie dans sa forme.
var rot_prise := 0
var prise := Vector2i.ZERO
var pose_vue := {}       # apercu de la pose en cours : {cases, ok}
var case_survolee = null # case du sac sous la souris

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fond := ColorRect.new()
	fond.color = Palette.FOND
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	# l'echoppe peinte, qui couvre tout l'ecran sans se deformer
	var peint := TextureRect.new()
	peint.texture = Palette.image("res://images/boutique_fond.png")
	peint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	peint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	peint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	peint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(peint)

	# le sac : un tapis assemble en tuiles, une par colonne ouverte
	sac = Tapis.new(self)
	add_child(sac)
	for y in Data.NID_H:
		for x in Data.NID_L:
			var c := CaseNid.new(self, Vector2i(x, y))
			cases_ui[c.position_nid] = c
			sac.add_child(c)

	# bandeau : acte, vie, victoires, or, puis le message du dernier noeud
	var bandeau := HBoxContainer.new()
	bandeau.add_theme_constant_override("separation", 34)
	barre = Palette.titre(_titre(""))
	bandeau.add_child(barre)
	for nom in ["vie", "victoires", "or"]:
		var c: Array = Palette.compteur(nom, 20)
		compteurs[nom] = c[1]
		bandeau.add_child(c[0])
	message_ui = _titre("")
	message_ui.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	bandeau.add_child(message_ui)
	haut = _cadre(bandeau)
	add_child(haut)
	# tout le comptoir est une zone de vente, sous les offres
	vente = ZoneVente.new(self)
	add_child(vente)
	# les offres sont posees sur le comptoir peint, sans cadre
	boutique_ui = _boutique()
	add_child(boutique_ui)
	monture_ui = _cadre(_panneau())
	add_child(monture_ui)
	reserve_ui = _cadre(_reserve())
	add_child(reserve_ui)
	var aide := Label.new()
	aide.text = "Glisse pour acheter, R ou molette pour tourner. 3 copies : ★. Ramène un objet sur le comptoir pour le revendre. Sur un autre objet : il prend sa place, l'autre passe en main."
	aide.add_theme_font_size_override("font_size", 13)
	aide.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	aide_ui = _cadre(aide)
	add_child(aide_ui)
	# bandeau de revente, au premier plan, qui ne capte pas la souris
	bandeau_vente = Label.new()
	bandeau_vente.add_theme_font_size_override("font_size", 24)
	bandeau_vente.add_theme_color_override("font_color", Color("#f2c94c"))
	var fond_bandeau := StyleBoxFlat.new()
	fond_bandeau.bg_color = Color(Palette.FOND, 0.92)
	fond_bandeau.set_content_margin_all(12)
	fond_bandeau.set_corner_radius_all(6)
	bandeau_vente.add_theme_stylebox_override("normal", fond_bandeau)
	bandeau_vente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bandeau_vente.visible = false
	add_child(bandeau_vente)
	resized.connect(_placer)
	_placer()
	rafraichir()

func _placer() -> void:
	var marge := 20.0
	haut.position = Vector2(marge, 14)
	haut.size = Vector2(size.x - 2 * marge, 0)
	# la monture en bas a droite ; a gauche, le comptoir (offres) puis le tapis
	monture_ui.reset_size()
	monture_ui.position = Vector2(size.x - monture_ui.size.x - marge, size.y - monture_ui.size.y - marge)
	var gauche := monture_ui.position.x - marge
	boutique_ui.reset_size()
	boutique_ui.position = Vector2((gauche - boutique_ui.size.x) / 2 + marge / 2, 80)
	aide_ui.reset_size()
	aide_ui.position = Vector2((gauche - aide_ui.size.x) / 2 + marge / 2, size.y - aide_ui.size.y - 6)
	reserve_ui.reset_size()
	reserve_ui.position = Vector2(size.x - reserve_ui.size.x - marge, 80)
	vente.position = Vector2(marge, 70)
	vente.size = Vector2(gauche - marge, boutique_ui.position.y + boutique_ui.size.y + 6 - 70)
	# le tapis prend la place libre sous le comptoir, en cases carrees
	var dessus := boutique_ui.position.y + boutique_ui.size.y + 14
	var dessous := aide_ui.position.y - 10
	var cote := minf((dessous - dessus) / Data.NID_H, (gauche - marge) / Data.NID_L)
	var cols := nid.colonnes.duplicate()
	cols.sort()
	sac.colonnes = cols
	sac.cote = cote
	sac.position = Vector2((gauche - cols.size() * cote) / 2 + marge / 2, dessus + (dessous - dessus - Data.NID_H * cote) / 2)
	sac.size = Vector2(cols.size() * cote, Data.NID_H * cote)
	for c in cases_ui:
		var i := cols.find(c.x)
		cases_ui[c].visible = i >= 0
		cases_ui[c].position = Vector2(i, c.y) * cote
		cases_ui[c].size = Vector2(cote, cote)
	sac.queue_redraw()

# Cadre sombre sous une zone, pour lire le texte sur le fond peint.
func _cadre(contenu: Control) -> PanelContainer:
	var c := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FOND, 0.8)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	c.add_theme_stylebox_override("panel", style)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.add_child(contenu)
	return c

func _titre(texte: String) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Palette.TEXTE)
	return l

func _boutique() -> Control:
	var col := Boutique.new(self)
	col.add_theme_constant_override("separation", 6)
	var g := HBoxContainer.new()
	g.add_theme_constant_override("separation", 18)
	g.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in Partie.TAILLE_BOUTIQUE:
		var o := Offre.new(self, i)
		offres_ui.append(o)
		g.add_child(o)
	col.add_child(g)
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 8)
	boutons.alignment = BoxContainer.ALIGNMENT_CENTER
	relance = Button.new()
	relance.custom_minimum_size = Vector2(150, 34)
	relance.pressed.connect(func():
		partie.relancer()
		rafraichir())
	boutons.add_child(relance)
	agrandir = Button.new()
	agrandir.custom_minimum_size = Vector2(150, 34)
	agrandir.tooltip_text = "Ouvre une colonne de plus sur le damier."
	agrandir.pressed.connect(func():
		partie.agrandir()
		rafraichir())
	boutons.add_child(agrandir)
	geler = Button.new()
	geler.custom_minimum_size = Vector2(150, 34)
	geler.tooltip_text = "Garde ces offres pour le prochain passage en boutique. Une relance dégèle."
	geler.pressed.connect(func():
		partie.geler()
		rafraichir())
	boutons.add_child(geler)
	col.add_child(boutons)
	return col

func _reserve() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var t := Label.new()
	t.text = "Réserve (sans effet)"
	t.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	col.add_child(t)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for k in Partie.TAILLE_RESERVE:
		var c := CaseReserve.new(self, k)
		reserve_cases.append(c)
		g.add_child(c)
	col.add_child(g)
	return col

func _panneau() -> Control:
	var ligne := VBoxContainer.new()
	ligne.add_theme_constant_override("separation", 8)
	vue = CreatureVue.new()
	vue.custom_minimum_size = Vector2(360, 200)
	vue.zoom = 0.62
	vue.clip_contents = true
	ligne.add_child(vue)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var defile := ScrollContainer.new()
	defile.custom_minimum_size = Vector2(360, 250)
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	infos = _texte()
	infos.fit_content = true
	infos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defile.add_child(infos)
	col.add_child(defile)
	bouton_combat = Button.new()
	bouton_combat.custom_minimum_size.y = 40
	bouton_combat.pressed.connect(_combattre)
	col.add_child(bouton_combat)
	ligne.add_child(col)
	return ligne

func _texte() -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.add_theme_color_override("default_color", Palette.TEXTE)
	t.add_theme_font_size_override("normal_font_size", 16)
	t.add_theme_font_size_override("bold_font_size", 16)
	t.add_theme_constant_override("table_h_separation", 6)
	t.add_theme_constant_override("line_separation", 2)
	return t

# --- actions ---------------------------------------------------------------

# depuis : case d'origine si on deplace une relique deja posee, null sinon.
# Un glisser de relique (offre, sac, reserve ou main) ?
static func glisse(data) -> bool:
	return data is Dictionary and data.has("id") and (data.has("offre") or data.has("depuis") or data.has("reserve") or data.has("main"))

# Apres une pose : si une relique a ete delogee, on la reprend en main tout de
# suite, pour la reposer ailleurs.
func apres_pose() -> void:
	rafraichir()
	if not partie.main.is_empty():
		call_deferred("_reprendre")

func _reprendre() -> void:
	if partie.main.is_empty():
		return
	rot_prise = partie.main.get("rot", 0)
	prise = Vector2i.ZERO
	montrer_vente(Partie.prix_revente(partie.main["id"], partie.main["niv"]))
	force_drag({"id": partie.main["id"], "main": true}, apercu(partie.main["id"]))

# La main lachee nulle part : en reserve, sinon dans le sac, sinon revendue.
func _fin_glisser() -> void:
	if not get_viewport().gui_is_dragging() and not partie.main.is_empty():
		partie.poser_main()
		rafraichir()

# depuis : ancre de la relique deplacee, ou null pour poser id directement.
func deposer(c: Vector2i, id: String, depuis, rot := -1) -> void:
	if depuis != null:
		nid.deplacer(depuis, c, rot)
	elif nid.accepte(c, id, null):
		nid.retirer(c)
		nid.placer(c, id)
	rafraichir()

func acheter(i: int, c: Vector2i, rot := 0) -> void:
	partie.acheter(i, c, rot)
	rafraichir()

# Pendant qu'on tient une relique : R ou la molette la tournent d'un quart.
func _input(ev: InputEvent) -> void:
	if not get_viewport().gui_is_dragging():
		return
	var tourne: bool = ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_R
	tourne = tourne or (ev is InputEventMouseButton and ev.pressed and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN])
	if tourne:
		rot_prise = (rot_prise + 1) % 4
		prise = Vector2i.ZERO
		pose_vue = {}
		sac.queue_redraw()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and sac != null:
		pose_vue = {}
		vente.survol = false
		montrer_vente(-1)
		sac.queue_redraw()
		call_deferred("_fin_glisser")

# Pendant qu'on tient une relique du sac : le comptoir s'eclaire, les offres
# s'estompent et un bandeau donne le prix de revente. prix < 0 : on cache.
func montrer_vente(prix: int) -> void:
	revente = prix
	vente.queue_redraw()
	boutique_ui.modulate.a = 0.3 if prix >= 0 else 1.0
	bandeau_vente.visible = prix >= 0
	if prix >= 0:
		bandeau_vente.text = "Lâche sur le comptoir pour revendre : +%d or" % prix
		bandeau_vente.reset_size()
		bandeau_vente.position = vente.position + (vente.size - bandeau_vente.size) / 2

func vendre(c: Vector2i) -> void:
	partie.vendre(c)
	rafraichir()

func rafraichir() -> void:
	if sac.colonnes.size() != nid.colonnes.size():
		_placer()
	for c in cases_ui:
		cases_ui[c].queue_redraw()
	for c in reserve_cases:
		c.queue_redraw()
	var cr := nid.eclore()
	vue.montrer(cr["forme"], _affinite_totale(), cr["armes"], cr["hybride"])
	infos.text = _decrire(cr)
	for o in offres_ui:
		o.queue_redraw()
	relance.text = "Relancer (%s)" % ("gratuit" if partie.prix_relance() == 0 else "%d or" % partie.prix_relance())
	relance.disabled = partie.bourse < partie.prix_relance() or partie.terminee()
	var prix_sac := partie.prix_agrandir()
	agrandir.text = "Sac complet" if prix_sac < 0 else "Agrandir (%d or)" % prix_sac
	agrandir.disabled = prix_sac < 0 or partie.bourse < prix_sac or partie.terminee()
	geler.text = "Dégeler" if partie.gelee else "Geler"
	geler.disabled = partie.terminee()
	barre.text = "Acte %d" % (partie.acte + 1)
	compteurs["vie"].text = "%d / %d" % [maxi(partie.pv_run, 0), Partie.PV_RUN]
	compteurs["victoires"].text = "%d" % partie.victoires
	compteurs["or"].text = "%d" % partie.bourse
	message_ui.text = partie.message
	if partie.terminee():
		bouton_combat.text = ("Run gagnée !" if partie.gagnee else "Run perdue.") + " Nouvelle partie"
	else:
		bouton_combat.text = "Vers la carte"

func _affinite_totale() -> int:
	var total := 0
	for v in nid.affinites().values():
		total += v
	return total

func _decrire(cr: Dictionary) -> String:
	var aff := nid.affinites()
	var doux := Palette.TEXTE_DOUX.to_html(false)
	var lignes := [
		"[font=%s][font_size=24]%s[/font_size][/font]" % [Palette.TITRE_POLICE, cr["nom"]],
		_affinites(aff),
		"[color=#%s][i]%s[/i][/color]" % [doux, Data.FORMES[cr["forme"]]["passif"]],
		"",
	]
	# les chiffres en tableau : un intitule discret, la valeur dessous
	var stats := [["PV", "%d" % cr["pv_max"]], ["Attaque", "%.0f" % cr["attaque"]],
		["Attaques/s", "%.2f" % (1.0 / cr["intervalle"])], ["Vol de vie", "%d %%" % roundi(cr["vol_de_vie"] * 100)]]
	if cr["bouclier"] > 0.0:
		stats.append(["Bouclier", "%d" % cr["bouclier"]])
	if cr["esquive"] > 0.0:
		stats.append(["Esquive", "%d %%" % roundi(cr["esquive"] * 100)])
	if cr["crit"] > 0.0:
		stats.append(["Critique", "%d %%" % roundi(cr["crit"] * 100)])
	if cr["epines"] > 0.0:
		stats.append(["Épines", "%.1f" % cr["epines"]])
	if cr["poison_attaque"] > 0.0:
		stats.append(["Poison/coup", "%.1f" % cr["poison_attaque"]])
	if cr["epines_poison"] > 0.0:
		stats.append(["Épines toxiques", "%.1f" % cr["epines_poison"]])
	var table := "[table=4]"
	for k in range(0, stats.size(), 4):
		var rang: Array = stats.slice(k, k + 4)
		while rang.size() < 4:
			rang.append(["", ""])
		for st in rang:
			table += "[cell][color=#%s][font_size=13]%s[/font_size][/color][/cell]" % [doux, st[0]]
		for st in rang:
			table += "[cell][b]%s[/b]   [/cell]" % st[1]
	lignes.append(table + "[/table]")
	var effets := []
	if cr["gousse"] > 0.0:
		effets.append("salve d'épines tous les %d coups reçus" % Data.GOUSSE_COUPS)
	if cr["belladone"]:
		effets.append("empoisonné, l'adversaire ne peut plus se soigner")
	if cr["coeur"]:
		effets.append("les épines se renforcent à chaque riposte")
	if cr["graine"]:
		effets.append("épines et poison se nourrissent l'un l'autre")
	if cr["brulure_attaque"] > 0.0:
		effets.append("%.1f brûlure par attaque" % cr["brulure_attaque"])
	if cr["degats_en_feu"] > 0.0:
		effets.append("+%d dégâts contre une cible en feu" % cr["degats_en_feu"])
	if cr["combustion_soin"] + cr["soin_par_charge"] > 0.0:
		effets.append("les combustions soignent")
	if cr["resine"]:
		effets.append("brûlure doublée vie basse")
	if cr["fournaise"]:
		effets.append("sous la moitié de sa vie : combustion totale et Braise")
	if cr["renaissances"] > 1:
		effets.append("%d renaissances" % cr["renaissances"])
	if cr["givre_attaque"] > 0.0:
		effets.append("%.1f givre par attaque" % cr["givre_attaque"])
	if cr["reduction"] + cr["cale"] > 0.0:
		effets.append("réduit les coups de %d %% (%d %% avec du bouclier)" % [roundi(minf(cr["reduction"], Data.REDUCTION_MAX) * 100), roundi(minf(cr["reduction"] + cr["cale"], Data.REDUCTION_MAX) * 100)])
	if cr["fil_plomb"] > 0.0:
		effets.append("bouclier tenu %d s : +%d" % [Data.FIL_PLOMB_DELAI, cr["fil_plomb"]])
	if cr["sablier_ensable"] > 0.0:
		effets.append("sa fatigue commence %d s plus tard" % cr["sablier_ensable"])
	for d in [["tuile", "premier coup après un nouveau bouclier réduit"], ["clef", "garde la moitié du mortier renouvelé"],
			["urne", "les dégâts évités le soignent au début de sa fatigue"], ["borne", "survit une fois à la fatigue"]]:
		if cr[d[0]]:
			effets.append(d[1])
	if cr["elan"]:
		effets.append("Foudre de %d tous les %d d'Élan" % [Data.FOUDRE_DEGATS + cr["eventail"], maxf(Data.ELAN_SEUIL - cr["manche"], Data.ELAN_SEUIL_MIN)])
	for d in [["ruban_criniere", "une esquive accélère"], ["etrier", "les séries d'attaques chargent plus"],
			["girouette", "les esquives renforcent la Foudre"], ["voile_cavale", "après la Foudre, forte esquive"]]:
		if cr[d[0]] > 0.0:
			effets.append(d[1])
	if cr["bride"]:
		effets.append("la Foudre ouvre un Galop libre")
	if cr["arcane"]:
		effets.append("un Transfert à vide tire un projectile d'arcane")
	if cr["poudre"] > 0.0:
		effets.append("ses attaques volent %.1f de bouclier" % cr["poudre"])
	if cr["cocon"] > 0.0:
		effets.append("+%d bouclier à chaque Transfert" % cr["cocon"])
	for d in [["mue", "malus renvoyés renforcés"], ["brume", "voler soigne"], ["phalene", "chaque Transfert déclenche une attaque"],
			["chrysalide", "sous la moitié de sa vie : tout renvoyer, tout voler"], ["aile_lune", "voler accélère"],
			["inversion", "à %d s : échange des pourcentages de vie" % Data.INVERSION_T]]:
		if cr[d[0]]:
			effets.append(d[1])
	if cr["eclat"]:
		effets.append("Éclat de %d tous les %d de soin chargé" % [Data.ECLAT_DEGATS + cr["prisme"], maxf(Data.ECLAT_SEUIL - cr["miroir"], Data.ECLAT_SEUIL_MIN)])
	if cr["regen"] + cr["bande"] > 0.0:
		effets.append("régénère %.1f PV/s (%.1f sous la moitié de sa vie)" % [cr["regen"], cr["regen"] + cr["bande"]])
	if cr["vasque"] > 0.0:
		effets.append("l'excédent de soin devient bouclier")
	if cr["lanterne"] > 0.0:
		effets.append("l'Éclat ajoute l'excédent de soin accumulé")
	if cr["carillon"] > 0.0:
		effets.append("gros soin tous les %d Éclats" % Data.CARILLON_TOUS)
	if cr["faiblesse_tous"] > 0:
		effets.append("Faiblesse toutes les %d attaques" % cr["faiblesse_tous"])
	if cr["sablier"] > 0.0:
		effets.append("malédictions +%d s" % cr["sablier"])
	if cr["chapelet"]:
		effets.append("malédictions empilables (x%d)" % Data.CHAPELET_CHARGES)
	if cr["renvoi"] > 0.0:
		effets.append("renvoie %d %% des dégâts à un adversaire maudit" % roundi(cr["renvoi"] * 100))
	if cr["crit_fletrissure"]:
		effets.append("les crits posent Flétrissure")
	if cr["crit_malediction"]:
		effets.append("les crits posent une malédiction")
	if cr["vol_par_malediction"] > 0.0:
		effets.append("+%d %% de vol de vie par malédiction" % roundi(cr["vol_par_malediction"] * 100))
	if cr["grimoire"] > 0.0:
		effets.append("une malédiction tous les %d PV volés" % cr["grimoire"])
	if cr["pacte"] > 0.0:
		effets.append("draine %d par attaque sous trois malédictions" % cr["pacte"])
	var bris := []
	if cr["bris_degats"] + cr["nova"] > 0.0:
		bris.append("%d dégâts" % (cr["bris_degats"] + cr["nova"]))
	if cr["bris_givre"] > 0.0:
		bris.append("%.1f givre" % cr["bris_givre"])
	if cr["nova"] > 0.0:
		bris.append("gèle une cible ralentie")
	if not bris.is_empty():
		effets.append("bouclier brisé : " + ", ".join(bris))
	if cr["reforme"] > 0.0:
		effets.append("bouclier de %d reformé %d s après un bris" % [cr["reforme"], Data.REFORME_DELAI])
	if cr["gel_bouclier"] > 0.0:
		effets.append("+%d bouclier à chaque gel" % cr["gel_bouclier"])
	if cr["rose"]:
		effets.append("un bris rapproche le prochain gel")
	var titre := "\n[color=#f2c94c][b]%s[/b][/color]"
	if not effets.is_empty():
		lignes.append(titre % "Effets")
		for x in effets:
			lignes.append("• " + x[0].to_upper() + x.substr(1))
	if not cr["sorts"].is_empty():
		lignes.append(titre % "Sorts")
	for s in cr["sorts"]:
		var d := "[b]%s%s[/b] (toutes les %.1f s)" % ["Cavalier, " if s["cavalier"] else "", s["nom"], s["recharge"]]
		if s["contre"] > 0:
			d = "[b]Cavalier, %s[/b] (après %d coups reçus) : %.1f dégâts" % [s["nom"], s["contre"], s["degats"]]
		elif s["esquive"]:
			d += " : esquive la prochaine attaque"
		elif s["coups"] > 0:
			d += " : %d x %.1f dégâts" % [s["coups"], s["degats"]]
		else:
			d += " :"
		if s["bouclier"] > 0.0:
			d += " +%d bouclier" % roundi(s["bouclier"])
		if s["poison"] > 0.0:
			d += " +%.1f poison" % s["poison"]
		if s["par_poison"] > 0.0:
			d += ", +%.1f par dose de poison" % s["par_poison"]
		if s["degats_epines"]:
			d += ", plus les épines"
		if s["graine"]:
			d += ", plante une graine"
		if s["givre"] > 0.0:
			d += ", +%.1f givre" % s["givre"]
		if s["double_ralenti"]:
			d += ", double contre une cible ralentie"
		if s["fracas"]:
			d += ", brise ton bouclier et ajoute sa valeur"
		if s["brise_gel"]:
			d += ", x4 contre une cible gelée"
		if s["perce"]:
			d += ", ignore l'esquive"
		if s["execution"]:
			d += ", double sous %d %% de PV" % roundi(Data.SEUIL_EXECUTION * 100)
		if s["brulure"] > 0.0:
			d += ", +%.1f brûlure" % s["brulure"]
		if s["combustion"] > 0.0:
			d += " combustion de %d %% des brûlures" % roundi(s["combustion"] * 100)
		if s["braise"] > 0.0:
			d += ", +%.1f Braise" % s["braise"]
		if s["achever_seuil"] > 0.0:
			d += ", x%.1f sous %d %% de vie" % [s["achever_mult"], roundi(s["achever_seuil"] * 100)]
		if s["combustion_affaiblie"]:
			d += ", combustion totale contre une cible affaiblie"
		if s["combustion_tous"] > 0:
			d += ", combustion totale tous les %d tirs" % s["combustion_tous"]
		if s["tir_renaissance"]:
			d += ", tire à la renaissance"
		if s["malediction"] != "":
			d += " pose %s" % Data.NOMS_MALEDICTION[s["malediction"]]
		if s["par_malediction"] > 0.0:
			d += ", +%d %% par malédiction" % roundi(s["par_malediction"] * 100)
		if s["consume_maledictions"]:
			d += ", consume les malédictions"
		if s["soin"] > 0.0:
			d += " soigne %.1f" % s["soin"]
		if s["charge_eclat"] > 0.0:
			d += ", charge l'Éclat de %d" % s["charge_eclat"]
		if s["apres_eclat"]:
			d += ", double après un Éclat"
		if s["eclat_tous"] > 0:
			d += ", un Éclat tous les %d tirs" % s["eclat_tous"]
		if s["transfert"] != "":
			var verbes := {"renvoyer": "renvoie un malus", "voler": "vole un bonus", "bouclier": "vole du bouclier",
				"echange": "vole un bonus et renvoie un malus"}
			d += (" %s (%.1f)" % [verbes[s["transfert"]], s["puissance"]])
			if s["transfert_tous"] > 0:
				d += " tous les %d tirs" % s["transfert_tous"]
		if s["mortier"] > 0.0:
			d += " bouclier de mortier %d (renouvelé)" % roundi(s["mortier"])
		if s["schiste"]:
			d += ", la cible frappe moins fort"
		if s["rempart"]:
			d += ", renforce la réduction tant que le bouclier tient"
		if s["fondations"]:
			d += ", bouclier selon les dégâts"
		if s["ages"]:
			d += ", soigne plus pendant la fatigue"
		if s["elan"] > 0.0:
			d += ", +%.1f Élan" % s["elan"]
		if s["riposte_esquive"]:
			d = "[b]Cavalier, %s[/b] (après une esquive) : %d x %.1f dégâts" % [s["nom"], s["coups"], s["degats"]]
		if s["alize"]:
			d += ", avance l'attaque suivante"
		if s["apres_foudre"]:
			d += ", perce et double après la Foudre"
		if s["par_transfert"] > 0.0:
			d += ", +%.1f par Transfert" % s["par_transfert"]
		if s["vol_de_vie"] > 0.0 and not s["esquive"]:
			d += ", vole %d %%" % roundi(s["vol_de_vie"] * 100)
		lignes.append("• " + d)
	return "\n".join(lignes)

# Seulement les elements presents, pour que la ligne tienne avec neuf elements.
func _affinites(aff: Dictionary) -> String:
	var l := []
	for e in aff:
		if aff[e] > 0:
			l.append("[color=#%s]%s %d[/color]" % [Palette.ELEMENTS[e]["vif"].lightened(0.2).to_html(false), _NOMS_ELEMENTS.get(e, e), aff[e]])
	return "   ".join(l) if not l.is_empty() else "[color=#8a8f99]Aucune affinité[/color]"

# Les affinites portent le nom de la dynastie de leur element.
const _NOMS_ELEMENTS := {"nature": "Printemps", "feu": "Été", "automne": "Automne", "glace": "Hiver",
	"aube": "Aube", "jour": "Jour", "crepuscule": "Crépuscule", "nuit": "Nuit"}

func _combattre() -> void:
	if partie.terminee():
		nouvelle_partie.emit()
	else:
		continuer.emit()

# --- elements d'interface --------------------------------------------------

# nom : false dans le sac, ou l'infobulle donne le nom et l'icone prend toute la case.
static func dessiner_relique(ci: CanvasItem, rect: Rect2, id: String, niv := 1, nom := true) -> void:
	var r: Dictionary = Data.RELIQUES[id]
	var couleurs: Dictionary = Palette.ELEMENTS[r["element"]]
	var police := ThemeDB.fallback_font
	var cadre := rect.grow(-3)
	ci.draw_rect(cadre, couleurs["fond"])
	ci.draw_rect(cadre, couleurs["vif"], false, 2.0)
	# rarete : bande de couleur en bas de la tuile (rien pour un commun)
	var rarete := Data.rarete(id)
	if rarete != "commun":
		ci.draw_rect(Rect2(cadre.position.x, cadre.end.y - 5, cadre.size.x, 5), Palette.RARETES[rarete])
	var tex := Palette.icone(id)
	if tex == null:
		var milieu := rect.position.y + rect.size.y / 2
		ci.draw_string(police, Vector2(rect.position.x, milieu), r["nom"],
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Palette.TEXTE)
		ci.draw_string(police, Vector2(rect.position.x, milieu + 18), r["type"],
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, couleurs["clair"])
	elif rect.size.x > rect.size.y * 1.4:
		# tuile large (boutique) : icone a gauche, nom a droite sur deux lignes
		var cote := cadre.size.y - 10
		_icone(ci, tex, Rect2(cadre.position + Vector2(5, 5), Vector2(cote, cote)))
		var x := cadre.position.x + cote + 10
		ci.draw_multiline_string(police, Vector2(x, cadre.position.y + 22), r["nom"],
			HORIZONTAL_ALIGNMENT_LEFT, cadre.end.x - x - 4, 12, 2, Palette.TEXTE)
	elif not nom:
		_icone(ci, tex, cadre.grow(-6))
	else:
		# case du Nid : icone en haut, nom en bas
		_icone(ci, tex, Rect2(cadre.position + Vector2(8, 6), Vector2(cadre.size.x - 16, cadre.size.y - 34)))
		ci.draw_string(police, Vector2(rect.position.x, cadre.end.y - 11), r["nom"],
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Palette.TEXTE)
	# niveau : une etoile par niveau au-dessus du premier, en haut de la tuile
	if niv > 1:
		ci.draw_string(police, Vector2(rect.position.x, rect.position.y + 20), "★".repeat(niv - 1),
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, Color("#f2c94c"))

# Une relique sur ses cases : fond de son element (les cases d'une meme
# relique se rejoignent), contour a la couleur de sa rarete, icone sur
# l'ensemble, etoiles de niveau. cote : taille d'une case.
static func dessiner_forme(ci: CanvasItem, cellules: Array, id: String, niv: int, cote: float, survol := false) -> void:
	var r: Dictionary = Data.RELIQUES[id]
	var couleurs: Dictionary = Palette.ELEMENTS[r["element"]]
	var rarete := Data.rarete(id)
	var bord: Color = Palette.RARETES[rarete] if rarete != "commun" else couleurs["vif"]
	var marge := cote * 0.12
	var boite: Rect2 = cellules[0]
	for c in cellules:
		boite = boite.merge(c)
	for c in cellules:
		# on ne rentre que sur les cotes qui ne touchent pas une autre case de la relique
		var g := 0.0 if cellules.has(Rect2(c.position - Vector2(cote, 0), c.size)) else marge
		var d := 0.0 if cellules.has(Rect2(c.position + Vector2(cote, 0), c.size)) else marge
		var h := 0.0 if cellules.has(Rect2(c.position - Vector2(0, cote), c.size)) else marge
		var b := 0.0 if cellules.has(Rect2(c.position + Vector2(0, cote), c.size)) else marge
		var plein := Rect2(c.position + Vector2(g, h), c.size - Vector2(g + d, h + b))
		ci.draw_rect(plein, couleurs["fond"].lightened(0.12) if survol else couleurs["fond"])
		if g > 0.0:
			ci.draw_line(plein.position, Vector2(plein.position.x, plein.end.y), bord, 2.0)
		if d > 0.0:
			ci.draw_line(Vector2(plein.end.x, plein.position.y), plein.end, bord, 2.0)
		if h > 0.0:
			ci.draw_line(plein.position, Vector2(plein.end.x, plein.position.y), bord, 2.0)
		if b > 0.0:
			ci.draw_line(Vector2(plein.position.x, plein.end.y), plein.end, bord, 2.0)
		# catalyseur : une fleche vers l'exterieur sur chaque cote libre, pour
		# montrer qu'il renforce ce qui le touche
		if r["type"] == "catalyseur":
			var f := cote * 0.09
			var jaune := Color("#f2c94c")
			var centre: Vector2 = c.get_center()
			for cote_libre in [[g, Vector2(-1, 0)], [d, Vector2(1, 0)], [h, Vector2(0, -1)], [b, Vector2(0, 1)]]:
				if cote_libre[0] <= 0.0:
					continue
				var dir: Vector2 = cote_libre[1]
				var pointe: Vector2 = centre + dir * (c.size.x / 2 - 1)
				var base: Vector2 = pointe - dir * f * 1.4
				var perp := Vector2(-dir.y, dir.x) * f
				var tri := PackedVector2Array([pointe, base + perp, base - perp])
				ci.draw_colored_polygon(tri, jaune)
				ci.draw_polyline(PackedVector2Array([pointe, base + perp, base - perp, pointe]), Color(0, 0, 0, 0.6), 1.0, true)
	var tex := Palette.icone(id)
	if tex != null:
		_icone(ci, tex, boite.grow(-marge - 4))
	else:
		ci.draw_string(ThemeDB.fallback_font, Vector2(boite.position.x, boite.get_center().y), r["nom"],
			HORIZONTAL_ALIGNMENT_CENTER, boite.size.x, 12, Palette.TEXTE)
	if niv > 1:
		ci.draw_string(ThemeDB.fallback_font, Vector2(boite.position.x, boite.position.y + marge + 16), "★".repeat(niv - 1),
			HORIZONTAL_ALIGNMENT_CENTER, boite.size.x, 16, Color("#f2c94c"))

# Icone centree dans la zone, proportions gardees.
static func _icone(ci: CanvasItem, tex: Texture2D, zone: Rect2) -> void:
	var k := minf(zone.size.x / tex.get_width(), zone.size.y / tex.get_height())
	var taille := tex.get_size() * k
	ci.draw_texture_rect(tex, Rect2(zone.position + (zone.size - taille) / 2, taille), false)

static func info(id: String) -> String:
	var r: Dictionary = Data.RELIQUES[id]
	var genre: String = r["type"]
	if r.has("famille"):
		genre = "arme (%s)" % Data.FAMILLES[r["famille"]]
	return "%s\n%s, %s" % [r["nom"], Data.NOMS_RARETE[Data.rarete(id)], genre]

# Infobulle d'une relique : nom a la couleur de sa rarete, genre, Cour,
# affinite, puis ce qu'elle fait.
const TROP_CHER := Color("#e5604f")

static func bulle(id: String, niv := 1, manque := 0) -> Control:
	var r: Dictionary = Data.RELIQUES[id]
	var rarete := Data.rarete(id)
	var pile := VBoxContainer.new()
	pile.add_theme_constant_override("separation", 6)
	# en tete : le blason de la dynastie, puis le nom
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 10)
	var blason := Palette.blason(r["element"])
	if blason != null:
		var ic := TextureRect.new()
		ic.texture = blason
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(30, 38)
		tete.add_child(ic)
	var nom := Label.new()
	nom.text = r["nom"] + ("  " + "★".repeat(niv - 1) if niv > 1 else "")
	nom.add_theme_font_size_override("font_size", 18)
	nom.add_theme_color_override("font_color", Palette.RARETES[rarete] if rarete != "commun" else Palette.TEXTE)
	nom.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tete.add_child(nom)
	pile.add_child(tete)
	var genre: String = r["type"].capitalize()
	if r.has("famille"):
		genre = "Arme (%s)" % Data.FAMILLES[r["famille"]]
	var cour: String = Data.DYNASTIES.get(r["element"], "Neutre")
	var taille := Data.empreinte(id).size()
	var ligne := "%s, %s, %d case%s" % [Data.NOMS_RARETE[rarete], genre.to_lower(), taille, "s" if taille > 1 else ""]
	var sous := Label.new()
	sous.text = ligne + "\n" + cour + ("" if r["affinite"] == 0 else ", affinité +%d" % r["affinite"])
	sous.add_theme_color_override("font_color", Palette.ELEMENTS[r["element"]]["clair"])
	pile.add_child(sous)
	var texte := Label.new()
	texte.text = Descriptions.TEXTES.get(id, "")
	if niv > 1:
		var mult: float = Data.NIVEAU_MULT[niv]
		texte.text += "\nNiveau %d : effets x%s." % [niv, ("%d" % mult) if mult == int(mult) else str(mult).replace(".", ",")]
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte.custom_minimum_size.x = 300
	texte.add_theme_color_override("font_color", Palette.TEXTE)
	pile.add_child(texte)
	if manque > 0:
		var prix := Label.new()
		prix.text = "Pas assez d'or : il manque %d or." % manque
		prix.add_theme_color_override("font_color", TROP_CHER)
		pile.add_child(prix)
	return pile

# Ce qu'on tient sous la souris : la forme de la relique, a la taille des
# cases du sac, qui tourne avec R ou la molette.
# Le moteur replace la racine de l'apercu sous la souris a chaque mouvement :
# la forme est un enfant decale, pour que la case saisie reste sous le curseur.
func apercu(id: String) -> Control:
	var racine := Control.new()
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var a := Apercu.new()
	a.id = id
	a.ecran = self
	a.modulate.a = 0.85
	racine.add_child(a)
	return racine

class Apercu extends Control:
	var id := ""
	var ecran: NidScreen
	func _process(_d: float) -> void:
		var cote: float = ecran.sac.cote
		position = -(Vector2(ecran.prise) * cote + Vector2(cote, cote) / 2)
		queue_redraw()
	func _draw() -> void:
		var cote: float = ecran.sac.cote
		var cellules := []
		for d in Data.empreinte(id, ecran.rot_prise):
			cellules.append(Rect2(Vector2(d) * cote, Vector2(cote, cote)))
		NidScreen.dessiner_forme(self, cellules, id, 1, cote)

class Offre extends Control:
	var ecran: NidScreen
	var index: int
	func _init(e: NidScreen, i: int) -> void:
		ecran = e
		index = i
		custom_minimum_size = Vector2(130, 146)
		tooltip_text = " "
	func _get_tooltip(_p: Vector2) -> String:
		return "" if _id() == "" else NidScreen.info(_id())
	func _make_custom_tooltip(_t: String) -> Object:
		return NidScreen.bulle(_id(), 1, _manque())
	func _id() -> String:
		return ecran.partie.offres[index]
	# Posee sur le comptoir : une ombre sur le bois, l'icone, une pierre a la
	# couleur de sa rarete, sa forme en petit, et une etiquette nom et prix.
	func _draw() -> void:
		var cote := 92.0
		var icone := Rect2(Vector2((size.x - cote) / 2, 4), Vector2(cote, cote))
		var police := ThemeDB.fallback_font
		if _id() == "":
			draw_string(police, Vector2(0, icone.get_center().y), "Vendu", HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(Palette.TEXTE, 0.6))
			return
		var prix := ecran.partie.prix_offre(index)
		var manque := _manque()
		draw_set_transform(Vector2(size.x / 2, icone.end.y - 6), 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, cote * 0.45, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO)
		if ecran.partie.gelee:
			draw_circle(icone.get_center(), cote * 0.55, Color("#9cd3f0", 0.25))
			draw_arc(icone.get_center(), cote * 0.55, 0, TAU, 40, Color("#9cd3f0"), 2.0, true)
		var tex := Palette.icone(_id())
		var teinte := Color(0.45, 0.45, 0.45) if manque > 0 else Color.WHITE
		if tex != null:
			var k := minf(cote / tex.get_width(), cote / tex.get_height())
			var t := tex.get_size() * k
			draw_texture_rect(tex, Rect2(icone.get_center() - t / 2, t), false, teinte)
		else:
			draw_string(police, Vector2(0, icone.get_center().y), Data.RELIQUES[_id()]["nom"], HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Palette.TEXTE)
		var rarete := Data.rarete(_id())
		if rarete != "commun":
			draw_circle(icone.position + Vector2(8, cote - 8), 7, Palette.RARETES[rarete])
			draw_arc(icone.position + Vector2(8, cote - 8), 7, 0, TAU, 16, Color(0, 0, 0, 0.6), 1.5, true)
		var forme := Data.empreinte(_id())
		if forme.size() > 1:
			var bas := Vector2i.ZERO
			for d in forme:
				bas = Vector2i(maxi(bas.x, d.x), maxi(bas.y, d.y))
			var o := Vector2(icone.end.x - (bas.x + 1) * 8, icone.position.y)
			for d in forme:
				draw_rect(Rect2(o + Vector2(d) * 8, Vector2(7, 7)), Palette.TEXTE)
				draw_rect(Rect2(o + Vector2(d) * 8, Vector2(7, 7)), Color(0, 0, 0, 0.6), false, 1.0)
		if manque > 0:
			_cadenas(icone.get_center())
		# etiquette : nom et prix
		var texte := "Offert" if index == ecran.partie.gratuite else "%d or" % prix
		if manque > 0:
			texte = "%d or, il manque %d" % [prix, manque]
		var etiquette := Rect2(Vector2(2, icone.end.y + 6), Vector2(size.x - 4, 40))
		draw_rect(etiquette, Color(Palette.FOND, 0.78))
		draw_rect(Rect2(etiquette.position, Vector2(etiquette.size.x, 2)), Palette.RARETES[rarete] if rarete != "commun" else Palette.CASE_BORD)
		draw_string(police, etiquette.position + Vector2(0, 17), Data.RELIQUES[_id()]["nom"], HORIZONTAL_ALIGNMENT_CENTER, etiquette.size.x, 12, Palette.TEXTE)
		draw_string(police, etiquette.position + Vector2(0, 34), texte, HORIZONTAL_ALIGNMENT_CENTER, etiquette.size.x, 13,
			NidScreen.TROP_CHER if manque > 0 else Color("#f2c94c"))
	func _manque() -> int:
		return maxi(0, ecran.partie.prix_offre(index) - ecran.partie.bourse)
	func _cadenas(c: Vector2) -> void:
		draw_arc(c + Vector2(0, -6), 8, PI, TAU, 12, NidScreen.TROP_CHER, 3.0, true)
		draw_rect(Rect2(c + Vector2(-11, -6), Vector2(22, 17)), NidScreen.TROP_CHER)
		draw_circle(c + Vector2(0, 2), 2.5, Color(0, 0, 0, 0.8))
	func _get_drag_data(_p: Vector2) -> Variant:
		if _id() == "" or ecran.partie.bourse < ecran.partie.prix_offre(index):
			return null
		ecran.rot_prise = 0
		ecran.prise = Vector2i.ZERO
		set_drag_preview(ecran.apercu(_id()))
		return {"id": _id(), "offre": index}
	# Ramener une relique posee sur la boutique la revend.
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return NidScreen.glisse(data) and not data.has("offre")
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.vendre_source(data)
		ecran.apres_pose()

class Boutique extends VBoxContainer:
	var ecran: NidScreen
	func _init(e: NidScreen) -> void:
		ecran = e
		mouse_filter = Control.MOUSE_FILTER_PASS
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return NidScreen.glisse(data) and not data.has("offre")
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.vendre_source(data)
		ecran.apres_pose()

# Le comptoir : y lacher une relique du sac la revend. Pendant qu'on en tient
# une, il s'eclaire et affiche le prix de revente.
class ZoneVente extends Control:
	var ecran: NidScreen
	var survol := false
	func _init(e: NidScreen) -> void:
		ecran = e
		mouse_filter = Control.MOUSE_FILTER_PASS
		mouse_exited.connect(func():
			survol = false
			queue_redraw())
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		var ok: bool = NidScreen.glisse(data) and not data.has("offre")
		if ok and not survol:
			survol = true
			queue_redraw()
		return ok
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.vendre_source(data)
		ecran.apres_pose()
	func _draw() -> void:
		if ecran.revente < 0:
			return
		var r := Rect2(Vector2.ZERO, size)
		var or_ := Color("#f2c94c")
		draw_rect(r, Color(or_, 0.22 if survol else 0.1))
		draw_rect(r, Color(or_, 0.9 if survol else 0.5), false, 3.0)

# Un emplacement de la reserve : une relique de cote, sans effet.
class CaseReserve extends Control:
	var ecran: NidScreen
	var index: int
	func _init(e: NidScreen, k: int) -> void:
		ecran = e
		index = k
		custom_minimum_size = Vector2(52, 52)
		tooltip_text = " "
	func _r() -> Dictionary:
		return ecran.partie.reserve[index]
	func _get_tooltip(_p: Vector2) -> String:
		return "" if _r().is_empty() else NidScreen.info(_r()["id"])
	func _make_custom_tooltip(_t: String) -> Object:
		return null if _r().is_empty() else NidScreen.bulle(_r()["id"], _r()["niv"])
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(Palette.CASE, 0.9))
		draw_rect(r, Palette.CASE_BORD, false, 1.0)
		if not _r().is_empty():
			NidScreen.dessiner_forme(self, [r], _r()["id"], _r()["niv"], size.x)
	func _get_drag_data(_p: Vector2) -> Variant:
		if _r().is_empty():
			return null
		ecran.rot_prise = 0
		ecran.prise = Vector2i.ZERO
		ecran.montrer_vente(Partie.prix_revente(_r()["id"], _r()["niv"]))
		set_drag_preview(ecran.apercu(_r()["id"]))
		return {"id": _r()["id"], "reserve": index}
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return NidScreen.glisse(data) and ecran.partie.ranger(data, index, true)
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.ranger(data, index)
		ecran.apres_pose()

class CaseNid extends Control:
	var ecran: NidScreen
	var position_nid: Vector2i
	func _init(e: NidScreen, c: Vector2i) -> void:
		ecran = e
		position_nid = c
		tooltip_text = " "
		mouse_entered.connect(func(): ecran.case_survolee = position_nid; ecran.sac.queue_redraw())
		mouse_exited.connect(func():
			if ecran.case_survolee == position_nid:
				ecran.case_survolee = null
			ecran.sac.queue_redraw())
	# ancre de la relique qui couvre cette case, null si vide
	func _ancre():
		return ecran.nid.ancre(position_nid)
	func _get_tooltip(_p: Vector2) -> String:
		var a = _ancre()
		return "" if a == null else NidScreen.info(ecran.nid.cases[a])
	func _make_custom_tooltip(_t: String) -> Object:
		var a = _ancre()
		return null if a == null else NidScreen.bulle(ecran.nid.cases[a], ecran.nid.niveau(a))
	func _get_drag_data(_p: Vector2) -> Variant:
		var a = _ancre()
		if a == null:
			return null
		ecran.montrer_vente(Partie.prix_revente(ecran.nid.cases[a], ecran.nid.niveau(a)))
		ecran.rot_prise = ecran.nid.rotation(a)
		ecran.prise = position_nid - a
		set_drag_preview(ecran.apercu(ecran.nid.cases[a]))
		return {"id": ecran.nid.cases[a], "depuis": a}
	# Ou tomberait la relique tenue si on la lachait ici. Sur une autre relique,
	# elle prend sa place et l'autre passe dans la main.
	func _pose(data: Dictionary) -> Dictionary:
		var b: Vector2i = position_nid - ecran.prise
		var pose := ecran.partie.poser(data, position_nid, b, ecran.rot_prise, true)
		pose["ancre"] = b
		return pose
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		if not NidScreen.glisse(data):
			return false
		var pose := _pose(data)
		ecran.pose_vue = pose
		ecran.sac.queue_redraw()
		return pose["ok"]
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.partie.poser(data, position_nid, position_nid - ecran.prise, ecran.rot_prise)
		ecran.apres_pose()

# Tapis du sac, en tuiles : chaque case prend la tuile dont les bords en cuir
# correspondent a sa place (haut, droite, bas, gauche du tapis). Une case sur
# deux est assombrie pour lire la grille.
# Les tuiles du tapis pour ces colonnes ouvertes (dans l'ordre), cases de
# cote pixels, a partir de origine. Sert au sac et au Nid en combat.
const TAPIS_SOMBRE := Color(0.8, 0.75, 0.68)

static func dessiner_tapis(ci: CanvasItem, colonnes: Array, cote: float, origine: Vector2) -> void:
	var n := colonnes.size()
	for i in n:
		for y in Data.NID_H:
			var bords := ""
			if y == 0:
				bords += "H"
			if i == n - 1:
				bords += "D"
			if y == Data.NID_H - 1:
				bords += "B"
			if i == 0:
				bords += "G"
			var tex := Palette.image("res://images/tapis/%s.png" % (bords if bords != "" else "toile"))
			var r := Rect2(origine + Vector2(i, y) * cote, Vector2(cote, cote))
			var teinte := TAPIS_SOMBRE if (colonnes[i] + y) % 2 == 1 else Color.WHITE
			if tex != null:
				ci.draw_texture_rect(tex, r, false, teinte)
			else:
				ci.draw_rect(r, Color("#d9c9a6") * teinte)

class Tapis extends Control:
	var ecran: NidScreen
	var colonnes: Array = []
	var cote := 100.0
	func _init(e: NidScreen) -> void:
		ecran = e
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		NidScreen.dessiner_tapis(self, colonnes, cote, Vector2.ZERO)
		var nid := ecran.nid
		var survolee = nid.ancre(ecran.case_survolee) if ecran.case_survolee != null else null
		# survol d'un catalyseur : les reliques qu'il touche s'allument
		var renforcees := []
		if survolee != null and Data.RELIQUES[nid.cases[survolee]]["type"] == "catalyseur":
			renforcees = nid.voisins(survolee)
		for a in nid.cases:
			var cellules := []
			for k in nid.cases_de(a):
				cellules.append(_rect(k))
			NidScreen.dessiner_forme(self, cellules, nid.cases[a], nid.niveau(a), cote, a == survolee)
			if a in renforcees:
				for r in cellules:
					draw_rect(r.grow(-cote * 0.1), Color("#f2c94c", 0.25))
					draw_rect(r.grow(-cote * 0.1), Color("#f2c94c"), false, 2.0)
		# apercu de la pose : vert si permise, rouge sinon
		if not ecran.pose_vue.is_empty():
			var couleur := Color(0.4, 0.9, 0.4, 0.35) if ecran.pose_vue["ok"] else Color(0.95, 0.3, 0.25, 0.35)
			for k in ecran.pose_vue["cases"]:
				if colonnes.has(k.x) and k.y >= 0 and k.y < Data.NID_H:
					draw_rect(_rect(k).grow(-cote * 0.06), couleur)
	func _rect(k: Vector2i) -> Rect2:
		return Rect2(Vector2(colonnes.find(k.x), k.y) * cote, Vector2(cote, cote))
