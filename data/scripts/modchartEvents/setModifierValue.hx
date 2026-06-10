//
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIText;

trace("Loaded Event Script: setModifierValue");

function eventFromXMLEditor(node) {
	var event = {
		type: node.get("type"),
		step: Std.parseFloat(node.get("step")),
		name: node.get("name"),
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
	node.set("value", e.value);
	if (e.DI_value != null && e.DI_value) {
		node.set("DI_value", e.DI_value);
	}
}

function getItemName(e) {
	return e.name;
}

function getItemNameFromXML(node) {
	return node.get("name");
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
		value: e.value,
		lastValue: e.lastValue,
		DI_value: e.DI_value
	};
}

function getDisplayName(e) {
	return "Set Modifier Value";
}

function getEventWindowWidth() {
	return 520;
}

function getEventWindowHeight() {
	return 300;
}
