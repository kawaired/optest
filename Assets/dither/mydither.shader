Shader "Unlit/mydither"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DitherRange("ditherrange",range(1,256))=16
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
                float4 color=tex2D(_MainTex,i.uv);
                float brightness=Luminance(color)*256;
                // float R=color.x*256;
                // float G=color.y*255;
                // float B=color.z*255;

                brightness=floor(brightness/_DitherRange);
                // R=R/_DitherRange;
                // G=G/_DitherRange;
                // B=B/_DitherRange;
                float NGray=DitherBayer(screenPos.x%4,screenPos.y%4,brightness);
                if(NGray==0)
                {
                    discard;
                }
                return color;
                // float NR=DitherBayer(screenPos.x%4,screenPos.y%4,R);
                // float NG=DitherBayer(screenPos.x%4,screenPos.y%4,G);
                // float NB=DitherBayer(screenPos.x%4,screenPos.y%4,B);
                // float3 graycolor=float3(NGray,NGray,NGray);
                // float3 finalcolor=float3(NR,NG,NB);
                //return finalcolor.xyzz;
                

                // float4 finalColor;
                // if(screenPos.x >= 300 && screenPos.x <= 500)
                // {
                //     finalColor = float4(1,1,1,1);
                // }
                // else
                // {
                //     finalColor = float4(0,0,0,1);
                // }
                // return finalColor;
            }
            ENDCG
        }
    }
}
