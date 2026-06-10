package shaders;

import flixel.system.FlxAssets.FlxShader;

class CustomImageShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform sampler2D customImage;
        uniform float uPosX;
        uniform float uPosY;
        uniform float uAngle;
        uniform float uScaleX;
        uniform float uScaleY;
        uniform float uAlpha;

        vec2 rotate(vec2 pt, float angle, vec2 center) {
            float s = sin(angle);
            float c = cos(angle);
            pt -= center;
            pt = vec2(pt.x * c - pt.y * s, pt.x * s + pt.y * c);
            return pt + center;
        }

        void main() {
            vec4 color = texture2D(bitmap, openfl_TextureCoordv);
            vec2 uv = openfl_TextureCoordv;

            vec2 uPos = vec2(uPosX, uPosY);
            vec2 uScale = vec2(uScaleX, uScaleY);

            vec2 image_uv = uv - vec2(0.5);
            image_uv /= uScale;
            image_uv += vec2(0.5);
            image_uv = rotate(image_uv, uAngle, vec2(0.5));
            image_uv -= uPos;

            vec4 overlay = texture2D(customImage, image_uv);
            color = mix(color, overlay, overlay.a * uAlpha);

            gl_FragColor = color;
        }
    ')
    public function new()
    {
        super();
    }
}