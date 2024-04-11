class_name Queueable
extends Resource



var node: Node
var parent: Node
var parent_visible_in_tree := false
var queued := false
var method: Callable



func _init(_node: Node) -> void:
	node = _node
	if not node.is_node_ready():
		await node.ready
	parent = node.get_parent()
	if not parent.is_node_ready():
		await parent.ready
	node.visibility_changed.connect(_on_visibility_changed)
	parent.visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _on_visibility_changed():
	parent_visible_in_tree = parent.is_visible_in_tree()
	if parent_visible_in_tree and queued:
		queued = false
		method.call()


func call_method() -> void:
	if queued:
		return
	if not parent_visible_in_tree or not node.visible:
		queued = true
		return
	method.call_deferred()
