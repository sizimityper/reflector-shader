Shader "sizimityper/Reflector_shader"
{
    Properties
    {
        _Color ("カラー", Color) = (1,1,1,1)
        _MainTex ("アルベド (RGB)", 2D) = "white" {}
        _RetroStrength ("反射強度", Range(0, 20)) = 5.0
        _RetroExponent ("反射フォーカス", Range(0.1, 128)) = 1.0
        _RetroCutoff ("反射カットオフ", Range(0, 0.9)) = 0.0
        _Glossiness ("スムーズネス", Range(0,1)) = 0.2
        _Metallic ("メタリック", Range(0,1)) = 0.0
        _BumpMap ("ノーマルマップ", 2D) = "bump" {}
        _BumpScale ("ノーマルスケール", Range(0, 2)) = 1.0
        _EmissionIntensity ("エミッション強度", Range(0, 10)) = 1.0
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

        // カスタムライティング関数：ライトが当たった部分をエミッションして再帰反射っぽい見た目にする
        inline half4 LightingRetroReflective(SurfaceOutputStandard s, half3 viewDir, UnityGI gi)
        {
            half4 pbsResult = LightingStandard(s, viewDir, gi);
            half3 lightDir = gi.light.dir;
            half3 normal = s.Normal;
            // 法線とライト方向の内積（ランバート項）
            half NdotL = saturate(dot(normal, lightDir));
            half NdotL_processed = NdotL;
            // カットオフが設定されている場合、しきい値以下の部分を除去してコントラストを上げる
            if (_RetroCutoff > 0.001)
            {
                NdotL_processed = saturate((NdotL - _RetroCutoff) / (1.0 - _RetroCutoff));
            }
            // 反射強度をべき乗で調整してエミッション量を計算
            half localBoost = pow(NdotL_processed, _RetroExponent) * _RetroStrength;
            // ライトカラーを輝度に変換（ITU-R BT.709係数）
            half lightIntensity = dot(gi.light.color, half3(0.2126, 0.7152, 0.0722));
            half3 localBoostColor = s.Albedo * lightIntensity * localBoost * _EmissionIntensity;
            pbsResult.rgb += localBoostColor;
            return pbsResult;
        }

        // ディファードレンダリング用（標準PBSに委譲）
        inline half4 LightingRetroReflective_Deferred(SurfaceOutputStandard s, half3 viewDir, UnityGI gi, out half4 outGBuffer0, out half4 outGBuffer1, out half4 outGBuffer2)
        {
            return LightingStandard_Deferred(s, viewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2);
        }

        // グローバルイルミネーション用（標準PBSに委譲）
        inline void LightingRetroReflective_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
        {
            LightingStandard_GI(s, data, gi);
        }

        // サーフェス関数：テクスチャとマテリアルパラメータをサーフェス出力に設定する
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
