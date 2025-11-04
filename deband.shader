// settings
uniform int iterations<
	string label = "Iterations";
	string widget_type = "slider";
	int minimum = 1;
	int maximum = 20;
	int step = 1;
> = 4; 
uniform float threshold<
	string label = "Threshold";
	string widget_type = "slider";
	float minimum = 1.0;
	float maximum = 100.0;
	float step = 0.01;
> = 100.0; 
uniform float range<
	string label = "Range";
	string widget_type = "slider";
	float minimum = 1.0;
	float maximum = 64.0;
	float step = 0.5;
> = 16.0; 


float div41(float x){ return frac(x / 41.0); }

float permute(float x){
	float px = ((34.0*x + 1.0) * x);
	return (px - floor(px / 289.0) * 289.0);
}


float4 average(texture2d tex, VertData v_in, float range, inout float hrmp){
	float dist = div41(hrmp) * range;
	hrmp = permute(hrmp);
	float dir = div41(hrmp) * 6.2831853;
	hrmp = permute(hrmp);
	float2 o = float2(dist/uv_size.x, dist/uv_size.y) * float2(cos(dir), sin(dir));

	return (
		tex.Sample(textureSampler, v_in.uv + float2(o.x, o.y)) +
		tex.Sample(textureSampler, v_in.uv + float2(-o.y, o.x)) +
		tex.Sample(textureSampler, v_in.uv + float2(-o.x, -o.y)) +
		tex.Sample(textureSampler, v_in.uv + float2(o.y, -o.x))
	) * 0.25;
}


float4 mainImage(VertData v_in) : TARGET {
	//seed prng
	float2 vTexCoord = v_in.uv;
	float3 _m = float3(v_in.pos.xy, 1.0) + float3(1.0, 1.0, 1.0);
	float hrmp = permute(permute(permute(_m.x)+_m.y)+_m.z);

	float4 avg;
	float4 diff;

	float4 icol = image.Sample(textureSampler, v_in.uv);

	for(int ix = 1; ix <= iterations; ix++){
		avg = average(image, v_in, float(ix) * range, hrmp);
		diff = abs(icol - avg);
		diff[3] = 1;
		icol = lerp(
			avg, icol,
			step({ (threshold/(float(ix)*16384.0)), (threshold/(float(ix)*16384.0)), 	(threshold/(float(ix)*16384.0)), 1 }, diff)
		);
	}

	return icol;
}
