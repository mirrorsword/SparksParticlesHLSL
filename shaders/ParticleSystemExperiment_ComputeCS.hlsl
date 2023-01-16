// Random fuction adapted from https://thebookofshaders.com/10/
float rand (float seed)
{
	return frac(sin(seed)*100000.0);
}

float3 rand3 (float seed)
{
	return float3(rand(seed),rand(seed+243),rand(seed+854));
}


// adaptation of 'normally distributed random number' from https://karthikkaranth.me/blog/generating-random-points-in-a-sphere/
float3 randPointInSphere(float seed)
{
	float3 randomVector = normalize(rand3(seed+234)*2-1);
	
	// cube root of random 0-1 value
	float radius = pow(rand(seed),1/3.0);
	
	return randomVector*radius;
}


// this is the data structure of the compute buffer
// it is the 'payload' of unique data for each particle.
struct InputData
{
	float3 Position;
	float NormalizedAge;
	float3 Velocity;
	int Alive;

};

cbuffer Uniforms : register(b0)
{
	// System Data
	float deltaTime;
	int frame;
	float time;
	
	// User Controls
	float Lifespan;
	float3 RotationSpeeds;
	float SpawnVariance;
	int ParticleCount;
};

RWStructuredBuffer<InputData> data : register(u0);

[numthreads(1, 1, 1)]
void main( uint3 id : SV_DispatchThreadID )
{
	// read values from buffer
	float3 pos = data[id.x].Position;
	float3 vel = data[id.x].Velocity;
	float normAge = data[id.x].NormalizedAge;
	int alive = data[id.x].Alive;
	
	// instead of storing both age and normalized age, the code only stores normalized age.
	// Since normalized age is needed for the vertex shader. 
	float age = normAge * Lifespan;
	
	// reset simulation every 3600 frames
	if (frame % 3600 == 0)
	{
		// distribute ages unfiformly throughout lifespan to allow continuous emission
		age = (float(id)/(ParticleCount-1)) * Lifespan;
		alive = false;
	}
	// if the simulation is not reset, then advance the age of the particles. 
	else
	{
		age += deltaTime;
	}
	
	// if age is greator than the lifespan, recycle the particle.
	// This is effectively the particle spawn logic.
	float dt = deltaTime;
	if ( age > Lifespan)
	{
		// -- New Partilce Age --
		// give particle a small initial age to simulate subframe births
		age = (age % Lifespan);
		// mark as allive so particle is visible
		alive = true;
		// increase delta time to account for the particle being born before start of frame.
		dt += age;
		
		// random vector from -1,-1,-1 to 1,1,1.
		float3 random_vel = randPointInSphere(id.x+time);
		
		
		// -- New Position and Velocity --
		// Paritlce emitter moves using a simplified 3D lissajous curve
		const float radius = 2;
		// adjust birth_time based on age to keep particles from bunching together
		float birth_time = time - age;
		float3 angle = birth_time * RotationSpeeds;
		// simplified lissajous postion equation
		pos = float3(sin(angle.x),cos(angle.y),sin(angle.z))*radius;
		// derriviated of the position equation is used to compute velocity
		vel = float3(cos(angle.x),-sin(angle.y),cos(angle.z))*radius*RotationSpeeds;
		
		// add randomness to velocity to break up the particles
		vel += random_vel*SpawnVariance;
	}

	// -- Particle Update Logic --
	// simple air turbulence using sine waves
	float3 samplePos = pos + time * float3(0,0.2,0);
	vel += sin(samplePos*0.6435).zxy * dt * 3;
	
	// integrate gravity to velocity
	vel += float3(0,-20,0)*dt;
	
	// integrate velocity to position
	pos += vel*dt;
	
	// -- Collision with Ground --
	const float ground_y = -10;
	if (pos.y <= ground_y)
	{
		
		// randomize normal to break up particle bounces
		float3 randomVector = randPointInSphere(id.x+time);
		float3 normal = normalize(float3(0,1,0) + randomVector*0.15);
		
		// -- reflection logic --
		// get the vector projection of the vel against the normal.
		float3 normalVelocity = dot(normal,vel)*normal;
		// get the vector rejection of the vel against the normal.
		float3 tangentalVelocity = vel - normalVelocity;
		const float drag = 0.1;
		const float restitution = lerp(0.2,0.6,rand(id.x+time+872));
		// combine normal and tangent velocity, scaling for drag and restitution.
		vel = normalVelocity * -1 * restitution + tangentalVelocity * (1-drag);
		
		// move particle above the ground plane
		pos.y = ground_y + 0.05;
	}
	
	// Test Random Sphere Distribution.
	/*
	vel = 0;
	pos = randPointInSphere(id.x)*2;
	*/
	
	// convert age into normalized age
	normAge =  age/Lifespan;
	
	// apply values to buffer
	data[id.x].Position = pos;
	data[id.x].Velocity = vel;
	data[id.x].Alive = alive;
	data[id.x].NormalizedAge = normAge;
}