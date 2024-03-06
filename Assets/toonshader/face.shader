Shader "Unlit/face"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _ShadowTex("shadowtex",2D)="white"{}
        _ShadowFactor("shadowfactor",range(0.5,1))=0.9
        _ShadowParam("shadowparam",range(0,2))=1
        _ShadowColor("shadowcolor",color)=(0,0,0,0)
        _MyLightColor("mylightcolor",color)=(0,0,0,0)
        _LightScale("lightscale",range(0.5,1.5))=1
        _LineColor("linecolor",COLOR)=(0,0,0,0)
        _LineWidth("linewidth",range(0,0.1))=0.05
        _MaxOutlineZoffset("maxoutlinzoffset",range(0,1))=0.5
        _Scale("scale",range(0,4))=2
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
                float3 lightdir:TEXCOORD1;
                float3 worldfront:TEXCOORD2;
                float3 worldleft:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ShadowTex;
            float4 _ShadowTex_ST;
            float _ShadowFactor;
            float _ShadowParam;
            float4 _ShadowColor;
            float4 _MyLightColor;
            float _LightScale;
            float _DitherRange;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.lightdir=UnityWorldSpaceLightDir(UnityObjectToWorldDir(v.vertex));
                o.worldfront=UnityObjectToWorldDir(float3(0,0,1)); 
                o.worldleft=UnityObjectToWorldDir(float3(-1,0,0));
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
                //return i.worldfront.z;
                 if(DitherBayer(i.vertex.x%4,i.vertex.y%4,_DitherRange)==0)
                {
                    discard;
                }
                float4 maintex=tex2D(_MainTex,i.uv);
                float4 shadowtex=float4(0,0,0,0);
                float frontlight=dot(i.worldfront.xz,i.lightdir.xz);
                float leftlight=dot(i.worldleft.xz,i.lightdir.xz);

                shadowtex=(leftlight<0)*tex2D(_ShadowTex,float2(1-i.uv.x,i.uv.y))+(leftlight>=0)*tex2D(_ShadowTex,i.uv);
                //return shadowtex;

                float confrontfactor=(frontlight>0)*(min(shadowtex.x>0,(frontlight+shadowtex.x)>=_ShadowParam));
                //return confrontfactor;
                float backtofactor=(frontlight<=0)*max(shadowtex.x+frontlight>=_ShadowParam,shadowtex.x>0.98);
                //return backtofactor;
                float facefactor=confrontfactor+backtofactor;
                //float4 facecolor=(1-facefactor)*_ShadowFactor*maintex+facefactor*maintex;
                float4 facecolor=lerp(facefactor,1,_ShadowFactor)*maintex;
                // return shadowtex.a;
                return facecolor*_MyLightColor*_LightScale;
            }
            ENDCG
        }
        Pass
        {
            cull front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float4 _LineColor;
            float _LineWidth;
            float _MaxOutlineZoffset;
            float _Scale;
            float _DitherRange;

            v2f vert (appdata v)
            {
                v2f o;
                float3 viewvertex=UnityObjectToViewPos(v.vertex);
                float2 viewnormalxy=normalize(float3(UnityObjectToViewPos(v.tangent.xyz).xy,0.01)).xy;
                float3 zoffsetfactor=(1+_MaxOutlineZoffset)*viewvertex;
                float tempx=abs(zoffsetfactor.z)/abs(UNITY_MATRIX_P[1].y);
                float4 temp=float4(0,0,0,0);
                temp.xy=sqrt(tempx)*_LineWidth*_Scale*viewnormalxy+zoffsetfactor.xy;
                o.vertex=UnityViewToClipPos(float3(temp.xy,zoffsetfactor.z));
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
                if(DitherBayer(i.vertex.x%4,i.vertex.y%4,_DitherRange)==0)
                {
                    discard;
                }
                return _LineColor;
            }
            ENDCG
        }
    }
}
