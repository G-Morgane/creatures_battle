class_name Exemples
extends RefCounted

# Nids de demonstration, en attendant la boutique.

# Plume a cote du Charbon (brulure), Tison a cote de la Graine (Braise).
static func nid_feu() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "charbon")
	n.placer(Vector2i(1, 0), "plume_incandescente")
	n.placer(Vector2i(0, 1), "cendre")
	n.placer(Vector2i(1, 1), "graine_brasier")
	n.placer(Vector2i(2, 1), "tison")
	return n

static func nid_nuit() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "croc_noir")
	n.placer(Vector2i(1, 0), "croc_noir")
	n.placer(Vector2i(0, 1), "nuee")
	n.placer(Vector2i(1, 1), "lune_creuse")
	n.placer(Vector2i(2, 1), "voile")
	return n

static func nid_terre() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "pierre")
	n.placer(Vector2i(1, 0), "pierre")
	n.placer(Vector2i(0, 1), "ecaille")
	n.placer(Vector2i(1, 1), "rempart")
	n.placer(Vector2i(2, 1), "socle")
	return n

static func nid_vent() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "sabot")
	n.placer(Vector2i(1, 0), "sabot")
	n.placer(Vector2i(0, 1), "crin")
	n.placer(Vector2i(1, 1), "rafale")
	n.placer(Vector2i(2, 1), "girouette")
	return n

# Ortie a cote de l'Epine (epines), Amanite a cote de la Baie et de la Spore (poison).
static func nid_nature() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "epine_ronce")
	n.placer(Vector2i(1, 0), "ortie")
	n.placer(Vector2i(2, 0), "baie")
	n.placer(Vector2i(1, 1), "spore")
	n.placer(Vector2i(2, 1), "amanite")
	return n

# Galet (bouclier) a cote de la Fourrure ; Croc a cote du Flocon (givre).
static func nid_glace() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "flocon")
	n.placer(Vector2i(1, 0), "croc_blizzard")
	n.placer(Vector2i(0, 1), "eclat_givre")
	n.placer(Vector2i(1, 1), "galet")
	n.placer(Vector2i(2, 1), "fourrure")
	return n
