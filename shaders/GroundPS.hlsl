struct PSInput
{
	float4 TexCoord: TEXCOORD;
};

float4 main(PSInput pin) : SV_TARGET
{
	float3 color = float3(1,1,1);
	float alpha = 1;
	float2 uv = pin.TexCoord.xy;
	float2 grid = floor(uv * 10);
	float2 grid2 = floor(uv * 100);
	float gridPattern1 = (grid.x + grid.y) % 2;
	float gridPattern2 = (grid2.x + grid2.y) % 2;
	color = lerp(0.8,lerp(gridPattern1,gridPattern2, 0.3), 0.3);
	
	
	// do tonemapping in pixel shader
	
	// Reinhard Curve https://bruop.github.io/tonemapping/
	const float whitePoint = 4.2;
	color = color*(1+color/whitePoint)/(1+color);
	
	// gamma correction
	color = pow(color,2.2);
	
	return float4(color, alpha);
}
