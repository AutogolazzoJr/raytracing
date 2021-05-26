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

#include "util.glsl"
#include "texture.glsl"
#include "intersect.glsl"

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