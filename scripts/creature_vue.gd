class_name CreatureVue
extends Control

# Monture dessinee a la main (formes simples) avec son cavalier encapuchonne.
# Elle grandit avec l'affinite totale et pulse quand le Nid change.

var forme := ""
var affinite := 0
var armes: Array = []   # ids des armes du cavalier (0, 1 ou 2)
var hybride := ""      # cle "a_b" quand la forme est un hybride
var elite := ""        # id d'elite : sa propre image, sans cavalier
var cavalier := "capuchon"  # images/cavaliers/<id>.png
# Bastion : eclat de l'oeil du temple (0 a 1) et phase du cycle.
var oeil := 0.0
var phase := ""
# En arene : pas de panneau, la monture de droite regarde a gauche,
# et elan la pousse vers l'adversaire quand elle frappe. Le cavalier, au sol,
# a son propre elan, pour ses coups d'arme.
var fond := true
var miroir := false
var elan := 0.0
var elan_cavalier := 0.0
# Taille d'affichage : 1 en arene, plus petit dans un panneau etroit.
var zoom := 1.0
# En arene : le cavalier se tient au sol devant sa monture, pas sur son dos.
var a_terre := false
const SOL_CAVALIER := Vector2(70, 95)   # ses pieds, dans le repere des formes
const TAILLE_A_TERRE := 0.85
var t := 0.0
var pulse := 1.0

# ar : liste d'armes (ou une seule arme, ou null).
func montrer(f: String, a: int, ar = [], h := "", el := "") -> void:
	elite = el
	var l: Array = ar if ar is Array else ([] if ar == null else [ar])
	var change: bool = f != forme or a != affinite or l != armes or h != hybride
	forme = f
	affinite = a
	armes = l
	hybride = h
	if change and is_inside_tree():
		pulse = 1.15
		create_tween().tween_property(self, "pulse", 1.0, 0.35).set_trans(Tween.TRANS_BACK)
	queue_redraw()

# Position (dans le repere de la vue) d'ou partent les sorts.
func source(cavalier: bool) -> Vector2:
	var sens := -1.0 if miroir else 1.0
	var echelle := minf(0.75 + 0.04 * affinite, 1.25) * zoom
	var p := Vector2(20, -150) if cavalier else Vector2(70, -30)
	if cavalier and a_terre:
		p = SOL_CAVALIER + Vector2(0, -50 * TAILLE_A_TERRE)
	var vol := 0.0 if cavalier and a_terre else _vol()
	return size / 2 + Vector2(0, (45 - vol) * zoom) + Vector2(p.x * sens, p.y) * echelle

# Au sol (a_terre), le phenix, la chauve-souris et le papillon volent au-dessus de leur ombre.
const VOL := {"feu": 40.0, "nuit": 50.0, "crepuscule": 70.0}
# Elites ailees, idem.
const VOL_ELITE := {"phalene": 60.0}

func _vol() -> float:
	if not a_terre or hybride != "":
		return 0.0
	if elite != "":
		return VOL_ELITE.get(elite, 0.0)
	return VOL.get(forme, 0.0)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	if fond:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.PANNEAU)
	var c: Dictionary = Palette.ELEMENTS[forme]
	# hybride sans dynastie dominante : la cape prend la couleur du premier element
	if forme == "" and hybride != "":
		c = Palette.ELEMENTS[hybride.split("_")[0]]
	var echelle := minf(0.75 + 0.04 * affinite, 1.25) * pulse * zoom
	# seules les montures ailees flottent
	var flotte := sin(t * 2.0) * 6.0 if forme in ["feu", "nuit", "crepuscule"] else 0.0
	var sens := -1.0 if miroir else 1.0
	var centre := size / 2 + Vector2(elan * sens, (45 + flotte - _vol()) * zoom)
	# ombre au sol, qui ne flotte pas
	draw_set_transform(size / 2 + Vector2(0, 130 * zoom), 0.0, Vector2(echelle, echelle * 0.25))
	draw_circle(Vector2.ZERO, 80, Color(0, 0, 0, 0.35))
	draw_set_transform(centre, 0.0, Vector2(echelle * sens, echelle))
	# une elite : la bete seule, plus grande
	if elite != "":
		draw_set_transform(centre, 0.0, Vector2(echelle * sens * 1.2, echelle * 1.2))
		# ouverture : la possession teinte la bete de violet
		if phase == "ouverture":
			var tex := Palette.image("res://images/montures/ennemis/%s.png" % elite)
			if tex != null:
				var taille := Vector2(SPRITE_LARGEUR, SPRITE_LARGEUR * tex.get_height() / tex.get_width())
				draw_texture_rect(tex, Rect2(Vector2(-taille.x / 2, 95 - taille.y), taille), false, Color(0.88, 0.75, 1.0))
		else:
			_sprite("ennemis/" + elite)
		if elite == "bastion":
			_oeil()
		elif elite == "voix":
			_yeux_voix()
		draw_set_transform(Vector2.ZERO)
		return
	# deux dynasties ou plus : l'hybride des deux premieres
	if hybride != "":
		_sprite("hybrides/" + hybride)
		_cavalier(c)
		draw_set_transform(Vector2.ZERO)
		return
	match forme:
		"feu":
			_sprite("feu")
		"nuit":
			_sprite("nuit")
		"nature":
			_sprite("nature")
		"glace":
			_sprite("glace")
		"aube":
			_sprite("aube")
		"crepuscule":
			_sprite("crepuscule")
		"automne":
			_sprite("automne")
		"jour":
			_sprite("jour")
		_:
			_informe(c)
	_cavalier(c)
	draw_set_transform(Vector2.ZERO)

# Monture dessinee par un artiste : centree sur le meme repere que les formes.
const SPRITE_LARGEUR := 260.0
# En arene, le phenix (fin et ajoure) est elargi pour peser autant que les autres.
const LARGEUR_FORME := {"feu": 320.0}

func _sprite(nom: String) -> void:
	var tex := Palette.image("res://images/montures/%s.png" % nom)
	if tex == null:
		_informe(Palette.ELEMENTS[forme])
		return
	# en arene seulement : au Nid, le cavalier est assis sur le dos regle a la main
	var largeur: float = LARGEUR_FORME.get(nom, SPRITE_LARGEUR) if a_terre else SPRITE_LARGEUR
	var taille := Vector2(largeur, largeur * tex.get_height() / tex.get_width())
	draw_texture_rect(tex, Rect2(Vector2(-taille.x / 2, 95 - taille.y), taille), false)

# L'oeil du temple (peint sur l'image) : un halo qui grandit avec le rempart,
# violet et bien plus fort quand la porte s'ouvre.
const OEIL_BASTION := Vector2(6, -50)

func _oeil() -> void:
	var ouvert := phase == "ouverture"
	var force := oeil * (1.6 if ouvert else 1.0)
	var c := Color(0.75, 0.25, 1.0) if ouvert else Color(1.0, 0.25, 0.25)
	for k in 4:
		draw_circle(OEIL_BASTION, 6.0 + (k + 1) * 7.0 * (0.4 + force), Color(c, 0.12 * force + 0.04))
	if ouvert:
		draw_circle(OEIL_BASTION, 7.0, Color(1, 0.9, 1, 0.6))

# Les yeux peints sur les bras de la Voix, en fraction de l'image retournee : ceux qui
# sont ouverts rougeoient, les autres sont clos d'une paupiere sombre.
const YEUX_VOIX := [Vector2(0.769, 0.170), Vector2(0.620, 0.438), Vector2(0.793, 0.569), Vector2(0.817, 0.740), Vector2(0.206, 0.285), Vector2(0.120, 0.599), Vector2(0.337, 0.726), Vector2(0.749, 0.323)]

func _yeux_voix() -> void:
	var tex := Palette.image("res://images/montures/ennemis/voix.png")
	if tex == null:
		return
	var taille := Vector2(SPRITE_LARGEUR, SPRITE_LARGEUR * tex.get_height() / tex.get_width())
	var origine := Vector2(-taille.x / 2, 95 - taille.y)
	var ouverts := roundi(oeil * YEUX_VOIX.size())
	var maree := phase == "communion"
	for k in YEUX_VOIX.size():
		var p: Vector2 = origine + YEUX_VOIX[k] * taille
		if k < ouverts:
			var c := Color(1.0, 0.2, 0.2, 0.55 if maree else 0.3)
			draw_circle(p, 9.0 if maree else 6.0, c)
		else:
			draw_colored_polygon(_paupiere(p), Color("#2b4f55"))

func _paupiere(p: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 12:
		var a := TAU * k / 12.0
		pts.append(p + Vector2(cos(a) * 7.0, sin(a) * 4.5))
	return pts

# Place du cavalier sur un sprite sans reglage a la main : le haut du dos,
# releve dans l'image (premier pixel opaque d'une colonne un peu a gauche
# du centre), dans le repere des formes. Calcule une fois par image.
static var _dos_cache := {}

func _dos_auto(nom: String) -> Vector2:
	if _dos_cache.has(nom):
		return _dos_cache[nom]
	var dos := Vector2(-10, -40)
	var tex := Palette.image("res://images/montures/%s.png" % nom)
	if tex != null:
		var img := tex.get_image()
		var x := int(img.get_width() * 0.42)
		for y in img.get_height():
			if img.get_pixel(x, y).a > 0.5:
				var taille := Vector2(SPRITE_LARGEUR, SPRITE_LARGEUR * tex.get_height() / tex.get_width())
				var k := SPRITE_LARGEUR / tex.get_width()
				# meme repere que _sprite : image centree, pieds a y = 95
				dos = Vector2(-taille.x / 2 + x * k, 95 - taille.y + y * k + 10)
				# ailes ou queue dressees : on ne s'assoit jamais plus haut qu'aux
				# trois cinquiemes de la hauteur
				dos.y = maxf(dos.y, 95 - taille.y * 0.6)
				break
	_dos_cache[nom] = dos
	return dos

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
	if hybride != "":
		dos = _dos_auto("hybrides/" + hybride)
	match "" if hybride != "" else forme:
		"nuit":
			dos = Vector2(15, -10)
		"nature":
			dos = Vector2(-22, -38)
		"glace":
			dos = Vector2(-25, -30)
		"aube":
			dos = Vector2(-30, -40)
		"crepuscule":
			dos = Vector2(40, -40)
		"jour":
			dos = Vector2(25, -12)
		"feu":
			dos = Vector2(20, -20)
		"automne":
			dos = Vector2(0, -5)
	# au sol : ni flottement ni pulsation de la monture
	if a_terre:
		var sens := -1.0 if miroir else 1.0
		var echelle := minf(0.75 + 0.04 * affinite, 1.25) * zoom
		# repere pose sur ses pieds, devant la monture. Les images regardent a
		# droite : telles quelles cote allie, en miroir cote ennemi.
		var pieds := size / 2 + Vector2(elan_cavalier * sens, 45 * zoom) + Vector2(SOL_CAVALIER.x * sens, SOL_CAVALIER.y) * echelle
		var k := echelle * TAILLE_A_TERRE
		draw_set_transform(pieds, 0.0, Vector2(k * sens, k))
		dos = Vector2(0, -22)
	# la seconde arme est dans l'autre main, derriere le cavalier
	if armes.size() > 1:
		_arme(dos, armes[1], Vector2(-26, 6))
	# le cavalier peint, assis sur le dos ; a defaut, la silhouette dessinee
	var peint := Palette.image("res://images/cavaliers/%s.png" % cavalier)
	if peint != null:
		var h := 96.0
		var taille := Vector2(h * peint.get_width() / peint.get_height(), h)
		var balance := 0.0 if a_terre else sin(t * 2.4) * 2.0
		draw_texture_rect(peint, Rect2(dos + Vector2(-taille.x / 2, 22 - taille.y + balance), taille), false)
		if not armes.is_empty():
			_arme(dos, armes[0], Vector2(18, -14))
		return
	var vent := sin(t * 3.0) * 6.0
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-6, -40), dos + Vector2(-50 + vent, 20), dos + Vector2(-20, 24), dos + Vector2(10, -30)]), c["vif"].darkened(0.1))
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-16, -36), dos + Vector2(16, -36), dos + Vector2(20, 14), dos + Vector2(-20, 14)]), c["vif"])
	draw_circle(dos + Vector2(0, -48), 18, c["vif"])
	draw_circle(dos + Vector2(4, -46), 12, Color("#14161b"))
	draw_circle(dos + Vector2(0, -47), 2.5, Color.WHITE)
	draw_circle(dos + Vector2(9, -47), 2.5, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([dos + Vector2(-8, -64), dos + Vector2(0, -84), dos + Vector2(10, -64)]), c["vif"])
	if not armes.is_empty():
		_arme(dos, armes[0], Vector2(18, -14))

# L'arme suit la couleur de son propre element, pas celle de la monture.
# main : position de la main qui la tient, depuis le dos du cavalier.
func _arme(dos: Vector2, arme: String, main_dos: Vector2) -> void:
	var c: Dictionary = Palette.ELEMENTS[Data.RELIQUES[arme]["element"]]
	var bois := Color("#7a5236")
	var main := dos + main_dos
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
