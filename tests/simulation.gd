extends SceneTree

# Simule des runs entieres avec des joueurs automatiques : carte, boutique,
# rencontres, combats contre le fantome.
# Lancer : godot --headless --path . -s res://tests/simulation.gd
# Plus de runs (plus long) :
#   godot --headless --path . -s res://tests/simulation.gd -- --runs=300

var RUNS := 100

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			RUNS = int(arg.get_slice("=", 1))
	for style in ["aleatoire", "simple"]:
		var gagnees := 0
		var noeuds := 0
		var actes := [0, 0, 0]          # runs arrivees a chaque acte
		var par_type := {}              # type -> [victoires, combats]
		var par_element := {}           # element choisi -> [runs, gagnees]
		for g in RUNS:
			var p := Partie.new(g + 1)
			# un cavalier a tour de role, comme les adversaires
			p.choisir_cavalier(Data.CAVALIERS.keys()[g % Data.CAVALIERS.size()])
			var j := JoueurAuto.new(style, g + 1)
			while not p.terminee():
				j.jouer_manche(p)
				p.entrer(j.choisir_noeud(p))
				var type: String = p.noeud()["type"]
				noeuds += 1
				if p.combat():
					var c := Combat.new(p.creature_joueur(), p.creature_adverse())
					var v := c.simuler()
					var m: Array = par_type.get(type, [0, 0])
					m[0] += 1 if v == 0 else 0
					m[1] += 1
					par_type[type] = m
					p.conclure_combat(v, c.cotes[1]["pv"] / c.cotes[1]["cr"]["pv_max"])
				elif type == "rencontre":
					p.choisir(j.choisir_rencontre(p))
				else:
					p.conclure()
			for a in p.acte + 1:
				actes[a] += 1
			gagnees += 1 if p.gagnee else 0
			var pe: Array = par_element.get(j.element, [0, 0])
			pe[0] += 1
			pe[1] += 1 if p.gagnee else 0
			par_element[j.element] = pe
		print("\n## Joueur %s (%d runs)" % [style, RUNS])
		print("Runs gagnées : %d %%   Noeuds par run : %.1f" % [roundi(100.0 * gagnees / RUNS), float(noeuds) / RUNS])
		print("Runs arrivées à l'acte 2 : %d %%, à l'acte 3 : %d %%" % [
			roundi(100.0 * actes[1] / RUNS), roundi(100.0 * actes[2] / RUNS)])
		var ligne := "Taux de victoire par type : "
		for t in par_type:
			ligne += "%s %d %% (%d)  " % [t, roundi(100.0 * par_type[t][0] / par_type[t][1]), par_type[t][1]]
		print(ligne)
		if style == "simple":
			ligne = "Runs gagnées par élément : "
			for e in par_element:
				ligne += "%s %d %% (%d)  " % [e, roundi(100.0 * par_element[e][1] / par_element[e][0]), par_element[e][0]]
			print(ligne)
	quit()
