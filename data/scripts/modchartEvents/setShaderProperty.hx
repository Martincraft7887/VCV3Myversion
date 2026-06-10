//
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIText;

trace("Loaded Event Script: setShaderProperty");

function createEventGame(typeID, node, itemIndex) {
	return {
		"type": typeID,
		"step": Std.parseFloat(node.get("step")),
		"itemIndex": itemIndex,
		"value": Std.parseFloat(node.get("value")) * (downscroll && node.exists("DI_value") && node.get("DI_value") == "true" ? -1 : 1)
	};
}

function updateEventGame(currentStep, e) {
	modchartItems[e.itemIndex].object.hset(modchartItems[e.itemIndex].property, e.value);
	return true;
}

function eventFromXMLEditor(node) {
	var event = {
		type: node.get("type"),
		step: Std.parseFloat(node.get("step")),
		name: node.get("name"),
		property: node.get("property"),
		value: Std.parseFloat(node.get("value")),
		lastValue: 0
	};

	if (node.exists("DI_value")) {
		event.DI_value = node.get("DI_value") == "true";
	}

	return event;
}

function eventToXMLEditor(node, e) {
	node.set("name", e.name);
	node.set("property", e.property);
	node.set("value", e.value);
	if (e.DI_value != null && e.DI_value) {
		node.set("DI_value", e.DI_value);
	}
}

function getItemName(e) {
	return e.name + "." + e.property;
}

function getItemNameFromXML(node) {
	return node.get("name") + "." + node.get("property");
}

function updateEventEditor(currentStep, e, item) {
	if (currentStep >= e.step) {
		var vMult:Float = (e.DI_value != null && e.DI_value && downscroll) ? -1.0 : 1.0;
		item.currentValue = e.value * vMult;
	}
}

function copyEventEditor(e) {
	return {
		type: e.type,
		step: e.step,
		name: e.name,
		property: e.property,
		value: e.value,
		lastValue: e.lastValue,
		DI_value: e.DI_value
	};
}

function getDisplayName(e) {
	return "Set Shader Property";
}

function getEventWindowWidth() {
	return 520;
}

function getEventWindowHeight() {
	return 300;
}
