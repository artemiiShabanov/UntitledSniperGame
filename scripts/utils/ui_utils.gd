class_name UIUtils
extends RefCounted
## Static utility helpers shared across all UI scripts.
## Eliminates duplicated focus-chaining, child cleanup, asset loading, and button collection.


static func chain_focus(buttons: Array[Button]) -> void:
	## Wire vertical focus neighbors so keyboard/gamepad navigation wraps around.
	if buttons.size() < 2:
		return
	for i in range(buttons.size()):
		buttons[i].focus_neighbor_top = buttons[(i - 1) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()


static func clear_children(container: Node) -> void:
	## Queue-free all children of a container (used before rebuilding UI lists).
	for child in container.get_children():
		child.queue_free()


static func try_load_tex(path: String) -> Texture2D:
	## Safely load a texture, returning null if the file doesn't exist.
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func collect_buttons(node: Node, out: Array[Button]) -> void:
	## Recursively collect all visible Button nodes under `node`.
	if node is Button and node.visible:
		out.append(node)
	for child in node.get_children():
		collect_buttons(child, out)


static func find_all_recursive(root: Node) -> Array[Node]:
	## Return every node in the subtree (iterative, avoids stack overflow on deep trees).
	var result: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		result.append(node)
		for child in node.get_children():
			stack.append(child)
	return result
