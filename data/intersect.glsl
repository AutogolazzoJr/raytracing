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