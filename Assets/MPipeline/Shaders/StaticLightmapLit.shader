﻿
 Shader "Maxwell/StaticLightmapLit" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Occlusion("Occlusion Scale", Range(0,1)) = 1
		_Cutoff("Cut off", Range(0, 1)) = 0
		_SpecularIntensity("Specular Intensity", Range(0,1)) = 0.3
		_MetallicIntensity("Metallic Intensity", Range(0, 1)) = 0.1
		_MainTex ("Albedo (RGB)AO(A)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_SpecularMap("R(Spec)G(Smooth)B(DetailMask)", 2D) = "white"{}
		_DetailAlbedo("Detail Albedo", 2D) = "white"{}
		_DetailNormal("Detail Normal", 2D) = "bump"{}
		_EmissionMultiplier("Emission Multiplier", Range(0, 128)) = 1
		_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionMap("Emission Map", 2D) = "white"{}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

	// ------------------------------------------------------------
	// Surface shader code generated out of a CGPROGRAM block:
CGINCLUDE
#pragma shader_feature DETAIL_ON
#pragma multi_compile _ LIGHTMAP_ON
#pragma target 5.0
#define DECAL

#pragma multi_compile __ ENABLE_RAINNING
#pragma multi_compile __ USE_RANNING
#pragma multi_compile __ CUT_OFF
//#define MOTION_VECTOR
#include "UnityCG.cginc"
#include "UnityDeferredLibrary.cginc"
#include "UnityPBSLighting.cginc"
#include "CGINC/VoxelLight.cginc"
#include "CGINC/Shader_Include/Common.hlsl"
#include "CGINC/Shader_Include/BSDF_Library.hlsl"
#include "CGINC/Shader_Include/AreaLight.hlsl"
#include "CGINC/Sunlight.cginc"
#include "CGINC/Lighting.cginc"
	struct Input {
			float2 uv_MainTex;
		};
cbuffer UnityPerMaterial
{
    float _SpecularIntensity;
		float _MetallicIntensity;
    float4 _EmissionColor;
		float _Occlusion;
		float _VertexScale;
		float _VertexOffset;
		float4 _MainTex_ST;
		float4 _DetailAlbedo_ST;
		float _Glossiness;
		float4 _Color;
		float _EmissionMultiplier;
		float _Cutoff;
}
		sampler2D _BumpMap;
		sampler2D _SpecularMap;
		sampler2D _MainTex; 
		sampler2D _DetailAlbedo; 
		sampler2D _DetailNormal;
		sampler2D _EmissionMap;
		sampler2D _RainTexture;

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
			// Albedo comes from a texture tinted by color
			float2 uv = IN.uv_MainTex;// - parallax_mapping(IN.uv_MainTex,IN.viewDir);
			float2 detailUV = TRANSFORM_TEX(uv, _DetailAlbedo);
			uv = TRANSFORM_TEX(uv, _MainTex);
			float4 spec = tex2D(_SpecularMap,uv);
			float4 c = tex2D (_MainTex, uv);
			#if CUT_OFF
			clip(c.a * _Color.a - _Cutoff);
			#endif
#if DETAIL_ON
			float3 detailNormal = UnpackNormal(tex2D(_DetailNormal, detailUV));
			float4 detailColor = tex2D(_DetailAlbedo, detailUV);
#endif
			o.Normal = UnpackNormal(tex2D(_BumpMap,uv));
			o.Albedo = c.rgb;
#if DETAIL_ON
			o.Albedo = lerp(detailColor.rgb, o.Albedo, c.a) * _Color.rgb;
			o.Normal = lerp(detailNormal, o.Normal, c.a);
			
#else
			o.Albedo *= _Color.rgb;
#endif
#if USE_RANNING && ENABLE_RAINNING
			o.Normal.xy += tex2D(_RainTexture, uv).xy;
#endif
			o.Alpha = 1;
			o.Occlusion = lerp(1, spec.b, _Occlusion);
			o.Specular = lerp(_SpecularIntensity * spec.g, o.Albedo * _SpecularIntensity * spec.g, _MetallicIntensity); 
			o.Smoothness = _Glossiness * spec.r;
			o.Emission = _EmissionColor * tex2D(_EmissionMap, uv) * _EmissionMultiplier;
		}
#include "CGINC/MPipeDeferred.cginc"
ENDCG

pass
{
	stencil{
  Ref 1
  comp always
  pass replace
}
Name "GBuffer"
Tags {"LightMode" = "GBuffer" "Name" = "GBuffer"}
ZTest Less
CGPROGRAM

#pragma vertex vert_surf
#pragma fragment frag_surf
ENDCG
}
	Pass
		{
			ZTest less
			Cull back
			Tags {"LightMode" = "DirectionalLight"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
			#pragma exclude_renderers gles
			#include "UnityCG.cginc"
			#include "CGINC/Procedural.cginc"
			
			float4x4 _ShadowMapVP;
			struct appdata_shadow
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				#if CUT_OFF
				float2 texcoord : TEXCOORD0;
				#endif
			};
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#if CUT_OFF
				float2 texcoord : TEXCOORD0;
				#endif
			};

			v2f vert (appdata_shadow v)
			{
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				v2f o;
				o.vertex = mul(_ShadowMapVP, worldPos);
				#if CUT_OFF
				o.texcoord = v.texcoord;
				#endif
				return o;
			}

			
			float frag (v2f i)  : SV_TARGET
			{
				#if CUT_OFF
				i.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);
				float4 c = tex2D(_MainTex, i.texcoord);
				clip(c.a * _Color.a - _Cutoff);
				#endif
				return i.vertex.z;
			}

			ENDCG
		}

		Pass
        {
			Tags {"LightMode"="PointLightPass"}
			ZTest less
			Cull back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #include "CGINC/Procedural.cginc"
			struct appdata_shadow
			{
				float4 vertex : POSITION;
				#if CUT_OFF
				float2 texcoord : TEXCOORD0;
				#endif
			};
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
				#if CUT_OFF
				float2 texcoord : TEXCOORD1;
				#endif
            };
            float4x4 _VP;
            v2f vert (appdata_shadow v) 
            {
                v2f o;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos.xyz;
                o.vertex = mul(_VP, worldPos);
				#if CUT_OFF
				o.texcoord = v.texcoord;
				#endif
                return o;
            }

            float frag (v2f i) : SV_Target
            {
				#if CUT_OFF
				i.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);
				float4 c = tex2D(_MainTex, i.texcoord);
				clip(c.a * _Color.a - _Cutoff);
				#endif
               return distance(i.worldPos, _LightPos.xyz) / _LightPos.w;
            } 
            ENDCG
        }

		Pass
		{
			Tags {"LightMode"="SpotLightPass"}
			ZTest less
			Cull back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
			#pragma exclude_renderers gles
			#include "UnityCG.cginc"
			#include "CGINC/Procedural.cginc"
			float4x4 _ShadowMapVP;
			float _LightRadius;
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#if CUT_OFF
				float2 texcoord : TEXCOORD0;
				#endif
			};
			struct appdata_shadow
			{
				float4 vertex : POSITION;
				#if CUT_OFF
				float2 texcoord : TEXCOORD0;
				#endif
			};

			v2f vert (appdata_shadow v)
			{
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				v2f o;
				o.vertex = mul(_ShadowMapVP, worldPos);
				#if CUT_OFF
				o.texcoord = v.texcoord;
				#endif
				return o;
			}
			float frag (v2f i) : SV_TARGET
			{
				#if CUT_OFF
				i.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);
				float4 c = tex2D(_MainTex, i.texcoord);
				clip(c.a * _Color.a - _Cutoff);
				#endif
				return i.vertex.z;
			}

			ENDCG
		}
	
}
	CustomEditor "ShouShouEditor"
}
