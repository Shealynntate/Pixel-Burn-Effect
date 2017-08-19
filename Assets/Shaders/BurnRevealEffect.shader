
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

Shader "Custom/BurnRevealEffect"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_Color ("Base Color", Color) = (1, 1, 1, 1)
		_Glossiness ("Smoothness", Range(0, 1)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0

		[Space(15)]
		_NoiseTex ("Noise Texture", 2D) = "black" {}
		_GlowColor ("Glow Color", Color) = (0.85, 1, 1, 1)
		[Space(15)]
		_EffectRadius ("Effect Radius", Range(0, 2)) = 0.5
		_DistortionLevel ("Distortion Level", Range(0, 0.5)) = 0.01
		_TexCutoff ("Texture Cutoff", Range(0, 1)) = 0.5
		_GlowAmount ("Glow Amount", Range(0, 1)) = 0.5
		[Toggle(ENABLE_PIXELIZATION)] _EnablePixel ("Pixelate?", Float) = 0
		[IntRange]_PixelLevel ("Pixelization Level", Range(0, 256)) = 80
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
		}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows alpha:fade
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _NoiseTex;
		fixed4 _Color;
		half _Glossiness;
		half _Metallic;
		fixed4 _GlowColor;
		float _EffectRadius;
		float _DistortionLevel;
		float _TexCutoff;
		float _PixelLevel;
		float _EnablePixel;
		float _GlowAmount;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_NoiseTex;
			float3 viewDir;
			float3 worldPos;
		};

		float tex_brightness(fixed4 c)
		{
			return c.r * 0.3 + c.g * 0.59 + c.b * 0.11;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			float tex_alpha_cutoff = 1 - _TexCutoff;

			float4 center = float4(0, 0, 0, 1);
			float3 local_pos = IN.worldPos - mul(unity_ObjectToWorld, center).xyz;
			float dot_product = dot(normalize(local_pos), normalize(IN.viewDir));
			
			// Pixelate the noise uv coordinates
			float2 noise_uv = _EnablePixel * floor(_PixelLevel * IN.uv_NoiseTex) / _PixelLevel + (1 - _EnablePixel) * IN.uv_NoiseTex;

			// Grab brightness value from noise texture
			float noise_tex_alpha = tex_brightness(tex2D(_NoiseTex, noise_uv));
		
			float brightness = clamp(noise_tex_alpha * _DistortionLevel + dot_product - (1 - _EffectRadius), 0, 1);
			float glow_cutoff_alpha = tex_alpha_cutoff - _GlowAmount * brightness;
			
			// Putting it all together
			float tex_visible = step(tex_alpha_cutoff, brightness);
			float glow_visible = (1 - tex_visible) * step(glow_cutoff_alpha, brightness);
			
			o.Albedo = tex2D(_MainTex, IN.uv_MainTex) * _Color * (1 - glow_visible);
			o.Alpha = clamp(tex_visible + glow_visible, 0, 1);
			o.Smoothness = _Glossiness;
			o.Metallic = _Metallic;
			o.Emission = _GlowColor * glow_visible;
		}

		ENDCG
	}

	FallBack "Diffuse"
}
