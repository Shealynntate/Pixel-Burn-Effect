
// Pixel Burn Effect for Unity

// Copyright (c) 2017 Shealyn Hindenlang

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

Shader "Custom/PixelBurn3DEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Base Color", Color) = (1, 1, 1, 1)
		_Glossiness ("Smoothness", Range(0, 1)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0

		[Space(10)]
		_NoiseTex ("Noise Texture", 2D) = "black" {}
		_GlowColor ("Glow Color", Color) = (1, 1, 1, 1)
		[Space(10)]
		[Header(Adjust Effect Parameters)]
		_Speed ("Effect Speed", Range(0, 30)) = 10
		_Start ("Start", Range(0, 0.999)) = 0.5
		_End ("End", Range(0.001, 1)) = 0.9
		_TexCutoff ("Texture Cutoff Alpha", Range(0, 1)) = 0.5
		_GlowCutoff ("Glow Cutoff Alpha", Range(0, 1)) = 0.3
		[IntRange]_PixelLevel ("Pixelization Level", Range(0, 512)) = 80
	}

	SubShader
	{
		Tags 
		{ 
			"RenderType" = "Transparent"
			"Queue" = "Transparent" 
			"DisableBatching" = "True"
			"IgnoreProjector" = "True"
		}
		
		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows vertex:vert alpha:fade
		#pragma target 3.0
		
		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_NoiseTex;
			float3 objPos;
		};
 
        void vert (inout appdata_full v, out Input o) 
		{
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.objPos = v.vertex;
        }

		sampler2D _MainTex;
		sampler2D _NoiseTex;
		fixed4 _Color;
		half _Glossiness;
		half _Metallic;
		fixed4 _GlowColor;
		float _Speed;
		float _Start;
		float _End;
		float _TexCutoff;
		float _GlowCutoff;
		int _PixelLevel;
		
		// Simple function to grab the brightness out of an image without an alpha channel. 
		float tex_brightness(fixed4 c)
		{
			return c.r * 0.3 + c.g * 0.59 + c.b * 0.11;
		}
		
		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			float max_brightness = 0; 
			float min_brightness = -1;

			// Set the y coordinate to [0, 1] in object space
			float y = IN.objPos.y + 0.5;

			// Calculate the slope and offset of the fade-out equation
			float slope = (min_brightness - max_brightness) / (_End - _Start);
			float offset = max_brightness - slope * _Start;
			
			float t = fmod(_Time.x * _Speed, 1);
			float2 noise_uv = float2(IN.uv_NoiseTex.x, IN.uv_NoiseTex.y - t);
			noise_uv = floor(_PixelLevel * noise_uv) / _PixelLevel;
			float noise_alpha = tex_brightness(tex2D(_NoiseTex, noise_uv));

			float brightness = clamp(noise_alpha + slope * y + offset, 0, 1);

			float tex_on = step(_TexCutoff, brightness);
			float glow_on = step(_GlowCutoff, brightness) * (1 - tex_on);

			o.Albedo = tex2D(_MainTex, IN.uv_MainTex) * _Color * (1 - glow_on);
			o.Alpha = clamp(tex_on + glow_on, 0, 1);
			o.Smoothness = _Glossiness;
			o.Metallic = _Metallic;
			o.Emission = _GlowColor * glow_on;
		}

		ENDCG
	}

	FallBack "Diffuse"
}