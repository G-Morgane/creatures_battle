class_name Progression
extends RefCounted

# Progression entre les runs : on remonte jusqu'au Reveur. Chaque run gagnee
# detruit d'abord son incarnation, puis ses ancrages un a un, avant de
# l'atteindre dans son reve. Ce qui est detruit reste perdu pour lui.
# Seul le nombre de runs gagnees est sauve ; les etapes s'en deduisent.

const INCARNATION := 1   # victoires pour detruire l'incarnation
const ANCRAGES := 2      # un ancrage par victoire ensuite
const REVE := 1          # victoires dans son reve pour le vaincre

# chemin de la sauvegarde ; les tests le remplacent
static var chemin := "user://progression.json"

static func charger() -> int:
	var f := FileAccess.open(chemin, FileAccess.READ)
	if f == null:
		return 0
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return 0
	var d: Variant = json.data
	if not d is Dictionary or not (d.get("victoires") is float or d.get("victoires") is int):
		return 0
	return maxi(int(d["victoires"]), 0)

static func enregistrer_victoire() -> int:
	var v := charger() + 1
	var f := FileAccess.open(chemin, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"victoires": v}))
	return v

# Compte la run une seule fois, et seulement si elle est gagnee.
static func compter_run(p: Partie) -> bool:
	if not p.gagnee or p.victoire_comptee:
		return false
	p.victoire_comptee = true
	enregistrer_victoire()
	return true

# Ancrages detruits pour v victoires.
static func ancrages(v: int) -> int:
	return clampi(v - INCARNATION, 0, ANCRAGES)

# {nom, texte} : ce qu'il reste a abattre apres v victoires (-1 : la sauvegarde).
static func etape(v := -1) -> Dictionary:
	if v < 0:
		v = charger()
	if v < INCARNATION:
		return {"nom": "incarnation", "texte": "Son incarnation garde le passage. La détruire ouvrira la voie vers ses ancrages."}
	if v < INCARNATION + ANCRAGES:
		return {"nom": "ancrages", "texte": "Ses ancrages le retiennent dans le monde. Chacun détruit reste perdu pour lui."}
	if v < INCARNATION + ANCRAGES + REVE:
		return {"nom": "reve", "texte": "Plus rien ne le retient. Il faut l'atteindre dans son rêve."}
	return {"nom": "vaincu", "texte": "Le Rêveur est vaincu. Les gardiens dorment en paix."}

# Une phrase courte sur l'etat du Reveur, pour l'ecran de depart.
static func etat(v := -1) -> String:
	if v < 0:
		v = charger()
	match etape(v)["nom"]:
		"incarnation":
			return "Incarnation intacte"
		"ancrages":
			return "Incarnation détruite, ancrages %d/%d" % [ancrages(v), ANCRAGES]
		"reve":
			return "Ancrages détruits, le rêve est ouvert"
	return "Le Rêveur est vaincu"

# Ce que la v-ieme victoire vient de detruire (fin de run).
static func recit(v: int) -> String:
	if v <= INCARNATION:
		return "L'incarnation du Rêveur est détruite."
	if v <= INCARNATION + ANCRAGES:
		return "Un ancrage du Rêveur est détruit (%d/%d)." % [ancrages(v), ANCRAGES]
	if v <= INCARNATION + ANCRAGES + REVE:
		return "Le Rêveur est vaincu dans son rêve."
	return "Le Rêveur ne revient pas."
