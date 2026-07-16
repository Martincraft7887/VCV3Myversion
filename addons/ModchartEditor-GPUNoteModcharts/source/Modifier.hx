//
import SubModifier;
import funkin.backend.utils.IniUtil;

class Modifier {
    public var name:String;
    public var value:Float = 0.0;
    public var strumLineID:Int = -1;
    public var strumID:Int = -1;
    public var strumIDs:Array<Int> = [-1];
    public var strumIDExpression:String = "-1";
    public var subMods:Array<SubModifier> = [];
    public var lastValues = [];

    public var shaderName:String;
    public var shaderFile:String = null;

    public function new(n:String, v:Float, slid:Int, sid:Dynamic, submods:Array<SubModifier>, ?shaderfile:String = null) {
        name = n;
        shaderName = n + "_value";
        value = v;
        strumLineID = slid;
        setStrumIDExpression(sid);
        subMods = submods;
        shaderFile = shaderfile;

        /*
        var iniData = ["" => ""];
        if (Assets.exists("modifiers/"+shaderFile+".ini")) {
            iniData = IniUtil.parseAsset("modifiers/"+shaderFile+".ini");
        }
        */

        for (sub in subMods) {
            sub.shaderName = n + "_" + sub.name;
        }
    }

    public function setStrumIDExpression(sid:Dynamic) {
        strumIDExpression = normalizeStrumIDExpression(sid);
        strumIDs = parseStrumIDExpression(strumIDExpression);
        strumID = strumIDs.length > 0 ? strumIDs[0] : -1;
    }

    public function appliesToStrumID(id:Int):Bool {
        return strumIDs.contains(-1) || strumIDs.contains(id);
    }

    public static function normalizeStrumIDExpression(sid:Dynamic):String {
        var ids = parseStrumIDExpression(sid);
        if (ids.length < 1 || ids.contains(-1)) return "-1";

        ids.sort(function(a, b) return a - b);
        var unique:Array<Int> = [];
        for (id in ids) {
            if (!unique.contains(id)) unique.push(id);
        }

        var consecutive = unique.length > 1;
        for (i in 1...unique.length) {
            if (unique[i] != unique[i - 1] + 1) {
                consecutive = false;
                break;
            }
        }

        if (consecutive) return Std.string(unique[0]) + ".." + Std.string(unique[unique.length - 1]);
        return unique.join(",");
    }

    public static function parseStrumIDExpression(sid:Dynamic):Array<Int> {
        var raw = sid == null ? "-1" : Std.string(sid);
        raw = StringTools.replace(raw, " ", "");
        if (raw == "") return [-1];

        var ids:Array<Int> = [];
        var index = 0;
        while (index < raw.length) {
            var parsed = readInt(raw, index);
            if (parsed == null) {
                index++;
                continue;
            }

            var start:Int = parsed.value;
            index = parsed.index;

            if (index + 1 < raw.length && raw.charAt(index) == "." && raw.charAt(index + 1) == ".") {
                index += 2;
                var rangeEnd = readInt(raw, index);
                if (rangeEnd != null) {
                    var end:Int = rangeEnd.value;
                    index = rangeEnd.index;
                    var step = start <= end ? 1 : -1;
                    var current = start;
                    while (true) {
                        if (!ids.contains(current)) ids.push(current);
                        if (current == end) break;
                        current += step;
                    }
                } else if (!ids.contains(start)) {
                    ids.push(start);
                }
            } else if (!ids.contains(start)) {
                ids.push(start);
            }

            while (index < raw.length && (raw.charAt(index) == "," || raw.charAt(index) == ".")) index++;
        }

        return ids.length > 0 ? ids : [-1];
    }

    static function readInt(raw:String, index:Int):Dynamic {
        var start = index;
        if (index < raw.length && raw.charAt(index) == "-") index++;
        var digitStart = index;
        while (index < raw.length) {
            var code = raw.charCodeAt(index);
            if (code < 48 || code > 57) break;
            index++;
        }
        if (digitStart == index) return null;
        return {value: Std.parseInt(raw.substr(start, index - start)), index: index};
    }

    public function setupShaderCode(shaderData:Dynamic) {
        if (shaderFile == null) return;

        
        shaderData.vertUniforms += "uniform float " + shaderName + ";\n";
        for (submod in subMods) {
            shaderData.vertUniforms += "uniform float " + submod.shaderName + ";\n";
        }

        if (Assets.exists("modifiers/"+shaderFile+".vert")) {
            var vertCode = Assets.getText("modifiers/"+shaderFile+".vert");
            vertCode = StringTools.replace(vertCode, "_value_", shaderName);
            for (submod in subMods) {
                vertCode = StringTools.replace(vertCode, "_" + submod.name + "_", submod.shaderName);
            }

            shaderData.vertFunctions += vertCode + "\n";
        }

        /*
        if (Assets.exists("modifiers/"+shaderFile+".frag")) {
            var fragCode = Assets.getText("modifiers/"+shaderFile+".frag");
            fragCode = StringTools.replace(fragCode, "_value_", shaderName);
            for (submod in subMods) {
                fragCode = StringTools.replace(fragCode, "_" + submod.name + "_", submod.shaderName);
            }

            shaderData.fragFunctions += fragCode + "\n";
        }
        */
    }
}
