//
import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UISprite;
import haxe.io.Path;
import haxe.io.Bytes;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIColorwheel;
import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIAutoCompleteTextBox;
import funkin.backend.utils.IniUtil;
import Xml;

function normalizeUniformType(type) {
    if (type == null) return null;
    var value = StringTools.trim(Std.string(type)).toLowerCase();
    return switch(value) {
        case "float" | "int" | "bool" | "vec2" | "vec3" | "vec4": value;
        default: null;
    };
}

function uniformComponentCount(type) {
    return switch(normalizeUniformType(type)) {
        case "vec2": 2;
        case "vec3": 3;
        case "vec4": 4;
        default: 1;
    };
}

function isColorUniform(name) {
    var lower = Std.string(name).toLowerCase();
    return lower.indexOf("color") >= 0 || lower.indexOf("colour") >= 0 || lower.indexOf("rgb") >= 0 || StringTools.startsWith(lower, "col") || StringTools.endsWith(lower, "col");
}

function getUniformComponents(name, type) {
    var count = uniformComponentCount(type);
    var names = isColorUniform(name) ? ["r", "g", "b", "a"] : ["x", "y", "z", "w"];
    return names.slice(0, count);
}

function stripIniQuotes(value) {
    value = StringTools.trim(value == null ? "" : Std.string(value));
    if (value.length >= 2 && ((StringTools.startsWith(value, "\"") && StringTools.endsWith(value, "\"")) || (StringTools.startsWith(value, "'") && StringTools.endsWith(value, "'"))))
        value = value.substr(1, value.length - 2);
    return StringTools.trim(value);
}

function parseBoolValue(value) {
    var lower = stripIniQuotes(value).toLowerCase();
    return lower == "true" || lower == "yes" || lower == "on" || lower == "1";
}

function parseUniformNumber(value, fallback:Float = 0) {
    var parsed = Std.parseFloat(stripIniQuotes(value));
    return Math.isNaN(parsed) ? fallback : parsed;
}

function getShaderUniformTypes(shaderName) {
    var types = ["" => ""];
    types.remove("");

    for (extension in ["frag", "vert"]) {
        var path = "shaders/modcharts/" + shaderName + "." + extension;
        if (!Assets.exists(path)) continue;

        for (rawLine in Assets.getText(path).split("\n")) {
            var line = StringTools.trim(rawLine);
            var comment = line.indexOf("//");
            if (comment >= 0) line = StringTools.trim(line.substr(0, comment));
            if (!StringTools.startsWith(line, "uniform ")) continue;

            line = StringTools.replace(line, "\t", " ");
            while (line.indexOf("  ") >= 0) line = StringTools.replace(line, "  ", " ");
            var tokens = line.split(" ");
            var typeIndex = 1;
            if (tokens.length > 3 && (tokens[typeIndex] == "lowp" || tokens[typeIndex] == "mediump" || tokens[typeIndex] == "highp")) typeIndex++;
            if (tokens.length <= typeIndex + 1) continue;

            var type = normalizeUniformType(tokens[typeIndex]);
            if (type == null) continue;
            var name = tokens[typeIndex + 1];
            var semicolon = name.indexOf(";");
            if (semicolon >= 0) name = name.substr(0, semicolon);
            var arrayStart = name.indexOf("[");
            if (arrayStart >= 0) name = name.substr(0, arrayStart);
            if (name != "") types.set(name, type);
        }
    }
    return types;
}

function parseShaderProperty(name, rawValue, detectedType, declaredType = null) {
    var value = stripIniQuotes(rawValue);
    var type = normalizeUniformType(declaredType);

    for (candidate in ["bool", "int", "float", "vec2", "vec3", "vec4"]) {
        var lower = value.toLowerCase();
        var prefix = candidate + ":";
        var callPrefix = candidate + "(";
        if (StringTools.startsWith(lower, prefix)) {
            type = candidate;
            value = StringTools.trim(value.substr(prefix.length));
            break;
        }
        if (StringTools.startsWith(lower, callPrefix) && StringTools.endsWith(value, ")")) {
            type = candidate;
            value = StringTools.trim(value.substr(callPrefix.length, value.length - callPrefix.length - 1));
            break;
        }
    }

    if (type == null) type = normalizeUniformType(detectedType);
    if (type == null) {
        var lower = value.toLowerCase();
        if (lower == "true" || lower == "false" || lower == "yes" || lower == "no" || lower == "on" || lower == "off") {
            type = "bool";
        } else {
            var partCount = value.split(",").length;
            type = partCount >= 2 && partCount <= 4 ? "vec" + partCount : "float";
        }
    }

    var count = uniformComponentCount(type);
    var values = [];
    if (type == "bool") {
        values.push(parseBoolValue(value) ? 1.0 : 0.0);
    } else {
        var parts = value.split(",");
        for (i in 0...count) values.push(parseUniformNumber(i < parts.length ? parts[i] : "0"));
    }

    return {
        name: name,
        type: type,
        values: values,
        components: getUniformComponents(name, type)
    };
}

function getShaderNodeDefinitions(node) {
    var definitions = [];
    var uniformTypes = getShaderUniformTypes(node.get("shader"));
    for (prop in getOrderedShaderNodeProperties(node)) {
        definitions.push(parseShaderProperty(
            prop.get("name"),
            prop.get("value"),
            uniformTypes.get(prop.get("name")),
            prop.exists("type") ? prop.get("type") : null
        ));
    }
    return definitions;
}

function getIniDefinitions(shaderName, iniPath, iniData, order) {
    var definitions = [];
    var uniformTypes = getShaderUniformTypes(shaderName);
    for (key in order)
        definitions.push(parseShaderProperty(key, iniData.get(key), uniformTypes.get(key)));
    return definitions;
}

function copyUniformValues(values) {
    var result = [];
    if (values != null) for (value in values) result.push(value * 1.0);
    return result;
}

function applyShaderDefinition(shader, definition) {
    try {
        switch(definition.type) {
            case "bool": shader.hset(definition.name, definition.values[0] >= 0.5);
            case "int": shader.hset(definition.name, Std.int(Math.round(definition.values[0])));
            case "vec2" | "vec3" | "vec4": shader.hset(definition.name, copyUniformValues(definition.values));
            default: shader.hset(definition.name, definition.values[0] * 1.0);
        }
    } catch(e:Dynamic) {
        trace('[Modchart shader] Could not set uniform "' + definition.name + '" as ' + definition.type + ': ' + e);
    }
}

function addShaderItemMetadata(item, definition, componentIndex:Int = -1) {
    item.uniformName = definition.name;
    item.uniformType = definition.type;
    item.componentIndex = componentIndex;
}

function getTimelineProperty(definition, componentIndex:Int = -1) {
    return componentIndex < 0 ? definition.name : definition.name + "." + definition.components[componentIndex];
}

function createGameItems(shaderName, shader, definition) {
    applyShaderDefinition(shader, definition);
    var count = uniformComponentCount(definition.type);
    if (count == 1) {
        var item = createModchartItem(shaderName + "." + definition.name, definition.name, "shader", definition.values[0], shader);
        addShaderItemMetadata(item, definition);
        return;
    }

    for (i in 0...count) {
        var property = getTimelineProperty(definition, i);
        var item = createModchartItem(shaderName + "." + property, property, "shader", definition.values[i], shader);
        addShaderItemMetadata(item, definition, i);
    }
}

function createEditorItems(shaderName, shader, definition) {
    applyShaderDefinition(shader, definition);
    var count = uniformComponentCount(definition.type);
    if (count == 1) {
        var item = createTimelineItem(shaderName + "." + definition.name, getItemTypeName(), shader);
        item.property = definition.name;
        item.defaultValue = definition.values[0];
        addShaderItemMetadata(item, definition);
        return;
    }

    for (i in 0...count) {
        var property = getTimelineProperty(definition, i);
        var item = createTimelineItem(shaderName + "." + property, getItemTypeName(), shader);
        item.property = property;
        item.defaultValue = definition.values[i];
        addShaderItemMetadata(item, definition, i);
    }
}

function setShaderItemValue(item, value) {
    if (item == null || item.object == null) return;
    var uniformName = item.uniformName == null ? item.property : item.uniformName;
    var uniformType = normalizeUniformType(item.uniformType);
    if (uniformType == null) uniformType = "float";
    var componentIndex = item.componentIndex == null ? -1 : Std.int(item.componentIndex);
    var parameter = item.object.data == null ? null : Reflect.field(item.object.data, uniformName);

    try {
        if (componentIndex >= 0) {
            if (parameter != null && parameter.value != null && parameter.value.length > componentIndex) {
                parameter.value[componentIndex] = value * 1.0;
            } else {
                var values = [];
                for (i in 0...uniformComponentCount(uniformType)) values.push(i == componentIndex ? value * 1.0 : 0.0);
                item.object.hset(uniformName, values);
            }
        } else {
            var typedValue:Dynamic = switch(uniformType) {
                case "bool": value >= 0.5;
                case "int": Std.int(Math.round(value));
                default: value * 1.0;
            };
            if (parameter != null && parameter.value != null && parameter.value.length > 0)
                parameter.value[0] = typedValue;
            else
                item.object.hset(uniformName, typedValue);
        }
    } catch(e:Dynamic) {
        trace('[Modchart shader] Could not update uniform "' + uniformName + '": ' + e);
    }
}


function getItemTypeName() {
    return "shader";
}
function getEventNameFromItem(item) {
    return "tweenShaderProperty";
}

function setupItemsFromXMLGame(xml) {
    for (node in xml.elementsNamed("Shader")) {

        var path = "modcharts/" + node.get("shader");
        var s = new CustomShader(path);
        
        for (definition in getShaderNodeDefinitions(node))
            createGameItems(node.get("name"), s, definition);

        if (node.exists("camGame") && node.get("camGame") == "true") {
            camGame.addShader(s);
        }
        if (node.exists("camHUD") && node.get("camHUD") == "true") {
            camHUD.addShader(s);
        }
        if (node.exists("camOther") && node.get("camOther") == "true") {
            camOther.addShader(s);
        }
    }
}

function setupItemsFromXMLEditor(xml) {
    for (node in xml.elementsNamed("Shader")) {

        var path = "modcharts/" + node.get("shader");
        var s = new CustomShader(path);

        var tlStartIndex = timelineList.length;
        
        for (definition in getShaderNodeDefinitions(node))
            createEditorItems(node.get("name"), s, definition);

        if (node.exists("camGame") && node.get("camGame") == "true") {
            camGame.addShader(s);
        }
        if (node.exists("camHUD") && node.get("camHUD") == "true") {
            camHUD.addShader(s);
        }
        if (node.exists("camOther") && node.get("camOther") == "true") {
            camOther.addShader(s);
        }

        timelineGroups.push({
            startIndex: tlStartIndex,
            endIndex: timelineList.length,
            color: FlxColor.fromString(node.get("color")),
            bg: null
        });
    }
}
function copyXMLItems(xml, output, packaged) {
    for (e in xml.elementsNamed("Shader")) {

        var event = Xml.createElement("Shader");
        for (att in e.attributes()) {
            event.set(att, e.get(att));
        }

        if (packaged) {
            var path = "shaders/modcharts/" + event.get("shader");
            if (Assets.exists(path+".frag")) {
                event.set("fragCode", Bytes.ofString(Assets.getText(path+".frag")).toHex()); //ensures that shader code wont break xml parsing
            } else {
                event.set("fragCode", "");
            }
            if (Assets.exists(path+".vert")) {
                event.set("vertCode", Bytes.ofString(Assets.getText(path+".vert")).toHex());
            } else {
                event.set("vertCode", "");
            }
        }

        for (node in e.elementsNamed("Property")) {
            var prop = Xml.createElement("Property");
            for (att in node.attributes()) {
                prop.set(att, node.get(att));
            }
            event.addChild(prop);
        }

        output.addChild(event);
    }
}

function updateItem(item, i) {
    var text = timelineUIList[i].valueText;
    if (text != null) {
        text.text = item.uniformType == "bool" ? (item.currentValue >= 0.5 ? "true" : "false") : Std.string(FlxMath.roundDecimal(item.currentValue, 2));
    }

    setShaderItemValue(item, item.currentValue);
}

function reloadItems() {
    camGame._filters = [];
    camHUD._filters = [];
    camOther._filters = [];
}


//edit menu stuff
function isEditable() { return true; }
function getXMLNodeName() {return "Shader";}
function getEditButtonText() { return "Add Post Process Shader"; }

function setupItemData(data, node) {
    data.file = node.get("shader");
    data.camGame = node.get("camGame") == "true";
    data.camHUD = node.get("camHUD") == "true";
    data.camOther = node.get("camOther") == "true";
    data.properties = [];
    for (definition in getShaderNodeDefinitions(node)) data.properties.push(definition);
}
function setupDefaultItemData(data) {
    data.camGame = true;
    data.camHUD = false;
    data.camOther = false;
    data.properties = [];
}

function getAvailableFiles() {
    var files = [];
    for (path in Paths.getFolderContent('shaders/modcharts/', true, null)) {
        if (Path.extension(path) == "ini") {
            var file = CoolUtil.getFilename(path);
            if (!files.contains(file)) {
                files.push(file);
            }
        }
    }
    return files;
}

function getEditDisplayName() { return "Shader"; }
function getFolderDisplayName() { return "(shaders/modcharts/)"; }

function getOrderedIniProperties(path:String, iniData) {
    var order:Array<String> = [];
    if (!Assets.exists(path) || iniData == null) return order;

    for (rawLine in Assets.getText(path).split("\n")) {
        var line = StringTools.trim(rawLine);
        if (line == "" || StringTools.startsWith(line, ";") || StringTools.startsWith(line, "#") || StringTools.startsWith(line, "[")) continue;

        var separator = line.indexOf("=");
        if (separator < 0) continue;

        var key = StringTools.trim(line.substr(0, separator));
        if (key != "" && key != "desc" && iniData.exists(key) && !order.contains(key))
            order.push(key);
    }

    // Keep supporting values accepted by IniUtil even if their formatting was
    // not recognized above, while preserving file order whenever possible.
    for (key => val in iniData) {
        if (key != "" && key != "desc" && !order.contains(key))
            order.push(key);
    }

    return order;
}

function getOrderedShaderNodeProperties(node) {
    var properties = [];
    var ordered = [];
    for (prop in node.elementsNamed("Property")) properties.push(prop);

    var iniPath = "shaders/modcharts/" + node.get("shader") + ".ini";
    if (Assets.exists(iniPath)) {
        var iniData = IniUtil.parseAsset(iniPath).get("Global");
        for (key in getOrderedIniProperties(iniPath, iniData)) {
            for (prop in properties) {
                if (prop.get("name") == key && !ordered.contains(prop))
                    ordered.push(prop);
            }
        }
    }

    // Unknown or old properties are preserved after the INI-defined ones.
    for (prop in properties) {
        if (!ordered.contains(prop)) ordered.push(prop);
    }

    return ordered;
}

function findProperty(properties, name) {
    if (properties == null) return null;
    for (property in properties) if (property.name == name) return property;
    return null;
}

function fitPropertyValues(values, count) {
    var result = [];
    for (i in 0...count) result.push(values != null && i < values.length ? values[i] * 1.0 : 0.0);
    return result;
}

function makeExtraValueID(name, type, componentIndex) {
    return name + "|" + type + "|" + componentIndex;
}

function parseExtraValueID(id) {
    var parts = Std.string(id).split("|");
    return {
        name: parts.length > 0 ? parts[0] : "",
        type: parts.length > 1 ? parts[1] : "float",
        componentIndex: parts.length > 2 ? Std.parseInt(parts[2]) : 0
    };
}

function setupEditMenu(data, itemButton) {
    var camGameCheckbox = new UICheckbox(16, 100, "Use on Game Camera?", data.camGame);
    itemButton.members.push(camGameCheckbox);
    itemButton.menuObjects.set("camGameCheckbox", camGameCheckbox);

    var camHUDCheckbox = new UICheckbox(16, 166, "Use on HUD Camera?", data.camHUD);
    itemButton.members.push(camHUDCheckbox);
    itemButton.menuObjects.set("camHUDCheckbox", camHUDCheckbox);

    var camOtherCheckbox = new UICheckbox(16, 166 + 66, "Use on Other Camera?", data.camOther);
    itemButton.members.push(camOtherCheckbox);
    itemButton.menuObjects.set("camOtherCheckbox", camOtherCheckbox);
}

function updateMenuPositions(itemButton) {
    itemButton.follow(itemButton, itemButton.menuObjects.get("camGameCheckbox"), 16, 80);
    itemButton.follow(itemButton, itemButton.menuObjects.get("camHUDCheckbox"), 16, 120);
    itemButton.follow(itemButton, itemButton.menuObjects.get("camOtherCheckbox"), 16, 160);
}
function getMenuHeight() {
    return 160 + 66;
}
function getBaseWindowHeight() {
    return 250;
}

function updateEditItem(data, itemButton) {
    var fileExists = false;
    var iniExists = false;
    var iniData = ["" => ""];
    var iniPropertyOrder:Array<String> = [];
    var iniPath = "shaders/modcharts/" + data.file + ".ini";
    if (Assets.exists("shaders/modcharts/" + data.file + ".vert") || Assets.exists("shaders/modcharts/" + data.file + ".frag")) {
        fileExists = true;
    }
    if (Assets.exists(iniPath)) {
        iniExists = true;
        iniData = IniUtil.parseAsset(iniPath).get("Global");
        iniPropertyOrder = getOrderedIniProperties(iniPath, iniData);
    }

    if (iniExists) {
        itemButton.descText.text = iniData.exists("desc") ? StringTools.replace(iniData.get("desc"), "#", "\n") : "";
    } else {
        itemButton.descText.text = fileExists ? "" : "\"" + data.file + "\" could not found!";
    }

    for (obj in itemButton.extraValues) {
        itemButton.members.remove(obj);
        obj.destroy();
    }
    for (obj in itemButton.extraLabels) {
        itemButton.members.remove(obj);
        obj.destroy();
    }
    itemButton.extraValues = [];
    itemButton.extraValuesList = [];
    itemButton.extraLabels = [];

    var definitions = iniExists ? getIniDefinitions(data.file, iniPath, iniData, iniPropertyOrder) : [];
    for (definition in definitions) {
        var previous = findProperty(data.properties, definition.name);
        if (previous != null) {
            if (previous.type != null && normalizeUniformType(previous.type) != null) definition.type = normalizeUniformType(previous.type);
            var previousValues = previous.values;
            if (previousValues == null && previous.value != null) previousValues = [previous.value];
            definition.values = fitPropertyValues(previousValues, uniformComponentCount(definition.type));
            definition.components = getUniformComponents(definition.name, definition.type);
        }

        var count = uniformComponentCount(definition.type);
        for (componentIndex in 0...count) {
            var input:Dynamic = definition.type == "bool"
                ? new UICheckbox(16, 100, "", definition.values[0] >= 0.5)
                : new UINumericStepper(16, 100, definition.values[componentIndex], 0, 6, null, null, 200);
            itemButton.members.push(input);
            itemButton.extraValues.push(input);
            itemButton.extraValuesList.push(makeExtraValueID(definition.name, definition.type, componentIndex));

            var displayName = definition.name;
            if (count > 1) displayName += "." + definition.components[componentIndex];
            var label:UIText = new UIText(0, 0, 0, displayName + " (" + definition.type + ")");
            itemButton.members.push(label);
            itemButton.extraLabels.push(label);
        }
    }
    data.properties = definitions;
}

function setDataValues(data, itemButton) {

    data.camGame = itemButton.menuObjects.get("camGameCheckbox").checked;
    data.camHUD = itemButton.menuObjects.get("camHUDCheckbox").checked;
    data.camOther = itemButton.menuObjects.get("camOtherCheckbox").checked;

    for (i => input in itemButton.extraValues) {
        var metadata = parseExtraValueID(itemButton.extraValuesList[i]);
        var prop = findProperty(data.properties, metadata.name);
        if (prop == null) continue;

        if (metadata.type == "bool") {
            prop.values[0] = input.checked ? 1.0 : 0.0;
        } else {
            input.__onChange(input.label.text);
            prop.values[metadata.componentIndex] = metadata.type == "int" ? Math.round(input.value) : input.value;
        }
    }

}

function createNodeFromData(data) {
    var node = Xml.createElement("Shader");
    node.set("name", data.name);
    node.set("shader", data.file);
    node.set("color", data.colorString);

    node.set("camGame", data.camGame ? "true" : "false");
    node.set("camHUD", data.camHUD ? "true" : "false");
    node.set("camOther", data.camOther ? "true" : "false");

    for (prop in data.properties) {
        var child = Xml.createElement("Property");
        child.set("name", prop.name);
        if (prop.type == "bool")
            child.set("value", prop.values[0] >= 0.5 ? "true" : "false");
        else if (uniformComponentCount(prop.type) > 1)
            child.set("value", prop.values.join(", "));
        else
            child.set("value", Std.string(prop.values[0]));
        if (prop.type != "float") child.set("type", prop.type);
        node.addChild(child);
    }

    return node;
}
