Shader "Unlit/door"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _DetailMask("detailmask",2D)="White"{}
        _BumpMap("bumpmap",2D)="white"{}
        _CubeMap("cubemap",Cube)=""{}


        _ElementViewEleDrawOn("elementvieweledrawon",range(0,1))=0.3
        _Color("color", Color)=(0.3,0.3,0.3,0.3)
        _EmissionRange("emissionrange",range(0,5))=0.3
        _UseMainMaskAlphaAsEmission("usemainmaskalphaasemission",range(0,10))=0.5
        _ReflectionCube_HDR("reflectioncube_HDR",float)=(0.2,0.2,0.2,0.2)
        _ReflectionCube_TexelSize("reflectioncube_texelsize",float)=(0.3,0.3,0.3,0.3)
        _MulAlbedo("mulalbedo",range(0,4))=1
        _EmissionColor("emissioncolor",Color)=(0.3,0.3,0.3,0.3)
        _EmissionStrength("emissionstrength",range(0,5))=2
        _RGColor("RGcolor",Color)=(0.1,0.1,0.1,0.1)
        _RGPower("RGpower",range(0,2))=0.5
        _RGStrength("RGstrenth",range(0,3))=1
        _FillNormalGaps("fillnormalgaps",range(0,1))=0.3
        _RainNoiseParam("rainnoiseparam",float)=(0.2,0.2,0.2,0.2)
        _RainIntensity("raininstensity",range(0,1))=0.5

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
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
                float4 tangent:TANGENT;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 tex1:TEXCOORD1;
                float4 tex2:TEXCOORD2;
                float4 tex3:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailMask;
            float4 _DetailMask_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _CubeMap;

            float _ElementViewEleDrawOn;
            float4 _Color;
            float _EmissionRange;
            float _UseMainMaskAlphaAsEmission;
            float4 _ReflectionCube_HDR;
            float4 _ReflectionCube_TexelSize;
            float _MulAlbedo;
            float4 _EmissionColor;
            float _EmissionStrength;
            float4 _RGColor;
            float _RGPower;
            float _RGStrength;
            float _FillNormalGaps;
            float4 _RainNoiseParam;
            float _RainIntensity;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // float3 worldnormal=UnityObjectToWorldNormal(v.normal);
                // float3 worldtangent=UnityObjectToWorld(v.tangent);
                // float3 sidetangent=cross(v.normal,v/tangent);
                float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 worldBinormal = normalize(cross(worldNormal, worldTangent)) * tangentSign;
                float3 worldpos=UnityObjectToWorldDir(v.vertex);
                o.tex1=float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldpos.x);
                o.tex2=float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldpos.y);
                o.tex3=float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldpos.z);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 maintex=tex2D(_MainTex,i.uv).xyz;
                float3 detailmask=tex2D(_DetailMask,i.uv).xyw;
                float tempx=_UseMainMaskAlphaAsEmission*detailmask.z;
                float3 mainmulcolor=maintex.xyz*_Color.xyz;
                float xlat16_33=clamp(detailmask.x,0.001,0.999);
                float4 bumptex=float4(0,0,0,0);
                //return tex2D(_BumpMap,i.uv);
                bumptex.xyz=tex2D(_BumpMap,i.uv).xyz;
                //return bumptex.xyzz;
                bool xlatb1=0;
                float4 temp=float4(0,0,0,0);
                temp.xyz=bumptex.xyz*2+float3(-1,-1,-1);//temp就是经过处理的还原的对应顶点的真实法线方向
                //return temp.xyzz;
                // xlatb1=bool(sqrt(dot(temp.xy,temp.xy))<_FillNormalGaps);
                // if(xlatb1)
                // {
                //     temp.xy=float2(0,0);
                // }
                float3 xlat4=float3(0,0,0);
                xlat4=(dot(i.tex1.xyz,temp.xyz),dot(i.tex2.xyz,temp.xyz),dot(i.tex1.xyz,temp.xyz));//取出法线贴图的法线信息，将其转化到世界空间下。
                float4 xlat1=float4(0,0,0,0);
                xlat1.xzw=normalize(xlat4).xyz;//
                return xlat1.xzww;
                //return xlat1.xzww;
                //return xlat1.xzww;
                //return float4(xlat1.xzw,1);
                xlat4=(i.tex1.w,i.tex2.w,i.tex3.w);
                float3 viewdir=normalize(_WorldSpaceCameraPos.xyz-xlat4);
                //return viewdir.xyzz;
                temp.x=saturate(_RainNoiseParam.z*_RainIntensity);
                //float xlat14=-xlat16_33+1;
                temp.w=temp.x*(1-xlat16_33)+xlat16_33;//更具temp.x做xlat16_33的值到1之间的一个插值,是对detailmask，R值的一个描述
                //return temp.wwww;
                float4 xlat5=(0,0,0,0);
                xlat5.xyz=_EmissionColor.xyz*_EmissionStrength*tempx;//控制发光强度与颜色，其中detailmask.z会影响xlat5
                float3 xlat6=(0,0,0);
                xlat6=(_MulAlbedo.xxx*mainmulcolor-_MulAlbedo.xxx+float3(1,1,1))*xlat5.xyz;//根据mulalbedo对主色调进行插值，然后乘上一个发光强度
                float xlat33=0;
                //return dot(xlat1.xzw,viewdir.xyz).xxxx;
                xlat33=max(1-max(dot(xlat1.xzw,viewdir.xyz),0),0);//fresnel
                tempx=min(pow(xlat33+0.0001,_RGPower),1);//提高fresenl的变化剧烈程度
                //return tempx.xxxx;
                xlat5.xyz=(_RGColor.xyz*_RGStrength.xxx-xlat6)*tempx+xlat6;//填充fresenl的颜色
                //return xlat5.xyzz;
                //return float4(xlat5.xyz,1);
                float3 xlat7=(0,0,0);
                xlat7.xyz=maintex.xyz*_Color.xyz-float3(0.04,0.04,0.04);
                tempx=1-temp.w;//detailmask，R值描述的取反
                float4 xlat0=float4(0,0,0,0);
                xlat0.xyz=detailmask.yyy*xlat7.xyz+float3(0.04,0.04,0.04);//通过deatilmask的y值来控制主主色调的强弱
                float xlat37=max(tempx,0.001);//属于(0.001,1)
                //return xlat37.xxxx;
                tempx=1-0.5*pow(detailmask.y*xlat37,2);//属于（0.5,1）,根据detailmask的G值勾勒出较暗的线条
                //return tempx.xxxx;
                //tempx=1-detailmask.y*xlat37;
                //return tempx.xxxx;
                //return xlat0.xyzz;
                xlat7=tempx*xlat0.xyz;
                //return xlat7.xyzz;
                float xlat40=0;
                xlat40=dot(viewdir.xyz,xlat1.xzw);//fresnel
                //return xlat40.xxxx;
                float3 xlat8=(0,0,0);
                //return xlat1.xzww;

                xlat8.xyz=xlat1.xzw*(2*xlat40)-viewdir.xyz;//根据视角出现渐变的HDR采样纹理的采样向量
                //return xlat1.xzww;
                //return xlat8.xyzz;
                //xlat8.xyz=viewdir.xyz;
                //return xlat8.xyzz;
                // float xlat41=0;
                // xlat41=log2(_ReflectionCube_TexelSize.z)*xlat37;
                float4 cubemsg=(0,0,0,0);
                // cubemsg=texCUBElod(_CubeMap,xlat8.xyz,xlat41);
                cubemsg=texCUBE(_CubeMap,xlat8.xyz);//读取cubemap的信息,其中cubemap的rgb的三个分量是呈递增的
                //return cubemsg.xyzz;
                float3 xlat9=(0,0,0);
                //return cubemsg;
                //  xlat9=pow((cubemsg.w-1)*_ReflectionCube_HDR.w+1,_ReflectionCube_HDR.y)*_ReflectionCube_HDR.x*cubemsg.xyz;
                //  xlat9=xlat9.xyz*(1-xlat37);
                //return cubemsg.wwww;
                //return pow((cubemsg.w-1)*_ReflectionCube_HDR.w+1,_ReflectionCube_HDR.y).xxxx;
                xlat9=pow(pow((cubemsg.w-1)*_ReflectionCube_HDR.w+1,_ReflectionCube_HDR.y)*_ReflectionCube_HDR.x*cubemsg.xyz,2)*(1-xlat37);//detailmask的R值的插值后的描述与cubemsg共同描述HDR的亮度信息
                //return xlat9.xyzz;
                xlat40=max(xlat40,0.001);
                //return xlat40.xxxx;
                xlat8.x=max(dot(xlat1.xzw,xlat8.xyz),0.001);
                float xlat19=exp2((xlat40*(-5.55)-7)*xlat40);//其中xlat19∈(0,1)
                float3 xlat10=(0,0,0);
                xlat10.xyz=(-xlat0.xyz)*tempx+float3(1,1,1);
                //return xlat10.xyzz;
                //return (xlat0.xyz*tempx).xyzz;
                //return xlat19.xxxx;
                //return xlat7.xyzz;
                xlat7.xyz=xlat10.xyz*xlat19+xlat7.xyz;//取xlat7到1的插值
                //return (xlat10.xyz*xlat19).xyzz;
                //return xlat7.xyzz;
                tempx=max(pow(xlat37,2)*0.5,0.0001);//加强线条对比，同时降低整体亮度
                xlat19=1-tempx;
                float xlat30=1/(xlat8.x*xlat19+tempx);
                tempx=(1/(xlat40*xlat19+tempx))*xlat30;
                xlat7.xyz=xlat7.xyz*xlat9.xyz*tempx*xlat40;
                tempx=1-detailmask.y;
                float4 test=(0,0,0,0);
                test.xyz=tempx*mainmulcolor;
                temp.xyz=xlat7.xyz*xlat8.x+test.xyz;
                test.x=sqrt(dot(xlat5.xyz,xlat5.xyz));
                //return xlat5.xyzz;
                float xlat12=0;
                if(test.x>=_EmissionRange)
                {
                    test.x=max(xlat5.z,xlat5.y);
                    test.w=max(test.x,xlat5.x);
                    test.xyz=xlat5.xyz/test.www;
                    xlat5.w=1;
                    if(test.w>1)
                    {
                        xlat0=test;
                    }
                    else
                    {
                        xlat0=xlat5;
                    }
                    xlat12=saturate(xlat0.w*0.05);
                    float xlat35=sqrt(xlat12);
                    xlat5.x=13;
                    test.w=xlat35;
                }
                else
                {
                    xlat5.x=0;
                    test.w=temp.w;
                    temp.w=0;
                }
                test.xyz=xlat1.xzw*0.5+0.5;
                //return test;
                return test.xyzz;
                xlat0.w=xlat5.x*0.004;
                if(!all(float4(0,0,0,0)==float4(_ElementViewEleDrawOn.xxxx)))
                {
                    xlat0.z=0;
                }
                // return test;
                // return xlat0;
                // return temp;
                //return float4(0.2,0.2,0.2,0.2);
               return test;
                // // sample the texture
                // fixed4 col = tex2D(_MainTex, i.uv);
                // // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                // return col;
            }
            ENDCG
        }
        
    }
}
