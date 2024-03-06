Shader "Unlit/body"
{
    Properties
    {
        //需要用到的贴图
        _MainTex ("maintext", 2D) = "white" {}
        _LightTex("lighttex",2D)="white"{}
        _ShadowRamp("shadowRamp",2D)="white"{}
        _MateTex("matetex",2D)="white"{}

        //整体色调和亮度控制
        _MyLightColor("mylightcolor",color)=(1,1,1,1)
        _LightScale("lightscale",range(0.5,1.5))=1

        //光影相关的参数
        _EmissionStrength("emissionstrength",range(0,2))=0.5
        _DiffuseOffset("diffuseoffset",range(0,1))=0.2
        _ShadowFactor("shadowfactor",range(0,1))=0.8
        _TimerNum("timenum",range(0,1))=0.5
        _SpecularColor("specularcolor",COLOR)=(1,1,1,1)
        _SpecularStrength("specularstrength",range(0,2))=0.2
        _SpecularOffset("specularoffset",range(0,0.5))=0.15
        _BottomParam("bottomparam",range(-1,1))=-0.2
        _TopParam("topparam",range(-1,1))=0.2
        _RimWidth("rimwidth",range(0,1))=0.1
        _RimStrange("rimstrange",range(0,0.2))=0.4
        _MaxOutlineZoffset("maxoutlinzoffset",range(0,1))=0.5

        //外描边的相关参数
        _LineColor("linecolor",COLOR)=(0,0,0,0)
        _LineWidth("linewidth",range(0,0.1))=0.0035

        //Pixel Masks for Screen-Door Transparency
        _DitherRange("ditherrange",range(0,16))=16
        [KeywordEnum(None,LightMap_R,LightMap_G,LightMap_B,LightMap_A,UV,BaseColor,BaseColor_A)] _TestMode("_TestMode",Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            cull back
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
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldnormal:TEXCOORD1;
                float3 lightdir:TEXCOORD2;
                float3 viewdir:TEXCOORD3;
                float4 tangent:TANGENT;
                float3 normal:NORMAL;
                float4 test:TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _LightTex;
            float4 _LightTex_ST;
            sampler2D _ShadowRamp;
            float4 _ShadowRamp_ST;
            sampler2D _MateTex;
            float4 _MateTex_ST;
            sampler2D _CameraDepthTexture;
            float4 _MyLightColor;
            float _LightScale;

            float4 _EmissionColor;
            float _EmissionStrength;
            float _DiffuseOffset;
            float _TimerNum;
            float _SpecularStrength;
            float _SpecularOffset;
            float _BottomParam;
            float _TopParam;
            float _RimWidth;
            float _RimStrange;
            float _ShadowFactor;
            float _DitherRange;

            float _TestMode;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.test=o.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldnormal=UnityObjectToWorldNormal(v.normal);
                o.lightdir=normalize(UnityWorldSpaceLightDir(v.vertex));
                o.viewdir=normalize(WorldSpaceViewDir(v.vertex));
                o.tangent=v.tangent;
                o.normal=v.normal;
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
                //return i.normal.xyzz;
                //return i.tangent;
                //Pixel Masks for Screen-Door Transparency
                //return i.test;
                // return i.vertex/400;
                // return i.vertex.xyzw/i.vertex.w;
                if(DitherBayer(i.vertex.x%4,i.vertex.y%4,_DitherRange)==0)
                {
                    discard;
                }

                //主贴图与光照贴图的采样
                float4 maintex=tex2D(_MainTex,i.uv);
                float4 lighttex=tex2D(_LightTex,i.uv);

                //通道颜色展示
                int mode = 1;
                if(_TestMode == mode++)
                    return lighttex.x;
                if(_TestMode ==mode++)
                    return lighttex.y; //阴影 Mask
                if(_TestMode ==mode++)
                    return lighttex.z; //漫反射 Mask
                if(_TestMode ==mode++)
                    return lighttex.w; //漫反射 Mask
                if(_TestMode ==mode++)
                    return float4(i.uv,0,0); //uv
                if(_TestMode ==mode++)
                    return maintex.xyzz; //BaseColor
                if(_TestMode ==mode++)
                    return maintex.wwww; //BaseColor.a
                //通道颜色输出结束代码部分结束

                //相关变量申明
                float3 worldnormal=normalize(i.worldnormal);
                float4 finalcolor=float4(0,0,0,0);
                float4 diffusecolor=float4(0,0,0,0);
                float4 specularcolor=float4(0,0,0,0);
                float4 emissioncolor=float4(0,0,0,0);

                //漫反射
                float ndotl=dot(worldnormal,i.lightdir);
                float stepfactor=saturate(smoothstep(_BottomParam,_TopParam,ndotl));
                float4 warmcolor=tex2D(_ShadowRamp,float2(clamp(lighttex.w,0.05,0.95),clamp((1-stepfactor)*0.5+0.5,0.53,0.97)));
                float4 coolcolor=tex2D(_ShadowRamp,float2(clamp(lighttex.w,0.05,0.95),clamp((1-stepfactor)*0.5,0.03,0.47)));
                //return warmcolor;
                float4 lerpcolor=lerp(coolcolor,warmcolor,_TimerNum);
                diffusecolor=maintex*(float4(1,1,1,1)-(float4(1,1,1,1)-lerpcolor)*_DiffuseOffset)*lerp(_ShadowFactor,1,stepfactor);
                //return diffusecolor;

                //高光反射
                float samplingx=clamp(dot(normalize(worldnormal.xz),normalize(i.viewdir.xz))*0.5-_SpecularOffset,0.05,0.5);
                float4 matetex=tex2D(_MateTex,float2(samplingx,worldnormal.y*0.495+0.5));
                specularcolor=(matetex*lighttex.x)*maintex*_SpecularStrength;

                //自发光
                emissioncolor=maintex*_EmissionStrength;

                //边缘光
                float2 screenParams01 = float2(i.vertex.x/_ScreenParams.x,i.vertex.y/_ScreenParams.y);
                float2 uvofs=screenParams01+UnityObjectToClipPos(i.tangent).xy*_RimWidth*i.vertex.z;
                float depth=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,uvofs);
                depth=LinearEyeDepth(depth);
                // return depth;
                float rim=((i.vertex.z-depth)>0.01)*_RimStrange;
                // return rim;
                //混色得到最终输出的颜色
                float4 physiclight=lerp(diffusecolor,specularcolor,lighttex.z);
                finalcolor=lerp(physiclight,emissioncolor,maintex.w)+rim.xxxx;
                return finalcolor*_MyLightColor*_LightScale;
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
                float2 uv : TEXCOORD0;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _LineWidth;
            float4 _LineColor;
            float _DitherRange;
            float _MaxOutlineZoffset;

            v2f vert (appdata v)
            {
                // v2f o;
                // o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // UNITY_TRANSFER_FOG(o,o.vertex);

                // o.vertex=UnityObjectToClipPos(v.vertex);
                // float tempx=abs(o.vertex.w)/abs(UNITY_MATRIX_P[1].y);
                // float3 viewnormal=mul((float3x3)UNITY_MATRIX_IT_MV,v.tangent.xyz);
                // float2 ndcnormal=normalize(UnityViewToClipPos(viewnormal).xy);
                // o.vertex.xy=o.vertex.xy+sqrt(tempx)*_LineWidth*ndcnormal;
                // return o;

                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                float3 viewvertex=UnityObjectToViewPos(v.vertex);
                float2 viewnormalxy=normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.tangent.xyz)).xy;
                float3 zoffsetfactor=(1+_MaxOutlineZoffset)*viewvertex;
                float tempx=abs(zoffsetfactor.z)/abs(UNITY_MATRIX_P[1].y);
                float4 temp=float4(0,0,0,0);
                temp.xy=sqrt(tempx)*_LineWidth*viewnormalxy+zoffsetfactor.xy;
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
                float4 maincolor=tex2D(_MainTex,i.uv);
                //return maincolor;
                return float4(maincolor.xyz*_LineColor,1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
