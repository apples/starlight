class_name FieldZoneFlags
extends RefCounted

enum {
	OPPONENT_BACK = 1,
	OPPONENT_FRONT = 2,
	OWN_BACK = 4,
	OWN_FRONT = 8,
}

static func describe(zones: int) -> Array:
	var opp: int = 0b0011 & zones
	var own: int = 0b0011 & (zones >> 2)
	var tr_front := TranslationServer.tr("front")
	var tr_rear := TranslationServer.tr("rear")
	var row_names := ["<null zone>", tr_rear, tr_front, ""]
	var opp_row: String = row_names[opp]
	var own_row: String = row_names[own]
	
	if zones == 0b1111:
		return [{ row = "", control = "" }]
	elif opp == own:
		return [{ row = opp_row, control = "" }]
	else:
		var opp_obj := { row = opp_row, control = "an opponent controls" }
		var own_obj := { row = own_row, control = "you control" }
		if opp and own:
			return [opp_obj, own_obj]
		elif opp or own:
			return [opp_obj] if opp else [own_obj]
		else:
			return []
