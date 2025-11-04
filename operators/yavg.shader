uniform texture2d other_image <string label = "other_image";>;
sampler_state uvshaderSampler {
Filter		= Linear;
AddressU	= Border;
AddressV	= Border;
BorderColor	= 00000000;
};
float4 mainImage(VertData v_in) : TARGET
{

	float4 pix = other_image.Sample(textureSampler, v_in.uv);
	float4 res = image.Sample(textureSampler, v_in.uv);
	
	res.rgb = (pix.rgb + res.rgb)/2.0;
	//res.r = (pix.r + res.r)/2.0;
	//res.g = (pix.g + res.g)/2.0;
	//res.b = (pix.b + res.b)/2.0;
	res.a = 1.0;
	return res;
}