class_name Synth
extends Node
## Renders the original Web Audio effects to sample buffers once, then plays them from a pool.

const RATE := 44100
const MUSIC_RATE := 22050
const MASTER := 0.6
const DAY_SCALE := [523.0, 587.0, 659.0, 784.0, 880.0, 1046.0]
const NIGHT_SCALE := [262.0, 294.0, 330.0, 392.0, 440.0]

var on := true
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _cache := {}
var _last := {}
var _next_music := 0.0
var _ambient: AudioStreamPlayer
var _warm: Array[String] = []


func _ready() -> void:
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_ambient = AudioStreamPlayer.new()
	add_child(_ambient)
	_ambient.stream = _render_ambient()
	_ambient.play()
	for f in DAY_SCALE + NIGHT_SCALE:
		_warm.append("note:%d" % int(f))
	_apply()


var _warm_t := 0.0


func _process(dt: float) -> void:
	# Render one music note every 0.3 s in the background so the first play has no stall.
	_warm_t += dt
	if not _warm.is_empty() and _warm_t > 0.3:
		_warm_t = 0.0
		_stream(_warm.pop_back())


func set_on(v: bool) -> void:
	on = v
	_apply()


func _apply() -> void:
	AudioServer.set_bus_mute(0, not on)


# ---------- public sounds ----------

func bubble() -> void:
	if _ok("bub", 90):
		_play("bubble", randf_range(0.76, 1.24))


func plop() -> void:
	_play("plop")


func eat() -> void:
	if _ok("eat", 120):
		_play("eat")


func coin() -> void:
	if _ok("coin", 220):
		_play("coin")


func buy() -> void:
	_play("buy")


func ach() -> void:
	_play("ach")


func hatch() -> void:
	_play("hatch")


func death() -> void:
	_play("death")


func splash() -> void:
	_play("splash")


func scrub() -> void:
	if _ok("scr", 70):
		_play("scrub", randf_range(0.9, 1.1))


func suck() -> void:
	if _ok("suck", 140):
		_play("suck", randf_range(0.87, 1.13))


func click() -> void:
	_play("click")


func keeper() -> void:
	_play("keeper")


func music(t: float, light: float) -> void:
	if not on or t < _next_music:
		return
	_next_music = t + randf_range(1.8, 4.2)
	var f: float = (DAY_SCALE if light > 0.6 else NIGHT_SCALE).pick_random()
	_play("note:%d" % int(f))
	if randf() < 0.3:
		_play("fifth:%d" % int(f))


# ---------- playback ----------

func _ok(k: String, gap_ms: int) -> bool:
	var n := Time.get_ticks_msec()
	if _last.has(k) and n - _last[k] < gap_ms:
		return false
	_last[k] = n
	return true


func _play(key: String, pitch := 1.0) -> void:
	if not on:
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _stream(key)
	p.pitch_scale = pitch
	p.play()


func _stream(key: String) -> AudioStreamWAV:
	if _cache.has(key):
		return _cache[key]
	var s: AudioStreamWAV
	if key.begins_with("note:"):
		var f := float(key.substr(5))
		s = _render([{"f": f, "dur": 1.8, "type": "triangle", "g": 0.022, "a": 0.02}], MUSIC_RATE)
	elif key.begins_with("fifth:"):
		var f := float(key.substr(6)) * 1.5
		s = _render([{"f": f, "dur": 1.6, "type": "sine", "g": 0.012, "a": 0.03, "delay": 0.35}], MUSIC_RATE)
	else:
		s = _render_effect(key)
	_cache[key] = s
	return s


func _render_effect(key: String) -> AudioStreamWAV:
	match key:
		"bubble":
			return _render([{"f": 500.0, "dur": 0.09, "g": 0.04, "to": 1100.0}])
		"plop":
			return _render([{"f": 320.0, "dur": 0.14, "g": 0.1, "to": 110.0}, {"f": 600.0, "dur": 0.08, "g": 0.03, "to": 1200.0, "delay": 0.05}])
		"eat":
			return _render([{"f": 660.0, "dur": 0.05, "type": "square", "g": 0.015, "to": 880.0}])
		"coin":
			return _render([{"f": 1318.0, "dur": 0.07, "type": "square", "g": 0.018}, {"f": 1760.0, "dur": 0.12, "type": "square", "g": 0.018, "delay": 0.06}])
		"buy":
			return _render(_arp([523.0, 659.0, 784.0], 0.16, "triangle", 0.09, 0.07))
		"ach":
			return _render(_arp([523.0, 659.0, 784.0, 1046.0], 0.28, "square", 0.035, 0.09))
		"hatch":
			return _render(_arp([660.0, 880.0, 990.0, 1320.0], 0.2, "triangle", 0.07, 0.08))
		"death":
			return _render(_arp([392.0, 330.0, 262.0], 0.45, "triangle", 0.08, 0.2))
		"keeper":
			return _render(_arp([392.0, 330.0], 0.3, "triangle", 0.06, 0.16))
		"splash":
			return _render([], RATE, {"dur": 0.6, "g": 0.5, "freq": 700.0})
		"scrub":
			return _render([], RATE, {"dur": 0.05, "g": 0.25, "freq": 2400.0})
		"suck":
			return _render([{"f": 230.0, "dur": 0.08, "type": "saw", "g": 0.02, "to": 90.0}])
		"click":
			return _render([{"f": 880.0, "dur": 0.04, "type": "square", "g": 0.02}])
	return _render([])


func _arp(freqs: Array, dur: float, type: String, g: float, step: float) -> Array:
	var out := []
	for i in freqs.size():
		out.append({"f": freqs[i], "dur": dur, "type": type, "g": g, "delay": i * step})
	return out


## Renders oscillator notes with exponential attack and release, like the Web Audio original.
func _render(notes: Array, rate := RATE, noise := {}) -> AudioStreamWAV:
	var total := 0.05
	for n in notes:
		total = maxf(total, n.get("delay", 0.0) + n.dur + 0.05)
	if not noise.is_empty():
		total = maxf(total, noise.dur)
	var count := ceili(total * rate)
	var buf := PackedFloat32Array()
	buf.resize(count)
	buf.fill(0.0)
	for n in notes:
		var t0: float = n.get("delay", 0.0)
		var dur: float = n.dur
		var att: float = n.get("a", 0.005)
		var g: float = n.g
		var f0: float = n.f
		var f1: float = n.get("to", f0)
		var type: String = n.get("type", "sine")
		var phase := 0.0
		var i0 := int(t0 * rate)
		var i1 := mini(count, int((t0 + dur + 0.05) * rate))
		var n_att := maxi(1, int(att * rate))
		var n_dur := maxi(n_att + 1, int(dur * rate))
		var att_mul := pow(g / 0.0001, 1.0 / n_att)
		var rel_mul := pow(0.0001 / g, 1.0 / (n_dur - n_att))
		var f_mul := pow(f1 / f0, 1.0 / n_dur)
		var env := 0.0001
		var f := f0
		for i in range(i0, i1):
			var k := i - i0
			if k < n_dur:
				f *= f_mul
			if k < n_att:
				env *= att_mul
			elif k < n_dur:
				env *= rel_mul
			else:
				env = 0.0001
			phase += f / rate
			var p := phase - floorf(phase)
			var v: float
			match type:
				"square":
					v = 1.0 if p < 0.5 else -1.0
				"triangle":
					v = 1.0 - 4.0 * absf(p - 0.5)
				"saw":
					v = 2.0 * p - 1.0
				_:
					v = sin(TAU * p)
			buf[i] += v * env
	if not noise.is_empty():
		var n := int(rate * noise.dur)
		var bq := _biquad("bandpass", noise.freq, 1.0, rate)
		var st := [0.0, 0.0, 0.0, 0.0]
		for i in n:
			var x := (randf() * 2.0 - 1.0) * (1.0 - float(i) / n)
			buf[i] += _bq_step(bq, st, x) * noise.g
	return _to_wav(buf, rate, false)


func _render_ambient() -> AudioStreamWAV:
	var rate := MUSIC_RATE
	var n := rate * 3
	var fade := int(rate * 0.2)
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var lv := 0.0
	var bq := _biquad("lowpass", 380.0, pow(10.0, 1.0 / 20.0), rate)
	var st := [0.0, 0.0, 0.0, 0.0]
	for i in n + fade:
		lv = (lv + 0.02 * (randf() * 2.0 - 1.0)) / 1.02
		raw[i] = _bq_step(bq, st, lv * 3.5) * 0.16
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		if i < fade:
			var k := float(i) / fade
			out[i] = raw[i] * k + raw[n + i] * (1.0 - k)
		else:
			out[i] = raw[i]
	return _to_wav(out, rate, true)


func _biquad(type: String, freq: float, q: float, rate: int) -> Array:
	var w0 := TAU * freq / rate
	var alpha := sin(w0) / (2.0 * q)
	var c := cos(w0)
	var b0: float
	var b1: float
	var b2: float
	if type == "bandpass":
		b0 = alpha
		b1 = 0.0
		b2 = -alpha
	else:
		b0 = (1.0 - c) / 2.0
		b1 = 1.0 - c
		b2 = (1.0 - c) / 2.0
	var a0 := 1.0 + alpha
	return [b0 / a0, b1 / a0, b2 / a0, -2.0 * c / a0, (1.0 - alpha) / a0]


func _bq_step(k: Array, st: Array, x: float) -> float:
	var y: float = k[0] * x + k[1] * st[0] + k[2] * st[1] - k[3] * st[2] - k[4] * st[3]
	st[1] = st[0]
	st[0] = x
	st[3] = st[2]
	st[2] = y
	return y


func _to_wav(buf: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] * MASTER, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = buf.size()
	return s
