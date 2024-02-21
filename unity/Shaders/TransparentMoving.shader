Shader "Custom/TransparentMoving"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _DistortionStrength ("Distortion Strength", Range(0,.1)) = 0.05
        _DistortionDensity ("Distortion Density", Range(0,1)) = .5
        _DistortionSpeed ("Speed", Range(0,1)) = .5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
        ZWrite Off
        

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:fade vertex:vert
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        // Properties
        fixed4 _Color;
        half _DistortionStrength;
        half _DistortionDensity;
        half _DistortionSpeed;

        // structs (see following for allowed inputs:
        // https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html)
        // https://docs.unity3d.com/Manual/SL-SurfaceShaders.html
        struct vertInput {
            float4 vertex : POSITION;
            // float4 tangent : TANGENT;
            float3 normal : NORMAL;
            // float4 texcoord : TEXCOORD0;
            // float4 texcoord1 : TEXCOORD1;
            // float4 texcoord2 : TEXCOORD2;
            // float4 texcoord3 : TEXCOORD3;
            // fixed4 color : COLOR;
        };
        struct Input
        {
            // float2 uv_nameoftextureproperty
            float4 color: COLOR;
            // float3 viewDir;
            // float4 screenPos;
            // float3 worldPos;
            // float3 worldRefl;// - contains world reflection vector if surface shader does not write to o.Normal. See Reflect-Diffuse shader for example.
            // float3 worldNormal;// - contains world normal vector if surface shader does not write to o.Normal.
            // float3 worldRefl: INTERNAL_DATA;// - contains world reflection vector if surface shader writes to o.Normal.
            // float3 worldNormal: INTERNAL_DATA;// - contains world normal vector if surface shader writes to o.Normal.
        };

        // functions
        void vert(inout vertInput v) {
            // sum of sines modulating the wobble
            float frequency = 1/_DistortionDensity;
            float speed = _DistortionSpeed;
            float amplitude = _DistortionStrength;
            float adjustment = 0;

            float count = 0;

            while (count < 3) {
                // calculate wave adjustment for loop
                adjustment += amplitude*sin(UNITY_TWO_PI*(v.vertex.y*frequency+_Time.y*speed*frequency));

                // adjust params for next sine wave
                frequency *= 2;
                speed *= .5;
                amplitude *= .5;

                // next count
                count++;
            } ;

            v.vertex.xyz += normalize(v.normal)*adjustment;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
