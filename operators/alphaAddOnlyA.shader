uniform texture2d other_image;
float4 mainImage(VertData v_in) : TARGET {
	float alpha = other_image.Sample(textureSampler, v_in.uv).a;
	float4 base = image.Sample(textureSampler, v_in.uv);
	base.a = clamp(base.a + alpha, 0.0,1.0);
	return base;
}
