#pragma header

        uniform float uTime;
        uniform float money; //con 1.1 se activa el disco
        uniform float transparency; 
        uniform float brillo;
        uniform float saturacion;
        //uniform float speed;
        uniform float awesomeOutline;


        const float offset = 1.0 / 128.0;
        
        

        vec3 normalizeColor(vec3 color)
        {
            return vec3(
                color[0] / 255.0,
                color[1] / 255.0,
                color[2] / 255.0
            );
        }

        vec3 rgb2hsv(vec3 c)
        {
            vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
            vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        vec3 hsv2rgb(vec3 c)
        {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

            vec4 swagColor = vec4(rgb2hsv(vec3(color[0], color[1], color[2])), color[3]);
           
            // [0] is the hue???
            if (money == 0.0) {
              swagColor[0] = rgb2hsv(vec3(color[0], color[1], color[2]))[0];
            } else if (money == 1.0) {
              swagColor[0] = 0.0;  // esto para que el 1 sea rojo
            } else if (money >= 1.1) {
              swagColor[0] = mod(uTime * 0.1, 1.0);
            } else {
              swagColor[0] = mod(money, 1.0);
            }

            if (saturacion == 0.0) {
                swagColor[1] = rgb2hsv(vec3(color[0], color[1], color[2]))[1];
            } else {
                swagColor[1] = clamp(saturacion, 0.0, 1.0);
            }

            if (brillo == 0.0) {
                swagColor[2] = rgb2hsv(vec3(color[0], color[1], color[2]))[2];
            } else {
                 swagColor[2] = clamp(brillo, 0.0, 1.0);
            }
               color.rgb = clamp(hsv2rgb(vec3(swagColor.r, swagColor.g, swagColor.b)), 0.0, 1.0);
  
            gl_FragColor = vec4(color.rgb, color.a);
           
            
          
            
        }