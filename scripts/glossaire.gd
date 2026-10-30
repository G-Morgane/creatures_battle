class_name Glossaire
extends CanvasLayer

# Glossaire consultable de partout : un bouton en haut a droite (ou F1) ouvre
# un panneau qui explique les regles, les etats et les dynasties. Les chiffres
# viennent de Data, ils suivent l'equilibrage.

var bouton: Button
var panneau: PanelContainer
var texte: RichTextLabel

func _ready() -> void:
	layer = 50
	# un calque ne recoit pas le theme de la fenetre : on le donne a ses racines
	var theme_jeu := Palette.theme_jeu()
	bouton = Button.new()
	bouton.text = "Glossaire"
	bouton.icon = Palette.ui("glossaire")
	bouton.expand_icon = true
	bouton.add_theme_constant_override("icon_max_width", 28)
	bouton.tooltip_text = "Règles, états et dynasties (F1)"
	bouton.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	bouton.offset_left = -170
	bouton.offset_right = -20
	bouton.offset_top = 22
	bouton.offset_bottom = 58
	bouton.pressed.connect(basculer)
	bouton.theme = theme_jeu
	add_child(bouton)

	panneau = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FOND, 0.97)
	style.border_color = Palette.CASE_BORD
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	panneau.add_theme_stylebox_override("panel", style)
	panneau.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right"]:
		panneau.set("offset_" + cote, 140 if cote == "left" else -140)
	panneau.offset_top = 70
	panneau.offset_bottom = -40
	panneau.visible = false
	panneau.theme = theme_jeu
	add_child(panneau)
	var pile := VBoxContainer.new()
	pile.add_theme_constant_override("separation", 10)
	panneau.add_child(pile)
	var tete := HBoxContainer.new()
	var titre := Label.new()
	titre.text = "Glossaire"
	titre.add_theme_font_size_override("font_size", 26)
	Palette.titre(titre)
	titre.add_theme_color_override("font_color", Palette.TEXTE)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(titre)
	var fermer := Button.new()
	fermer.text = "Fermer"
	fermer.pressed.connect(basculer)
	tete.add_child(fermer)
	pile.add_child(tete)
	# a gauche les signets (un par chapitre), a droite le chapitre ouvert
	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 18)
	pile.add_child(corps)
	var signets := VBoxContainer.new()
	signets.custom_minimum_size.x = 220
	signets.add_theme_constant_override("separation", 6)
	corps.add_child(signets)
	var defile := ScrollContainer.new()
	defile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corps.add_child(defile)
	texte = RichTextLabel.new()
	texte.bbcode_enabled = true
	texte.fit_content = true
	texte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texte.add_theme_color_override("default_color", Palette.TEXTE)
	texte.add_theme_font_size_override("normal_font_size", 17)
	texte.add_theme_font_size_override("bold_font_size", 18)
	defile.add_child(texte)
	var groupe := ButtonGroup.new()
	var liste := chapitres()
	for k in liste.size():
		var b := Button.new()
		b.text = liste[k][0]
		b.toggle_mode = true
		b.button_group = groupe
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 40
		b.pressed.connect(func():
			texte.text = "[font=%s][font_size=24][color=#f2c94c]%s[/color][/font_size][/font]\n\n%s" % [Palette.TITRE_POLICE, liste[k][0], liste[k][1]]
			defile.scroll_vertical = 0)
		signets.add_child(b)
		if k == 0:
			b.button_pressed = true
			b.pressed.emit()

func basculer() -> void:
	panneau.visible = not panneau.visible

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_F1 or (ev.keycode == KEY_ESCAPE and panneau.visible):
			basculer()
			get_viewport().set_input_as_handled()

# Debut d'un chapitre (un signet dans le glossaire).
const CHAPITRE := "\u0001"

static func _section(titre: String) -> String:
	return CHAPITRE + titre + "\n"

# [titre, texte] pour chaque chapitre.
static func chapitres() -> Array:
	var l := []
	for bloc in contenu().split(CHAPITRE, false):
		var i := bloc.find("\n")
		l.append([bloc.substr(0, i), bloc.substr(i + 1).strip_edges()])
	return l

static func _terme(nom: String, texte: String) -> String:
	return "[b]%s[/b] : %s\n\n" % [nom, texte]

static func contenu() -> String:
	var t := ""
	t += _section("Le Nid et la monture")
	t += _terme("Reliques", "on les achète en boutique et on les pose sur le tapis du sac. Chacune donne de l'affinité à sa dynastie.")
	t += _terme("Monture", "la dynastie qui a le plus d'affinité donne son passif. Au moins 2 objets d'une autre dynastie : un hybride des deux. Sinon, la monture pure. Sans affinité : une créature informe.")
	t += _terme("Types", "Essence (stats et effets permanents), Sort (se déclenche sur sa recharge), Catalyseur (renforce les reliques qui touchent l'une de ses cases ; des flèches jaunes autour, et ses voisines s'allument au survol), Arme (tenue par le cavalier, lance son propre sort).")
	t += _terme("Signature", "Chaque sort et chaque arme ajoute, à chaque activation, un petit effet de sa dynastie : Été 1 brûlure, Printemps 1 dose de poison, Hiver 1 givre, Nuit draine 5 PV, Aube soigne 3 PV, Crépuscule un projectile d'arcane de 4, Automne une griffe de 3, Jour 3 de bouclier. Multiplié par le niveau. Chaque essence en donne un cinquième à chaque attaque de la monture.")
	t += _terme("Formes", "une relique prend de 1 à 4 cases selon sa rareté, ou sa famille pour une arme. R ou la molette la tournent pendant qu'on la tient.")
	t += _terme("Sac", "il commence sur 4 colonnes de 4 cases. En boutique, Agrandir ouvre une case de ton choix collée au sac (2 or, puis +1 à chaque achat) ; chaque boss battu en offre une, chaque niveau aussi. Jusqu'à 8 colonnes.")
	t += _terme("Niveau", "il monte seul : un point d'expérience par nœud franchi. Chaque niveau donne +%d PV à la monture et une case de sac offerte. Les adversaires ont le niveau de leurs manches jouées." % Partie.PV_PAR_NIVEAU)
	t += _terme("Fusion", "3 copies identiques fusionnent en ★ (effets x%s), puis 2 ★ en ★★ (effets x%s, 6 copies en tout). Tout fusionne, armes et légendaires compris." % [_nombre(Data.NIVEAU_MULT[2]), _nombre(Data.NIVEAU_MULT[3])])
	t += _terme("Réserve", "%d emplacements hors du sac pour garder des reliques de côté. Elles n'y ont aucun effet et ne comptent pas pour les fusions." % Partie.TAILLE_RESERVE)
	t += _terme("Échange", "lâcher une relique sur une autre la met à sa place ; l'autre passe dans ta main pour être reposée. Lâchée nulle part, elle va en réserve (ou dans le sac, ou revendue s'il n'y a plus de place).")
	t += _terme("Armes", "pas de limite : chaque arme du sac lance son propre sort. Le cavalier en montre deux.")
	t += _section("La run")
	t += _terme("Carte", "3 actes à embranchements. On choisit son chemin ; le boss attend au bout de chaque acte.")
	t += _terme("Nœuds", "Duel (contre un autre Nid au même stade), Élite (plus fort, relique épique offerte), Rencontre (un choix), Feu de camp (ravive la Ferveur), Boss (relique légendaire offerte).")
	t += _terme("Ferveur", "la volonté du cavalier de poursuivre la quête. Une défaite en coûte selon le nœud et la vie qui restait à l'adversaire. À 0, la run est perdue.")
	t += _terme("Boutique", "ouverte après chaque combat, sans obligation d'acheter. Relancer change les offres : 1 or, puis 1 de plus à chaque relance de la même boutique. Clic droit sur une offre : la verrouiller, elle reste aux relances et à la boutique suivante. Une offre sur dix environ est soldée à moitié prix. Ramener un objet du sac sur le comptoir le revend pour la moitié de son prix.")
	t += _terme("Rareté", "commun, rare, épique, légendaire. Les raretés hautes apparaissent au fil des nœuds.")
	t += _section("Le combat")
	t += _terme("Déroulé", "automatique : attaques selon la vitesse, sorts selon leur recharge. Même Nids, même combat.")
	t += _terme("Fatigue", "après %d s, des dégâts croissants des deux côtés pour finir le combat." % Data.MORT_SUBITE)
	t += _terme("Coup critique", "x%s dégâts. Les Lames et l'Automne donnent des chances de critique à toute la monture." % _nombre(Data.CRIT_MULT))
	t += _terme("Esquive", "une attaque ou un coup d'arme esquivé ne fait rien. Le Hast perce l'esquive.")
	t += _section("Les états")
	t += _terme("Brûlure", "dégâts chaque seconde, qui passent à travers le bouclier. Les charges s'éteignent d'elles-mêmes.")
	t += _terme("Combustion", "consume les brûlures de la cible d'un coup, en gros dégâts.")
	t += _terme("Éventail", "chaque arme lancée par le Paon en donne 1 (jusqu'à %d) : +%d %% de dégâts et de vitesse de recharge des armes par charge." % [Data.EVENTAIL_MAX, roundi(Data.EVENTAIL_BONUS * 100)])
	t += _terme("Poison", "des doses qui blessent chaque seconde, passent à travers le bouclier et s'empilent jusqu'à %d." % Data.POISON_MAX)
	t += _terme("Épines", "blessent celui qui frappe ; celles du Cerf l'empoisonnent aussi.")
	t += _terme("Givre", "chaque charge ralentit attaques et recharges de %d %%. À %d charges, la cible gèle." % [roundi(Data.GIVRE_RALENTI * 100), Data.GEL_SEUIL])
	t += _terme("Gel", "la cible n'attaque plus et ses recharges s'arrêtent un moment.")
	t += _terme("Bouclier", "absorbe les coups avant les PV.")
	t += _terme("Malédictions", "durent %d s, renouvelées si on les repose. Faiblesse : %d %% de dégâts en moins. Flétrissure : %d %% de soins reçus en moins. Stigmate : %d %% de dégâts reçus en plus." % [Data.MALEDICTION_DUREE, roundi(Data.FAIBLESSE * 100), roundi(Data.FLETRISSURE * 100), roundi(Data.STIGMATE * 100)])
	t += _terme("Éclat", "les soins remplissent une jauge ; pleine (%d), elle frappe l'adversaire." % Data.ECLAT_SEUIL)
	t += _terme("Illusion", "un double du Papillon, créé par les sorts de la monture (%d au plus). Elle encaisse une attaque ou un coup d'arme à sa place, puis éclate en projectile d'arcane." % Data.ILLUSIONS_MAX)
	t += _terme("Régénération", "des PV rendus chaque seconde.")
	t += _section("Les cavaliers")
	for c in Data.CAVALIERS:
		t += _terme("%s, %s" % [Data.CAVALIERS[c], Data.TALENTS[c][0]], Data.TALENTS[c][1])
	t += _section("Les élites")
	for e in Data.ELITES:
		t += _terme(Data.ELITES[e]["nom"], Data.ELITES[e]["texte"])
	t += _section("Les gardiens")
	t += "Les boss de fin d'acte sont des gardiens possédés par le Rêveur. Les vaincre les purifie : ils sont libérés, pas tués.\n\n"
	for g in Data.GARDIENS:
		t += _terme(Data.GARDIENS[g]["nom"], Data.GARDIENS[g]["texte"])
	t += _terme("Le cycle du Bastion", "Rempart : il gagne du bouclier et frappe lentement. Ouverture : il s'immobilise et l'œil du temple absorbe son bouclier. Le Regard : une attaque selon le bouclier absorbé (plafonnée). Résistance : son cavalier referme la porte, il reste sans protection et encaisse plus. Entamer son bouclier affaiblit le Regard.")
	t += _section("Le Rêveur")
	t += "Un dieu ancien qui possède les créatures à travers son rêve. Une seule run ne suffit pas : chaque run gagnée le rapproche de sa fin, et ce qui est détruit reste perdu pour lui.\n\n"
	t += _terme("Incarnation", "%s run%s gagnée%s pour la détruire." % [Progression.INCARNATION, "s" if Progression.INCARNATION > 1 else "", "s" if Progression.INCARNATION > 1 else ""])
	t += _terme("Ancrages", "%d ancrages le retiennent dans le monde, un par run gagnée ensuite." % Progression.ANCRAGES)
	t += _terme("Le rêve", "sans ancrage, on l'atteint dans son rêve : %d run%s gagnée%s de plus pour le vaincre." % [Progression.REVE, "s" if Progression.REVE > 1 else "", "s" if Progression.REVE > 1 else ""])
	t += _terme("État", "affiché sur l'écran de départ ; la fin d'une run gagnée dit ce qui vient de tomber.")
	t += _section("Les dynasties")
	for e in Data.DYNASTIES:
		# sans le nom de la monture : elle se decouvre en jouant
		t += _terme(Data.DYNASTIES[e], Data.IDENTITES[e])
	return t

static func _nombre(x: float) -> String:
	return ("%d" % x) if x == int(x) else str(x).replace(".", ",")
