class_name Glossaire
extends CanvasLayer

# Glossaire consultable de partout : un bouton en haut a droite (ou F1) ouvre
# un panneau qui explique les regles, les etats et les dynasties. Les chiffres
# viennent de Data, ils suivent l'equilibrage.

var bouton: Button
var panneau: PanelContainer

func _ready() -> void:
	layer = 50
	bouton = Button.new()
	bouton.text = "Glossaire"
	bouton.tooltip_text = "Règles, états et dynasties (F1)"
	bouton.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	bouton.offset_left = -130
	bouton.offset_right = -20
	bouton.offset_top = 22
	bouton.offset_bottom = 58
	bouton.pressed.connect(basculer)
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
	add_child(panneau)
	var pile := VBoxContainer.new()
	pile.add_theme_constant_override("separation", 10)
	panneau.add_child(pile)
	var tete := HBoxContainer.new()
	var titre := Label.new()
	titre.text = "Glossaire"
	titre.add_theme_font_size_override("font_size", 26)
	titre.add_theme_color_override("font_color", Palette.TEXTE)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(titre)
	var fermer := Button.new()
	fermer.text = "Fermer"
	fermer.pressed.connect(basculer)
	tete.add_child(fermer)
	pile.add_child(tete)
	var defile := ScrollContainer.new()
	defile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pile.add_child(defile)
	var texte := RichTextLabel.new()
	texte.bbcode_enabled = true
	texte.fit_content = true
	texte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texte.add_theme_color_override("default_color", Palette.TEXTE)
	texte.add_theme_font_size_override("normal_font_size", 16)
	texte.add_theme_font_size_override("bold_font_size", 17)
	texte.text = contenu()
	defile.add_child(texte)

func basculer() -> void:
	panneau.visible = not panneau.visible

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_F1 or (ev.keycode == KEY_ESCAPE and panneau.visible):
			basculer()
			get_viewport().set_input_as_handled()

static func _section(titre: String) -> String:
	return "\n[font_size=21][color=#f2c94c]%s[/color][/font_size]\n" % titre

static func _terme(nom: String, texte: String) -> String:
	return "[b]%s[/b] : %s\n" % [nom, texte]

static func contenu() -> String:
	var t := ""
	t += _section("Le Nid et la monture")
	t += _terme("Reliques", "on les achète en boutique et on les pose sur le tapis du sac. Chacune donne de l'affinité à sa dynastie.")
	t += _terme("Monture", "la dynastie qui a le plus d'affinité donne son passif. Une seule dynastie : sa monture pure. Deux ou plus : un hybride des deux premières. Sans affinité : une créature informe.")
	t += _terme("Types", "Essence (stats et effets permanents), Sort (se déclenche sur sa recharge), Catalyseur (renforce les reliques qui touchent l'une de ses cases ; des flèches jaunes autour, et ses voisines s'allument au survol), Arme (tenue par le cavalier, lance son propre sort).")
	t += _terme("Formes", "une relique prend de 1 à 4 cases selon sa rareté, ou sa famille pour une arme. R ou la molette la tournent pendant qu'on la tient.")
	t += _terme("Sac", "il commence sur 4 colonnes et s'agrandit d'une colonne en boutique (prix croissant) ou après chaque boss battu, jusqu'à 8.")
	t += _terme("Fusion", "3 copies identiques au même niveau fusionnent : ★ (effets x%s), puis ★★ (effets x%s). Tout fusionne, armes et légendaires compris." % [_nombre(Data.NIVEAU_MULT[2]), _nombre(Data.NIVEAU_MULT[3])])
	t += _terme("Armes", "pas de limite : chaque arme du sac lance son propre sort. Le cavalier en montre deux.")
	t += _section("La run")
	t += _terme("Carte", "3 actes à embranchements. On choisit son chemin ; le boss attend au bout de chaque acte.")
	t += _terme("Nœuds", "Duel (contre un autre Nid au même stade), Élite (plus fort, relique épique offerte), Rencontre (un choix), Marché (raretés en avance, relances gratuites), Feu de camp (soigne des PV de run), Boss (relique légendaire offerte).")
	t += _terme("PV de run", "une défaite en coûte selon le nœud et la vie qui restait à l'adversaire. À 0, la run est perdue.")
	t += _terme("Boutique", "ouverte après chaque nœud, sans obligation d'acheter. Relancer change les offres ; Geler les garde pour le prochain passage. Revendre rend la moitié du prix.")
	t += _terme("Rareté", "commun, rare, épique, légendaire. Les raretés hautes apparaissent au fil des nœuds.")
	t += _section("Le combat")
	t += _terme("Déroulé", "automatique : attaques selon la vitesse, sorts selon leur recharge. Même Nids, même combat.")
	t += _terme("Fatigue", "après %d s, des dégâts croissants des deux côtés pour finir le combat." % Data.MORT_SUBITE)
	t += _terme("Coup critique", "x%s dégâts. Les Lames donnent des chances de critique à toute la monture." % _nombre(Data.CRIT_MULT))
	t += _section("Les états")
	t += _terme("Brûlure", "dégâts chaque seconde, qui passent à travers le bouclier. Les charges s'éteignent d'elles-mêmes.")
	t += _terme("Combustion", "consume les brûlures de la cible d'un coup, en gros dégâts.")
	t += _terme("Braise", "hâte : +%d %% de vitesse par charge, jusqu'à %d charges." % [roundi(Data.HATE_PAR_BRAISE * 100), Data.BRAISE_MAX])
	t += _terme("Poison", "des doses qui blessent chaque seconde, passent à travers le bouclier et s'empilent jusqu'à %d." % Data.POISON_MAX)
	t += _terme("Épines", "blessent celui qui frappe.")
	t += _terme("Givre", "chaque charge ralentit attaques et recharges de %d %%. À %d charges, la cible gèle." % [roundi(Data.GIVRE_RALENTI * 100), Data.GEL_SEUIL])
	t += _terme("Gel", "la cible n'attaque plus et ses recharges s'arrêtent un moment.")
	t += _terme("Bouclier", "absorbe les coups avant les PV. Certaines reliques se déclenchent quand il se brise.")
	t += _terme("Vol de vie", "une part des dégâts infligés revient en soin.")
	t += _terme("Malédictions", "durent %d s. Faiblesse : %d %% de dégâts en moins. Langueur : %d %% de vitesse d'attaque en moins. Flétrissure : %d %% de soins reçus en moins. Une charge chacune, trois avec le Chapelet des rancunes." % [Data.MALEDICTION_DUREE, roundi(Data.FAIBLESSE * 100), roundi(Data.LANGUEUR * 100), roundi(Data.FLETRISSURE * 100)])
	t += _terme("Éclat", "les soins remplissent une jauge ; pleine (%d), elle frappe l'adversaire." % Data.ECLAT_SEUIL)
	t += _terme("Transfert", "vole un bonus adverse (bouclier, Braise...) ou lui renvoie un malus (poison, brûlure, givre, malédiction). Rien à déplacer : un projectile d'arcane.")
	t += _terme("Régénération", "des PV rendus chaque seconde.")
	t += _section("Les dynasties")
	for e in Data.DYNASTIES:
		t += _terme("%s (%s)" % [Data.DYNASTIES[e], Data.FORMES[e]["nom"]], Data.IDENTITES[e])
	return t

static func _nombre(x: float) -> String:
	return ("%d" % x) if x == int(x) else str(x).replace(".", ",")
