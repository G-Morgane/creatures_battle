class_name Exemples
extends RefCounted

# Nids de demonstration, en attendant la boutique.

# Tison entre les deux Charbons et la Graine (brulure renforcee).
static func nid_feu() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "charbon")
	n.placer(Vector2i(1, 0), "tison")
	n.placer(Vector2i(2, 0), "charbon")
	n.placer(Vector2i(0, 1), "cendre")
	n.placer(Vector2i(1, 1), "graine_brasier")
	return n

# Poupee a cote du Sceau : il pose aussi une malediction manquante.
static func nid_nuit() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "aiguille")
	n.placer(Vector2i(1, 0), "sceau")
	n.placer(Vector2i(2, 0), "poupee")
	n.placer(Vector2i(0, 1), "sablier")
	n.placer(Vector2i(1, 1), "aiguille")
	return n

# Ortie a cote de la Spore (une dose de plus).
static func nid_nature() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "epine_ronce")
	n.placer(Vector2i(1, 0), "ortie")
	n.placer(Vector2i(2, 0), "spore")
	n.placer(Vector2i(1, 1), "baie")
	n.placer(Vector2i(2, 1), "epine_ronce")
	return n

# Croc a cote du Flocon et du Galet (givre renforce).
static func nid_glace() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "flocon")
	n.placer(Vector2i(1, 0), "croc_blizzard")
	n.placer(Vector2i(2, 0), "galet")
	n.placer(Vector2i(0, 1), "fourrure")
	n.placer(Vector2i(1, 1), "flocon")
	return n

# Huile entre deux Meches (soins renforces).
static func nid_aube() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "meche")
	n.placer(Vector2i(1, 0), "huile")
	n.placer(Vector2i(2, 0), "meche")
	n.placer(Vector2i(0, 1), "miroir")
	n.placer(Vector2i(1, 1), "bande")
	return n

# Pollen entre deux Battements (recharge plus rapide).
static func nid_crepuscule() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "battement")
	n.placer(Vector2i(1, 0), "pollen")
	n.placer(Vector2i(2, 0), "battement")
	n.placer(Vector2i(0, 1), "cocon")
	n.placer(Vector2i(1, 1), "poudre")
	return n

# Pelage roux touche par trois objets (+24 % de crit).
static func nid_automne() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "croc_renard")
	n.placer(Vector2i(1, 0), "pelage_roux")
	n.placer(Vector2i(2, 0), "feuille_morte")
	n.placer(Vector2i(1, 1), "bourrasque")
	n.placer(Vector2i(0, 1), "croc_renard")
	return n

# Broche de soleil a cote de l'Arc a plumes (degats renforces).
static func nid_jour() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "plume_ocelle")
	n.placer(Vector2i(1, 0), "broche_soleil")
	n.placer(Vector2i(2, 0), "arc_plumes")
	n.placer(Vector2i(0, 1), "ecu_dore")
	n.placer(Vector2i(1, 1), "roue")
	return n
