//
import haxe.io.Bytes;
import Xml;

var stageHueShader = null;
var stageHueGameItem = null;

function getItemTypeName() {
    return "stageHue";
}

function getEventNameFromItem(item) {
	// Stage hue tweens always use linear easing (see tweenStageHue.hx).
	return "tweenStageHue";
}

function getStageHueEaseName() {
	return "linear";
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

function applyStageHueShader(shader) {
    stageHueShader = shader;
    var daStage = getStageHueStage();
    if (shader == null || daStage == null || daStage.stageSprites == null) return;

    for (name => obj in daStage.stageSprites) {
        if (obj != null) {
            obj.shader = shader;
        }
    }
}

function setStageHueValue(shader, value) {
    if (shader == null) return;

    try {
        shader.hset("hue", value);
    } catch(e:Dynamic) {
        Reflect.setProperty(shader, "hue", value);
    }

    try {
        scripts.call("setRTXHue", [value]);
    } catch(e:Dynamic) {}

    applyStageHueShader(shader);
}

function createStageHueShader(defaultValue) {
    var shader = new CustomShader("colorswap");
    setStageHueValue(shader, defaultValue);
    applyStageHueShader(shader);
    return shader;
}

function createStageHueItem(defaultValue) {
    var shader = createStageHueShader(defaultValue);

    stageHueGameItem = createModchartItem("stageHue.hue", "hue", getItemTypeName(), defaultValue, shader);
    return stageHueGameItem;
}

function setupDefaultsGame() {
    if (stageHueGameItem == null) {
        createStageHueItem(0.0);
    }
}

function setupItemsFromXMLGame(xml) {
    for (node in xml.elementsNamed("StageHue")) {
        var value = node.exists("value") ? Std.parseFloat(node.get("value")) : 0.0;
        var shader = createStageHueShader(value);
        if (stageHueGameItem == null) {
            createStageHueItem(value);
        } else {
            stageHueGameItem.value = value;
            stageHueGameItem.object = shader;
        }
    }
}

function setupItemsFromXMLEditor(xml) {
    for (node in xml.elementsNamed("StageHue")) {
        var value = node.exists("value") ? Std.parseFloat(node.get("value")) : 0.0;
        var item = timelineIndexMap.exists("stageHue.hue") ? timelineItems[timelineIndexMap.get("stageHue.hue")] : createTimelineItem("stageHue.hue", getItemTypeName(), null);
        var shader = createStageHueShader(value);
        item.object = shader;
        item.property = "hue";
        item.defaultValue = value;
    }
}

function setupDefaultsEditor() {
    if (timelineIndexMap.exists("stageHue.hue")) return;

    var item = createTimelineItem("stageHue.hue", getItemTypeName(), createStageHueShader(0.0));
    item.property = "hue";
    item.defaultValue = 0.0;
}

function copyXMLItems(xml, output, packaged) {
    for (e in xml.elementsNamed("StageHue")) {
        var item = Xml.createElement("StageHue");
        for (att in e.attributes()) {
            item.set(att, e.get(att));
        }

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
    if (text != null) {
        text.text = Std.string(FlxMath.roundDecimal(item.currentValue, 2));
    }

    setStageHueValue(item.object, item.currentValue);
}

function postXMLLoad(xml) {
    applyStageHueShader(stageHueShader);
}

function postXMLLoadGame(xml) {
    applyStageHueShader(stageHueShader);
}

function onStageChanged(n) {
    applyStageHueShader(stageHueShader);
}

function reloadItems() {}
