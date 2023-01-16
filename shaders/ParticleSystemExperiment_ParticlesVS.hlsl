cbuffer InputVars : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
	float3 CameraPosition;
	float3 ColorCurveGamma;
	float3 ColorTint;
	float Brightness;
};

struct VSInput
{
	float3 Position : POSITION;
	float3 Normal : NORMAL;
	float4 TexCoord: TEXCOORD;
	float3 ActualPosition : POSITION1;
	float NormalizedAge;
	float3 Velocity : VELOCITY;
	int Alive;

};

struct VSOutput
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR;
	float4 TexCoord: TEXCOORD;
};

VSOutput main(VSInput vin)
{
	VSOutput vout = (VSOutput)0;

	// -- PARTICLE VERTEX POSITION --
	float3 localPos =  vin.Position;
	float3 particlePositionWS = mul(float4(vin.ActualPosition.xyz, 1.0f), matGeo);
	float3 particleToCamera = normalize(CameraPosition - particlePositionWS);

	
	float size = 0.1;
	
	size *= saturate((1 - vin.NormalizedAge)*5);
	
	float3 parX, parY; // x and y axes of particle sprite
	float3 posWS;
	
	float speed = length(vin.Velocity);
	
	
	parY = speed > 0.01 ? vin.Velocity : float3(0,1,0);
	// flatten parY with respect to camera
	parY = normalize(parY - dot(parY,particleToCamera)*particleToCamera);
	
	parX = normalize(cross(particleToCamera,parY));
	
	// stretch based on speed
	float stretchFactor = max(1,speed/size/60);
	//stretchFactor = 1;

	
	posWS = particlePositionWS + localPos.x* size * parX + localPos.y * size * parY * stretchFactor;
	

	// transform from world space to camera projection
	vout.Position = mul(float4(posWS, 1.0f), matVP);
	
	
	// -- PARTICLE APPEARANCE --
	const float brightness = 7;
	// artistic approximation of blackbody radiation curve
	float3 color = pow(1-vin.NormalizedAge,ColorCurveGamma) * ColorTint * Brightness;
	
	// fade out alpha from NormalizedAge 0.5 to 1
	float alpha = saturate((1 - vin.NormalizedAge)*5);
	
	// if particle is motion-blurred than it should be more transparent
	alpha /= stretchFactor;
	vout.Color = float4(color,alpha);
	vout.TexCoord = vin.TexCoord;
	
	// if particle is not yet spawned make it nonrenderable
	if (vin.Alive == 0)
	{
		vout.Position = 0;
		vout.Color = 0;
	}
	

	return vout;
}

