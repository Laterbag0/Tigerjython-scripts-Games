extends Control
# Seal Clicker - attach this to a root Control node.
# Put your image at res://seal.png

const SAVE_PATH := "user://seal_clicker.cfg"
const COST_GROWTH := 1.15

# type "click" = adds to points per click, "auto" = adds points per second
var upgrades := [
	{"name": "Gentle Pat",            "desc": "+1 per click",   "type": "click", "value": 1.0,   "base_cost": 20.0,    "owned": 0},
	{"name": "Fish Snack",            "desc": "+1 per second",  "type": "auto",  "value": 1.0,   "base_cost": 50.0,    "owned": 0},
	{"name": "Seal Pup Helper",       "desc": "+5 per second",  "type": "auto",  "value": 5.0,   "base_cost": 300.0,   "owned": 0},
	{"name": "Fish Bucket",           "desc": "+10 per click",  "type": "click", "value": 10.0,  "base_cost": 1000.0,  "owned": 0},
	{"name": "Ice Floe Farm",         "desc": "+25 per second", "type": "auto",  "value": 25.0,  "base_cost": 2500.0,  "owned": 0},
	{"name": "Whipped Cream Factory", "desc": "+120 per second","type": "auto",  "value": 120.0, "base_cost": 12000.0, "owned": 0},
]

var points: float = 0.0
var click_power: float = 1.0
var per_second: float = 0.0

var count_label: Label
var cps_label: Label
var seal_button: TextureButton
var upgrade_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_load_game()
	_recalculate()

	var timer := Timer.new()
	timer.wait_time = 10.0
	timer.autostart = true
	timer.timeout.connect(_save_game)
	add_child(timer)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1b2a41")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	margin.add_child(hbox)

	# ---- Left side: counter + seal ----
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.4
	hbox.add_child(left)

	count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 44)
	left.add_child(count_label)

	cps_label = Label.new()
	cps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cps_label.add_theme_font_size_override("font_size", 20)
	left.add_child(cps_label)

	seal_button = TextureButton.new()
	if ResourceLoader.exists("res://seal.jpg"):
		seal_button.texture_normal = load("res://seal.jpg")
	else:
		push_warning("Put your image at res://seal.png")
	seal_button.ignore_texture_size = true
	seal_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	seal_button.custom_minimum_size = Vector2(250, 250)
	seal_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	seal_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seal_button.pressed.connect(_on_seal_pressed)
	seal_button.resized.connect(func(): seal_button.pivot_offset = seal_button.size / 2.0)
	left.add_child(seal_button)

	# ---- Right side: shop ----
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)

	var title := Label.new()
	title.text = "Boosts"
	title.add_theme_font_size_override("font_size", 30)
	right.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)

	var shop := VBoxContainer.new()
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop.add_theme_constant_override("separation", 8)
	scroll.add_child(shop)

	for i in upgrades.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 70)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_buy.bind(i))
		shop.add_child(b)
		upgrade_buttons.append(b)


func _process(delta: float) -> void:
	points += per_second * delta
	_update_ui()


func _update_ui() -> void:
	count_label.text = "%s clicks" % _fmt(points)
	cps_label.text = "per click: %s   |   per second: %s" % [_fmt(click_power), _fmt(per_second)]
	for i in upgrades.size():
		var u: Dictionary = upgrades[i]
		var cost := _cost(u)
		var b := upgrade_buttons[i]
		b.text = "%s  (owned: %d)\n%s  -  Cost: %s" % [u["name"], u["owned"], u["desc"], _fmt(cost)]
		b.disabled = points < cost


func _on_seal_pressed() -> void:
	points += click_power
	_pop_animation()
	_floating_text("+" + _fmt(click_power))


func _buy(index: int) -> void:
	var u: Dictionary = upgrades[index]
	var cost := _cost(u)
	if points >= cost:
		points -= cost
		u["owned"] += 1
		_recalculate()


func _cost(u: Dictionary) -> float:
	return ceil(u["base_cost"] * pow(COST_GROWTH, u["owned"]))


func _recalculate() -> void:
	click_power = 1.0
	per_second = 0.0
	for u in upgrades:
		if u["type"] == "click":
			click_power += u["value"] * u["owned"]
		else:
			per_second += u["value"] * u["owned"]


# ---------- Effects ----------
func _pop_animation() -> void:
	var tween := create_tween()
	tween.tween_property(seal_button, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(seal_button, "scale", Vector2.ONE, 0.1)


func _floating_text(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 28)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = get_global_mouse_position() + Vector2(randf_range(-30, 30), -40)
	add_child(l)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(l, "position:y", l.position.y - 80, 0.7)
	tween.tween_property(l, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(l.queue_free)


# ---------- Helpers ----------
func _fmt(n: float) -> String:
	var suffixes := ["", "K", "M", "B", "T", "Qa"]
	var i := 0
	while n >= 1000.0 and i < suffixes.size() - 1:
		n /= 1000.0
		i += 1
	if i == 0:
		return str(int(n)) if is_equal_approx(n, floorf(n)) or n >= 100.0 else "%.1f" % n
	return "%.2f%s" % [n, suffixes[i]]


# ---------- Save / load ----------
func _save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "points", points)
	var owned := []
	for u in upgrades:
		owned.append(u["owned"])
	cfg.set_value("save", "owned", owned)
	cfg.save(SAVE_PATH)


func _load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	points = cfg.get_value("save", "points", 0.0)
	var owned: Array = cfg.get_value("save", "owned", [])
	for i in min(owned.size(), upgrades.size()):
		upgrades[i]["owned"] = owned[i]


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
