class_name CreatureVue
extends Control

# Monture dessinee a la main (formes simples) avec son cavalier encapuchonne.
# Elle grandit avec l'affinite totale et pulse quand le Nid change.

var forme := ""
var affinite := 0
var t := 0.0
var pulse := 1.0

func montrer(f: String, a: int) -> void:
	var change := f != forme or a != affinite
	forme = f
	affinite = a
	if change and is_inside_tree():
		pulse = 1.15
		create_tween().tween_property(self, "pulse", 1.0, 0.35).set_trans(Tween.TRANS_BACK)
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PANNEAU)
	var c: Dictionary = Palette.ELEMENTS[forme]
	var echelle := minf(0.75 + 0.04 * affinite, 1.25) * pulse
	var flotte := sin(t * 2.0) * 6.0 if forme != "" else 0.0
	var centre := size / 2 + Vector2(0, 45 + flotte)
	# ombre au sol, qui ne flotte pas
	draw_set_transform(size / 2 + Vector2(0, 130), 0.0, Vector2(echelle, echelle * 0.25))
	draw_circle(Vector2.ZERO, 80, Color(0, 0, 0, 0.35))
	draw_set_transform(centre, 0.0, Vector2(echelle, echelle))
	match forme:
		"feu":
			_phenix(c)
		"ombre":
			_chauve_souris(c)
		_:
			_informe(c)
	_cavalier(c)
	draw_set_transform(Vector2.ZERO)

func _phenix(c: Dictionary) -> void:
	var battement := sin(t * 6.0) * 12.0
	# queue de flammes
	for i in 3:
		var dy := (i - 1) * 16.0
		draw_colored_polygon(PackedVector2Array([Vector2(-50, dy - 8), Vector2(-130 - i * 10, dy + 10 + sin(t * 5 + i) * 8), Vector2(-50, dy + 12)]),
			[c["vif"], c["clair"], c["vif"]][i])
	# ailes
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -10), Vector2(-60, -90 - battement), Vector2(20, -20)]), c["vif"])
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -12), Vector2(10, -110 - battement), Vector2(40, -20)]), c["clair"])
	# corps et tete
	draw_circle(Vector2(0, 0), 52, c["vif"].darkened(0.15))
	draw_circle(Vector2(62, -40), 26, c["vif"].darkened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(84, -46), Vector2(110, -36), Vector2(84, -30)]), c["clair"])
	draw_circle(Vector2(70, -46), 5, Color.WHITE)
	# crete
	for i in 3:
		draw_colored_polygon(PackedVector2Array([Vector2(50 + i * 8, -60), Vector2(42 + i * 10, -90 - i * 4), Vector2(60 + i * 8, -62)]), c["vif"])
	# pattes
	draw_line(Vector2(-10, 48), Vector2(-14, 90), c["clair"], 5)
	draw_line(Vector2(20, 46), Vector2(24, 90), c["clair"], 5)

func _chauve_souris(c: Dictionary) -> void:
	var battement := sin(t * 8.0) * 18.0
	for cote in [-1, 1]:
		var ail := PackedVector2Array([
			Vector2(cote * 30, -20), Vector2(cote * 150, -70 - battement), Vector2(cote * 130, -10 - battement * 0.5),
			Vector2(cote * 100, 0), Vector2(cote * 80, 20 - battement * 0.3), Vector2(cote * 30, 20)])
		draw_colored_polygon(ail, c["fond"].lightened(0.15))
		draw_polyline(ail, c["vif"], 2.0)
	draw_circle(Vector2(0, 0), 50, c["fond"].lightened(0.3))
	draw_circle(Vector2(0, -56), 30, c["fond"].lightened(0.3))
	for cote in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([Vector2(cote * 8, -80), Vector2(cote * 26, -112), Vector2(cote * 28, -70)]), c["fond"].lightened(0.3))
		draw_circle(Vector2(cote * 11, -58), 5, c["clair"])
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -40), Vector2(-4, -30), Vector2(0, -40)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -40), Vector2(4, -30), Vector2(8, -40)]), Color.WHITE)

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
	var dos := Vector2(-38, -30) if forme == "ombre" else Vector2(-10, -60)
	var vent := sin(t * 3.0) * 6.0
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-6, -40), dos + Vector2(-50 + vent, 20), dos + Vector2(-20, 24), dos + Vector2(10, -30)]), c["vif"].darkened(0.1))
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-16, -36), dos + Vector2(16, -36), dos + Vector2(20, 14), dos + Vector2(-20, 14)]), c["vif"])
	draw_circle(dos + Vector2(0, -48), 18, c["vif"])
	draw_circle(dos + Vector2(4, -46), 12, Color("#14161b"))
	draw_circle(dos + Vector2(0, -47), 2.5, Color.WHITE)
	draw_circle(dos + Vector2(9, -47), 2.5, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-8, -64), dos + Vector2(0, -84), dos + Vector2(10, -64)]), c["vif"])
