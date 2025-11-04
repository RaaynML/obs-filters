uniform texture2d other_image;
float4 mainImage(VertData v_in) : TARGET {
	float4 other = other_image.Sample(textureSampler, v_in.uv);
	float4 base = image.Sample(textureSampler, v_in.uv);
	base.rgb = base.rgb + other.rgb;
	base.a = 1.0;
	return base;
}
