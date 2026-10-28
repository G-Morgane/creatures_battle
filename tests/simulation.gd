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
		var par_relique := {}           # id dans le sac -> [combats, victoires]
		# element choisi -> {combats, degats faits, degats subis, duree, sources: source -> degats}
		var par_combat := {}
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
					var vus := {}
					for id in p.nid.cases.values():
						if vus.has(id):
							continue
						vus[id] = true
						var r: Array = par_relique.get(id, [0, 0])
						r[0] += 1
						r[1] += 1 if v == 0 else 0
						par_relique[id] = r
					var pc: Dictionary = par_combat.get(j.element, {"combats": 0, "faits": 0.0, "subis": 0.0, "duree": 0.0, "sources": {}})
					pc["combats"] += 1
					pc["duree"] += c.t
					for i in 2:
						for src in c.stats[i]:
							var d: float = c.stats[i][src]["degats"]
							pc["faits" if i == 0 else "subis"] += d
							if i == 0:
								pc["sources"][src] = pc["sources"].get(src, 0.0) + d
					par_combat[j.element] = pc
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
			_combats(par_combat)
			_reliques(par_relique)
	quit()

# Par element joue : degats faits et subis par combat, duree, et les trois
# sources qui font le plus de degats.
func _combats(par_combat: Dictionary) -> void:
	print("\nPar combat (moyennes) :")
	for e in par_combat:
		var pc: Dictionary = par_combat[e]
		var n: float = pc["combats"]
		var src: Array = pc["sources"].keys()
		src.sort_custom(func(a, b): return pc["sources"][a] > pc["sources"][b])
		var top := ", ".join(src.slice(0, 3).map(func(s): return "%s %d %%" % [s, roundi(100.0 * pc["sources"][s] / maxf(pc["faits"], 1.0))]))
		print("  %s : fait %d, subit %d, %.1f s  (%s)" % [e, roundi(pc["faits"] / n), roundi(pc["subis"] / n), pc["duree"] / n, top])

# Taux de victoire des combats ou la relique est dans le sac (au moins 30 combats).
func _reliques(par_relique: Dictionary) -> void:
	var ids := par_relique.keys().filter(func(id): return par_relique[id][0] >= 30)
	var taux := func(id): return float(par_relique[id][1]) / par_relique[id][0]
	ids.sort_custom(func(a, b): return taux.call(a) > taux.call(b))
	var f := func(id): return "%s %d %% (%d)" % [id, roundi(100.0 * taux.call(id)), par_relique[id][0]]
	print("\nReliques, meilleures : " + ", ".join(ids.slice(0, 8).map(f)))
	print("Reliques, pires : " + ", ".join(ids.slice(-8).map(f)))
	var absentes := Data.RELIQUES.keys().filter(func(id): return not par_relique.has(id) or par_relique[id][0] < 30)
	print("Reliques trop peu vues : " + ", ".join(absentes.map(func(id): return "%s (%d)" % [id, par_relique.get(id, [0])[0]])))
	var nouvelles := ["calice", "cadran", "mousse", "stalagmite", "trainee", "reflet", "terreau"]
	print("Nouvelles reliques : " + ", ".join(nouvelles.filter(func(id): return par_relique.has(id)).map(f)))
