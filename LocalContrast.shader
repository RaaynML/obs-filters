#define LC_BLOCK 8
#define LC_SAMPLES 4

uniform bool CorrectGamma<
	string label = "Perform gamma correction";
> = true;

uniform int ContrastLimit<
	string label = "Contrast limit";
	string widget_type = "slider";
	float minimum = 0.0;
	float maximum = 63.0;
	float step = 1.0;
> = 40;

float luma709(float3 rgb){
	return dot(rgb, float3(0.2126, 0.7152, 0.0722));
}

float curveWeight(float value){
	float bottom = min(value, 0.5);
	float top = max(value, 0.5);
	return 2.0 * (bottom * bottom + 2.0 * top - top * top) - 1.5;
}

float4 mainImage(VertData v_in) : TARGET {
	float2 pixel = floor(v_in.uv * uv_size);
	float2 blockOrigin = floor(pixel / LC_BLOCK) * LC_BLOCK;
	float2 sampleStep = LC_BLOCK / (float)LC_SAMPLES;
	float2 texel = 1.0 / uv_size;
	float2 halfTexel = texel * 0.5;

	float minLuma = 1.0;
	float maxLuma = 0.0;
	float meanLuma = 0.0;

	[unroll]
	for(int iy = 0; iy < LC_SAMPLES; ++iy){
		[unroll]
		for(int ix = 0; ix < LC_SAMPLES; ++ix){
			float2 samplePixel = blockOrigin + (float2(ix, iy) + 0.5) * sampleStep;
			float2 sampleUV = clamp(samplePixel * texel, halfTexel, 1.0 - halfTexel);
			float sampleY = luma709(image.Sample(textureSampler, sampleUV).rgb);

			minLuma = min(minLuma, sampleY);
			maxLuma = max(maxLuma, sampleY);
			meanLuma += sampleY;
		}
	}

	float sampleCount = (float)(LC_SAMPLES * LC_SAMPLES);
	meanLuma /= sampleCount;

	float contrastLimit = 1.0 - (float)ContrastLimit / 127.0;
	minLuma = min(minLuma, max(0.0, meanLuma - contrastLimit));
	maxLuma = max(maxLuma, min(1.0, meanLuma + contrastLimit));

	float4 source = image.Sample(textureSampler, v_in.uv);
	float3 rgb = source.rgb;

	float y = (luma709(rgb) - minLuma) / max(maxLuma - minLuma, 0.00001);
	float u = dot(rgb, float3(-0.09991, -0.33609, 0.436));
	float v = dot(rgb, float3(0.615, -0.55861, -0.05639));

	if(CorrectGamma){
		float curveAmount = 2.0 - contrastLimit * 2.0;
		curveAmount = curveAmount * curveAmount * curveAmount;
		y = lerp(y, curveWeight(y), curveAmount);
	}

	float3 result = float3(
		y + 1.28033 * v, y - 0.21482 * u - 0.38059 * v, y + 2.12798 * u
	);

	return float4(result, source.a);
}
