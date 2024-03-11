Shader "Custom/Unlit/RayMarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            ///// defines for ray marching
            #define MAX_STEPS 100
            #define MIN_SURFDIST 0.001
            #define MAX_DIST 100

            #include "UnityCG.cginc"

            ///// structs
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 rd : TEXCOORD2;
                UNITY_FOG_COORDS(1)
            };
            struct RayMarchResults
            {
                float distanceFromRo;
                int numSteps;
            };
            sampler2D _MainTex;
            float4 _MainTex_ST;


            ///// ray marching functions
            float GetDist(float3 vertex) {
                // sphere pos
                float3 spherePos = float3(0,0,5);
                float sphereRadius = 1;

                return distance(vertex, spherePos) - sphereRadius;
            }
            RayMarchResults RayMarch(float3 ro, float3 rd) {
                RayMarchResults results;
                results.distanceFromRo = 0;

                // loop for ma number of steps
                for (results.numSteps = 0; results.numSteps < MAX_STEPS; results.numSteps++) {
                    // get distance to surface
                    float surfDistance = GetDist(ro+rd*results.distanceFromRo);

                    // if close enough, exit
                    if (surfDistance < MIN_SURFDIST) {
                        break;
                    }

                    // march position
                    results.distanceFromRo += surfDistance;
                }

                return results;
            }

            ///// shader functinos
            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                o.ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                o.rd = o.vertex-o.ro;
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                // // sample the texture
                fixed4 col = fixed4(0,0,0,0);//tex2D(_MainTex, i.uv);

                // ray march this clip pos
                RayMarchResults r = RayMarch(i.ro, normalize(i.rd));

                // discard pixel if nothing hit
                if (r.numSteps == MAX_STEPS) {
                    clip(-1);
                }
                // otherwise set to white
                else {
                    col.rgb = fixed3(1,1,1);
                }
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            
            ENDCG
        }
    }
}
