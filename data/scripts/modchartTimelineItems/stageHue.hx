import haxe.io.Bytes;
import Xml;

var stageHueShader = null;
var stageHueGameItems = [];
var stageHueApplyHUD:Bool = false;
var stageHueHUDShader = null;
var stageHueHUDCamera = null;

function getItemTypeName() {
    return "stageHue";
}

function getEventNameFromItem(item) {
    return "tweenStageHue";
}

function getStageHueStage() {
    var daStage = null;
    try {
        daStage = Reflect.field(FlxG.state, "stage");
    } catch(e:Dynamic) {}
    if (daStage == null) {
        try {
            daStage = Reflect.field(PlayState.instance, "stage");
        } catch(e:Dynamic) {}
    }
    return daStage;
}

function getStageHueHUDCamera() {
    var hud = null;
    try {
        hud = Reflect.field(FlxG.state, "camHUD");
    } catch(e:Dynamic) {}
    if (hud == null) {
        try {
            hud = Reflect.field(PlayState.instance, "camHUD");
        } catch(e:Dynamic) {}
    }
    return hud;
}

function clearStageHueHUDShader() {
    if (stageHueHUDCamera != null && stageHueHUDShader != null) {
        try {
            stageHueHUDCamera.removeShader(stageHueHUDShader);
        } catch(e:Dynamic) {}
    }
    stageHueHUDCamera = null;
    stageHueHUDShader = null;
}

function applyStageHueHUDShader(shader) {
    var hud = getStageHueHUDCamera();
    if (!stageHueApplyHUD || shader == null || hud == null) {
        clearStageHueHUDShader();
        return;
    }

    if (stageHueHUDCamera == hud && stageHueHUDShader == shader) return;

    clearStageHueHUDShader();
    try {
        hud.addShader(shader);
        stageHueHUDCamera = hud;
        stageHueHUDShader = shader;
    } catch(e:Dynamic) {}
}

function applyStageHueShader(shader) {
    stageHueShader = shader;
    var daStage = getStageHueStage();
    if (shader != null && daStage != null && daStage.stageSprites != null) {
        for (name => obj in daStage.stageSprites) {
            if (obj != null) obj.shader = shader;
        }
    }
    applyStageHueHUDShader(shader);
}

function setStageHueUniform(shader, property, value) {
    if (shader == null) return;

    try {
        shader.hset(property, value);
    } catch(e:Dynamic) {
        Reflect.setProperty(shader, property, value);
    }
}

function setStageHueValue(shader, property, value) {
    if (shader == null) return;

    setStageHueUniform(shader, property, value);
    if (property == "hue") {
        try {
            scripts.call("setRTXHue", [value]);
        } catch(e:Dynamic) {}
    }
    applyStageHueShader(shader);
}

function getStageHueNodeValue(node, property, alias, fallback) {
    var value = fallback;
    if (node.exists(property)) {
        value = Std.parseFloat(node.get(property));
    } else if (alias != null && node.exists(alias)) {
        value = Std.parseFloat(node.get(alias));
    }
    return Math.isNaN(value) ? fallback : value;
}

function getStageHueNodeValues(node) {
    var legacyHue = node.exists("value") ? Std.parseFloat(node.get("value")) : 0.0;
    if (Math.isNaN(legacyHue)) legacyHue = 0.0;

    return {
        hue: getStageHueNodeValue(node, "hue", null, legacyHue),
        sat: getStageHueNodeValue(node, "sat", "saturation", 0.0),
        brt: getStageHueNodeValue(node, "brt", "brightness", 0.0)
    };
}

function getStageHuePropertyValue(values, property) {
    return switch(property) {
        case "sat": values.sat;
        case "brt": values.brt;
        default: values.hue;
    };
}

function createStageHueShader(hue, sat, brt) {
    var shader = new CustomShader("colorswap");
    setStageHueUniform(shader, "hue", hue);
    setStageHueUniform(shader, "sat", sat);
    setStageHueUniform(shader, "brt", brt);
    try {
        scripts.call("setRTXHue", [hue]);
    } catch(e:Dynamic) {}
    applyStageHueShader(shader);
    return shader;
}

function createStageHueGameItems(shader, values) {
    stageHueGameItems = [];
    stageHueGameItems.push(createModchartItem("stageHue.hue", "hue", getItemTypeName(), values.hue, shader));
    stageHueGameItems.push(createModchartItem("stageHue.sat", "sat", getItemTypeName(), values.sat, shader));
    stageHueGameItems.push(createModchartItem("stageHue.brt", "brt", getItemTypeName(), values.brt, shader));
}

function bindStageHueGameItems(shader, values) {
    if (stageHueGameItems.length == 0) {
        createStageHueGameItems(shader, values);
        return;
    }

    for (item in stageHueGameItems) {
        item.object = shader;
        item.value = getStageHuePropertyValue(values, item.property);
    }
}

function setupDefaultsGame() {
    if (stageHueGameItems.length > 0) return;

    var values = {hue: 0.0, sat: 0.0, brt: 0.0};
    createStageHueGameItems(createStageHueShader(values.hue, values.sat, values.brt), values);
}

function setupItemsFromXMLGame(xml) {
    for (node in xml.elementsNamed("StageHue")) {
        var values = getStageHueNodeValues(node);
        stageHueApplyHUD = node.exists("camHUD") && node.get("camHUD") == "true";
        var shader = createStageHueShader(values.hue, values.sat, values.brt);
        bindStageHueGameItems(shader, values);
    }
}

function setupStageHueTimelineItem(property, defaultValue, shader) {
    var name = "stageHue." + property;
    var item = timelineIndexMap.exists(name)
        ? timelineItems[timelineIndexMap.get(name)]
        : createTimelineItem(name, getItemTypeName(), shader);
    item.object = shader;
    item.property = property;
    item.defaultValue = defaultValue;
    return item;
}

function setupItemsFromXMLEditor(xml) {
    for (node in xml.elementsNamed("StageHue")) {
        var values = getStageHueNodeValues(node);
        stageHueApplyHUD = node.exists("camHUD") && node.get("camHUD") == "true";
        var shader = createStageHueShader(values.hue, values.sat, values.brt);
        setupStageHueTimelineItem("hue", values.hue, shader);
        setupStageHueTimelineItem("sat", values.sat, shader);
        setupStageHueTimelineItem("brt", values.brt, shader);
    }
}

function setupDefaultsEditor() {
    if (timelineIndexMap.exists("stageHue.hue") && timelineIndexMap.exists("stageHue.sat") && timelineIndexMap.exists("stageHue.brt")) return;

    var shader = createStageHueShader(0.0, 0.0, 0.0);
    setupStageHueTimelineItem("hue", 0.0, shader);
    setupStageHueTimelineItem("sat", 0.0, shader);
    setupStageHueTimelineItem("brt", 0.0, shader);
}

function copyXMLItems(xml, output, packaged) {
    for (e in xml.elementsNamed("StageHue")) {
        var item = Xml.createElement("StageHue");
        for (att in e.attributes()) item.set(att, e.get(att));

        if (packaged) {
            var path = "shaders/colorswap";
            item.set("fragCode", Assets.exists(path + ".frag") ? Bytes.ofString(Assets.getText(path + ".frag")).toHex() : "");
            item.set("vertCode", Assets.exists(path + ".vert") ? Bytes.ofString(Assets.getText(path + ".vert")).toHex() : "");
        }

        output.addChild(item);
    }
}

function updateItem(item, i) {
    var text = timelineUIList[i].valueText;
    if (text != null) text.text = Std.string(FlxMath.roundDecimal(item.currentValue, 2));
    setStageHueValue(item.object, item.property, item.currentValue);
}

function postXMLLoad(xml) {
    if (xml != null && xml.exists("stageHueCamHUD"))
        stageHueApplyHUD = xml.get("stageHueCamHUD") == "true";
    applyStageHueShader(stageHueShader);
}

function postXMLLoadGame(xml) {
    if (xml != null && xml.exists("stageHueCamHUD"))
        stageHueApplyHUD = xml.get("stageHueCamHUD") == "true";
    applyStageHueShader(stageHueShader);
}

function onStageChanged(n) {
    applyStageHueShader(stageHueShader);
}

function reloadItems() {
    clearStageHueHUDShader();
    stageHueShader = null;
    stageHueGameItems = [];
    stageHueApplyHUD = false;
}

function destroy() {
    clearStageHueHUDShader();
}
