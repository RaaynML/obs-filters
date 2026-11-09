//single-pass *approximation* of Ioxa's ReShade Clarity.
uniform int ClarityRadius = 3;
uniform float ClarityOffset = 2.0;
uniform int ClarityBlendMode = 2;
uniform int ClarityBlendIfDark = 50;
uniform int ClarityBlendIfLight = 205;
uniform bool ClarityViewBlendIfMask = false;
uniform float ClarityStrength = 0.4;
uniform float ClarityDarkIntensity = 0.4;
uniform float ClarityLightIntensity = 0.0;
uniform bool ClarityViewMask = false;

float sampleLuma(float2 uv){
	float3 rgb = image.Sample(textureSampler, uv).rgb;
	return dot( rgb, float3( 0.32786885, 0.655737705, 0.0163934436 ) );
}

float kernelWeight(int i){
	if(i == 0){ return ( 6.0 / 16.0 ); }
	if(abs(i) == 1){ return ( 4.0 / 16.0 ); }
	return ( 1.0 / 16.0 );
}

float smoothMask(float value, float edge){
	float width = max(edge * 0.4, 0.0001);
	float t = saturate((value - (edge - width * 0.5)) / width);
	return t * t * (3.0 - 2.0 * t);
}

float blendClarity(float base, float mask){
	if(ClarityBlendMode == 0){
		float a = 2.0 * base * mask + base * base * (1.0 - 2.0 * mask);
		float b = 2.0 * base * (1.0 - mask) + sqrt(max(base, 0.0)) * (2.0 * mask - 1.0);
		return lerp(a, b, step(0.49, mask));
	}
	if(ClarityBlendMode == 1){ return lerp(2.0 * base * mask, 1.0 - 2.0 * (1.0 - base) * (1.0 - mask), step(0.5, base)); }
	if(ClarityBlendMode == 2){ return lerp(2.0 * base * mask, 1.0 - 2.0 * (1.0 - base) * (1.0 - mask), step(0.5, mask)); }
	if(ClarityBlendMode == 3){ return saturate(2.0 * base * mask);	}
	if(ClarityBlendMode == 4){
		float hi = base / max(2.0 * (1.0 - mask), 0.0001);
		return lerp(2.0 * base * mask, hi, step(0.5, mask));
	}
	if(ClarityBlendMode == 5){ return base + 2.0 * mask - 1.0; }
	return saturate(base + mask - 0.5);
}

float4 mainImage(VertData v_in) : TARGET
{
	float4 original = image.Sample(textureSampler, v_in.uv);
	float luma = dot( original.rgb, float3( 0.32786885, 0.655737705, 0.0163934436 ) );

	float radius = (1.0 + (float)ClarityRadius * 1.5) * max(ClarityOffset, 0.0);
	float2 stepUV = radius / uv_size.xy;
	float blurredLuma = 0.0;

	[unroll]
	for(int y = -2; y <= 2; ++y){
		[unroll]
		for(int x = -2; x <= 2; ++x){
			float weight = kernelWeight(x) * kernelWeight(y);
			blurredLuma += sampleLuma(v_in.uv + float2(x,y) * stepUV) * weight;
		}
	}

	float sharp = (luma + 1.0 - blurredLuma) * 0.5;
	float curved = sharp * sharp * sharp * (sharp * (sharp * 6.0 - 15.0) + 10.0);
	float darkMask = lerp(sharp, curved, ClarityDarkIntensity);
	float lightMask = lerp(sharp, curved, ClarityLightIntensity);
	sharp = lerp(darkMask, lightMask, step(0.5, sharp));

	float blendIfMask = 1.0;
	float pixelLuma = dot(original.rgb, float3(0.3333333, 0.3333333, 0.3333333));

	if(ClarityBlendIfDark > 0){ blendIfMask *= smoothMask(pixelLuma, (float)ClarityBlendIfDark / 255.0); }
	if(ClarityBlendIfLight < 255){ blendIfMask *= 1.0 - smoothMask(pixelLuma, (float)ClarityBlendIfLight / 255.0); }

	if(ClarityViewBlendIfMask){ return float4(blendIfMask.xxx, original.a); }

	if(ClarityViewMask){ return float4(sharp.xxx, original.a); }

	float adjustedLuma = blendClarity(luma, sharp);
	float3 chroma = original.rgb / max(luma, 0.0001);
	float3 clarityColor = saturate(chroma * adjustedLuma);
	float amount = saturate(ClarityStrength * blendIfMask);

	return float4(lerp(original.rgb, clarityColor, amount), original.a);
}
