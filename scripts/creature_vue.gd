class_name CreatureVue
extends Control

# Monture dessinee a la main (formes simples) avec son cavalier encapuchonne.
# Elle grandit avec l'affinite totale et pulse quand le Nid change.

var forme := ""
var affinite := 0
var arme = null   # id de relique ou null
# En arene : pas de panneau, la monture de droite regarde a gauche,
# et elan la pousse vers l'adversaire quand elle frappe.
var fond := true
var miroir := false
var elan := 0.0
var t := 0.0
var pulse := 1.0

func montrer(f: String, a: int, ar = null) -> void:
	var change: bool = f != forme or a != affinite or ar != arme
	forme = f
	affinite = a
	arme = ar
	if change and is_inside_tree():
		pulse = 1.15
		create_tween().tween_property(self, "pulse", 1.0, 0.35).set_trans(Tween.TRANS_BACK)
	queue_redraw()

# Position (dans le repere de la vue) d'ou partent les sorts.
func source(cavalier: bool) -> Vector2:
	var sens := -1.0 if miroir else 1.0
	var echelle := minf(0.75 + 0.04 * affinite, 1.25)
	var p := Vector2(20, -150) if cavalier else Vector2(70, -30)
	return size / 2 + Vector2(0, 45) + Vector2(p.x * sens, p.y) * echelle

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	if fond:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.PANNEAU)
	var c: Dictionary = Palette.ELEMENTS[forme]
	var echelle := minf(0.75 + 0.04 * affinite, 1.25) * pulse
	# seules les montures ailees flottent
	var flotte := sin(t * 2.0) * 6.0 if forme in ["feu", "nuit", "crepuscule"] else 0.0
	var sens := -1.0 if miroir else 1.0
	var centre := size / 2 + Vector2(elan * sens, 45 + flotte)
	# ombre au sol, qui ne flotte pas
	draw_set_transform(size / 2 + Vector2(0, 130), 0.0, Vector2(echelle, echelle * 0.25))
	draw_circle(Vector2.ZERO, 80, Color(0, 0, 0, 0.35))
	draw_set_transform(centre, 0.0, Vector2(echelle * sens, echelle))
	match forme:
		"feu":
			_sprite("feu")
		"nuit":
			_sprite("nuit")
		"terre":
			_tortue(c)
		"vent":
			_sprite("vent")
		"nature":
			_sprite("nature")
		"glace":
			_sprite("glace")
		"aube":
			_sprite("aube")
		"crepuscule":
			_sprite("crepuscule")
		_:
			_informe(c)
	_cavalier(c)
	draw_set_transform(Vector2.ZERO)

# Monture dessinee par un artiste : centree sur le meme repere que les formes.
const SPRITE_LARGEUR := 260.0

func _sprite(nom: String) -> void:
	var tex := Palette.image("res://images/montures/%s.png" % nom)
	if tex == null:
		_informe(Palette.ELEMENTS[forme])
		return
	var taille := Vector2(SPRITE_LARGEUR, SPRITE_LARGEUR * tex.get_height() / tex.get_width())
	draw_texture_rect(tex, Rect2(Vector2(-taille.x / 2, 95 - taille.y), taille), false)

func _tortue(c: Dictionary) -> void:
	var pas := sin(t * 2.0) * 4.0
	# pattes courtes et tete qui sort de la carapace
	for x in [-55, -20, 25, 55]:
		draw_rect(Rect2(x - 12, 30 + (pas if x < 0 else -pas) * 0.5, 24, 40), c["fond"].lightened(0.3))
	draw_circle(Vector2(95 + pas, 10), 24, c["fond"].lightened(0.3))
	draw_circle(Vector2(104 + pas, 4), 4, Color.WHITE)
	# carapace en dome, avec ses plaques
	var dome := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		dome.append(Vector2(cos(a) * 90, sin(a) * 70 + 40))
	draw_colored_polygon(dome, c["vif"].darkened(0.2))
	draw_polyline(dome, c["clair"], 3.0)
	for p in [Vector2(-40, 5), Vector2(0, -15), Vector2(40, 5), Vector2(-15, 25), Vector2(25, 25)]:
		var hexa := PackedVector2Array()
		for k in 7:
			hexa.append(p + Vector2(cos(TAU * k / 6.0), sin(TAU * k / 6.0)) * 16)
		draw_polyline(hexa, c["clair"].darkened(0.2), 2.0)
	draw_line(Vector2(-92, 40), Vector2(92, 40), c["clair"], 4.0)

func _informe(c: Dictionary) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var r := 55.0 + sin(a * 3.0 + t * 2.0) * 6.0
		pts.append(Vector2(cos(a), sin(a) * 0.8) * r)
	draw_colored_polygon(pts, c["fond"].lightened(0.2))
	draw_circle(Vector2(-14, -8), 5, c["clair"])
	draw_circle(Vector2(14, -8), 5, c["clair"])

# Cavalier encapuchonne : visage sombre, deux yeux, cape a la couleur de l'element.
func _cavalier(c: Dictionary) -> void:
	var dos := Vector2(-10, -60)
	match forme:
		"nuit":
			dos = Vector2(15, -10)
		"terre":
			dos = Vector2(-10, -78)
		"nature", "glace":
			dos = Vector2(-22, -38)
		"aube":
			dos = Vector2(-30, -40)
		"crepuscule":
			dos = Vector2(40, -40)
		"vent":
			dos = Vector2(-20, -45)
		"feu":
			dos = Vector2(20, -20)
	var vent := sin(t * 3.0) * 6.0
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-6, -40), dos + Vector2(-50 + vent, 20), dos + Vector2(-20, 24), dos + Vector2(10, -30)]), c["vif"].darkened(0.1))
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-16, -36), dos + Vector2(16, -36), dos + Vector2(20, 14), dos + Vector2(-20, 14)]), c["vif"])
	draw_circle(dos + Vector2(0, -48), 18, c["vif"])
	draw_circle(dos + Vector2(4, -46), 12, Color("#14161b"))
	draw_circle(dos + Vector2(0, -47), 2.5, Color.WHITE)
	draw_circle(dos + Vector2(9, -47), 2.5, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-8, -64), dos + Vector2(0, -84), dos + Vector2(10, -64)]), c["vif"])
	if arme != null:
		_arme(dos)

# L'arme suit la couleur de son propre element, pas celle de la monture.
func _arme(dos: Vector2) -> void:
	var c: Dictionary = Palette.ELEMENTS[Data.RELIQUES[arme]["element"]]
	var bois := Color("#7a5236")
	var main := dos + Vector2(18, -14)
	# arme dessinee par un artiste : son icone, tenue en main
	var tex := Palette.icone(arme)
	if tex != null and arme != "lance_guet":
		var cote := 90.0
		var k := cote / maxf(tex.get_width(), tex.get_height())
		var taille := tex.get_size() * k
		draw_texture_rect(tex, Rect2(main - taille / 2 + Vector2(10, -20), taille), false)
		return
	match arme:
		"baton_braise":
			draw_line(main + Vector2(0, 40), main + Vector2(0, -80), bois, 5)
			var f := sin(t * 9.0) * 3.0
			draw_colored_polygon(PackedVector2Array([main + Vector2(-10, -80), main + Vector2(f, -112), main + Vector2(10, -80)]), c["vif"])
			draw_circle(main + Vector2(0, -84), 7, c["clair"])
		"lance_guet":
			draw_line(main + Vector2(-60, 40), main + Vector2(70, -50), bois, 4)
			draw_colored_polygon(PackedVector2Array([main + Vector2(64, -58), main + Vector2(92, -66), main + Vector2(76, -42)]), c["clair"])
		"faux_lunaire":
			draw_line(main + Vector2(0, 40), main + Vector2(0, -85), bois, 4)
			var lame := PackedVector2Array()
			for p in [Vector2(0, -85), Vector2(-22, -100), Vector2(-56, -96), Vector2(-80, -72), Vector2(-52, -86), Vector2(-22, -90)]:
				lame.append(main + p)
			draw_colored_polygon(lame, c["clair"])
