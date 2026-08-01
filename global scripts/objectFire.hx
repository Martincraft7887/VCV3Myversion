import funkin.backend.shaders.CustomShader;
import StringTools;

var objectFireEntries:Array<Dynamic> = [];
var objectFireTime:Float = 0;

/**
 * Applies ObjectFire to any sprite.
 *
 * Call it from a stage/song script with:
 * scripts.call("applyObjectFire", [sprite, { ...options... }]);
 */
function applyObjectFire(target:Dynamic, options:Dynamic = null):Dynamic {
	if (target == null) return null;

	var entry = getObjectFireEntry(target);
	if (entry == null) {
		var shader = new CustomShader("ObjectFire");
		entry = {
			target: target,
			shader: shader,
			previousShader: target.shader,
			settings: defaultObjectFireSettings()
		};
		objectFireEntries.push(entry);
		target.shader = shader;
	} else if (target.shader != entry.shader) {
		entry.previousShader = target.shader;
		target.shader = entry.shader;
	}

	mergeObjectFireOptions(entry.settings, options);
	configureObjectFireShader(entry.shader, entry.settings);
	return entry.shader;
}

/** Updates every configurable property on an active fire object. */
function configureObjectFire(target:Dynamic, options:Dynamic):Dynamic {
	if (target == null) return null;
	var entry = getObjectFireEntry(target);
	if (entry == null) return applyObjectFire(target, options);

	mergeObjectFireOptions(entry.settings, options);
	configureObjectFireShader(entry.shader, entry.settings);
	return entry.shader;
}

/** Changes only the three palette colors, without resetting other properties. */
function setObjectFireColors(target:Dynamic, core:Dynamic, middle:Dynamic, outer:Dynamic):Dynamic {
	if (target == null) return null;
	var entry = getObjectFireEntry(target);
	if (entry == null) {
		return applyObjectFire(target, {
			coreColor: core,
			middleColor: middle,
			outerColor: outer
		});
	}

	entry.settings.coreColor = objectFireColor(core, entry.settings.coreColor);
	entry.settings.middleColor = objectFireColor(middle, entry.settings.middleColor);
	entry.settings.outerColor = objectFireColor(outer, entry.settings.outerColor);
	setObjectFireUniform(entry.shader, "coreColor", entry.settings.coreColor);
	setObjectFireUniform(entry.shader, "midColor", entry.settings.middleColor);
	setObjectFireUniform(entry.shader, "outerColor", entry.settings.outerColor);
	return entry.shader;
}

/** Changes only intensity. Set it to 0 to fade the visual out without removing it. */
function setObjectFireIntensity(target:Dynamic, value:Dynamic):Dynamic {
	if (target == null) return null;
	var entry = getObjectFireEntry(target);
	if (entry == null) return applyObjectFire(target, {intensity: value});

	entry.settings.intensity = objectFireNumber(value, entry.settings.intensity, 0.0, 2.0);
	setObjectFireUniform(entry.shader, "intensity", entry.settings.intensity);
	return entry.shader;
}

/** Removes ObjectFire and restores the shader the object had before it. */
function removeObjectFire(target:Dynamic) {
	if (target == null) return;

	var index = objectFireEntries.length - 1;
	while (index >= 0) {
		var entry = objectFireEntries[index];
		if (entry != null && entry.target == target) {
			restoreObjectFireEntry(entry);
			objectFireEntries.splice(index, 1);
			return;
		}
		index--;
	}
}

/** Removes ObjectFire from every object managed by this helper. */
function clearObjectFire() {
	for (entry in objectFireEntries)
		restoreObjectFireEntry(entry);
	objectFireEntries = [];
}

function defaultObjectFireSettings():Dynamic {
	return {
		intensity: 1.0,
		speed: 1.0,
		scale: 1.0,
		coverage: 0.72,
		charAmount: 0.45,
		coreColor: [1.0, 0.95, 0.63],
		middleColor: [1.0, 0.45, 0.0],
		outerColor: [0.7, 0.035, 0.0]
	};
}

function mergeObjectFireOptions(settings:Dynamic, options:Dynamic) {
	if (settings == null || options == null) return;

	if (Reflect.hasField(options, "intensity"))
		settings.intensity = objectFireNumber(Reflect.field(options, "intensity"), settings.intensity, 0.0, 2.0);
	if (Reflect.hasField(options, "speed"))
		settings.speed = objectFireNumber(Reflect.field(options, "speed"), settings.speed, 0.0, 4.0);
	if (Reflect.hasField(options, "scale"))
		settings.scale = objectFireNumber(Reflect.field(options, "scale"), settings.scale, 0.25, 4.0);
	if (Reflect.hasField(options, "coverage"))
		settings.coverage = objectFireNumber(Reflect.field(options, "coverage"), settings.coverage, 0.0, 1.0);
	if (Reflect.hasField(options, "charAmount"))
		settings.charAmount = objectFireNumber(Reflect.field(options, "charAmount"), settings.charAmount, 0.0, 1.0);
	if (Reflect.hasField(options, "coreColor"))
		settings.coreColor = objectFireColor(Reflect.field(options, "coreColor"), settings.coreColor);
	if (Reflect.hasField(options, "middleColor"))
		settings.middleColor = objectFireColor(Reflect.field(options, "middleColor"), settings.middleColor);
	if (Reflect.hasField(options, "outerColor"))
		settings.outerColor = objectFireColor(Reflect.field(options, "outerColor"), settings.outerColor);
}

function configureObjectFireShader(shader:Dynamic, settings:Dynamic) {
	if (shader == null) return;

	setObjectFireUniform(shader, "iTime", objectFireTime);
	setObjectFireUniform(shader, "intensity", settings.intensity);
	setObjectFireUniform(shader, "fireSpeed", settings.speed);
	setObjectFireUniform(shader, "fireScale", settings.scale);
	setObjectFireUniform(shader, "coverage", settings.coverage);
	setObjectFireUniform(shader, "charAmount", settings.charAmount);
	setObjectFireUniform(shader, "coreColor", settings.coreColor);
	setObjectFireUniform(shader, "midColor", settings.middleColor);
	setObjectFireUniform(shader, "outerColor", settings.outerColor);
}

function getObjectFireEntry(target:Dynamic):Dynamic {
	for (entry in objectFireEntries)
		if (entry != null && entry.target == target)
			return entry;
	return null;
}

function restoreObjectFireEntry(entry:Dynamic) {
	if (entry == null || entry.target == null) return;
	try {
		if (entry.target.shader == entry.shader)
			entry.target.shader = entry.previousShader;
	} catch(e:Dynamic) {}
}

function objectFireNumber(value:Dynamic, fallback:Float, minimum:Float, maximum:Float):Float {
	var parsed = value == null ? Math.NaN : Std.parseFloat(Std.string(value));
	if (Math.isNaN(parsed)) parsed = fallback;
	return Math.max(minimum, Math.min(maximum, parsed));
}

function objectFireColor(value:Dynamic, fallback:Array<Float>):Array<Float> {
	if (value == null) return fallback.copy();
	if (Std.isOfType(value, Array)) {
		var array:Array<Dynamic> = cast value;
		if (array.length >= 3) {
			return [
				objectFireNumber(array[0], fallback[0], 0.0, 1.0),
				objectFireNumber(array[1], fallback[1], 0.0, 1.0),
				objectFireNumber(array[2], fallback[2], 0.0, 1.0)
			];
		}
	}

	var color:Null<Int> = null;
	if (Std.isOfType(value, Int)) {
		color = cast value;
	} else {
		var raw = StringTools.trim(Std.string(value));
		if (StringTools.startsWith(raw, "#")) raw = raw.substr(1);
		if (StringTools.startsWith(raw.toLowerCase(), "0x")) raw = raw.substr(2);
		if (raw.length == 8) raw = raw.substr(2);
		if (raw.length == 6) color = Std.parseInt("0x" + raw);
	}

	if (color == null) return fallback.copy();
	return [
		((color >> 16) & 0xFF) / 255.0,
		((color >> 8) & 0xFF) / 255.0,
		(color & 0xFF) / 255.0
	];
}

function setObjectFireUniform(shader:Dynamic, name:String, value:Dynamic) {
	if (shader == null) return;
	try {
		shader.hset(name, value);
	} catch(e:Dynamic) {
		try {
			Reflect.setProperty(shader, name, value);
		} catch(e2:Dynamic) {}
	}
}

function update(elapsed:Float) {
	if (objectFireEntries.length <= 0) return;
	objectFireTime += elapsed;

	for (entry in objectFireEntries)
		if (entry != null && entry.shader != null)
			setObjectFireUniform(entry.shader, "iTime", objectFireTime);
}

function destroy() {
	clearObjectFire();
}
