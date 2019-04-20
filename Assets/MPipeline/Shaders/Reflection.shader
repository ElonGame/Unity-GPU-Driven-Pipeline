﻿Shader "Unlit/Reflection"
{

CGINCLUDE
#pragma target 5.0
#include "UnityCG.cginc"
#include "CGINC/VoxelLight.cginc"
#include "UnityGBuffer.cginc"
#include "UnityPBSLighting.cginc"
#include "CGINC/Reflection.cginc"
#pragma multi_compile _ UNITY_HDR_ON
#pragma multi_compile _ EnableGTAO
#pragma multi_compile _ ENABLE_SSR


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            
            
ENDCG
    SubShader
    {
        Cull off ZWrite off ZTest Greater
        Blend one one
        Tags { "RenderType"="Opaque" }
        LOD 100
//Pass 0 Regular Projection
        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			float4x4 _InvVP;    //Inverse View Project Matrix
			Texture2D<half4> _CameraGBufferTexture0; SamplerState sampler_CameraGBufferTexture0;       //RGB Diffuse A AO
			Texture2D<half4> _CameraGBufferTexture1; SamplerState sampler_CameraGBufferTexture1;       //RGB Specular A Smoothness
			Texture2D<half3> _CameraGBufferTexture2; SamplerState sampler_CameraGBufferTexture2;       //RGB Normal
			Texture2D<float> _CameraDepthTexture; SamplerState sampler_CameraDepthTexture;
			Texture2D<float2> _AOROTexture; SamplerState sampler_AOROTexture;
            float2 _Jitter;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                float depth = _CameraDepthTexture.Sample(sampler_CameraDepthTexture, i.uv);
                float4 worldPos = mul(_InvVP, float4(i.uv * 2 - 1, depth, 1));
				float linearDepth = LinearEyeDepth(depth);
                worldPos /= worldPos.w;

                float3 normal = normalize(_CameraGBufferTexture2.Sample(sampler_CameraGBufferTexture2, i.uv).xyz * 2 - 1);
                float occlusion = _CameraGBufferTexture0.Sample(sampler_CameraGBufferTexture0, i.uv).w;
				float4 specular = _CameraGBufferTexture1.Sample(sampler_CameraGBufferTexture1, i.uv);

#if EnableGTAO
				float2 aoro = _AOROTexture.Sample(sampler_AOROTexture, i.uv);
				occlusion = min(occlusion, min(aoro.x, aoro.y));
#endif
                float3 viewDir = normalize(worldPos.xyz - _WorldSpaceCameraPos);
                //float3 CalculateReflection(float linearDepth, float3 worldPos, float3 viewDir, float4 specular, float3 normal, float occlusion)
				return CalculateReflection(linearDepth, worldPos.xyz, viewDir, specular, normal, occlusion, i.uv);
            }
            ENDCG
        }
    }
}
