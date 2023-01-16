cbuffer InputVars : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
};


struct VSInput
{
	float3 Position : POSITION;
	float3 Normal : NORMAL;
	float4 TexCoord: TEXCOORD;

};

struct VSOutput
{
	float4 Position : SV_POSITION;
	float4 TexCoord: TEXCOORD;
};

VSOutput main(VSInput vin)
{
	VSOutput vout = (VSOutput)0;
	
	float3 pos = vin.Position;
	vout.Position = mul(mul(float4(pos, 1.0f), matGeo), matVP);
	vout.TexCoord = vin.TexCoord;
	return vout;
}