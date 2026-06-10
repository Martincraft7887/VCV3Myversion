#pragma header

        uniform float uTime;
        uniform float money; //0 y 1 es default , 1.1 se activa el disco pero debes poner el utime sino gg
        uniform float colorraro; // 1 es rojo 1.1 es disco este hace otros colores con tonos grises pero el 0 actua como rojo pero en si esta puesto como default 
        //si tienes money y colorraro activo el money actuara como el color importante , debe tener utime si quieres que salga el disco lol xd
       


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
            
            vec4 swagColorMoney = swagColor;
    
            if (money >= 1.1) {
              swagColorMoney[0] += mod(uTime * 0.1, 1.0);
            } else {
              float hueIncrement = money;
              swagColorMoney[0] = mod(swagColorMoney[0] + mod(money, 1.0) * hueIncrement, 1.0);
            }

            vec4 swagColorColorRaro = swagColorMoney;

            if (colorraro == 0.0) {
               swagColorColorRaro[0] = swagColorMoney[0];

            } else if (colorraro >= 1.1) {
               swagColorColorRaro[0] = mod(uTime * 0.1, 1.0);
            } else {
               swagColorColorRaro[0] = mod(colorraro, 1.0);
            }

            color = vec4(hsv2rgb(vec3(swagColorColorRaro[0], swagColorColorRaro[1], swagColorColorRaro[2])), swagColorColorRaro[3]);
            


           
            
            gl_FragColor = color;
            
            
    
        }