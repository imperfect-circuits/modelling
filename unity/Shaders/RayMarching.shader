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
                float3 curPosition;
            };
            sampler2D _MainTex;
            float4 _MainTex_ST;


            ///// ray marching functions
            float GetDist(float3 vertex) {
                // sphere pos
                float3 spherePos = (0,0,0);
                float sphereRadius = .05;

                return distance(vertex, spherePos) - sphereRadius;
            }
            RayMarchResults RayMarch(float3 ro, float3 rd) {
                RayMarchResults results;
                results.distanceFromRo = 0;

                // loop for ma number of steps
                for (results.numSteps = 0; results.numSteps < MAX_STEPS; results.numSteps++) {
                    // get distance to surface
                    results.curPosition = ro+rd*results.distanceFromRo;
                    float surfDistance = GetDist(results.curPosition);

                    // if close enough, exit
                    if (surfDistance < MIN_SURFDIST || results.distanceFromRo > MAX_DIST) {
                        break;
                    }

                    // march position
                    results.distanceFromRo += surfDistance;
                }

                return results;
            }

            ///// Lighting functions
            float3 GetNormal(float3 pos) {
                // normal in a signed distance field is the gradiant, a vector
                // of the partial differentials of each dimension
                float2 h = float2(0.001, 0);
                return normalize(float3(
                    GetDist(pos+h.xyy)-GetDist(pos-h.xyy),
                    GetDist(pos+h.yxy)-GetDist(pos-h.yxy),
                    GetDist(pos+h.yyx)-GetDist(pos-h.yyx)
                ));
            }

            ///// shader functinos
            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                o.ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                o.rd = v.vertex-o.ro;
                return o;
            }
            float4 frag (v2f i) : SV_Target
            {
                // // sample the texture
                float4 col = (0,0,0,0);//tex2D(_MainTex, i.uv);

                // ray march this clip pos
                RayMarchResults r = RayMarch(i.ro, normalize(i.rd));

                // discard pixel if nothing hit
                if (r.numSteps == MAX_STEPS || r.distanceFromRo > MAX_DIST) {
                    clip(-1);
                }
                // otherwise set to white
                else {
                    col.rgb = (1,1,1);
                    col.rgb = GetNormal(r.curPosition);
                }
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            
            ENDCG
        }
    }
}
