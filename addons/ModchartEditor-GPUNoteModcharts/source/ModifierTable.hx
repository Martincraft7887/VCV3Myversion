//
import Modifier;

class ModifierTable {
    public function new() {}

    public var modifiers:Array<Dynamic> = [];
    public var modTable:Array<Dynamic> = [];

    public var shaderPool:Array<Dynamic> = [];
    public var vertTable:Array<Dynamic> = [];
    public var fragTable:Array<Dynamic> = [];
    public var keyCounts:Array<Int> = [];

    public function addModifier(mod:Modifier) {
        modifiers.push(mod);
    }

    public function getKeyCount(strumLineID:Int):Int {
        var keyCount:Int = 4;
        if (PlayState.SONG != null && PlayState.SONG.strumLines != null && strumLineID >= 0 && strumLineID < PlayState.SONG.strumLines.length && PlayState.SONG.strumLines[strumLineID] != null) {
            var strumLine = PlayState.SONG.strumLines[strumLineID];
            if (Reflect.hasField(strumLine, "keyCount") && Reflect.field(strumLine, "keyCount") != null) {
                keyCount = Std.int(Reflect.field(strumLine, "keyCount"));
            }
        }

        var runtimeKeyCount = getRuntimeKeyCount(strumLineID);
        if (runtimeKeyCount > keyCount) keyCount = runtimeKeyCount;

        for (mod in modifiers) {
            if (mod.strumLineID == -1 || mod.strumLineID == strumLineID) {
                for (id in mod.strumIDs) {
                    if (id >= keyCount) keyCount = id + 1;
                }
            }
        }

        return keyCount < 1 ? 1 : keyCount;
    }

    public function getRuntimeKeyCount(strumLineID:Int):Int {
        var count:Int = 0;

        try {
            if (PlayState.instance != null) {
                var lines:Dynamic = Reflect.field(PlayState.instance, "strumLines");
                if (lines != null) {
                    var line:Dynamic = null;
                    var members:Dynamic = Reflect.field(lines, "members");

                    if (members != null && strumLineID >= 0 && strumLineID < members.length) {
                        line = members[strumLineID];
                    } else if (strumLineID >= 0 && strumLineID < lines.length) {
                        line = lines[strumLineID];
                    }

                    if (line != null) {
                        var lineMembers:Dynamic = Reflect.field(line, "members");
                        if (lineMembers != null) {
                            count = lineMembers.length;
                        } else {
                            count = line.length;
                        }
                    }
                }
            }
        } catch(e:Dynamic) {}

        return count;
    }

    public function init() {
        construct();
        generateShaders();
    }

    public function construct() {
        modTable = [];
        keyCounts = [];

        for (mod in modifiers) {
            mod.lastValues = [];
            for (sub in mod.subMods) sub.lastValues = [];
        }

        for(p in 0...PlayState.SONG.strumLines.length) {
            modTable.push([]);
            for (mod in modifiers) {
                mod.lastValues.push([]);
                for (sub in mod.subMods) sub.lastValues.push([]);
            }

            var keyCount:Int = getKeyCount(p);
            keyCounts.push(keyCount);
            for (i in 0...keyCount) {
                modTable[p].push([]);
                for (mod in modifiers) {
                    if ((mod.strumLineID == -1 || mod.strumLineID == p) && mod.appliesToStrumID(i)) {
                        modTable[p][i].push(mod);
                    }
                    mod.lastValues[p][i] = Math.NEGATIVE_INFINITY;
                    for (sub in mod.subMods) sub.lastValues[p][i] = Math.NEGATIVE_INFINITY;
                }
            }
        }
    }

    public function applyValuesToShader(shader:CustomShader, strumLineID:Int, strumID:Int) {
        if (shader == null || strumLineID < 0 || strumID < 0) return;
        if (modTable == null || modTable[strumLineID] == null || modTable[strumLineID][strumID] == null) return;

        for (mod in modTable[strumLineID][strumID]) {
            //only update value if needed
            if (mod.lastValues[strumLineID][strumID] != mod.value) {
                mod.lastValues[strumLineID][strumID] = mod.value;
                shader.hset(mod.shaderName, mod.value);
            }
            
            for (sub in mod.subMods) {
                if (sub.lastValues[strumLineID][strumID] != sub.value) {
                    sub.lastValues[strumLineID][strumID] = sub.value;
                    shader.hset(sub.shaderName, sub.value);
                }
            }
        }
    }

    public function getShader(strumLineID:Int, strumID:Int) {
        if (!hasShaderLane(strumLineID, strumID)) return null;

        var pool = shaderPool[strumLineID][strumID];

        if (pool.length < 1) {
            return createShader(strumLineID, strumID);
        } else {
            var shader = pool.pop();
            return shader;
        }
    }
    public function putShader(shader:CustomShader, strumLineID:Int, strumID:Int) {
        if (shader == null || !hasShaderLane(strumLineID, strumID)) return;

        var pool = shaderPool[strumLineID][strumID];
        pool.push(shader);
    }

    public function createShader(strumLineID:Int, strumID:Int) {
        if (!hasShaderLane(strumLineID, strumID)) return null;

        var shader = new FunkinShader(fragTable[strumLineID][strumID], vertTable[strumLineID][strumID]);
        shader.data.vertexID.value = [0, 1, 2, 3];
        return shader;
    }

    public function hasShaderLane(strumLineID:Int, strumID:Int):Bool {
        if (strumLineID < 0 || strumID < 0) return false;
        if (shaderPool == null || vertTable == null || fragTable == null) return false;
        if (shaderPool[strumLineID] == null || vertTable[strumLineID] == null || fragTable[strumLineID] == null) return false;
        return shaderPool[strumLineID][strumID] != null && vertTable[strumLineID][strumID] != null && fragTable[strumLineID][strumID] != null;
    }
    
    public function generateShaders() {
        var baseShaderName = "notePerspective";
        var fragShaderPath = Paths.fragShader(baseShaderName);
        var vertShaderPath = Paths.vertShader(baseShaderName);
        var baseFragCode = Assets.exists(fragShaderPath) ? Assets.getText(fragShaderPath) : null;
        var baseVertCode = Assets.exists(vertShaderPath) ? Assets.getText(vertShaderPath) : null;

        vertTable = [];
        fragTable = [];
        shaderPool = [];

        for(p in 0...PlayState.SONG.strumLines.length) {
            vertTable.push([]);
            fragTable.push([]);
            shaderPool.push([]);

            var keyCount:Int = p < keyCounts.length ? keyCounts[p] : getKeyCount(p);
            for (i in 0...keyCount) {

                var data = {
                    vertUniforms: "",
                    vertFunctions: "",
                    fragUniforms: "",
                    fragFunctions: "",
                }

                for (mod in modTable[p][i]) {
                    mod.setupShaderCode(data);
                }

                var vert = baseVertCode;
                vert = StringTools.replace(vert, "#pragma modifierUniforms", data.vertUniforms);
                vert = StringTools.replace(vert, "#pragma modifierFunctions", data.vertFunctions);

                var frag = baseFragCode;
                frag = StringTools.replace(frag, "#pragma modifierUniforms", data.fragUniforms);
                frag = StringTools.replace(frag, "#pragma modifierFunctions", data.fragFunctions);

                vertTable[p].push(vert);
                fragTable[p].push(frag);
                shaderPool[p].push([]);
            }
        }
    }
}
