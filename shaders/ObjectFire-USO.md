# Object Fire

El shader se aplica directamente a objetos desde código. La utilidad global se encarga de crear los shaders, animar su tiempo y restaurar el shader anterior al quitar el fuego.

## Colores

- **Core Color:** la parte más caliente y brillante.
- **Middle Color:** el cuerpo principal de la llama.
- **Outer Color:** los bordes más fríos de la llama.

Ejemplos:

| Estilo | Core | Middle | Outer |
| --- | --- | --- | --- |
| Fuego normal | `#FFF2A0` | `#FF7200` | `#B30900` |
| Fuego azul | `#FFFFFF` | `#28B8FF` | `#0636B8` |
| Fuego verde | `#F1FFB0` | `#45F04B` | `#087A32` |
| Fuego morado | `#FFF0FF` | `#C147FF` | `#4A087A` |

## Uso recomendado desde un script de stage o canción

```haxe
function postCreate() {
	var object = stage.stageSprites["lavaRock"];

	scripts.call("applyObjectFire", [object, {
		coreColor: "#FFF2A0",
		middleColor: "#FF7200",
		outerColor: "#B30900",
		intensity: 1.0,
		speed: 1.0,
		scale: 1.0,
		coverage: 0.72,
		charAmount: 0.45
	}]);
}
```

Funciona igual con personajes u otros sprites:

```haxe
scripts.call("applyObjectFire", [dad, {
	coreColor: "#FFFFFF",
	middleColor: "#28B8FF",
	outerColor: "#0636B8"
}]);
```

No es necesario crear un `update()` en el script que lo aplica. La utilidad global actualiza automáticamente todos los shaders activos.

## Cambiarlo después

```haxe
// Cambiar solamente la paleta.
scripts.call("setObjectFireColors", [object, "#F1FFB0", "#45F04B", "#087A32"]);

// Cambiar cualquier combinación de propiedades.
scripts.call("configureObjectFire", [object, {intensity: 1.5, speed: 2.0, coverage: 0.9}]);

// Quitar el efecto y restaurar el shader anterior.
scripts.call("removeObjectFire", [object]);

// Quitar el efecto de todos los objetos.
scripts.call("clearObjectFire", []);
```

Los colores aceptan texto hexadecimal (`"#FF7200"`), enteros de `FlxColor` o arreglos RGB normalizados (`[1.0, 0.45, 0.0]`).

## Uso manual sin la utilidad global

```haxe
var fireShader:CustomShader;
var fireTime:Float = 0;

function postCreate() {
	fireShader = new CustomShader("ObjectFire");
	fireShader.hset("iTime", 0);
	fireShader.hset("intensity", 1.0);
	fireShader.hset("fireSpeed", 1.0);
	fireShader.hset("fireScale", 1.0);
	fireShader.hset("coverage", 0.72);
	fireShader.hset("charAmount", 0.45);
	fireShader.hset("coreColor", [1.0, 0.95, 0.63]);
	fireShader.hset("midColor", [1.0, 0.45, 0.0]);
	fireShader.hset("outerColor", [0.7, 0.035, 0.0]);

	stage.stageSprites["lavaRock"].shader = fireShader;
}

function update(elapsed:Float) {
	fireTime += elapsed;
	fireShader.hset("iTime", fireTime);
}
```

El shader conserva el canal alfa original. Esto evita rectángulos de color alrededor de sprites transparentes y hace que también sea seguro para personajes animados. Como todo `FlxSprite` admite un solo fragment shader, aplicar este efecto reemplaza temporalmente cualquier shader que ya tuviera el objeto; la utilidad restaura el anterior cuando se llama a `removeObjectFire`.
