extends SceneTree

# Simule des parties entieres avec des joueurs automatiques.
# Lancer : godot --headless --path . -s res://tests/simulation.gd

const PARTIES := 300

func _initialize() -> void:
	for style in ["aleatoire", "simple"]:
		var repartition := []
		repartition.resize(Partie.VICTOIRES_MAX + 1)
		repartition.fill(0)
		var par_manche := {}   # manche -> [victoires, combats]
		var total := 0
		var par_element := {}   # element choisi -> [parties, victoires]
		for g in PARTIES:
			var p := Partie.new(g + 1)
			var j := JoueurAuto.new(style, g + 1)
			while not p.terminee():
				j.jouer_manche(p)
				var v := Combat.new(p.nid.eclore(), p.adversaire().eclore()).simuler()
				var m: Array = par_manche.get(p.manche, [0, 0])
				m[0] += 1 if v == 0 else 0
				m[1] += 1
				par_manche[p.manche] = m
				p.enregistrer(v)
			repartition[p.victoires] += 1
			total += p.victoires
			var pe: Array = par_element.get(j.element, [0, 0])
			pe[0] += 1
			pe[1] += p.victoires
			par_element[j.element] = pe
		print("\n## Joueur %s (%d parties)" % [style, PARTIES])
		print("Victoires moyennes : %.2f   Parties gagnées (7) : %d %%" % [
			float(total) / PARTIES, roundi(100.0 * repartition[Partie.VICTOIRES_MAX] / PARTIES)])
		var ligne := "Répartition des victoires : "
		for k in repartition.size():
			ligne += "%d:%d%%  " % [k, roundi(100.0 * repartition[k] / PARTIES)]
		print(ligne)
		ligne = "Taux de victoire par manche : "
		var manches := par_manche.keys()
		manches.sort()
		for m in manches:
			if par_manche[m][1] >= 20:
				ligne += "m%d:%d%%  " % [m, roundi(100.0 * par_manche[m][0] / par_manche[m][1])]
		print(ligne)
		print("Sans élimination (difficulté réelle) : " + _courbe(style))
		if style == "simple":
			ligne = "Victoires moyennes par élément : "
			for e in par_element:
				ligne += "%s %.1f (%d)  " % [e, float(par_element[e][1]) / par_element[e][0], par_element[e][0]]
			print(ligne)
	quit()

# Chaque partie joue 9 manches quoi qu'il arrive : pas de biais de survie.
func _courbe(style: String) -> String:
	var gagnes := {}
	for g in PARTIES:
		var p := Partie.new(g + 1)
		var j := JoueurAuto.new(style, g + 1)
		for m in range(1, 10):
			j.jouer_manche(p)
			var v := Combat.new(p.nid.eclore(), p.adversaire().eclore()).simuler()
			gagnes[m] = gagnes.get(m, 0) + (1 if v == 0 else 0)
			p.enregistrer(v)
	var ligne := ""
	for m in range(1, 10):
		ligne += "m%d:%d%%  " % [m, roundi(100.0 * gagnes[m] / PARTIES)]
	return ligne
