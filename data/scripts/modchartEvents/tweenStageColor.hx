import funkin.editors.ui.UIText;

var STAGE_COLOR_EASE = "linear";

function getStageColorEaseFunc():Float->Float {
    return CoolUtil.flxeaseFromString(STAGE_COLOR_EASE, "");
}

function normalizeStageColorProperty(property) {
    return switch(property) {
        case "temp": "temperature";
        case "sat": "saturation";
        case "con": "contrast";
        case "temperature" | "saturation" | "contrast": property;
        default: "temperature";
    };
}

function getStageColorPropertyFromXML(node) {
    return normalizeStageColorProperty(node.exists("property") ? node.get("property") : "temperature");
}

function createEventGame(typeID, node, itemIndex) {
    return {
        "type": typeID,
        "step": Std.parseFloat(node.get("step")),
        "itemIndex": itemIndex,
        "property": getStageColorPropertyFromXML(node),
        "value": Std.parseFloat(node.get("value")),
        "time": Std.parseFloat(node.get("time")),
        "ease": getStageColorEaseFunc(),
        "startValue": Std.parseFloat(node.get("startValue"))
    };
}

function getItemNameFromXML(node) {
    return "stageColor." + getStageColorPropertyFromXML(node);
}

function setStageColorItemValue(item, value) {
    if (item == null || item.object == null) return;
    var parameter = item.object.data == null ? null : Reflect.field(item.object.data, item.property);
    if (parameter != null && parameter.value != null && parameter.value.length > 0)
        parameter.value[0] = value;
    else
        item.object.hset(item.property, value);
}

function updateEventGame(currentStep, e) {
    var item = modchartItems[e.itemIndex];
    if (e.time > 0 && currentStep < e.step + e.time) {
        var l = (currentStep - e.step) / e.time;
        setStageColorItemValue(item, FlxMath.lerp(e.startValue, e.value, e.ease(l)));
        return false;
    }

    setStageColorItemValue(item, e.value);
    return true;
}

function getStageColorNeutralValue(property) {
    return normalizeStageColorProperty(property) == "temperature" ? 0.0 : 1.0;
}

function createEventEditor(name, step, item) {
    var property = normalizeStageColorProperty(item.property);
    return {
        "type": "tweenStageColor",
        "step": step,
        "property": property,
        "value": getStageColorNeutralValue(property),
        "time": 4,
        "ease": STAGE_COLOR_EASE,
        "startValue": item.currentValue,
        "lastValue": 0
    };
}

function updateEventEditor(currentStep, e, item) {
    var easeFunc = getStageColorEaseFunc();
    if (e.time > 0 && currentStep < e.step + e.time) {
        var l = (currentStep - e.step) / e.time;
        item.currentValue = FlxMath.lerp(e.startValue, e.value, easeFunc(l));
    } else {
        item.currentValue = e.value;
    }
}

function copyEventEditor(e) {
    return {
        "type": e.type,
        "step": e.step,
        "property": normalizeStageColorProperty(e.property),
        "value": e.value,
        "time": e.time,
        "ease": STAGE_COLOR_EASE,
        "startValue": e.startValue,
        "lastValue": e.lastValue
    };
}

function eventFromXMLEditor(node) {
    return {
        "type": node.get("type"),
        "step": Std.parseFloat(node.get("step")),
        "property": getStageColorPropertyFromXML(node),
        "value": Std.parseFloat(node.get("value")),
        "time": Std.parseFloat(node.get("time")),
        "ease": STAGE_COLOR_EASE,
        "startValue": Std.parseFloat(node.get("startValue")),
        "lastValue": 0
    };
}

function eventToXMLEditor(node, e) {
    node.set("property", normalizeStageColorProperty(e.property));
    node.set("value", e.value);
    node.set("time", e.time);
    node.set("ease", STAGE_COLOR_EASE);
    node.set("startValue", e.startValue);
}

function getItemName(e) {
    return "stageColor." + normalizeStageColorProperty(e.property);
}

function getStageColorPropertyDisplayName(property) {
    return switch(normalizeStageColorProperty(property)) {
        case "saturation": "Saturation";
        case "contrast": "Contrast";
        default: "Temperature";
    };
}

function getDisplayName(e) {
    return "Tween Stage " + getStageColorPropertyDisplayName(e.property);
}

function getEventWindowWidth() {
    return 640;
}

function getEventWindowHeight() {
    return 310;
}

function setupEventWindow(event, propertyMap, windowData) {
    windowData.state.add(new UIText(windowData.curX, windowData.curY, 0, getDisplayName(event), 24));
    windowData.curY += 28 + 25;

    var firstRowY = windowData.curY;
    windowData.curX = windowData.windowSpr.x + 84;
    windowData.addStepper("startValue", "Start Value", event.startValue, 0.01, 0.1);

    windowData.curX = windowData.windowSpr.x + windowData.windowSpr.bWidth - 204;
    windowData.curY = firstRowY;
    windowData.addStepper("value", "Value", event.value, 0.01, 0.1);

    windowData.curX = windowData.windowSpr.x + (windowData.windowSpr.bWidth / 2) - 60;
    windowData.curY = firstRowY + 84;
    windowData.addStepper("time", "Time", event.time, 0.25, 4);
}

function saveEventWindow(event, propertyMap) {
    event.startValue = propertyMap.get("startValue").value;
    event.value = propertyMap.get("value").value;
    event.time = propertyMap.get("time").value;
    event.ease = STAGE_COLOR_EASE;
}
