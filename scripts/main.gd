extends Node

# Prototype : deux Nids d'exemple eclosent et se battent, journal a l'ecran.

func _ready() -> void:
	var a := Exemples.nid_feu()
	var b := Exemples.nid_ombre()
	var combat := Combat.new(a.eclore(), b.eclore())
	combat.simuler()

	var texte := RichTextLabel.new()
	texte.set_anchors_preset(Control.PRESET_FULL_RECT)
	texte.offset_left = 32
	texte.offset_top = 32
	texte.bbcode_enabled = true
	texte.add_theme_font_size_override("normal_font_size", 18)
	texte.text = "%s\n\n%s\n\n[b]Combat[/b]\n%s" % [
		_decrire(a), _decrire(b), "\n".join(combat.journal)]
	add_child(texte)

func _decrire(n: Nid) -> String:
	var cr := n.eclore()
	var lignes := ["[b]%s[/b] (passif : %s)" % [cr["nom"], Data.FORMES[cr["forme"]]["passif"]]]
	for y in Data.NID_H:
		var ligne := []
		for x in Data.NID_L:
			var c := Vector2i(x, y)
			ligne.append(Data.RELIQUES[n.cases[c]]["nom"] if n.cases.has(c) else "·")
		lignes.append("   ".join(ligne))
	return "\n".join(lignes)
