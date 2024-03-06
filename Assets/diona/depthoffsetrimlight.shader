Shader "Unlit/depthoffsetrimlight"
{
   Properties
    {
        _MainTex ("Texture", 2D) = "black" {}
        _Color("Color",color) = (0,0,0,0)
        _RimOffect("RimOffect",range(0,1)) = 0.5
        _Threshold("RimThreshold",range(-1,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float clipW :TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            float4 _MainTex_ST;
            float4 _Color;
            float  _RimOffect;
            float _Threshold;


            v2f vert (appdata_full v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.clipW = o.vertex.w ;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				//return float4(i.clipW.xxxx);
                float2 screenParams01 = float2(i.vertex.x/_ScreenParams.x,i.vertex.y/_ScreenParams.y);
                float2 offectSamplePos = screenParams01-float2(_RimOffect/i.clipW,0);
                float offcetDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, offectSamplePos);
                float trueDepth   = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenParams01);
                float linear01EyeOffectDepth = Linear01Depth(offcetDepth);
                float linear01EyeTrueDepth = Linear01Depth(trueDepth);
                float depthDiffer = linear01EyeOffectDepth-linear01EyeTrueDepth;
                float rimIntensity = step(_Threshold,depthDiffer);
                float4 col = float4(rimIntensity,rimIntensity,rimIntensity,1);
                return col;
            }

            ENDCG
        }
    }
    FallBack "Diffuse" 
}
