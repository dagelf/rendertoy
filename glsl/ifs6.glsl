/* Modified by Avi Levy (c) 2015
 *
 * This is the famous Sierpinski
 * tetrahedron, to 16 iterations.
 *
 * Instructions:
 *      Click and drag the fractal
 *          - Upwards zooms in
 *          - Left/right rotates
 *
 * 
 * Original by inigo quilez - iq/2013
 */

const vec3 va = vec3(  0.0,  0.57735,  0.0 );
const vec3 vb = vec3(  0.0, -1.0,  1.15470 );
const vec3 vc = vec3(  1.0, -1.0, -0.57735 );
const vec3 vd = vec3( -1.0, -1.0, -0.57735 );

// return distance and address
vec2 map(vec3 p) {
    float a = 0.0;
    float s = 1.0;
    float r = 1.0;
    float dm;
    vec3 v;
    for(int i=0; i<16; i++) {
        float d, t;
        d = dot(p-va,p-va);              v=va; dm=d; t=0.0;
        d = dot(p-vb,p-vb); if( d<dm ) { v=vb; dm=d; t=1.0; }
        d = dot(p-vc,p-vc); if( d<dm ) { v=vc; dm=d; t=2.0; }
        d = dot(p-vd,p-vd); if( d<dm ) { v=vd; dm=d; t=3.0; }
        p = v + 2.0*(p - v); r*= 2.0;
        a = t + 4.0*a; s*= 4.0;
    }
    
    return vec2( (sqrt(dm)-1.0)/r, a/s );
}

const float precis = 0.000001;

vec3 intersect(in vec3 ro, in vec3 rd) {
    vec3 res = vec3(1e20, 0.0, 0.0);
    
    float maxd = 5.0;

    // sierpinski
    float h = 1.0;
    float t = 0.5;
    float m = 0.0;
    vec2 r;
    for(int i=0; i<100; i++) {
        r = map( ro+rd*t );
        if( r.x<precis || t>maxd ) break;
        m = r.y;
        t += r.x;
    }

    if(t < maxd && r.x < precis) {
        res = vec3(t, 2., m);
    }

    return res;
}

vec3 light = normalize(vec3(1., .7, .9));

vec4 render(in vec3 ro, in vec3 rd) {
    // raymarch
    vec3 tm = intersect(ro,rd);
    if(tm.y < 0.5) {
        return vec4(0., 0., 0., 1.);
    }
    // Position vector
    vec3 position = ro + tm.x * rd;
    
    // Normal vector calculation
    vec3 epsilon = vec3(precis, 0., 0.);
    vec3 normal = normalize(
        vec3(
            map(position + epsilon.xyy).x - map(position - epsilon.xyy).x,
            map(position + epsilon.yxy).x - map(position - epsilon.yxy).x,
            map(position + epsilon.yyx).x - map(position - epsilon.yyx).x
        )
    );

    // Occlusion calculation
    float ao = 0.;
    float sca = 1.;
    for(int i=0; i<8; i++) {
        float h = 0.001 + 0.5*pow(float(i)/7.0,1.5);
        float d = map(position + h * normal).x;
        ao += -(d-h)*sca;
        sca *= 0.95;
    }

    // surface-light interacion
    vec3 color = (
        .5 + .5 * cos(
            6.2831 * tm.z + vec3(0., 1., 2.)
        )
    )
    * (0.5 + 0.5 * normal.y) // ambient lighting
    * clamp(1.0 - 0.8*ao, 0.0, 1.0) // occlusion
    * 1.5 * vec3(1);

    return vec4(
        pow(clamp(color, 0., 1.), vec3(.45)) // gamma
    , 1.);
}

void mainImage(out vec4 color, in vec2 fragCoord) {
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    vec2 m = vec2(0.5);
    if(iMouse.z>0.0) {
        m = iMouse.xy/iResolution.xy/10.;
        m.y = pow(2., 150. * m.y - 3.);
    }

    // camera
    float an = 3.2 + 0.5*iTime - 6.2831*(m.x-0.5);

    vec3 ro = vec3(2.5*sin(an),0.0,2.5*cos(an));
    vec3 ta = vec3(0.0,-0.5,0.0);
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( p.x*uu + p.y*vv + 5.0*ww*m.y );

    color = render(ro, rd);
}
