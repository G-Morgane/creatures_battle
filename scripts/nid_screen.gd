class_name NidScreen
extends Control

# Ecran du Nid : boutique a gauche, grille au centre, creature a droite.
# Glisser une offre dans une case vide l'achete, glisser une case vers une
# autre echange, la ramener a la boutique ou clic droit la revend.

signal combattre
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
var offres_ui: Array = []
var relance: Button
var bouton_combat: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fond := ColorRect.new()
	fond.color = Palette.FOND
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 32)
	add_child(marge)
	var pile := VBoxContainer.new()
	pile.add_theme_constant_override("separation", 20)
	marge.add_child(pile)
	barre = _titre("")
	pile.add_child(barre)
	var colonnes := HBoxContainer.new()
	colonnes.add_theme_constant_override("separation", 40)
	colonnes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pile.add_child(colonnes)

	colonnes.add_child(_boutique())
	colonnes.add_child(_grille())
	colonnes.add_child(_panneau())
	rafraichir()

func _titre(texte: String) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Palette.TEXTE)
	return l

func _boutique() -> Control:
	var col := Boutique.new(self)
	col.add_theme_constant_override("separation", 12)
	col.add_child(_titre("Boutique"))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	for i in Partie.TAILLE_BOUTIQUE:
		var o := Offre.new(self, i)
		offres_ui.append(o)
		g.add_child(o)
	col.add_child(g)
	relance = Button.new()
	relance.text = "Relancer (%d or)" % Partie.PRIX_RELANCE
	relance.pressed.connect(func():
		partie.relancer()
		rafraichir())
	col.add_child(relance)
	var aide := Label.new()
	aide.text = "Glisse une offre dans le Nid pour l'acheter.\nRamène une relique ici ou clic droit\npour la revendre (moitié du prix).\nUne seule arme pour le cavalier."
	aide.add_theme_color_override("font_color", Palette.TEXTE_DOUX)
	col.add_child(aide)
	return col

func _grille() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.add_child(_titre("Nid"))
	var g := GridContainer.new()
	g.columns = Data.NID_L
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for y in Data.NID_H:
		for x in Data.NID_L:
			var c := CaseNid.new(self, Vector2i(x, y))
			cases_ui[c.position_nid] = c
			g.add_child(c)
	col.add_child(g)
	return col

func _panneau() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	vue = CreatureVue.new()
	vue.custom_minimum_size = Vector2(340, 300)
	col.add_child(vue)
	infos = _texte()
	infos.fit_content = true
	col.add_child(infos)
	bouton_combat = Button.new()
	bouton_combat.custom_minimum_size.y = 44
	bouton_combat.pressed.connect(_combattre)
	col.add_child(bouton_combat)
	return col

func _texte() -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.add_theme_color_override("default_color", Palette.TEXTE)
	t.add_theme_font_size_override("normal_font_size", 16)
	t.add_theme_font_size_override("bold_font_size", 16)
	return t

# --- actions ---------------------------------------------------------------

# depuis : case d'origine si on deplace une relique deja posee, null sinon.
func deposer(c: Vector2i, id: String, depuis) -> void:
	if depuis == c or not nid.accepte(c, id, depuis):
		return
	var ancien = nid.cases.get(c)
	nid.retirer(c)
	if depuis != null:
		nid.retirer(depuis)
		if ancien != null:
			nid.placer(depuis, ancien)
	nid.placer(c, id)
	rafraichir()

func acheter(i: int, c: Vector2i) -> void:
	partie.acheter(i, c)
	rafraichir()

func vendre(c: Vector2i) -> void:
	partie.vendre(c)
	rafraichir()

func rafraichir() -> void:
	for c in cases_ui:
		cases_ui[c].queue_redraw()
	var cr := nid.eclore()
	vue.montrer(cr["forme"], _affinite_totale(), cr["arme"])
	infos.text = _decrire(cr)
	for o in offres_ui:
		o.queue_redraw()
	relance.disabled = partie.bourse < Partie.PRIX_RELANCE or partie.terminee()
	barre.text = "Manche %d      Or %d      Victoires %d / %d      Défaites %d / %d" % [
		partie.manche, partie.bourse, partie.victoires, Partie.VICTOIRES_MAX, partie.defaites, Partie.DEFAITES_MAX]
	if partie.terminee():
		var gagne := partie.victoires >= Partie.VICTOIRES_MAX
		bouton_combat.text = ("Partie gagnée !" if gagne else "Partie perdue.") + " Nouvelle partie"
	else:
		bouton_combat.text = "Combattre (manche %d)" % partie.manche

func _affinite_totale() -> int:
	var total := 0
	for v in nid.affinites().values():
		total += v
	return total

func _decrire(cr: Dictionary) -> String:
	var aff := nid.affinites()
	var lignes := [
		"[b]%s[/b]   [color=#%s]%s[/color]" % [cr["nom"], Palette.TEXTE_DOUX.to_html(false), Data.FORMES[cr["forme"]]["passif"]],
		"Feu %d   Nuit %d" % [aff.get("feu", 0), aff.get("nuit", 0)],
		"PV %d   Attaque %.0f   Une attaque toutes les %.2f s   Vol de vie %d %%" % [
			cr["pv_max"], cr["attaque"], cr["intervalle"], roundi(cr["vol_de_vie"] * 100)],
	]
	for s in cr["sorts"]:
		var d := "[b]%s%s[/b] (toutes les %.1f s)" % ["Cavalier, " if s["cavalier"] else "", s["nom"], s["recharge"]]
		if s["esquive"]:
			d += " : esquive la prochaine attaque"
		else:
			d += " : %d x %.1f dégâts" % [s["coups"], s["degats"]]
		if s["perce"]:
			d += ", ignore l'esquive"
		if s["execution"]:
			d += ", double sous %d %% de PV" % roundi(Data.SEUIL_EXECUTION * 100)
		if s["brulure"]:
			d += ", brûle"
		if s["vol_de_vie"] > 0.0 and not s["esquive"]:
			d += ", vole %d %%" % roundi(s["vol_de_vie"] * 100)
		lignes.append(d)
	return "\n".join(lignes)

func _combattre() -> void:
	if partie.terminee():
		nouvelle_partie.emit()
	else:
		combattre.emit()

# --- elements d'interface --------------------------------------------------

static func dessiner_relique(ci: CanvasItem, rect: Rect2, id: String) -> void:
	var r: Dictionary = Data.RELIQUES[id]
	var couleurs: Dictionary = Palette.ELEMENTS[r["element"]]
	var police := ThemeDB.fallback_font
	ci.draw_rect(rect.grow(-3), couleurs["fond"])
	ci.draw_rect(rect.grow(-3), couleurs["vif"], false, 2.0)
	var milieu := rect.position.y + rect.size.y / 2
	ci.draw_string(police, Vector2(rect.position.x, milieu), r["nom"],
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Palette.TEXTE)
	ci.draw_string(police, Vector2(rect.position.x, milieu + 18), r["type"],
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, couleurs["clair"])

static func apercu(id: String) -> Control:
	var a := Apercu.new()
	a.id = id
	a.size = TUILE
	a.modulate.a = 0.85
	return a

class Apercu extends Control:
	var id := ""
	func _draw() -> void:
		NidScreen.dessiner_relique(self, Rect2(Vector2.ZERO, size), id)

class Offre extends Control:
	var ecran: NidScreen
	var index: int
	func _init(e: NidScreen, i: int) -> void:
		ecran = e
		index = i
		custom_minimum_size = NidScreen.TUILE + Vector2(0, 20)
	func _id() -> String:
		return ecran.partie.offres[index]
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, NidScreen.TUILE)
		if _id() == "":
			draw_rect(rect.grow(-3), Palette.CASE)
			draw_string(ThemeDB.fallback_font, Vector2(0, rect.size.y / 2 + 5), "Acheté",
				HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Palette.TEXTE_DOUX)
			return
		var abordable := ecran.partie.bourse >= Partie.prix(_id())
		modulate.a = 1.0 if abordable else 0.4
		NidScreen.dessiner_relique(self, rect, _id())
		draw_string(ThemeDB.fallback_font, Vector2(0, rect.size.y + 15), "%d or" % Partie.prix(_id()),
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color("#f2c94c") if abordable else Palette.TEXTE_DOUX)
	func _get_drag_data(_p: Vector2) -> Variant:
		if _id() == "" or ecran.partie.bourse < Partie.prix(_id()):
			return null
		set_drag_preview(NidScreen.apercu(_id()))
		return {"id": _id(), "offre": index}
	# Ramener une relique posee sur la boutique la revend.
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("depuis")
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.vendre(data["depuis"])

class Boutique extends VBoxContainer:
	var ecran: NidScreen
	func _init(e: NidScreen) -> void:
		ecran = e
		mouse_filter = Control.MOUSE_FILTER_PASS
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("depuis")
	func _drop_data(_p: Vector2, data: Variant) -> void:
		ecran.vendre(data["depuis"])

class CaseNid extends Control:
	var ecran: NidScreen
	var position_nid: Vector2i
	var survol := false
	func _init(e: NidScreen, c: Vector2i) -> void:
		ecran = e
		position_nid = c
		custom_minimum_size = NidScreen.CASE_TAILLE
		mouse_entered.connect(func(): survol = true; queue_redraw())
		mouse_exited.connect(func(): survol = false; queue_redraw())
	func _id():
		return ecran.nid.cases.get(position_nid)
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Palette.SURVOL if survol else Palette.CASE)
		draw_rect(rect, Palette.CASE_BORD, false, 1.0)
		if _id() != null:
			NidScreen.dessiner_relique(self, rect.grow(-4), _id())
	func _get_drag_data(_p: Vector2) -> Variant:
		if _id() == null:
			return null
		set_drag_preview(NidScreen.apercu(_id()))
		return {"id": _id(), "depuis": position_nid}
	func _can_drop_data(_p: Vector2, data: Variant) -> bool:
		if not data is Dictionary:
			return false
		if data.has("offre"):
			return ecran.partie.peut_acheter(data["offre"], position_nid)
		return data.has("depuis") and ecran.nid.accepte(position_nid, data["id"], data["depuis"])
	func _drop_data(_p: Vector2, data: Variant) -> void:
		if data.has("offre"):
			ecran.acheter(data["offre"], position_nid)
		else:
			ecran.deposer(position_nid, data["id"], data["depuis"])
	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
			ecran.vendre(position_nid)
