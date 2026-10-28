extends SceneTree

# Tableau des matchups : duree et vainqueur de chaque combat entre builds types.
# Lancer : godot --headless --path . -s res://tests/equilibrage.gd

const CIBLE_MIN := 15.0
const CIBLE_MAX := 25.0

func _builds() -> Dictionary:
	var b := {}
	b["Feu"] = Exemples.nid_feu()
	b["Feu + bâton"] = _avec(Exemples.nid_feu(), "baton_braise", Vector2i(2, 0))
	b["Feu + lance"] = _avec(Exemples.nid_feu(), "lance_guet", Vector2i(2, 0))
	b["Nuit"] = Exemples.nid_nuit()
	b["Nuit + faux"] = _avec(Exemples.nid_nuit(), "faux_nuit", Vector2i(2, 0))
	b["Nuit + lance"] = _avec(Exemples.nid_nuit(), "lance_guet", Vector2i(2, 0))
	b["Nature"] = Exemples.nid_nature()
	b["Nature + sarbacane"] = _avec(Exemples.nid_nature(), "sarbacane", Vector2i(3, 0))
	b["Nature + arc"] = _avec(Exemples.nid_nature(), "arc_saule", Vector2i(3, 0))
	b["Glace"] = Exemples.nid_glace()
	b["Glace + javelot"] = _avec(Exemples.nid_glace(), "javelot", Vector2i(3, 0))
	b["Glace + hachette"] = _avec(Exemples.nid_glace(), "hachette", Vector2i(3, 0))
	b["Aube"] = Exemples.nid_aube()
	b["Aube + sceptre"] = _avec(Exemples.nid_aube(), "sceptre_aurore", Vector2i(3, 0))
	b["Aube + hachette"] = _avec(Exemples.nid_aube(), "hachette_matin", Vector2i(3, 0))
	b["Crépuscule"] = Exemples.nid_crepuscule()
	b["Crépuscule + arc"] = _avec(Exemples.nid_crepuscule(), "arc_crepuscule", Vector2i(3, 0))
	b["Crépuscule + fléchettes"] = _avec(Exemples.nid_crepuscule(), "flechettes", Vector2i(3, 0))
	return b

func _avec(n: Nid, id: String, c: Vector2i) -> Nid:
	n.placer(c, id)
	return n

func _initialize() -> void:
	var b := _builds()
	var noms := b.keys()
	var durees := []
	var victoires := {}
	print("| Build A | Build B | Durée | Vainqueur |")
	print("|---|---|---|---|")
	for i in noms.size():
		for j in range(i + 1, noms.size()):
			var c := Combat.new(b[noms[i]].eclore(), b[noms[j]].eclore())
			var v := c.simuler()
			var gagnant: String = "Égalité" if v == -1 else [noms[i], noms[j]][v]
			victoires[gagnant] = victoires.get(gagnant, 0) + 1
			var hors := c.t < CIBLE_MIN - 0.01 or c.t > CIBLE_MAX + 0.01
			print("| %s | %s | %.1f s%s | %s |" % [noms[i], noms[j], c.t, " ⚠" if hors else "", gagnant])
			durees.append(c.t)
	durees.sort()
	print("\nDurée min %.1f s, médiane %.1f s, max %.1f s" % [durees[0], durees[durees.size() / 2], durees[-1]])
	print("Victoires : ", victoires)
	quit()
