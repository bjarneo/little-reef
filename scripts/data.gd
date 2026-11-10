class_name D
extends RefCounted
## Static game data and the small math helpers that the simulation and the renderer share.

const DAY := 240.0
const SAVE_PATH := "user://little-reef-save.json"
const SETTINGS_PATH := "user://little-reef-settings.json"
const M32 := 0xFFFFFFFF

static var COLORS: Dictionary = {
	"coral": {"name": "Coral", "d": Color("#6e1a2a"), "m": Color("#e8495c"), "l": Color("#ff9e9a"), "w": 3.0},
	"tangerine": {"name": "Tangerine", "d": Color("#733010"), "m": Color("#f27c2c"), "l": Color("#ffc18a"), "w": 3.0},
	"lemon": {"name": "Lemon", "d": Color("#6a5612"), "m": Color("#f0d040"), "l": Color("#fff3a8"), "w": 3.0},
	"moss": {"name": "Moss", "d": Color("#1f4a24"), "m": Color("#5cb44c"), "l": Color("#bbe89c"), "w": 3.0},
	"cobalt": {"name": "Cobalt", "d": Color("#16245e"), "m": Color("#4a6ff0"), "l": Color("#a8c0ff"), "w": 3.0},
	"orchid": {"name": "Orchid", "d": Color("#46195e"), "m": Color("#b35ee0"), "l": Color("#e8b8ff"), "w": 3.0},
	"pearl": {"name": "Pearl", "d": Color("#5a6078"), "m": Color("#e4e8f2"), "l": Color("#ffffff"), "w": 2.0, "rare": 2.0},
	"ink": {"name": "Ink", "d": Color("#05050a"), "m": Color("#2c2c44"), "l": Color("#6a6a92"), "w": 2.0, "rare": 2.0},
	"gilt": {"name": "Gilt", "d": Color("#6a4606"), "m": Color("#eab020"), "l": Color("#fff6c0"), "w": 1.2, "rare": 3.0},
}
const COLOR_KEYS: Array[String] = ["coral", "tangerine", "lemon", "moss", "cobalt", "orchid", "pearl", "ink", "gilt"]
const COMMON: Array[String] = ["coral", "tangerine", "lemon", "moss", "cobalt", "orchid"]
const RARE: Array[String] = ["pearl", "ink", "gilt"]

## Fin specs are [back, front, height at back, height at front, sweep]. Sweep leans the fin backward.
static var BODIES: Dictionary = {
	"goby": {"name": "Goby", "rx": 5.0, "ry": 2.3, "tl": 3, "tail": "fan", "spread": 0.45, "dorsal": [-0.6, 0.5, 2, 1], "anal": [-0.5, 0.0, 1, 1],
		"speed": 6.0, "value": 20, "income": 2.0, "price": 15, "bottom": true, "show": "moss", "show2": "lemon"},
	"pebble": {"name": "Pebble", "rx": 5.5, "ry": 4.0, "tl": 5, "tail": "fan", "spread": 0.75, "dorsal": [-0.5, 0.3, 2, 1], "anal": [-0.6, -0.1, 1, 1],
		"speed": 9.0, "value": 30, "income": 3.0, "price": 25, "show": "tangerine", "show2": "lemon"},
	"dart": {"name": "Dart", "rx": 6.5, "ry": 2.6, "tl": 4, "tail": "fork", "spread": 0.8, "dorsal": [-0.3, 0.2, 2, 1], "anal": [-0.6, -0.2, 1, 1],
		"speed": 17.0, "value": 45, "income": 4.0, "price": 40, "show": "cobalt", "show2": "lemon"},
	"sail": {"name": "Sailfin", "rx": 4.5, "ry": 4.8, "tl": 3, "tail": "fan", "spread": 0.5, "dorsal": [-1.4, 0.3, 7, 1], "anal": [-1.4, 0.0, 7, 1],
		"speed": 7.0, "value": 90, "income": 7.0, "price": 80, "show": "lemon", "show2": "cobalt"},
	"angel": {"name": "Angel", "rx": 3.8, "ry": 4.8, "tl": 3, "tail": "fork", "spread": 0.75, "dorsal": [-0.7, 0.5, 7, 2, 0.8], "anal": [-0.7, 0.5, 7, 2, 0.8],
		"speed": 7.0, "value": 110, "income": 8.0, "price": 100, "streamers": true, "show": "orchid", "show2": "lemon"},
	"ribbon": {"name": "Ribbon", "rx": 10.0, "ry": 1.7, "tl": 3, "tail": "point", "spread": 0.0, "dorsal": [-0.9, 0.7, 1, 1], "anal": [-0.9, -0.1, 1, 1],
		"speed": 10.0, "value": 130, "income": 10.0, "price": 120, "wave": true, "bottom": true, "show": "moss", "show2": "lemon"},
	"tang": {"name": "Tang", "rx": 6.0, "ry": 4.3, "tl": 4, "tail": "fork", "spread": 0.85, "dorsal": [-0.9, 0.6, 2, 2], "anal": [-0.8, 0.3, 2, 2],
		"speed": 12.0, "value": 150, "income": 11.0, "price": 140, "show": "cobalt", "show2": "lemon"},
	"betta": {"name": "Betta", "rx": 4.5, "ry": 2.8, "tl": 8, "tail": "veil", "spread": 0.8, "dorsal": [-0.9, 0.1, 4, 2, 0.5], "anal": [-1.0, 0.4, 5, 3, 0.5],
		"speed": 5.0, "value": 170, "income": 12.0, "price": 160, "show": "coral", "show2": "orchid"},
	"puff": {"name": "Puff", "rx": 5.0, "ry": 4.5, "tl": 2, "tail": "fan", "spread": 0.6, "dorsal": [-0.3, 0.1, 1, 1], "anal": null,
		"speed": 6.0, "value": 260, "income": 15.0, "price": 0, "spines": true, "breed_only": true, "show": "orchid", "show2": "lemon"},
	"lantern": {"name": "Lantern", "rx": 5.0, "ry": 3.6, "tl": 3, "tail": "fan", "spread": 0.6, "dorsal": [-0.4, 0.1, 1, 1], "anal": [-0.5, 0.0, 1, 1],
		"speed": 8.0, "value": 320, "income": 18.0, "price": 0, "lure": true, "breed_only": true, "show": "ink", "show2": "cobalt"},
}
const BODY_KEYS: Array[String] = ["goby", "pebble", "dart", "sail", "angel", "ribbon", "tang", "betta", "puff", "lantern"]
const SPECIAL_BODIES: Array[String] = ["puff", "lantern"]

const PATTERNS := {"solid": "Solid", "striped": "Striped", "spotted": "Spotted", "split": "Split"}
const PATTERN_KEYS: Array[String] = ["solid", "striped", "spotted", "split"]
const STAGES := [
	{"name": "Fry", "scale": 0.38, "size": 0.3},
	{"name": "Juvenile", "scale": 0.68, "size": 0.6},
	{"name": "Adult", "scale": 1.0, "size": 1.0},
]

const DECOR := {
	"grass": {"name": "Seagrass", "price": 15, "plant": true, "anim": true, "desc": "Plant · cleans water"},
	"kelp": {"name": "Kelp", "price": 30, "plant": true, "anim": true, "desc": "Tall plant · cleans water"},
	"starfish": {"name": "Starfish", "price": 12, "desc": "Five arms, no hurry"},
	"moss": {"name": "Moss ball", "price": 25, "plant": true, "desc": "Round plant · cleans water"},
	"driftwood": {"name": "Driftwood", "price": 35, "desc": "Old wood, new home"},
	"amphora": {"name": "Amphora", "price": 50, "desc": "Lost at sea"},
	"anemone": {"name": "Anemone", "price": 55, "anim": true, "desc": "Sways · fish love it"},
	"diver": {"name": "Diver", "price": 80, "desc": "Bubbles from the helmet"},
	"castle": {"name": "Castle", "price": 120, "desc": "A keep for tiny fish"},
	"shell": {"name": "Shell", "price": 10, "desc": "Small and shiny"},
	"rock": {"name": "Rock", "price": 20, "desc": "A hiding spot"},
	"coral": {"name": "Fan coral", "price": 45, "desc": "Fish love it"},
	"arch": {"name": "Rock arch", "price": 60, "desc": "Swim-through"},
	"chest": {"name": "Sunken chest", "price": 90, "desc": "Burps bubbles"},
}
const DECOR_KEYS: Array[String] = ["grass", "kelp", "moss", "shell", "starfish", "rock", "driftwood", "coral", "amphora", "anemone", "arch", "diver", "chest", "castle"]
## How many decorations fit, per "Bigger tank" level.
const MAX_DECOR := [16, 20, 24, 30]

const CAP := [6, 10, 14, 20]
## Tank size per "Bigger tank" level. The world grows by this factor in both directions.
const TANK := [1.0, 1.3, 1.6, 2.0]
const FILTER := [1.0, 0.7, 0.5, 0.35]
const UPG := {
	"cap": {"name": "Bigger tank", "prices": [150, 400, 900]},
	"filter": {"name": "Filter", "prices": [100, 300, 700]},
	"pump": {"name": "Air pump", "prices": [60]},
	"feeder": {"name": "Auto-feeder", "prices": [250]},
}
const UPG_KEYS: Array[String] = ["cap", "filter", "pump", "feeder"]

const NAMES: Array[String] = ["Nori", "Pip", "Mochi", "Basil", "Kip", "Juniper", "Taro", "Olive", "Sprat", "Fennel", "Clove", "Biscuit", "Pico", "Marlo", "Wren", "Dot", "Ziggy", "Hops", "Inky", "Bean", "Toffee", "Kelpie", "Rue", "Sable", "Tansy", "Bloop", "Puddle", "Gus", "Lumi", "Opal", "Quill", "Remy", "Sage", "Tilly", "Umi", "Vera", "Yuzu", "Zest", "Figgy", "Pesto", "Miso", "Waffles", "Bramble", "Cricket", "Dumpling"]

const ACH := [
	{"id": "first", "name": "New Arrival", "desc": "Buy a fish", "r": 10},
	{"id": "snack", "name": "Snack Time", "desc": "Feed 25 times", "r": 15},
	{"id": "keeper", "name": "Say Hello", "desc": "Tap the keeper's face behind the tank", "r": 20},
	{"id": "clear", "name": "Crystal Clear", "desc": "Get water to 100%", "r": 20},
	{"id": "green", "name": "Green Thumb", "desc": "Have 5 plants", "r": 30},
	{"id": "designer", "name": "Interior Designer", "desc": "Place 8 decorations", "r": 30},
	{"id": "parent", "name": "Proud Parent", "desc": "Hatch your first fry", "r": 40},
	{"id": "grown", "name": "All Grown Up", "desc": "Raise a fry to adult", "r": 40},
	{"id": "rare", "name": "Rare Find", "desc": "Discover a Pearl, Ink or Gilt fish", "r": 60},
	{"id": "variety", "name": "Mixed Shoal", "desc": "Keep 6 kinds of fish at once", "r": 60},
	{"id": "puff", "name": "Puff!", "desc": "Discover the Puff", "r": 80},
	{"id": "lantern", "name": "Glow Up", "desc": "Discover the Lantern", "r": 80},
	{"id": "collector", "name": "Collector", "desc": "Fill 15 book entries", "r": 100},
	{"id": "house", "name": "Full House", "desc": "Keep 12 fish alive", "r": 60},
	{"id": "tycoon", "name": "Tycoon", "desc": "Earn 1,000 coins", "r": 100},
	{"id": "elder", "name": "Old Timer", "desc": "Keep a fish alive for 10 days", "r": 80},
	{"id": "curator", "name": "Curator", "desc": "Fill 40 book entries", "r": 200},
]

const HOURS := [[0.0, "#3b4680", 0.3], [5.0, "#3b4680", 0.3], [6.5, "#d8a8a0", 0.6], [8.0, "#ffffff", 1.0], [17.5, "#ffffff", 1.0], [19.0, "#f0b08a", 0.7], [20.5, "#3b4680", 0.3], [24.0, "#3b4680", 0.3]]


## Rounds like JavaScript Math.round: halves go toward positive infinity.
static func jr(v: float) -> int:
	return floori(v + 0.5)


static func hash2(x: int, y: int, s: int) -> float:
	var h: int = ((x * 374761393) & M32) ^ ((y * 668265263) & M32) ^ (((s + 1) * 982451653) & M32)
	h = ((h ^ (h >> 13)) * 1274126177) & M32
	h = h ^ (h >> 16)
	return float(h) / 4294967296.0


## Mixes two colors and rounds each channel to 8 bits, as the canvas version does.
static func mix(a: Color, b: Color, t: float) -> Color:
	return Color8(jr(a.r8 + (b.r8 - a.r8) * t), jr(a.g8 + (b.g8 - a.g8) * t), jr(a.b8 + (b.b8 - a.b8) * t))


static func grey(c: Color) -> Color:
	var l := jr((c.r8 * 0.3 + c.g8 * 0.59 + c.b8 * 0.11) * 0.8 + 30.0)
	var out := mix(c, Color8(l, l, l), 0.85)
	out.a = c.a
	return out


static func hours_of(t: float) -> float:
	return fmod(6.0 + t * 24.0, 24.0)


static func sky_at(t: float) -> Dictionary:
	var h := hours_of(t)
	for i in HOURS.size() - 1:
		var a: Array = HOURS[i]
		var b: Array = HOURS[i + 1]
		if h >= a[0] and h <= b[0]:
			var span: float = b[0] - a[0]
			var k: float = (h - a[0]) / (span if span != 0.0 else 1.0)
			return {"tint": mix(Color(a[1]), Color(b[1]), k), "light": lerpf(a[2], b[2], k)}
	return {"tint": Color.WHITE, "light": 1.0}


static func phase_of(t: float) -> String:
	var h := hours_of(t)
	if h >= 6.0 and h < 8.0:
		return "Dawn"
	if h >= 8.0 and h < 18.0:
		return "Day"
	if h >= 18.0 and h < 20.0:
		return "Dusk"
	return "Night"


static func color_mult(c: String) -> float:
	return COLORS[c].get("rare", 1.0)


static func fish_value(f: Dictionary) -> int:
	if not f.alive:
		return 0
	var P: Dictionary = BODIES[f.g.b]
	var st: float = [0.15, 0.4, 1.0][f.stage]
	return maxi(1, jr(P.value * color_mult(f.g.c1) * (1.2 if f.g.p != "solid" else 1.0) * st * (0.5 + f.health / 200.0)))


static func income_of(f: Dictionary, night: bool) -> float:
	if not f.alive or f.stage < 2:
		return 0.0
	var P: Dictionary = BODIES[f.g.b]
	return P.income * color_mult(f.g.c1) * (1.2 if f.g.p != "solid" else 1.0) * (0.25 + f.happy / 100.0 * 0.95) * (0.6 if night else 1.0)


static func variety_name(g: Dictionary) -> String:
	return (PATTERNS[g.p] + " " if g.p != "solid" else "") + COLORS[g.c1].name + " " + BODIES[g.b].name


static func weighted_color() -> String:
	if randf() < 0.4:
		var tot := 0.0
		for k in RARE:
			tot += COLORS[k].w
		var r := randf() * tot
		for k in RARE:
			r -= COLORS[k].w
			if r <= 0.0:
				return k
		return RARE[0]
	return COMMON.pick_random()


static func upgrade_desc(key: String, level: int) -> String:
	match key:
		"cap":
			return "Holds %d fish · wider tank" % CAP[mini(level + 1, 3)]
		"filter":
			return "Water stays clean longer"
		"pump":
			return "Bubbles · happier, healthier fish"
		"feeder":
			return "Feeds the tank 3× a day"
	return ""


## The xorshift32 generator from the original engine. Seeds give the same decor shapes.
class Rng:
	var s: int

	func _init(seed_value: int) -> void:
		s = seed_value & 0xFFFFFFFF
		if s == 0:
			s = 1

	func next() -> float:
		s = (s ^ (s << 13)) & 0xFFFFFFFF
		s = s ^ (s >> 17)
		s = (s ^ (s << 5)) & 0xFFFFFFFF
		return float(s) / 4294967296.0
