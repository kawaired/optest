Shader "Unlit/rimlight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RimOffset("rimoffset",range(0,1))=0.5
        _RimLightLength("rimlightlength",range(-1,1))=0.02
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            //Tags {"LightMode"="ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 viewlight:TEXCOORD1;
                float3 viewnormal:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            float _RimOffset;
            float _RimLightLength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.viewlight=(UnityWorldSpaceLightDir(v.vertex));
                o.viewnormal=(v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //return float4(1,1,1,1);
                float2 screenParams01 = float2(i.vertex.x/_ScreenParams.x,i.vertex.y/_ScreenParams.y);
                float2 uvofs=screenParams01+normalize(i.viewnormal).xy*_RimLightLength;
                float depth=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,uvofs);
                float rim=saturate(i.vertex.z-depth);
                return rim.xxxx;


                // float ndotl=saturate(dot(i.viewnormal,i.viewlight)+_RimLightLength);
                
                // float2 offsetpos=screenParams01-float2(ndotl/i.vertex.w,0);
                // float depth=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,screenParams01);
                // float offsetdepth=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,offsetpos);
                // float lineardepth=Linear01Depth(depth);
                // float offsetlinedepth=Linear01Depth(offsetdepth);
                // float depthdiffer=offsetlinedepth-lineardepth;
                // return depthdiffer.xxxx;
            
            //return tex2D(_CameraDepthTexture,i.uv);
            }
            ENDCG
        }
    }
    FallBack "Diffuse" 
}
