struct PSInput
{
	float4 Color : COLOR;
	float4 TexCoord: TEXCOORD;
};

float4 main(PSInput pin) : SV_TARGET
{
	float3 color = pin.Color;
	float2 uv = pin.TexCoord.xy;
	
	// radial gradient
	float alpha = 1-distance(uv,0.5)*2;
	
	alpha = pow(saturate(alpha),0.5);
	alpha *= pin.Color.a;
	alpha = alpha;
	
	
	// do tonemapping in pixel shader
	
	// Reinhard Curve https://bruop.github.io/tonemapping/
	const float whitePoint = 4.2;
	color = color*(1+color/whitePoint)/(1+color);
	
	// gamma correction
	color = pow(color,2.2);
	
	return float4(color, saturate(alpha));
}
