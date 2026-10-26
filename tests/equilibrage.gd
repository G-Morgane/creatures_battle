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
	b["Ombre"] = Exemples.nid_ombre()
	b["Ombre + faux"] = _avec(Exemples.nid_ombre(), "faux_lunaire", Vector2i(2, 0))
	b["Ombre + lance"] = _avec(Exemples.nid_ombre(), "lance_guet", Vector2i(2, 0))
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
