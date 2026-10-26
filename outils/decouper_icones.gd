extends SceneTree

# Decoupe les planches d'objets (fond creme) en icones transparentes.
# Lancer : godot --headless --path . -s res://outils/decouper_icones.gd
# Entree : planches images/objets_*.png, *armes*.png (fond creme), montures images/<bete>.png
# Sortie : images/icones/<id>.png, images/montures/<element>.png, images/controle.png

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
	"flocon":        ["objets_loup", 35, 65, 235, 262],
	"galet":         ["objets_loup", 290, 100, 240, 225],
	"eclat_givre":   ["objets_loup", 555, 55, 210, 272],
	"fourrure":      ["objets_loup", 775, 110, 240, 215],
	"croc_blizzard": ["objets_loup", 70, 415, 280, 270],
	"ecorce":        ["objets_loup", 355, 405, 330, 280],
	"cristal":       ["objets_loup", 720, 420, 275, 262],
	"coeur_banquise":["objets_loup", 130, 780, 340, 290],
	"rose_neiges":   ["objets_loup", 525, 745, 400, 325],
	"noyau_hiver":   ["objets_loup", 342, 1105, 370, 357],
	"javelot":       ["loup_armes", 60, 40, 560, 285],
	"hachette":      ["loup_armes", 600, 90, 345, 230],
	"pique":         ["loup_armes", 50, 400, 570, 510],
	"hache_glace":   ["loup_armes", 535, 435, 465, 465],
	"lance_hiver":   ["loup_armes", 40, 995, 975, 372],
	"charbon":       ["phenix_objets", 40, 95, 225, 215],
	"plume_incandescente": ["phenix_objets", 290, 45, 250, 265],
	"tison":         ["phenix_objets", 550, 95, 220, 215],
	"cendre":        ["phenix_objets", 770, 160, 240, 150],
	"graine_brasier":["phenix_objets", 100, 420, 215, 262],
	"obsidienne":    ["phenix_objets", 380, 400, 285, 282],
	"resine":        ["phenix_objets", 750, 415, 215, 265],
	"coeur_fournaise":["phenix_objets", 165, 785, 310, 262],
	"fleur_cendres": ["phenix_objets", 530, 740, 390, 308],
	"oeuf_brasier":  ["phenix_objets", 318, 1085, 405, 370],
	"baton_braise":  ["phenix_arme", 70, 15, 425, 420],
	"faux_tison":    ["phenix_arme", 545, 15, 440, 415],
	"baton_brasier": ["phenix_arme", 60, 455, 460, 548],
	"faux_cendres":  ["phenix_arme", 480, 525, 525, 495],
	"baton_premier": ["phenix_arme", 30, 1030, 965, 445],
}

# Objets de glace blancs et bleu pale, proches du fond creme : tolerance resserree,
# et pas de retrait du fond enferme (il confond le blanc peint avec le papier).
# [seuil dur, seuil doux, retirer les trous]
const TOLERANCE := {"objets_loup": [0.045, 0.09, false], "loup_armes": [0.045, 0.09, false]}
const TOLERANCE_DEFAUT := [0.10, 0.22, true]
# Reglages propres a un objet (prioritaires sur ceux de sa planche).
const TOLERANCE_OBJET := {
	"galet": [0.025, 0.06, false],      # sa neige touche le bord de la zone
	"hachette": [0.045, 0.09, true],    # fond enferme entre manche et lame
	"cendre": [0.045, 0.09, false],     # cendres claires
	"fleur_cendres": [0.045, 0.09, false],  # petales creme
	"plume_incandescente": [0.06, 0.12, true],  # tuyau blanc
}

# Zones de la planche a effacer avant decoupe : morceaux d'un voisin qui deborde.
const MASQUES := {
	"pique": [Rect2i(450, 760, 175, 160)],
	"hache_glace": [Rect2i(535, 400, 95, 110)],
	"oeuf_brasier": [Rect2i(300, 1100, 50, 45)],
	"baton_brasier": [Rect2i(130, 440, 270, 60), Rect2i(478, 870, 45, 140)],
	"faux_cendres": [Rect2i(640, 998, 250, 30), Rect2i(478, 520, 30, 90)],
	"baton_premier": [Rect2i(340, 1400, 370, 90), Rect2i(130, 1030, 290, 50), Rect2i(610, 1030, 290, 50)],
}

# image de la bete (fond transparent) -> element
const MONTURES := {"cerf": "nature", "loup": "glace", "phenix": "feu"}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://images/icones")
	DirAccess.make_dir_recursive_absolute("res://images/montures")
	var planches := {}
	var icones := []
	for id in ZONES:
		var z: Array = ZONES[id]
		if not planches.has(z[0]):
			planches[z[0]] = Image.load_from_file("res://images/%s.png" % z[0])
		var zone := Rect2i(z[1], z[2], z[3], z[4])
		var img: Image = planches[z[0]].get_region(zone)
		img.convert(Image.FORMAT_RGBA8)
		var fond: Color = planches[z[0]].get_pixel(5, 5)
		for m in MASQUES.get(id, []):
			img.fill_rect(Rect2i(m.position - zone.position, m.size), fond)
		_detourer(img, fond, TOLERANCE_OBJET.get(id, TOLERANCE.get(z[0], TOLERANCE_DEFAUT)))
		img = img.get_region(img.get_used_rect())
		_reduire(img, TAILLE_ICONE)
		img.save_png("res://images/icones/%s.png" % id)
		icones.append(img)
	var betes := []
	for bete in MONTURES:
		var m := Image.load_from_file("res://images/%s.png" % bete)
		m = m.get_region(m.get_used_rect())
		_reduire(m, TAILLE_MONTURE)
		m.save_png("res://images/montures/%s.png" % MONTURES[bete])
		betes.append(m)
	_controle(icones, betes)
	print("icones : ", icones.size())
	quit()

# Fond creme -> transparent, avec un bord adouci pour eviter le liseré.
# Remplissage depuis les bords : le creme a l'interieur d'un objet (taches de
# l'amanite) reste opaque.
func _detourer(img: Image, fond: Color, tol: Array) -> void:
	var dur: float = tol[0]
	var doux: float = tol[1]
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
		if d >= doux:
			continue
		c.a = 0.0 if d < dur else (d - dur) / (doux - dur)
		img.set_pixelv(p, c)
		if d < dur:
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				pile.append(p + o)
	if tol[2]:
		_trous(img, fond, vu, SEUIL_TROU)

# Fond enferme dans un objet (interieur d'un arc) : grandes zones de la couleur
# exacte du fond. Les petites taches creme (amanite) sont gardees.
const SEUIL_TROU := 0.06
const AIRE_TROU := 150

func _trous(img: Image, fond: Color, vu: PackedByteArray, seuil: float) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y0 in h:
		for x0 in w:
			if vu[y0 * w + x0] or not _proche(img.get_pixel(x0, y0), fond, seuil):
				continue
			var zone: Array[Vector2i] = []
			var pile: Array[Vector2i] = [Vector2i(x0, y0)]
			while not pile.is_empty():
				var p: Vector2i = pile.pop_back()
				if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or vu[p.y * w + p.x]:
					continue
				if not _proche(img.get_pixelv(p), fond, seuil):
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
func _controle(icones: Array, betes: Array) -> void:
	var lignes := ceili(icones.size() / 5.0)
	var c := Image.create(5 * 180, lignes * 180 + 360, false, Image.FORMAT_RGBA8)
	c.fill(Color("#171a21"))
	for i in icones.size():
		var ic: Image = icones[i]
		c.blend_rect(ic, Rect2i(Vector2i.ZERO, ic.get_size()), Vector2i((i % 5) * 180 + 10, (i / 5) * 180 + 10))
	var x := 10
	for bete in betes:
		var m: Image = bete.duplicate()
		m.resize(m.get_width() * 340 / m.get_height(), 340)
		c.blend_rect(m, Rect2i(Vector2i.ZERO, m.get_size()), Vector2i(x, lignes * 180 + 10))
		x += m.get_width() + 20
	c.save_png("res://images/controle.png")
