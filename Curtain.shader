Shader "Unlit/Certain"
{
    Properties
    {
        _Color ("Color", COLOR) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "black" {}
        _Mask ("Mask map", 2D) = "black" {}
        _amp ("Amplification", Float) = 0.3
        
        _MaskScale ("Mask Scale", Range(0, 1)) = 1
        _MaskSpeed ("Mask Speed", Float) = 1
        _MaskSpeed2 ("Mask Speed 2", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Trensparent" "Queue"="AlphaTest+1" "RenderType"="Transparent"}
        Cull off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 keyLightColor : TEXCOORD1;
                float3 ambientAndBackLightColor : TEXCOORD2;
                float3 normal : NORMAL;
                LIGHTING_COORDS(0,1) // replace 0 and 1 with the next available TEXCOORDs in your shader, don't put a semicolon at the end of this line.
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : POSITION;
            };

            fixed4 _Color;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Mask;

            fixed _amp;
            fixed _MaskScale;
            fixed _MaskSpeed;
            fixed _MaskSpeed2;

            v2f vert (appdata v)
            {
                v2f o;
                float4 tex = tex2Dlod (_Mask, float4(float2(v.uv.x+_Time.x * _MaskSpeed, v.uv.y) * _MaskScale,0,0));
                float4 tex2 = tex2Dlod (_Mask, float4(float2(v.uv.x-_Time.x * _MaskSpeed2, v.uv.y) * _MaskScale,0,0));
                v.vertex.x += (0.5 - tex.r * tex2.r * _amp);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                // in vert shader;
                TRANSFER_VERTEX_TO_FRAGMENT(o); // Calculates shadow and light attenuation and passes it to the frag shader.

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 main = tex2D(_MainTex, i.uv);
                fixed4 col = tex2D(_Mask, float4(float2(i.uv.x+_Time.x * _MaskSpeed, i.uv.y) * _MaskScale,0,0));
                fixed4 col2 = tex2D(_Mask, float4(float2(i.uv.x-_Time.x * _MaskSpeed2, i.uv.y) * _MaskScale,0,0));

                col.a = col.r + col2.r;
                col2.a = col2.r + col.r;

                
                //in frag shader;
                float atten = LIGHT_ATTENUATION(i); // This is a float for your shadow/attenuation value, multiply your lighting value by this to get shadows. Replace i with whatever you've defined your input struct to be called (e.g. frag(v2f [b]i[/b]) : COLOR { ... ).

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return main * (atten - col.r + col2.r) * _Color;
            }
            ENDCG
        }
    }
}
