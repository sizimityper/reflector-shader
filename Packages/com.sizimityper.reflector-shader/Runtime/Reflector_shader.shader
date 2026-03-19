Shader "sizimityper/Reflector_shader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _RetroStrength ("Reflective Strength", Range(0, 20)) = 5.0
        _RetroExponent ("Reflective Focus", Range(0.1, 128)) = 1.0
        _RetroCutoff ("Reflective Cutoff", Range(0, 0.9)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.2
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0, 2)) = 1.0
        _EmissionIntensity ("Emission Intensity", Range(0, 10)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf RetroReflective fullforwardshadows
        #pragma target 3.0

        #include "UnityPBSLighting.cginc"

        sampler2D _MainTex;
        sampler2D _BumpMap;
        half _BumpScale;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        half _RetroStrength;
        half _RetroExponent;
        half _RetroCutoff;
        half _EmissionIntensity;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
        };

        inline half4 LightingRetroReflective(SurfaceOutputStandard s, half3 viewDir, UnityGI gi)
        {
            half4 pbsResult = LightingStandard(s, viewDir, gi);
            half3 lightDir = gi.light.dir;
            half3 normal = s.Normal;
            half NdotL = saturate(dot(normal, lightDir));
            half NdotL_processed = NdotL;
            if (_RetroCutoff > 0.001)
            {
                NdotL_processed = saturate((NdotL - _RetroCutoff) / (1.0 - _RetroCutoff));
            }
            half localBoost = pow(NdotL_processed, _RetroExponent) * _RetroStrength;
            half lightIntensity = dot(gi.light.color, half3(0.2126, 0.7152, 0.0722));
            half3 localBoostColor = s.Albedo * lightIntensity * localBoost * _EmissionIntensity;
            pbsResult.rgb += localBoostColor;
            return pbsResult;
        }

        inline half4 LightingRetroReflective_Deferred(SurfaceOutputStandard s, half3 viewDir, UnityGI gi, out half4 outGBuffer0, out half4 outGBuffer1, out half4 outGBuffer2)
        {
            return LightingStandard_Deferred(s, viewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2);
        }

        inline void LightingRetroReflective_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
        {
            LightingStandard_GI(s, data, gi);
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Normal = UnpackScaleNormal(tex2D(_BumpMap, IN.uv_BumpMap), _BumpScale);
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Standard"
}
