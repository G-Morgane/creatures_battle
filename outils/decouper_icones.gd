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
	"ruban":         ["chauvesouris_objets", 40, 80, 265, 232],
	"aiguille":      ["chauvesouris_objets", 295, 60, 225, 258],
	"sceau":         ["chauvesouris_objets", 555, 70, 200, 252],
	"poupee":        ["chauvesouris_objets", 105, 425, 240, 258],
	"sablier":       ["chauvesouris_objets", 410, 405, 200, 268],
	"peigne":        ["chauvesouris_objets", 690, 440, 315, 252],
	"masque":        ["chauvesouris_objets", 65, 780, 460, 258],
	"grimoire":      ["chauvesouris_objets", 570, 745, 370, 292],
	"pacte":         ["chauvesouris_objets", 140, 1110, 750, 345],
	"dague_minuit":  ["chauvesouris_armes", 80, 60, 400, 335],
	"faux_lunaire":  ["chauvesouris_armes", 520, 20, 470, 375],
	"lame_veuve":    ["chauvesouris_armes", 60, 475, 440, 390],
	"faux_festin":   ["chauvesouris_armes", 490, 480, 500, 410],
	"faux_nuit":     ["chauvesouris_armes", 35, 940, 965, 530],
	"serpe_ronces":  ["chapelet_serpe", 100, 30, 640, 860],
	"chapelet":      ["chapelet_serpe", 820, 40, 600, 850],
	"meche":         ["lion_objets", 35, 105, 220, 200],
	"huile":         ["lion_objets", 265, 95, 220, 205],
	"miroir":        ["lion_objets", 535, 75, 200, 225],
	"bande":         ["lion_objets", 760, 125, 245, 180],
	"encensoir":     ["lion_objets", 70, 395, 270, 272],
	"vasque":        ["lion_objets", 360, 455, 310, 212],
	"prisme":        ["lion_objets", 690, 400, 320, 277],
	"voile_aube":    ["lion_objets", 75, 745, 460, 292],
	"carillon":      ["lion_objets", 570, 740, 310, 247],
	"lanterne":      ["lion_objets", 290, 1070, 450, 372],
	"sceptre_aurore":["lion_arme", 130, 55, 390, 297],
	"hachette_matin":["lion_arme", 590, 90, 380, 257],
	"baton_rosee":   ["lion_arme", 70, 440, 470, 460],
	"hache_solaire": ["lion_arme", 480, 460, 520, 440],
	"sceptre_premier":["lion_arme", 55, 985, 930, 445],
	"battement":     ["papillon_objets", 20, 85, 285, 240],
	"poudre":        ["papillon_objets", 325, 75, 245, 252],
	"cocon":         ["papillon_objets", 595, 25, 165, 305],
	"pollen":        ["papillon_objets", 790, 95, 220, 237],
	"mue":           ["papillon_objets", 45, 440, 320, 232],
	"brume":         ["papillon_objets", 370, 420, 280, 262],
	"phalene":       ["papillon_objets", 660, 445, 345, 232],
	"chrysalide":    ["papillon_objets", 265, 720, 190, 312],
	"aile_lune":     ["papillon_objets", 505, 730, 445, 302],
	"inversion":     ["papillon_objets", 325, 1060, 400, 397],
	"arc_crepuscule":["papillon_armes", 35, 15, 520, 390],
	"flechettes":    ["papillon_armes", 605, 65, 375, 317],
	"glaive_brume":  ["papillon_armes", 45, 445, 570, 527],
	"arc_lunes":     ["papillon_armes", 585, 475, 410, 472],
	"lance_entre":   ["papillon_armes", 35, 1030, 970, 450],
	"fer":           ["cheval_objets", 40, 95, 200, 215],
	"ruban_criniere":["cheval_objets", 270, 85, 285, 227],
	"grelot":        ["cheval_objets", 585, 80, 180, 232],
	"duvet":         ["cheval_objets", 800, 75, 210, 237],
	"etrier":        ["cheval_objets", 40, 425, 250, 272],
	"manche":        ["cheval_objets", 310, 450, 360, 227],
	"eventail":      ["cheval_objets", 675, 410, 335, 272],
	"voile_cavale":  ["cheval_objets", 70, 815, 555, 257],
	"girouette_indocile": ["cheval_objets", 640, 755, 345, 307],
	"bride":         ["cheval_objets", 30, 1105, 965, 357],
	"dague_brise":   ["cheval_armes", 95, 75, 390, 308],
	"javelot_alizes":["cheval_armes", 535, 25, 460, 357],
	"sabre_rafale":  ["cheval_armes", 45, 520, 450, 405],
	"lance_bourrasque": ["cheval_armes", 520, 455, 480, 465],
	"rapiere":       ["cheval_armes", 35, 1045, 965, 425],
	"brique":        ["tortue_objets", 25, 85, 280, 202],
	"truelle":       ["tortue_objets", 307, 65, 228, 222],
	"cale":          ["tortue_objets", 542, 95, 228, 192],
	"fossile":       ["tortue_objets", 785, 80, 225, 207],
	"fil_plomb":     ["tortue_objets", 75, 385, 225, 267],
	"tuile":         ["tortue_objets", 330, 420, 345, 217],
	"sablier_ensable":["tortue_objets", 720, 380, 265, 272],
	"clef":          ["tortue_objets", 150, 750, 330, 247],
	"urne":          ["tortue_objets", 555, 715, 310, 282],
	"borne":         ["tortue_objets", 270, 1025, 520, 432],
	"hachette_schiste": ["tortue_armes", 105, 65, 400, 297],
	"baton_glaise":  ["tortue_armes", 550, 40, 425, 342],
	"baton_rempart": ["tortue_armes", 70, 465, 480, 462],
	"hache_fondations": ["tortue_armes", 470, 505, 525, 432],
	"baton_ages":    ["tortue_armes", 50, 1005, 950, 427],
}

# Objets de glace blancs et bleu pale, proches du fond creme : tolerance resserree,
# et pas de retrait du fond enferme (il confond le blanc peint avec le papier).
# [seuil dur, seuil doux, retirer les trous, (seuil des trous, facultatif)]
const TOLERANCE := {"objets_loup": [0.045, 0.09, false], "loup_armes": [0.045, 0.09, false],
	# Aube : ivoire, creme, peche, tout est proche du papier
	"lion_objets": [0.03, 0.06, false], "lion_arme": [0.03, 0.06, false],
	"papillon_objets": [0.05, 0.10, true, 0.05], "papillon_armes": [0.05, 0.10, true, 0.05],
	# Vent : ivoire et menthe pale
	"cheval_objets": [0.035, 0.07, false], "cheval_armes": [0.035, 0.07, false],
	"tortue_objets": [0.04, 0.08, false], "tortue_armes": [0.04, 0.08, false]}
const TOLERANCE_DEFAUT := [0.10, 0.22, true]
# Reglages propres a un objet (prioritaires sur ceux de sa planche).
const TOLERANCE_OBJET := {
	"galet": [0.025, 0.06, false],      # sa neige touche le bord de la zone
	"hachette": [0.045, 0.09, true],    # fond enferme entre manche et lame
	"cendre": [0.045, 0.09, false],     # cendres claires
	"fleur_cendres": [0.045, 0.09, false],  # petales creme
	"plume_incandescente": [0.06, 0.12, true],  # tuyau blanc
	# parties creme proches du papier : dents, parchemin, pages, crocs, lame d'os
	"peigne": [0.03, 0.07, false],
	"pacte": [0.025, 0.06, false],
	"grimoire": [0.03, 0.07, false],
	"masque": [0.04, 0.08, false],
	"faux_lunaire": [0.045, 0.09, true],
	"faux_nuit": [0.03, 0.07, true, 0.08],  # fond enferme entre ruban et manche, grain du papier
	"serpe_ronces": [0.05, 0.10, true],     # lame vert pale
	"chapelet": [0.04, 0.08, true, 0.06],   # croc creme, fond enferme dans l'anneau
	"cocon": [0.03, 0.06, false],           # soie creme
	"mue": [0.04, 0.08, false],             # peau lilas pale
	"etrier": [0.035, 0.07, true, 0.04],    # fond enferme dans l'etrier
	"bride": [0.035, 0.07, true, 0.04],     # fond enferme dans les boucles
	"ruban_criniere": [0.035, 0.07, true, 0.04],
	"duvet": [0.025, 0.05, false],          # aigrette creme
	"fil_plomb": [0.04, 0.08, true, 0.04],  # fond dans la boucle de corde
	"sablier_ensable": [0.04, 0.08, true, 0.04],  # fond entre les piliers
	"urne": [0.04, 0.08, true, 0.04],       # fond dans les anses
}

# Zones de la planche a effacer avant decoupe : morceaux d'un voisin qui deborde.
const MASQUES := {
	"pique": [Rect2i(450, 760, 175, 160)],
	"hache_glace": [Rect2i(535, 400, 95, 110)],
	"oeuf_brasier": [Rect2i(300, 1100, 50, 45)],
	"baton_brasier": [Rect2i(130, 440, 270, 60), Rect2i(478, 870, 45, 140)],
	"faux_cendres": [Rect2i(640, 998, 250, 30), Rect2i(478, 520, 30, 90)],
	"baton_premier": [Rect2i(340, 1400, 370, 90), Rect2i(130, 1030, 290, 50), Rect2i(610, 1030, 290, 50)],
	"pacte": [Rect2i(130, 1095, 240, 40)],
	"voile_aube": [Rect2i(60, 735, 250, 40)],
	"encensoir": [Rect2i(60, 370, 260, 35)],
	"baton_rosee": [Rect2i(478, 815, 70, 95)],
	"hache_solaire": [Rect2i(478, 440, 85, 115)],
	"lanterne": [Rect2i(270, 1090, 80, 45)],
	"sceptre_premier": [Rect2i(320, 1400, 390, 90)],
	"chrysalide": [Rect2i(250, 728, 60, 45)],
	"inversion": [Rect2i(315, 1080, 55, 45)],
	"lance_entre": [Rect2i(330, 1405, 380, 85)],
	"bride": [Rect2i(25, 1110, 340, 48)],
	"borne": [Rect2i(260, 1050, 85, 45)],
	"baton_rempart": [Rect2i(476, 840, 80, 90)],
	"hache_fondations": [Rect2i(468, 503, 85, 105)],
	"baton_ages": [Rect2i(340, 1400, 360, 80)],
	"eventail": [Rect2i(672, 540, 30, 140)],
	"dague_brise": [Rect2i(130, 380, 250, 10)],
	"sabre_rafale": [Rect2i(130, 915, 250, 15)],
	"rapiere": [Rect2i(320, 1400, 390, 85)],
	"glaive_brume": [Rect2i(150, 438, 280, 32), Rect2i(586, 700, 32, 280), Rect2i(130, 950, 300, 30)],
	"arc_lunes": [Rect2i(583, 470, 40, 80)],
	"faux_festin": [Rect2i(640, 862, 240, 40)],
	"faux_nuit": [Rect2i(340, 1400, 360, 80)],
}

# image de la bete (fond transparent) -> element
const MONTURES := {"cerf": "nature", "loup": "glace", "phenix": "feu", "chauvesouris": "nuit", "lion": "aube", "papillon": "crepuscule", "cheval": "vent", "tortue": "terre"}

# Poussieres : ilots opaques isoles plus petits que cette aire (en pixels, avant reduction).
const POUSSIERE_ICONE := 40
const POUSSIERE_MONTURE := 150
# Debris tenaces d'un voisin : nettoyage plus fort pour ces objets.
const POUSSIERE_OBJET := {"hache_solaire": 1500}

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
		_poussiere(img, POUSSIERE_OBJET.get(id, POUSSIERE_ICONE))
		img = img.get_region(img.get_used_rect())
		_reduire(img, TAILLE_ICONE)
		img.save_png("res://images/icones/%s.png" % id)
		icones.append(img)
	var betes := []
	for bete in MONTURES:
		var m := Image.load_from_file("res://images/%s.png" % bete)
		m.convert(Image.FORMAT_RGBA8)
		_poussiere(m, POUSSIERE_MONTURE)
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
		_trous(img, fond, vu, tol[3] if tol.size() > 3 else minf(SEUIL_TROU, dur))

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

# Retire les ilots opaques isoles (poussieres, debris d'un voisin, bouts de texte)
# plus petits que aire. Un pixel compte comme opaque au-dela de 5 % d'alpha.
func _poussiere(img: Image, aire: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var vu := PackedByteArray()
	vu.resize(w * h)
	for y0 in h:
		for x0 in w:
			if vu[y0 * w + x0] or img.get_pixel(x0, y0).a <= 0.05:
				continue
			var ilot: Array[Vector2i] = []
			var pile: Array[Vector2i] = [Vector2i(x0, y0)]
			while not pile.is_empty():
				var p: Vector2i = pile.pop_back()
				if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or vu[p.y * w + p.x]:
					continue
				if img.get_pixelv(p).a <= 0.05:
					continue
				vu[p.y * w + p.x] = 1
				ilot.append(p)
				for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					pile.append(p + o)
			if ilot.size() < aire:
				for p in ilot:
					img.set_pixelv(p, Color(0, 0, 0, 0))

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
