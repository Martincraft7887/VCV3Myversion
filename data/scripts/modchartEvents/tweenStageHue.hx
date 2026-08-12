import funkin.editors.ui.UIText;

var STAGE_HUE_EASE = "linear";

function getStageHueEaseFunc():Float->Float {
    return CoolUtil.flxeaseFromString(STAGE_HUE_EASE, "");
}

function normalizeStageHueProperty(property) {
    return switch(property) {
        case "saturation": "sat";
        case "brightness": "brt";
        case "sat" | "brt" | "hue": property;
        default: "hue";
    };
}

function getStageHuePropertyFromXML(node) {
    return normalizeStageHueProperty(node.exists("property") ? node.get("property") : "hue");
}

function createEventGame(typeID, node, itemIndex) {
    return {
        "type": typeID,
        "step": Std.parseFloat(node.get("step")),
        "itemIndex": itemIndex,
        "property": getStageHuePropertyFromXML(node),
        "value": Std.parseFloat(node.get("value")),
        "time": Std.parseFloat(node.get("time")),
        "ease": getStageHueEaseFunc(),
        "startValue": Std.parseFloat(node.get("startValue"))
    };
}

function getItemNameFromXML(node) {
    return "stageHue." + getStageHuePropertyFromXML(node);
}

function setStageHueItemValue(item, value) {
    if (item == null || item.object == null) return;

    var parameter = item.object.data == null ? null : Reflect.field(item.object.data, item.property);
    if (parameter != null && parameter.value != null && parameter.value.length > 0)
        parameter.value[0] = value;
    else
        item.object.hset(item.property, value);

    if (item.property == "hue") {
        try {
            scripts.call("setRTXHue", [value]);
        } catch(err:Dynamic) {}
    }
}

function updateEventGame(currentStep, e) {
    var item = modchartItems[e.itemIndex];
    if (e.time > 0 && currentStep < e.step + e.time) {
        var l = (currentStep - e.step) / e.time;
        setStageHueItemValue(item, FlxMath.lerp(e.startValue, e.value, e.ease(l)));
        return false;
    }

    setStageHueItemValue(item, e.value);
    return true;
}

function createEventEditor(name, step, item) {
    return {
        "type": "tweenStageHue",
        "step": step,
        "property": normalizeStageHueProperty(item.property),
        "value": 0,
        "time": 4,
        "ease": STAGE_HUE_EASE,
        "startValue": item.currentValue,
        "lastValue": 0
    };
}

function updateEventEditor(currentStep, e, item) {
    var easeFunc = getStageHueEaseFunc();
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
        "property": normalizeStageHueProperty(e.property),
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
        "property": getStageHuePropertyFromXML(node),
        "value": Std.parseFloat(node.get("value")),
        "time": Std.parseFloat(node.get("time")),
        "ease": STAGE_HUE_EASE,
        "startValue": Std.parseFloat(node.get("startValue")),
        "lastValue": 0
    };
}

function eventToXMLEditor(node, e) {
    node.set("property", normalizeStageHueProperty(e.property));
    node.set("value", e.value);
    node.set("time", e.time);
    node.set("ease", STAGE_HUE_EASE);
    node.set("startValue", e.startValue);
}

function getItemName(e) {
    return "stageHue." + normalizeStageHueProperty(e.property);
}

function getStageHuePropertyDisplayName(property) {
    return switch(normalizeStageHueProperty(property)) {
        case "sat": "Saturation";
        case "brt": "Brightness";
        default: "Hue";
    };
}

function getDisplayName(e) {
    return "Tween Stage " + getStageHuePropertyDisplayName(e.property);
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
    event.ease = STAGE_HUE_EASE;
}
