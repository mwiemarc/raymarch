﻿Shader "Custom/SceneShader" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "" {}
        _CamPos ("CamPos", Vector) = (0,0,0,0)
        _CamDir ("CamDir", Vector) = (0,0,0,0)
        _CamUp ("CamUp", Vector) = (0,0,0,0)
        _TanHalfFov ("TanHalfFov", Float) = 60
    }

CGINCLUDE

    #include "UnityCG.cginc"

    struct v2f
    {
        float4 pos : SV_POSITION;
        half2 uv : TEXCOORD0;
    };

    uniform sampler2D _MainTex;
    uniform float4 _CamPos;
    uniform float4 _CamDir;
    uniform float4 _CamUp;
    uniform float _TanHalfFov;

// ----------------------------------------------------------------------------

float distfunc(float3 p) {return length(p)-1;} // DISTANCE_FUNCTION

// ----------------------------------------------------------------------------

    const int MAX_ITER = 50;
    const float MAX_DIST = 30.0;
    const float EPSILON = 0.01;

    bool march (float3 ro, float3 rd, out float3 pos)
    {
        float totalDist = 0.0;
        pos = ro;
        float dist = EPSILON;

        for (int i = 0; i < MAX_ITER; i++) {
            if (dist < EPSILON || totalDist > MAX_DIST) break;
            dist = distfunc(pos);
            totalDist += dist;
            pos += dist * rd;
        }

        return dist < EPSILON;
    }

    v2f vert(appdata_img v)
    {
        v2f o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv = v.texcoord.xy;
        return o;
    }

    float4 frag(v2f i) : SV_Target
    {
        const float3 cameraOrigin = _CamPos.xyz;
        const float3 cameraDir    = _CamDir.xyz;
        const float3 cameraUp     = _CamUp.xyz;
        const float3 cameraRight  = cross(cameraUp, cameraDir);
        const float2 screenPos = -1 + 2 * i.uv;
        screenPos.x *= _ScreenParams.x / _ScreenParams.y;
        screenPos *= _TanHalfFov;
        const float3 rayDir = normalize(cameraRight * screenPos.x + cameraUp * screenPos.y + cameraDir);

        float3 pos;
        bool hit = march (cameraOrigin, rayDir, pos);

        float3 color = float3 (0.0);

        if (hit) {
            const float2 eps = float2(0.0, EPSILON);

            float3 normal = normalize(float3(
                distfunc(pos + eps.yxx) - distfunc(pos - eps.yxx),
                distfunc(pos + eps.xyx) - distfunc(pos - eps.xyx),
                distfunc(pos + eps.xxy) - distfunc(pos - eps.xxy)));

            color = float3(0.5) + normal/2;
        }
        else {
            color = float3(0);
        }

        return float4(color, 1.0);
    }

ENDCG

    Subshader {
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }

    Fallback off
}
