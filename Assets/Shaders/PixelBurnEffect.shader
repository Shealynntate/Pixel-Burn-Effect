
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

Shader "Unlit/PixelBurnEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex ("Noise Texture", 2D) = "black" {}
		[Space(10)]
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
		
		Blend SrcAlpha OneMinusSrcAlpha
		Fog { Mode Off }
		Lighting Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 noise_uv : TEXCOORD1;
				float4 vertex : SV_POSITION;
				float4 objPos : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
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

			v2f vert (appdata v)
			{
				v2f o;
				o.objPos = v.vertex;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.noise_uv = TRANSFORM_TEX(v.uv, _NoiseTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float max_brightness = 0; 
 				float min_brightness = -1;

 				// Set the y coordinate to [0, 1] in object space
 				float y = i.objPos.y + 0.5;

				// Calculate the slope and offset of the fade-out equation
				float slope = (min_brightness - max_brightness) / (_End - _Start);
				float offset = max_brightness - slope * _Start;
				
				float t = fmod(_Time.x * _Speed, 1);
				float2 noise_uv = float2(i.noise_uv.x, i.noise_uv.y - t);
				noise_uv = floor(_PixelLevel * noise_uv) / _PixelLevel;
				float noise_alpha = tex_brightness(tex2D(_NoiseTex, noise_uv));

				float brightness = clamp(noise_alpha + slope * y + offset, 0, 1);

 				float tex_on = step(_TexCutoff, brightness);
				float glow_on = step(_GlowCutoff, brightness);

				return (tex2D(_MainTex, i.uv) * tex_on + glow_on * (1 - tex_on)) * _GlowColor;
			}

			ENDCG
		}
	}
}