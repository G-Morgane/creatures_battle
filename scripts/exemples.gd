class_name Exemples
extends RefCounted

# Nids de demonstration, en attendant la boutique.

static func nid_feu() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "braise")
	n.placer(Vector2i(1, 0), "braise")
	n.placer(Vector2i(0, 1), "plume_cendre")
	n.placer(Vector2i(1, 1), "souffle_ardent")
	n.placer(Vector2i(2, 1), "foyer")
	return n

static func nid_ombre() -> Nid:
	var n := Nid.new()
	n.placer(Vector2i(0, 0), "croc_noir")
	n.placer(Vector2i(1, 0), "croc_noir")
	n.placer(Vector2i(0, 1), "nuee")
	n.placer(Vector2i(1, 1), "lune_creuse")
	n.placer(Vector2i(2, 1), "voile")
	return n
