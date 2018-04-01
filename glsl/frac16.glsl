#define opRep(p, c) mod(p,c)-.5*c

float sdTorus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
mat3 rotMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}
float map(vec3 p) {
    mat3 rot = rotMatrix(vec3(1.,0.,0.), 190.);
    rot *= rotMatrix(vec3(0.,1.,0.), sin(iTime)*3.);
    p*=rot;
    p = opRep(p, vec3(.5));
	return sdTorus(p, vec2(.3, .02));
}
vec2 trace (vec3 o, vec3 r) {
	float t = 0.;
    float i;
    float precis = .01;
    for (i = 0.; i < 64.; ++i) {
        o.z *= sin(iTime);
    	vec3 p = o + r * t;
        float d = map(p);
        if (d<precis) break;
        t += d;
    }
    return vec2(t, i);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (2.*fragCoord-iResolution.xy )/iResolution.y;
	vec3 o = vec3(0.0, -0.015, -0.2);
    vec3 r = normalize(vec3(uv, 1.));
    vec2 t = trace(o, r);

    vec3 col = vec3(.2,.1,.4)*cos(iTime)*0.5+0.1;

    fragColor = vec4(col,1.0)*t.x;
}
