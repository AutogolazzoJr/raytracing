#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define DEPTH 4
#define NUM_FACES 8

#define MAX_VALUE 3.402823466E+38
#define PI 3.141592653589793

uniform vec3 iResolution;
uniform float iTime;
uniform int numSamples;
uniform bool drawNormals;
uniform bool useNormalMaps;
uniform float fovLength;
//uniform bool enableRotation;
uniform vec3 cameraPos;
uniform vec2 cameraRotation;

//uniform int faceTypes[NUM_FACES];
//uniform int faceMaterials[NUM_FACES];
//uniform float faceReflectances[NUM_FACES * 3];
//uniform float facePoints[NUM_FACES * 6];

uniform int faces[NUM_FACES];
uniform float data[4000];

struct incoming {
    float angle;
    vec3 reflectance;
};

struct tValue {
    float t;
    bool success;
    vec3 normal;
	vec2 texCoord;
	vec3 basis1;
	vec3 basis2;
};

struct intersectedRay {
    vec3 point;
    vec3 normal;
    int id;
	int material;
	vec2 texCoord;
	vec3 basis1;
	vec3 basis2;
};

const float tol = 0.0001;
int depth = 0;
int sampleN = 0;
incoming angles[DEPTH];
const float BRDF = (1. / PI) / PI;
const float prob = 1. / (2. * PI);

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
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D texture4;
uniform sampler2D texture5;
uniform sampler2D texture6;
uniform sampler2D texture7;
uniform sampler2D texture8;
uniform sampler2D texture9;
uniform sampler2D texture10;

vec4 textureAt(int textureID, vec2 texCoord) {
	switch(textureID) {
	case 1:
		return texture(texture1, texCoord);
	case 2:
		return texture(texture2, texCoord);
	case 3:
		return texture(texture3, texCoord);
	case 4:
		return texture(texture4, texCoord);
	case 5:
		return texture(texture5, texCoord);
	case 6:
		return texture(texture6, texCoord);
	case 7:
		return texture(texture7, texCoord);
	case 8:
		return texture(texture8, texCoord);
	case 9:
		return texture(texture9, texCoord);
	case 10:
		return texture(texture10, texCoord);
	}
}
tValue raySphere(vec3 ray, vec3 rayOrigin, vec4 sphere) {
    tValue tv;
    tv.success = false;
	sphere = vec4(sphere.xyz - rayOrigin, sphere.w);
	vec3 loc = sphere.xyz;
	float a = dot(ray, ray);
	float b = -2. * dot(loc, ray);
	float c = dot(loc, loc) - sphere.w * sphere.w;
	float desc = b * b - 4. * a * c;
	if (desc < 0.)
		return tv;
	else {
		float t1 = (-b + sqrt(desc)) / (2. * a);
		float t2 = (-b - sqrt(desc)) / (2. * a);
		if (t1 <= tol) {
			if (t2 <= tol) {
				return tv;
			}
			tv.normal = ray * t2 - sphere.xyz;
            tv.t = t2;
            tv.success = true;
			return tv;
		} else if (t2 <= tol) {
			if (t1 <= tol) {
				return tv;
			}
			tv.normal = ray * t1 - sphere.xyz;
            tv.t = t1;
            tv.success = true;
			return tv;
		}
		float t3 = min(t1, t2);
		tv.normal = ray * t3 - sphere.xyz;
        tv.t = t3;
        tv.success = true;
		return tv;
	}
}

tValue rayPlane(vec3 ray, vec3 rayOrigin, vec3 planeNorm, vec3 planeP) {
    tValue tv;
    tv.success = false;
	planeP = planeP - rayOrigin;
	float t = dot(planeNorm, planeP) / dot(planeNorm, ray);
	if (t <= tol) {
		return tv;
	}
	if (dot(ray, planeNorm) > 0.)
		planeNorm *= -1.;
	tv.normal = planeNorm;
    tv.t = t;
    tv.success = true;
	return tv;
}

#define POLY_POINTS 4
tValue rayPolygon(vec3 ray, vec3 rayOrigin, vec3 planeNorm, vec3 planeP, vec3 polyPoints[POLY_POINTS]) {
	tValue plane = rayPlane(ray, rayOrigin, planeNorm, planeP);
	if (!plane.success) {
		return plane;
	}
	vec3 testPoint3d = rayOrigin + ray * plane.t;
	vec2 points[4];
	vec2 planePoint;
	vec2 testPoint;
	planeNorm = abs(planeNorm);
	float max = max(max(planeNorm.x, planeNorm.y), planeNorm.z);
	if (max == planeNorm.x) {
		for (int i = 0; i < POLY_POINTS; i++) {
			points[i] = polyPoints[i].yz;
		}
		planePoint = planeP.yz;
		testPoint = testPoint3d.yz;
	} else if (max == planeNorm.y) {
		for (int i = 0; i < POLY_POINTS; i++) {
			points[i] = polyPoints[i].xz;
		}
		planePoint = planeP.xz;
		testPoint = testPoint3d.xz;
	} else {
		for (int i = 0; i < POLY_POINTS; i++) {
			points[i] = polyPoints[i].xy;
		}
		planePoint = planeP.xy;
		testPoint = testPoint3d.xy;
	}
	bool working = true;
	for (int i = 0; i < POLY_POINTS; i++) {
		vec2 pointOne = points[i];
		vec2 pointTwo = points[(i + 1) % POLY_POINTS];
		vec3 line = standardForm(pointOne, pointTwo);
		if (lineVal(line, planePoint) * lineVal(line, testPoint) < 0) { //TODO: tolerance
			working = false;
		}
	}
	if (working) {
		vec3 basis1 = polyPoints[1] - polyPoints[0];
		vec3 basis2 = polyPoints[3] - polyPoints[0];
		/*
		float det = basis1.x * basis2.y - basis2.x * basis1.y;
		vec2 temp = vec2(basis2.y, -basis1.y);
		basis2 = (1. / det) * vec2(-basis2.x, basis1.x);
		basis1 = (1. / det) * temp;
		vec2 vec = testPoint - points[0];
		plane.texCoord.x = basis1.x * vec.x + basis2.x * vec.y;
		plane.texCoord.y = basis1.y * vec.x + basis2.y * vec.y;
		//*/
		vec3 vec = testPoint3d - polyPoints[0];
		plane.texCoord.x = comp(vec, basis1);
		plane.texCoord.y = comp(vec, basis2);
		plane.basis1 = normalize(basis1);
		plane.basis2 = normalize(basis2);
		return plane;
	}
	tValue failed;
	failed.success = false;
	return failed;
}

tValue rayCircle(vec3 ray, vec3 rayOrigin, vec3 planeNorm, vec3 planeP, float radius) {
    tValue tv;
    tv.success = false;
	planeP = planeP - rayOrigin;
	float t = dot(planeNorm, planeP) / dot(planeNorm, ray);
	if (t <= tol || sqrt(dot((planeP - ray * t) * (planeP - ray * t), vec3(1.))) > radius) {
		return tv;
	}
	if (dot(ray, planeNorm) > 0.)
		planeNorm *= -1.;
    tv.normal = planeNorm;
    tv.t = t;
	tv.success = true;
	return tv;
}

intersectedRay rayIntersect(vec3 ray, vec3 rayOrigin) {
    intersectedRay r;
	tValue intersect;
    r.id = -1;
	int b = 0;
	float t = MAX_VALUE;//intersect.x;
	for (int i = 0; i < NUM_FACES; i++) {
		b = faces[i];
		int type = int(data[b++]);
		if (type == 0) {
			vec3 vecOne = vec3(data[b++], data[b++], data[b++]);
			vec3 vecTwo = vec3(data[b++], data[b++], data[b++]);
			intersect = rayPlane(ray, rayOrigin, vecOne, vecTwo);
		} else if (type == 1) {
			intersect = raySphere(ray, rayOrigin, vec4(data[b++], data[b++], data[b++], data[b++]));
		} else if (type == 2) {
			vec3 quadPoints[4];
			for (int i = 0; i < 4; i++) {
				quadPoints[i] = vec3(data[b++], data[b++], data[b++]);
			}
			vec3 normal = -normalize(cross(quadPoints[1] - quadPoints[0], quadPoints[2] - quadPoints[0]));
			vec3 planePoint3d = vec3(0.);
			for (int i = 0; i < 4; i++) {
				planePoint3d += quadPoints[i];
			}
			planePoint3d /= 4;
			intersect = rayPolygon(ray, rayOrigin, normal, planePoint3d, quadPoints);
		}
		if (intersect.success && intersect.t < t) {
			t = intersect.t;
			r.normal = intersect.normal;
			r.texCoord = intersect.texCoord;
			r.basis1 = intersect.basis1;
			r.basis2 = intersect.basis2;
			r.id = int(data[b++]);
			r.material = b;//vec3(data[b++], data[b++], data[b++]);
		}
	}
	r.normal = normalize(r.normal);
    r.point = rayOrigin + ray * t;
	return r;
}

vec3 trace(vec3 ray) {
	vec3 origin = cameraPos;  //y is .4
	vec3 final = vec3(0.);
	depth = -1;
	for (int d = 0; d < DEPTH; d++) {
        intersectedRay intersect = rayIntersect(ray, origin);
		int b = intersect.material;
		if (intersect.id == -1) {
			break;
		}
		if (intersect.id == 0) {
            final = vec3(data[b++], data[b++], data[b++]);
        } else {
            origin = intersect.point;
			/*if (drawNormals) {
				return (intersect.normal + 1.) * .5;
				//return vec3(abs(intersect.texCoord.x), 0., 0.);
				//return vec3(0., abs(intersect.texCoord.y), 0.);
				//return vec3(abs(intersect.texCoord), 0.);
			}*/
            if (intersect.id == 2 && randomFloat(50.) < data[b + 3]) {
                intersect.id = 1;
            }
			if (intersect.id == 3) {
				intersect.id = 2;
			}
            if (intersect.id == 2) {
				angles[d].reflectance = vec3(data[b++], data[b++], data[b++]);
                ray = 2. * (dot(intersect.normal, ray)) * intersect.normal - ray;
                if(dot(ray, intersect.normal) < 0.) {
                    ray *= -1.;
                }
                angles[d].angle = -10.;
            } else if (intersect.id == 1) {
				angles[d].reflectance = vec3(data[b++], data[b++], data[b++]);
                ray = normalize(randomCosVector(intersect.normal));
                float cos_theta = dot(ray, intersect.normal);
                angles[d].angle = cos_theta;
            } else if (intersect.id == 4) {
				intersect.texCoord *= 1.;
				if (data[b + 1] != -1.) {
					if (useNormalMaps) {
						vec3 norm = normalize(textureAt(int(data[b + 1]), intersect.texCoord.xy).xyz - .5);
						norm.y = -norm.y;
						//norm.x = -norm.x;
						intersect.normal = normalize(norm.x * intersect.basis1 + norm.y * intersect.basis2 + norm.z * intersect.normal);
					}
					//float temp = norm.x;
					//norm.x = norm.y;
					//norm.y = -temp;
					//intersect.normal = normalize(vec3(dot(intersect.basis1, norm), dot(intersect.basis2, norm), dot(oldNorm, norm)));
					//intersect.normal = normalize(vec3(intersect.basis1.x * norm.x + intersect.basis2.x * norm.y + oldNorm.x * norm.z, intersect.basis1.y * norm.x + intersect.basis2.y * norm.y + oldNorm.y * norm.z, intersect.basis1.z * norm.x + intersect.basis2.z * norm.y + oldNorm.z * norm.z));
					//intersect.normal = normalize(intersect.basis2);
					//if(dot(ray, intersect.normal) < 0.) {
					//	intersect.normal *= -1.;
					//}
					if(dot(ray, intersect.normal) < 0.) {
						ray *= -1.;
					}
					//intersect.normal = -oldNorm;
					//intersect.normal = norm;
				}
				if (data[b] != -1.) {
					angles[d].reflectance = textureAt(int(data[b]), intersect.texCoord.xy).xyz;
				}
				else {
					angles[d].reflectance = vec3(.99, .99, .99);//vec3(abs(intersect.texCoord), 0.);
				}
				if (data[b + 2] != -1.) {
					float prob = textureAt(int(data[b + 2]), intersect.texCoord.xy).x * .1;
					if (randomFloat(110.) < prob) {
						ray = 2. * (dot(intersect.normal, ray)) * intersect.normal - ray;
						if(dot(ray, intersect.normal) < 0.) {
							ray *= -1.;
						}
						angles[d].angle = -10.;
					} else {
						ray = normalize(randomCosVector(intersect.normal));
						float cos_theta = dot(ray, intersect.normal);
						angles[d].angle = cos_theta;
					}
				} else {
					ray = normalize(randomCosVector(intersect.normal));
					float cos_theta = dot(ray, intersect.normal);
					angles[d].angle = cos_theta;
				}
			}
			if (drawNormals) { //TODO: get rid of this
				return (intersect.normal + 1.) * .5;
			}
            depth = d;
        }
	}
	//*
	for (int d = DEPTH - 1; d >= 0; d--) {
		if (d <= depth) {
			if (angles[d].angle != -10.) {
				final = (angles[d].reflectance * BRDF * final * angles[d].angle / prob);
			}
		}
	}//*/
	return final;
}

void main() {
    float range = fovLength;
	float aspect = iResolution.y / iResolution.x;
	float x = map(0., iResolution.x, -range, range, gl_FragCoord.x);
	float y = map(0., iResolution.y, -range * aspect, range * aspect, gl_FragCoord.y);
	float z = -1.;
	float theta;
	float phi;
	theta = cameraRotation.x;
	phi = cameraRotation.y;
	float x1 = x * cos(theta) - z * sin(theta);
	z = x * sin(theta) + z * cos(theta);
	x = x1;
	float y1 = y * cos(phi) - z * sin(phi);
	z = y * sin(phi) + z * cos(phi);
	y = y1;
	vec3 ray = vec3(x, y, z);
	vec3 color = vec3(0.);
	/*if (drawNormals) {
		fragColor = vec4(trace(ray), 1.);
		return;
	}*/
	for (int i = 0; i < numSamples; i++) {
		sampleN = i;
		vec3 result = trace(ray);
		color += result;
	}
	color /= numSamples;
	gl_FragColor = vec4(color, 1.);
}
