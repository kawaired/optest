Shader "Unlit/normaldither"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DitherRange("ditherrange",range(0,16))=16
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenpos:TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _DitherRange;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenpos=ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float DitherBayer(int x,int y, float brightness)
            {
                const float dither[16]={
                    0,8,2,10,
                    12,4,14,6,
                    3,11,1,9,
                    15,7,13,5
                };
                int r=y*4+x;
                return dither[r]<brightness;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenPos = i.screenpos.xy/i.screenpos.w;
                screenPos.xy *= _ScreenParams.xy;
                if(DitherBayer(screenPos.x%4,screenPos.y%4,_DitherRange)==0)
                {
                    discard;
                }
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
