uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

uint hash( uvec2 v ) { return hash( v.x ^ hash(v.y)                         ); }
uint hash( uvec3 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z)             ); }
uint hash( uvec4 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z) ^ hash(v.w) ); }

float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}

float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }
float random( vec2  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec3  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec4  v ) { return floatConstruct(hash(floatBitsToUint(v))); }

float randomFloat(float addSeed) {
    return random(vec4(gl_FragCoord.xy, iTime + float(sampleN), float(depth) + addSeed));
}

float comp(vec2 u, vec2 v) {
	float l = length(v);
	return dot(u, v) / l;
}

float comp(vec3 u, vec3 v) {
	float l = length(v);
	return dot(u, v) / (l * l);
}

vec3 randomVector() {
	return vec3(randomFloat(0.) - .5, randomFloat(100.) - .5, randomFloat(200.) - .5);
}

vec3 randomCosVector(vec3 normal) {
    vec3 rand = normalize(randomVector());
    return normalize(rand + normal);
}

//returns the standard form line in Ax + By = C
vec3 standardForm(vec2 one, vec2 two) {
	float x2x1 = two.x - one.x;
	if (abs(x2x1) < tol) {
		return vec3(1., 0., one.x);
	}
	float m = (two.y - one.y) / x2x1;
	return vec3(-m, 1., one.y - m * one.x);
}

float lineVal(vec3 line, vec2 point) {
	return point.x * line.x + point.y * line.y - line.z;
}

float map(float min1, float max1, float min2, float max2, float value) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}