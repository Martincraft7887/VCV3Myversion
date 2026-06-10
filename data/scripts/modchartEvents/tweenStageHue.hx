//
import funkin.editors.ui.UIText;

var STAGE_HUE_EASE = "linear";

function getStageHueEaseFunc():Float->Float {
	return CoolUtil.flxeaseFromString(STAGE_HUE_EASE, "");
}

function createEventGame(typeID, node, itemIndex) {
	return {
		"type": typeID,
		"step": Std.parseFloat(node.get("step")),
		"itemIndex": itemIndex,
		"value": Std.parseFloat(node.get("value")),
		"time": Std.parseFloat(node.get("time")),
		"ease": getStageHueEaseFunc(),
		"startValue": Std.parseFloat(node.get("startValue"))
	};
}

function getItemNameFromXML(node) {
	return "stageHue.hue";
}

function updateEventGame(currentStep, e) {
	var easeFunc = getStageHueEaseFunc();

	if (currentStep < e.step + e.time) {
		var l = (currentStep - e.step) * (1 / ((e.step + e.time) - e.step));
		var value = FlxMath.lerp(e.startValue, e.value, easeFunc(l));
		modchartItems[e.itemIndex].object.hset(modchartItems[e.itemIndex].property, value);
		try {
			scripts.call("setRTXHue", [value]);
		} catch(err:Dynamic) {}
		return false;
	}

	modchartItems[e.itemIndex].object.hset(modchartItems[e.itemIndex].property, e.value);
	try {
		scripts.call("setRTXHue", [e.value]);
	} catch(err:Dynamic) {}
	return true;
}

function createEventEditor(name, step, item) {
	return {
		"type": "tweenStageHue",
		"step": step,
		"value": 0,
		"time": 4,
		"ease": STAGE_HUE_EASE,
		"startValue": item.currentValue,
		"lastValue": 0
	};
}

function updateEventEditor(currentStep, e, item) {
	var easeFunc = getStageHueEaseFunc();

	if (currentStep < e.step + e.time) {
		var l = (currentStep - e.step) * (1 / ((e.step + e.time) - e.step));
		item.currentValue = FlxMath.lerp(e.startValue, e.value, easeFunc(l));
	} else {
		item.currentValue = e.value;
	}
}

function copyEventEditor(e) {
	return {
		"type": e.type,
		"step": e.step,
		"value": e.value,
		"time": e.time,
		"ease": STAGE_HUE_EASE,
		"startValue": e.startValue,
		"lastValue": e.lastValue
	};
}

function eventFromXMLEditor(node) {
	return {
		"type": node.get("type"),
		"step": Std.parseFloat(node.get("step")),
		"value": Std.parseFloat(node.get("value")),
		"time": Std.parseFloat(node.get("time")),
		"ease": STAGE_HUE_EASE,
		"startValue": Std.parseFloat(node.get("startValue")),
		"lastValue": 0
	};
}

function eventToXMLEditor(node, e) {
	node.set("value", e.value);
	node.set("time", e.time);
	node.set("ease", STAGE_HUE_EASE);
	node.set("startValue", e.startValue);
}

function getItemName(e) {
	return "stageHue.hue";
}

function getDisplayName(e) {
	return "Tween Stage Hue";
}

function getEventWindowWidth() {
	return 640;
}

function getEventWindowHeight() {
	return 310;
}

function setupEventWindow(event, propertyMap, windowData) {
	windowData.state.add(new UIText(windowData.curX, windowData.curY, 0, getDisplayName(event), 24));
	windowData.curY += 28 + 50;

	windowData.curX = windowData.windowSpr.x + (windowData.windowSpr.bWidth / 2) - 50;
	windowData.addStepper("startValue", "Start Value", event.startValue, 0.01, 0.1);
	windowData.curY += 50;
	windowData.addStepper("value", "Value", event.value, 0.01, 0.1);
	windowData.curY += 50;
	windowData.addStepper("time", "Time", event.time, 0.25, 4);
}

function saveEventWindow(event, propertyMap) {
	event.startValue = propertyMap.get("startValue").value;
	event.value = propertyMap.get("value").value;
	event.time = propertyMap.get("time").value;
	event.ease = STAGE_HUE_EASE;
}
