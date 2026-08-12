//
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;


function createEventGame(typeID, node, itemIndex) {
    return {
        "type": typeID,
        "step": Std.parseFloat(node.get("step")),
        "itemIndex": itemIndex,
        "value": Std.parseFloat(node.get("value")) * (downscroll && node.exists("DI_value") && node.get("DI_value") == "true" ? -1 : 1),
        "time": Std.parseFloat(node.get("time")),
        "ease": CoolUtil.flxeaseFromString(node.get("ease"), ""),
        "startValue": Std.parseFloat(node.get("startValue")) * (downscroll && node.exists("DI_startValue") && node.get("DI_startValue") == "true" ? -1 : 1)
    };
}
function getItemNameFromXML(node) {
    return node.get("name") + "." + node.get("property");
}

function getShaderItemType(item) {
    if (item != null && Reflect.hasField(item, "uniformType") && item.uniformType != null)
        return Std.string(item.uniformType).toLowerCase();
    return "float";
}

function setTweenShaderFloat(item, value:Float) {
    if (item == null || item.object == null) return;
    var uniformName = Reflect.hasField(item, "uniformName") && item.uniformName != null ? item.uniformName : item.property;
    var uniformType = getShaderItemType(item);
    var componentIndex = Reflect.hasField(item, "componentIndex") && item.componentIndex != null ? Std.int(item.componentIndex) : -1;
    var parameter = item.object.data == null ? null : Reflect.field(item.object.data, uniformName);

    if (componentIndex >= 0) {
        if (parameter != null && parameter.value != null && parameter.value.length > componentIndex) {
            parameter.value[componentIndex] = value;
        } else {
            var count = uniformType == "vec2" ? 2 : (uniformType == "vec4" ? 4 : 3);
            var values = [];
            for (i in 0...count) values.push(i == componentIndex ? value : 0.0);
            item.object.hset(uniformName, values);
        }
        return;
    }

    var typedValue:Dynamic = switch(uniformType) {
        case "bool": value >= 0.5;
        case "int": Std.int(Math.round(value));
        default: value;
    };
    if (parameter != null && parameter.value != null && parameter.value.length > 0)
        parameter.value[0] = typedValue;
    else
        item.object.hset(uniformName, typedValue);
}
function updateEventGame(currentStep, e) {
    var item = modchartItems[e.itemIndex];
    if (e.time > 0 && currentStep < e.step + e.time) {
        var l = (currentStep - e.step) / e.time;
        setTweenShaderFloat(item, FlxMath.lerp(e.startValue, e.value, e.ease(l)));
        return false; //dont remove yet
    }
    setTweenShaderFloat(item, e.value);
    return true;
}

function createEventEditor(name, step, item) {
    var separator = name.indexOf(".");
    var shaderName = separator < 0 ? name : name.substr(0, separator);
    var propertyName = separator < 0 ? "" : name.substr(separator + 1);
    var uniformType = getShaderItemType(item);
    return {
        "type": "tweenShaderProperty",
        "step": step,
        "name": shaderName,
        "property": propertyName,
        "value": 0,
        "time": uniformType == "bool" ? 0 : 4,
        "ease": uniformType == "bool" ? "linear" : "cubeInOut",
        "startValue": item.currentValue,
        "lastValue": 0,
        "uniformType": uniformType
    };
}

function updateEventEditor(currentStep, e, item) {
    if (e.time > 0 && currentStep < e.step + e.time) {
        var easeFunc:Float->Float = CoolUtil.flxeaseFromString(e.ease, "");

        var startVMult:Float = (e.DI_startValue != null && e.DI_startValue && downscroll) ? -1.0 : 1.0;
        var vMult:Float = (e.DI_value != null && e.DI_value && downscroll) ? -1.0 : 1.0;

        var l = (currentStep - e.step) * ((1) / ((e.step+e.time) - e.step));
        var newValue = FlxMath.lerp(e.startValue*startVMult, e.value*vMult, easeFunc(l));

        item.currentValue = newValue;
    } else {
        var vMult:Float = (e.DI_value != null && e.DI_value && downscroll) ? -1.0 : 1.0;
        item.currentValue = e.value*vMult;
    }
}

function copyEventEditor(e) {
    return {
        "type": e.type,
        "step": e.step,
        "name": e.name,
        "property": e.property,
        "value": e.value,
        "time": e.time,
        "ease": e.ease,
        "startValue": e.startValue,
        "lastValue": e.lastValue,
        "DI_value": e.DI_value,
        "DI_startValue": e.DI_startValue,
        "uniformType": e.uniformType
    };
}

function eventFromXMLEditor(node) {

    var event = {
        "type": node.get("type"),
        "step": Std.parseFloat(node.get("step")),
        "name": node.get("name"),
        "property": node.get("property"),
        "value": Std.parseFloat(node.get("value")),
        "time": Std.parseFloat(node.get("time")),
        "ease": node.get("ease"),
        "startValue": Std.parseFloat(node.get("startValue")),
        "lastValue": 0,
        "uniformType": node.exists("uniformType") ? node.get("uniformType") : "float"
    };

    if (node.exists("DI_startValue")) {
        event.DI_startValue = node.get("DI_startValue") == "true";
    }
    if (node.exists("DI_value")) {
        event.DI_value = node.get("DI_value") == "true";
    }

    return event;
}

function eventToXMLEditor(node, e) {
    node.set("name", e.name);
    node.set("property", e.property);
    node.set("value", e.value);
    node.set("time", e.time);
    node.set("ease", e.ease);
    node.set("startValue", e.startValue);
    if (e.uniformType != null && e.uniformType != "float") node.set("uniformType", e.uniformType);
    
    if (e.DI_startValue != null && e.DI_startValue) {
        node.set("DI_startValue", e.DI_startValue);
    }
    if (e.DI_value != null && e.DI_value) {
        node.set("DI_value", e.DI_value);
    }
}
function getItemName(e) {
    return e.name + "." + e.property;
}
function getDisplayName(e) {
    return e != null && e.uniformType == "bool" ? "Set Shader Bool" : "Tween Shader Property";
}
function getEventWindowWidth() {
    return 960;
}
function getEventWindowHeight() {
    return 420;
}
function setupEventWindow(event, propertyMap, windowData) {
    windowData.state.add(new UIText(windowData.curX, windowData.curY, 0, getItemName(event), 24));
    windowData.curY += 28 + 50;

    if (event.uniformType == "bool") {
        windowData.addCheckbox("boolValue", "Enabled", event.value >= 0.5);
        return;
    }

    var temp = windowData.curY;
    windowData.curX += 115;
    
    windowData.curY -= 50;
    windowData.createEaseBoxes();
    windowData.curY += 50;

    windowData.addStepper("startValue", "Start Value", event.startValue);

    windowData.curX -= 65;
    windowData.addCheckbox("DI_startValue", "Inverse on Downscroll?", event.DI_startValue != null ? event.DI_startValue : false);
    windowData.curX += 65;

    windowData.curY = temp;
    windowData.curX += 600;
    windowData.addStepper("value", "End Value", event.value);
    
    windowData.curX -= 65;
    windowData.addCheckbox("DI_value", "Inverse on Downscroll?", event.DI_value != null ? event.DI_value : false);
    windowData.curX += 65;

    windowData.curY += 100;
    //TODO: change to textbox instead
    var dropdown = new UIDropDown(windowData.windowSpr.x+(windowData.windowSpr.bWidth/2)-150, windowData.curY, 320, 32, easeList, easeList.indexOf(event.ease));
    propertyMap.set("ease", dropdown);
    var changeEaseFunc = windowData.changeEaseFunc;
    dropdown.onChange = function(index) {
        changeEaseFunc(CoolUtil.flxeaseFromString(easeList[index], ""));
    };
    windowData.state.add(dropdown);

    windowData.curY -= 28;
    windowData.addStepper("time", "Tween Length (steps)", event.time, 1, 4);
}
function saveEventWindow(event, propertyMap) {
    if (event.uniformType == "bool") {
        event.startValue = event.value;
        event.value = propertyMap.get("boolValue").checked ? 1.0 : 0.0;
        event.time = 0;
        event.ease = "linear";
        event.DI_startValue = false;
        event.DI_value = false;
        return;
    }

    propertyMap.get("startValue").__onChange(propertyMap.get("startValue").label.text);
    propertyMap.get("value").__onChange(propertyMap.get("value").label.text);
    propertyMap.get("time").__onChange(propertyMap.get("time").label.text);

    event.startValue = propertyMap.get("startValue").value;
    event.value = propertyMap.get("value").value;
    event.ease = easeList[propertyMap.get("ease").index];
    event.time = propertyMap.get("time").value;

    event.DI_startValue = propertyMap.get("DI_startValue").checked;
    event.DI_value = propertyMap.get("DI_value").checked;
}
