class_name DefaiteScreen
extends Control

# Run perdue (Ferveur a 0) : une grande banniere a la place du retour au Nid,
# puis une nouvelle partie.

signal nouvelle_partie

var partie: Partie

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fond := TextureRect.new()
	fond.texture = Palette.image("res://images/fond_map.png")
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.modulate = Color(0.45, 0.4, 0.4)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)

	# la banniere : une bande sombre sur toute la largeur
	var bande := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FOND, 0.9)
	style.border_color = Color("#8c2a1e")
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.set_content_margin_all(36)
	bande.add_theme_stylebox_override("panel", style)
	bande.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	bande.anchor_left = 0.0
	bande.anchor_right = 1.0
	bande.offset_left = 0
	bande.offset_right = 0
	bande.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(bande)
	var pile := VBoxContainer.new()
	pile.add_theme_constant_override("separation", 18)
	pile.alignment = BoxContainer.ALIGNMENT_CENTER
	bande.add_child(pile)

	var titre := Label.new()
	titre.text = "Perdu"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 120)
	Palette.titre(titre)
	titre.add_theme_color_override("font_color", Color("#d0442e"))
	titre.add_theme_color_override("font_outline_color", Color.BLACK)
	titre.add_theme_constant_override("outline_size", 12)
	pile.add_child(titre)

	var detail := Label.new()
	detail.text = "La Ferveur s'est éteinte. Acte %d, %d victoire%s." % [partie.acte + 1, partie.victoires, "s" if partie.victoires > 1 else ""]
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 22)
	detail.add_theme_color_override("font_color", Palette.TEXTE)
	pile.add_child(detail)

	var bouton := Button.new()
	bouton.text = "Nouvelle partie"
	bouton.add_theme_font_size_override("font_size", 22)
	bouton.custom_minimum_size = Vector2(260, 52)
	bouton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bouton.pressed.connect(func(): nouvelle_partie.emit())
	pile.add_child(bouton)

	# la banniere apparait
	bande.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(bande, "modulate:a", 1.0, 0.5)
