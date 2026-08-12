import haxe.io.Bytes;
import Xml;

var stageColorShader = null;
var stageColorGameItems = [];
var stageColorApplyHUD:Bool = false;
var stageColorGameCamera = null;
var stageColorGameShader = null;
var stageColorHUDCamera = null;
var stageColorHUDShader = null;

function getItemTypeName() {
    return "stageColor";
}

function getEventNameFromItem(item) {
    return "tweenStageColor";
}

function getStageColorGameCamera() {
    var camera = null;
    try {
        camera = camGame;
    } catch(e:Dynamic) {}
    if (camera == null) {
        try {
            camera = Reflect.getProperty(FlxG.state, "camGame");
        } catch(e:Dynamic) {}
    }
    if (camera == null) {
        try {
            camera = Reflect.getProperty(PlayState.instance, "camGame");
        } catch(e:Dynamic) {}
    }
    return camera;
}

function getStageColorHUDCamera() {
    var camera = null;
    try {
        camera = camHUD;
    } catch(e:Dynamic) {}
    if (camera == null) {
        try {
            camera = Reflect.getProperty(FlxG.state, "camHUD");
        } catch(e:Dynamic) {}
    }
    if (camera == null) {
        try {
            camera = Reflect.getProperty(PlayState.instance, "camHUD");
        } catch(e:Dynamic) {}
    }
    return camera;
}

function removeStageColorShader(camera, shader) {
    if (camera == null || shader == null) return;
    try {
        camera.removeShader(shader);
    } catch(e:Dynamic) {}
}

function clearStageColorShaders() {
    removeStageColorShader(stageColorGameCamera, stageColorGameShader);
    removeStageColorShader(stageColorHUDCamera, stageColorHUDShader);
    stageColorGameCamera = null;
    stageColorGameShader = null;
    stageColorHUDCamera = null;
    stageColorHUDShader = null;
}

function applyStageColorShader(shader) {
    stageColorShader = shader;
    var game = getStageColorGameCamera();
    var hud = getStageColorHUDCamera();

    if (stageColorGameCamera != game || stageColorGameShader != shader) {
        removeStageColorShader(stageColorGameCamera, stageColorGameShader);
        stageColorGameCamera = null;
        stageColorGameShader = null;
        if (game != null && shader != null) {
            try {
                game.addShader(shader);
                stageColorGameCamera = game;
                stageColorGameShader = shader;
            } catch(e:Dynamic) {
                trace("stageColor: could not add color.frag to camGame: " + e);
            }
        }
    }

    if (!stageColorApplyHUD || hud == null || shader == null) {
        removeStageColorShader(stageColorHUDCamera, stageColorHUDShader);
        stageColorHUDCamera = null;
        stageColorHUDShader = null;
    } else if (stageColorHUDCamera != hud || stageColorHUDShader != shader) {
        removeStageColorShader(stageColorHUDCamera, stageColorHUDShader);
        stageColorHUDCamera = null;
        stageColorHUDShader = null;
        try {
            hud.addShader(shader);
            stageColorHUDCamera = hud;
            stageColorHUDShader = shader;
        } catch(e:Dynamic) {
            trace("stageColor: could not add color.frag to camHUD: " + e);
        }
    }
}

function setStageColorUniform(shader, property, value) {
    if (shader == null) return;
    try {
        shader.hset(property, value);
    } catch(e:Dynamic) {
        Reflect.setProperty(shader, property, value);
    }
}

function setStageColorValue(shader, property, value) {
    setStageColorUniform(shader, property, value);
    applyStageColorShader(shader);
}

function getStageColorNodeValue(node, property, fallback) {
    if (!node.exists(property)) return fallback;
    var value = Std.parseFloat(node.get(property));
    return Math.isNaN(value) ? fallback : value;
}

function getStageColorNodeValues(node) {
    return {
        temperature: getStageColorNodeValue(node, "temperature", 0.0),
        saturation: getStageColorNodeValue(node, "saturation", 1.0),
        contrast: getStageColorNodeValue(node, "contrast", 1.0)
    };
}

function getStageColorPropertyValue(values, property) {
    return switch(property) {
        case "saturation": values.saturation;
        case "contrast": values.contrast;
        default: values.temperature;
    };
}

function createStageColorShader(temperature, saturation, contrast) {
    var shader = new CustomShader("color");
    setStageColorUniform(shader, "temperature", temperature);
    setStageColorUniform(shader, "saturation", saturation);
    setStageColorUniform(shader, "contrast", contrast);
    stageColorShader = shader;
    return shader;
}

function hasStageColorEvents(xml) {
    if (xml == null) return false;
    for (list in xml.elementsNamed("Events")) {
        for (event in list.elementsNamed("Event")) {
            if (event.get("type") == "tweenStageColor") return true;
        }
    }
    return false;
}

function createStageColorGameItems(shader, values) {
    stageColorGameItems = [];
    stageColorGameItems.push(createModchartItem("stageColor.temperature", "temperature", getItemTypeName(), values.temperature, shader));
    stageColorGameItems.push(createModchartItem("stageColor.saturation", "saturation", getItemTypeName(), values.saturation, shader));
    stageColorGameItems.push(createModchartItem("stageColor.contrast", "contrast", getItemTypeName(), values.contrast, shader));
}

function bindStageColorGameItems(shader, values) {
    if (stageColorGameItems.length == 0) {
        createStageColorGameItems(shader, values);
        return;
    }

    for (item in stageColorGameItems) {
        item.object = shader;
        item.value = getStageColorPropertyValue(values, item.property);
    }
}

function setupDefaultsGame() {
    if (stageColorGameItems.length > 0) return;
    var values = {temperature: 0.0, saturation: 1.0, contrast: 1.0};
    createStageColorGameItems(createStageColorShader(values.temperature, values.saturation, values.contrast), values);
}

function setupItemsFromXMLGame(xml) {
    for (node in xml.elementsNamed("StageColor")) {
        var values = getStageColorNodeValues(node);
        stageColorApplyHUD = node.exists("camHUD") && node.get("camHUD") == "true";
        var shader = createStageColorShader(values.temperature, values.saturation, values.contrast);
        bindStageColorGameItems(shader, values);
        applyStageColorShader(shader);
    }
}

function setupStageColorTimelineItem(property, defaultValue, shader) {
    var name = "stageColor." + property;
    var item = timelineIndexMap.exists(name)
        ? timelineItems[timelineIndexMap.get(name)]
        : createTimelineItem(name, getItemTypeName(), shader);
    item.object = shader;
    item.property = property;
    item.defaultValue = defaultValue;
    return item;
}

function setupItemsFromXMLEditor(xml) {
    for (node in xml.elementsNamed("StageColor")) {
        var values = getStageColorNodeValues(node);
        stageColorApplyHUD = node.exists("camHUD") && node.get("camHUD") == "true";
        var shader = createStageColorShader(values.temperature, values.saturation, values.contrast);
        setupStageColorTimelineItem("temperature", values.temperature, shader);
        setupStageColorTimelineItem("saturation", values.saturation, shader);
        setupStageColorTimelineItem("contrast", values.contrast, shader);
        applyStageColorShader(shader);
    }
}

function setupDefaultsEditor() {
    if (timelineIndexMap.exists("stageColor.temperature") && timelineIndexMap.exists("stageColor.saturation") && timelineIndexMap.exists("stageColor.contrast")) return;

    var shader = createStageColorShader(0.0, 1.0, 1.0);
    setupStageColorTimelineItem("temperature", 0.0, shader);
    setupStageColorTimelineItem("saturation", 1.0, shader);
    setupStageColorTimelineItem("contrast", 1.0, shader);
    applyStageColorShader(shader);
}

function copyXMLItems(xml, output, packaged) {
    for (e in xml.elementsNamed("StageColor")) {
        var item = Xml.createElement("StageColor");
        for (att in e.attributes()) item.set(att, e.get(att));

        if (packaged) {
            var path = "shaders/color";
            item.set("fragCode", Assets.exists(path + ".frag") ? Bytes.ofString(Assets.getText(path + ".frag")).toHex() : "");
            item.set("vertCode", Assets.exists(path + ".vert") ? Bytes.ofString(Assets.getText(path + ".vert")).toHex() : "");
        }

        output.addChild(item);
    }
}

function updateItem(item, i) {
    var text = timelineUIList[i].valueText;
    if (text != null) text.text = Std.string(FlxMath.roundDecimal(item.currentValue, 2));
    setStageColorValue(item.object, item.property, item.currentValue);
}

function postXMLLoad(xml) {
    if (xml != null && xml.exists("stageColorCamHUD"))
        stageColorApplyHUD = xml.get("stageColorCamHUD") == "true";
    applyStageColorShader(stageColorShader);
}

function postXMLLoadGame(xml) {
    if (xml != null && xml.exists("stageColorCamHUD"))
        stageColorApplyHUD = xml.get("stageColorCamHUD") == "true";
    if (stageColorGameShader != null || hasStageColorEvents(xml))
        applyStageColorShader(stageColorShader);
}

function reloadItems() {
    clearStageColorShaders();
    stageColorShader = null;
    stageColorGameItems = [];
    stageColorApplyHUD = false;
}

function destroy() {
    clearStageColorShaders();
}
