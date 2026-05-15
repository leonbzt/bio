class_name MetaModifiers

static func is_unlocked(node_id: StringName) -> bool:
	var tree: Dictionary = GameState.meta_save.get("evolution_tree", {})
	return bool(tree.get(String(node_id), false))
