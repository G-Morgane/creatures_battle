extends SceneTree

# Decoupe les planches d'objets (fond creme) en icones transparentes.
# Lancer : godot --headless --path . -s res://outils/decouper_icones.gd
# Entree : images/objets_cerf.png, images/armes_cerf.png, images/cerf.png
# Sortie : images/icones/<id>.png, images/montures/nature.png, images/controle.png

const TAILLE_ICONE := 160
const TAILLE_MONTURE := 520

# id -> [planche, x, y, largeur, hauteur], zones relevees a la main (images 1024 x 1536)
const ZONES := {
	"epine_ronce":   ["objets_cerf", 40, 55, 240, 265],
	"baie":          ["objets_cerf", 285, 55, 230, 265],
	"ortie":         ["objets_cerf", 530, 55, 250, 265],
	"spore":         ["objets_cerf", 780, 40, 210, 280],
	"liane":         ["objets_cerf", 35, 425, 330, 285],
	"amanite":       ["objets_cerf", 390, 410, 260, 300],
	"gousse":        ["objets_cerf", 690, 410, 310, 300],
	"belladone":     ["objets_cerf", 130, 820, 390, 265],
	"coeur_roncier": ["objets_cerf", 540, 790, 400, 290],
	"graine_jardin": ["objets_cerf", 320, 1115, 420, 335],
	"sarbacane":     ["armes_cerf", 40, 50, 548, 270],
	"dague_epine":   ["armes_cerf", 598, 55, 392, 265],
	"arc_saule":     ["armes_cerf", 35, 420, 510, 420],
	"fouet_ronces":  ["armes_cerf", 530, 455, 460, 385],
	"arc_jardin":    ["armes_cerf", 55, 920, 925, 460],
}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://images/icones")
	DirAccess.make_dir_recursive_absolute("res://images/montures")
	var planches := {}
	var icones := []
	for id in ZONES:
		var z: Array = ZONES[id]
		if not planches.has(z[0]):
			planches[z[0]] = Image.load_from_file("res://images/%s.png" % z[0])
		var img: Image = planches[z[0]].get_region(Rect2i(z[1], z[2], z[3], z[4]))
		img.convert(Image.FORMAT_RGBA8)
		_detourer(img, planches[z[0]].get_pixel(5, 5))
		img = img.get_region(img.get_used_rect())
		_reduire(img, TAILLE_ICONE)
		img.save_png("res://images/icones/%s.png" % id)
		icones.append(img)
	var cerf := Image.load_from_file("res://images/cerf.png")
	cerf = cerf.get_region(cerf.get_used_rect())
	_reduire(cerf, TAILLE_MONTURE)
	cerf.save_png("res://images/montures/nature.png")
	_controle(icones, cerf)
	print("icones : ", icones.size())
	quit()

# Fond creme -> transparent, avec un bord adouci pour eviter le liseré.
# Remplissage depuis les bords : le creme a l'interieur d'un objet (taches de
# l'amanite) reste opaque.
func _detourer(img: Image, fond: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var vu := PackedByteArray()
	vu.resize(w * h)
	var pile: Array[Vector2i] = []
	for x in w:
		pile.append(Vector2i(x, 0))
		pile.append(Vector2i(x, h - 1))
	for y in h:
		pile.append(Vector2i(0, y))
		pile.append(Vector2i(w - 1, y))
	while not pile.is_empty():
		var p: Vector2i = pile.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or vu[p.y * w + p.x]:
			continue
		vu[p.y * w + p.x] = 1
		var c := img.get_pixelv(p)
		var d := Vector3(c.r - fond.r, c.g - fond.g, c.b - fond.b).length()
		if d >= 0.22:
			continue
		c.a = 0.0 if d < 0.10 else (d - 0.10) / 0.12
		img.set_pixelv(p, c)
		if d < 0.10:
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				pile.append(p + o)
	_trous(img, fond, vu)

# Fond enferme dans un objet (interieur d'un arc) : grandes zones de la couleur
# exacte du fond. Les petites taches creme (amanite) sont gardees.
const SEUIL_TROU := 0.06
const AIRE_TROU := 150

func _trous(img: Image, fond: Color, vu: PackedByteArray) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y0 in h:
		for x0 in w:
			if vu[y0 * w + x0] or not _proche(img.get_pixel(x0, y0), fond, SEUIL_TROU):
				continue
			var zone: Array[Vector2i] = []
			var pile: Array[Vector2i] = [Vector2i(x0, y0)]
			while not pile.is_empty():
				var p: Vector2i = pile.pop_back()
				if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or vu[p.y * w + p.x]:
					continue
				if not _proche(img.get_pixelv(p), fond, SEUIL_TROU):
					continue
				vu[p.y * w + p.x] = 1
				zone.append(p)
				for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					pile.append(p + o)
			if zone.size() >= AIRE_TROU:
				for p in zone:
					var c := img.get_pixelv(p)
					c.a = 0.0
					img.set_pixelv(p, c)

func _proche(c: Color, fond: Color, seuil: float) -> bool:
	return Vector3(c.r - fond.r, c.g - fond.g, c.b - fond.b).length() < seuil

func _reduire(img: Image, maxi_cote: int) -> void:
	var k := float(maxi_cote) / maxf(img.get_width(), img.get_height())
	if k < 1.0:
		img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)

# Planche de controle sur fond sombre, pour verifier les decoupes a l'oeil.
func _controle(icones: Array, cerf: Image) -> void:
	var c := Image.create(5 * 180, 3 * 180 + 360, false, Image.FORMAT_RGBA8)
	c.fill(Color("#171a21"))
	for i in icones.size():
		var ic: Image = icones[i]
		c.blend_rect(ic, Rect2i(Vector2i.ZERO, ic.get_size()), Vector2i((i % 5) * 180 + 10, (i / 5) * 180 + 10))
	var m := cerf.duplicate()
	m.resize(cerf.get_width() * 340 / cerf.get_height(), 340)
	c.blend_rect(m, Rect2i(Vector2i.ZERO, m.get_size()), Vector2i(10, 3 * 180 + 10))
	c.save_png("res://images/controle.png")
