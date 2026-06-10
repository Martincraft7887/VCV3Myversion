#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
uniform float sizex;
uniform float sizey;
#define iChannel0 bitmap
#define texture flixel_texture2D

int   column        = 1;
int   row           = 1;
float borderSize    = 1.0;
int   actualScreen  = 0;
vec4  borderColor   = vec4(0.0);
vec3  subResolution = vec3(0.0);

void display(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / subResolution.xy;
    uv = vec2(abs(uv.x - 0.5) * 2.0, uv.y);
    fragColor = texture(iChannel0, uv);
}

void splitScreen(out vec4 fragColor, in vec2 fragCoord) {
    vec2 newFragCoord = fragCoord;
    vec3 newResolution = iResolution - borderSize;
    
    float adjustedSizeX = sizex > 0.0 ? sizex : newResolution.x / float(column);
    float adjustedSizeY = sizey > 0.0 ? sizey : newResolution.y / float(row);

    vec2 subFragCoord = vec2(mod(newFragCoord.x, adjustedSizeX),
                             mod(newFragCoord.y, adjustedSizeY)) - borderSize;

    subResolution = vec3(adjustedSizeX, adjustedSizeY, newResolution.z) - borderSize;

    int actualColumn = int(newFragCoord.x / (subResolution.x + borderSize)) + 1;
    int actualRow = int((newResolution.y - newFragCoord.y) / (subResolution.y + borderSize));
    actualScreen = actualRow * column + actualColumn;

    if (subFragCoord.x > 0.0 && subFragCoord.x < subResolution.x &&
        subFragCoord.y > 0.0 && subFragCoord.y < subResolution.y) {
        display(fragColor, subFragCoord);
    } else {
        fragColor = borderColor;
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    if (iTime < 5.0)
        column = int(iTime) + 1;
    else if (iTime < 10.0)
        column = int(10.0 - iTime) + 1;
    else if (iTime < 15.0)
        row = int(iTime - 10.0) + 1;
    else if (iTime < 20.0)
        row = int(20.0 - iTime) + 1;   
    else if (iTime < 25.0) {
        column = int(iTime - 20.0) + 1;
        row = int(iTime - 20.0) + 1;
    } else if (iTime < 30.0) {
        column = int(30.0 - iTime) + 1;
        row = int(30.0 - iTime) + 1;
    } else {
        column = 3;
        row = 3;
    }

    splitScreen(fragColor, fragCoord);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize);
}