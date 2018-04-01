/*
Created by soma_arc - 2017
This work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.
*/

// from Syntopia http://blog.hvidtfeldts.net/index.php/2015/01/path-tracing-3d-fractals/
vec2 rand2n(vec2 co, float sampleIndex) {
	vec2 seed = co * (sampleIndex + 1.0);
	seed+=vec2(-1,1);
	// implementation based on: lumina.sourceforge.net/Tutorials/Noise.html
	return vec2(fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453),
                 fract(cos(dot(seed.xy ,vec2(4.898,7.23))) * 23421.631));
}


vec3 sphereInvert(vec3 pos, vec4 sphere){
	vec3 diff = pos - sphere.xyz;
    float d = length(diff);
	return (diff * sphere.w * sphere.w)/(d * d) + sphere.xyz;
}

const float EPSILON = 0.0001;
const float PI = 3.14159265;
const float PI_2 = 3.14159265 / 2.;

vec3 calcRay (const vec3 eye, const vec3 target, const vec3 up, const float fov,
              const float width, const float height, const vec2 coord){
  float imagePlane = (height * .5) / tan(fov * .5);
  vec3 v = normalize(target - eye);
  vec3 xaxis = normalize(cross(v, up));
  vec3 yaxis =  normalize(cross(v, xaxis));
  vec3 center = v * imagePlane;
  vec3 origin = center - (xaxis * (width  *.5)) - (yaxis * (height * .5));
  return normalize(origin + (xaxis * coord.x) + (yaxis * (height - coord.y)));
}

const vec4 K = vec4(1.0, .666666, .333333, 3.0);
vec3 hsv2rgb(float h, float s, float v){
  vec3 p = abs(fract(vec3(h) + K.xyz) * 6.0 - K.www);
  return v * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), s);
}

bool intersectBox(vec3 rayOrg, vec3 rayDir, vec3 boxMin, vec3 boxMax,
                  out float hit0, out float hit1, out bool inBox) {
	float t0 = -1000000.0, t1 = 1000000.0;
    hit0 = t0;
    hit1 = t1;
    inBox = false;
    vec3 tNear = (boxMin - rayOrg) / rayDir;
    vec3 tFar  = (boxMax - rayOrg) / rayDir;
    
    if (tNear.x > tFar.x) {
        float tmp = tNear.x;
        tNear.x = tFar.x;
        tFar.x = tmp;
    }
    
    t0 = max(tNear.x, t0);
    t1 = min(tFar.x, t1);

    
    if (tNear.y > tFar.y) {
        float tmp = tNear.y;
        tNear.y = tFar.y;
        tFar.y = tmp;
    }
    t0 = max(tNear.y, t0);
    t1 = min(tFar.y, t1);

    if (tNear.z > tFar.z) {
        float tmp = tNear.z;
        tNear.z = tFar.z;
        tFar.z = tmp;
    }
    t0 = max(tNear.z, t0);
    t1 = min(tFar.z, t1);

    if (t0 <= t1 && 0. < t1) {
        if(t0 < 0.) inBox = true;
        hit0 = t0;
        hit1 = t1;
        return true;
    }
    return false;
}

bool intersectPlane(vec3 rayOrigin, vec3 rayDir, int objId,
                    vec3 center, float size, mat3 rotation,
                    inout int hitObjId,
                    inout float minDist, inout vec3 normal, inout vec3 col) {
    vec3 n = rotation * vec3(0, 0, 1);
    vec3 xAxis = rotation * vec3(1, 0, 0);
    vec3 yAxis = rotation * vec3(0, 1, 0);
    float d = -dot(center, n);
    float v = dot(n, rayDir);
    float t = -(dot(n, rayOrigin) + d) / v;
    if(0.001 < t && t < minDist){
        vec3 p = rayOrigin + t * rayDir;
        float hSize = size * .5;
        float x = dot(p - center, xAxis);
        float y = dot(p - center, yAxis);
        if(-hSize <= x && x <= hSize &&
           -hSize <= y && y <= hSize ){
            if((-hSize <= x && x <= hSize &&
               -hSize/4. <= y && y <= hSize/4.) ||
              (-hSize/4. <= x && x <= hSize/4. &&
               -hSize <= y && y <= hSize)){
            	col = vec3(1);
            }else{
            	col = vec3(0);
            }
			minDist = t;
            normal = n;
            hitObjId = objId;
            return true;
        }
    }
    return false;
}

const vec4 baseSphere = vec4(0, 0, 0, 125);
const vec4 s1 = vec4(300, 300, 0, 300);
const vec4 s2 = vec4(300, -300, 0, 300);
const vec4 s3 = vec4(-300, 300, 0, 300);
const vec4 s4 = vec4(-300, -300, 0, 300);
const vec4 s5 = vec4(0, 0, 424.26, 300);
const vec4 s6 = vec4(0, 0, -424.26, 300);
const float s1r2 = s1.w * s1.w;
const float s2r2 = s2.w * s2.w;
const float s3r2 = s3.w * s3.w;
const float s4r2 = s4.w * s4.w;
const float s5r2 = s5.w * s5.w;
const float s6r2 = s6.w * s6.w;

// (zPos, distance, twist, size)
vec4 planes;

const int MAX_KLEIN_ITARATION = 8;
float distIIS(vec3 pos, out float loopNum){
    pos -= vec3(0, 0, 0);
  	float dr = 1.;
  	bool loopEnd = true;
  	float scalingFactor= 0.2;
  	loopNum = 0.;
  	for(int i = 0 ; i < MAX_KLEIN_ITARATION ; i++){
  		loopEnd = true;
    	
        if(pos.z < -planes.x || planes.x < pos.z){
        	pos.z += planes.x;
            float nn = abs(floor(pos.z/(planes.y)));
        	loopNum += nn;
            pos.z = mod(pos.z, planes.y);
        	pos.z -= planes.x;
            
            float theta = -(planes.z * nn);
            float cosTheta = cos(theta);
            float sinTheta = sin(theta);
            mat3 m = mat3(cosTheta, -sinTheta, 0,
                          sinTheta, cosTheta, 0,
                           0, 0, 1);
            pos = m * pos;
        }
            
        if(distance(pos, s1.xyz) < s1.w){
            vec3 diff = (pos - s1.xyz);
      		dr *= s1r2 / dot(diff, diff);
      		pos = sphereInvert(pos, s1);
      		loopEnd = false;
      		loopNum++;
        }else if(distance(pos, s2.xyz) < s2.w){
            vec3 diff = (pos - s2.xyz);
      		dr *= s2r2 / dot(diff, diff);
      		pos = sphereInvert(pos, s2);
      		loopEnd = false;
      		loopNum++;
        }else if(distance(pos, s3.xyz) < s3.w){
            vec3 diff = (pos - s3.xyz);
      		dr *= s3r2 / dot(diff, diff);
      		pos = sphereInvert(pos, s3);
      		loopEnd = false;
      		loopNum++;
        }else if(distance(pos, s4.xyz) < s4.w){
            vec3 diff = (pos - s4.xyz);
      		dr *= s4r2 / dot(diff, diff);
      		pos = sphereInvert(pos, s4);
      		loopEnd = false;
      		loopNum++;
        }else if(distance(pos, s5.xyz) < s5.w){
            vec3 diff = (pos - s5.xyz);
      		dr *= s5r2 / dot(diff, diff);
      		pos = sphereInvert(pos, s5);
      		loopEnd = false;
      		loopNum++;
        }else if(distance(pos, s6.xyz) < s6.w){
            vec3 diff = (pos - s6.xyz);
      		dr *= s6r2 / dot(diff, diff);
      		pos = sphereInvert(pos, s6);
      		loopEnd = false;
      		loopNum++;
        }
        
    	if(loopEnd == true) break;
    }

    return (distance(pos, baseSphere.xyz) - baseSphere.w) / abs(dr) * scalingFactor;
}

vec3 getNormal(const vec3 p){
	const vec2 d = vec2(1., 0.);
    float loopNum;
	return normalize(vec3(distIIS(p + d.xyy, loopNum) - distIIS(p - d.xyy, loopNum),
                          distIIS(p + d.yxy, loopNum) - distIIS(p - d.yxy, loopNum),
                          distIIS(p + d.yyx, loopNum) - distIIS(p - d.yyx, loopNum)));
}


const vec3 LIGHT_DIR = normalize(vec3(1, 1, 0));

int MAX_MARCH = 500;
vec3 calcColor(float time, vec3 eye, vec3 rayDir){
  	vec3 l = vec3(0);

    vec3 rayPos = eye;
    float dist;
    float rayLength = 0.;
    bool hit = false;
    float loopNum;
    
    float t0, t1;
    bool inBox;
    float bboxSize = 500.;
    vec3 bboxMin = vec3(-bboxSize, -bboxSize, -90000);
    vec3 bboxMax = vec3(bboxSize, bboxSize, 90000);
    
    bool hitBBox = intersectBox(eye, rayDir, bboxMin, bboxMax, t0, t1, inBox);
    
    vec3 normal;
    mat3 rotation = mat3(1, 0, 0,
                     0, 1, 0,
                     0, 0, 1);
    
    float cosTheta = cos(planes.z);
    float sinTheta = sin(planes.z);
    mat3 twist = mat3(cosTheta, -sinTheta, 0,
                      sinTheta, cosTheta, 0,
                      0, 0, 1);
    float minDist = 99999999.;
    int objId = -1;
    vec3 pCol = vec3(0);
    intersectPlane(eye, rayDir, 1, vec3(0, 0, planes.x), planes.w,
                   rotation, objId, minDist, normal, pCol);
    intersectPlane(eye, rayDir, 1, vec3(0, 0, -planes.x), planes.w,
                   rotation * twist, objId, minDist, normal, pCol);
    if(hitBBox == false && objId == -1) return vec3(0);

    
    if(!inBox){
    	rayLength = t0;
        rayPos = eye + rayDir * rayLength;
    }
    t1 = min(t1, minDist);
    int marchNum = 0;
    for(int i = 0 ; i < MAX_MARCH ; i++) {
        if(rayLength > t1) break;
        marchNum = i;
    	dist = distIIS(rayPos, loopNum);
        
        rayLength += dist;
        rayPos = eye + rayDir * rayLength;
        if(dist < 0.08){
            hit = true;
            break;
        }
    }
    
    if(hit || objId != -1){
        vec3 mCol;
        if(!hit){
        	mCol = mix(vec3(0, 0, 7), vec3(1), pCol.x);
        }else{
        	if(loopNum == 0.)
        		mCol = hsv2rgb(0.33, 1., .77);
    		else
        		mCol = hsv2rgb(0.0 + loopNum * 0.1 , 1., 1.);
        	normal = getNormal(rayPos);
        }
        const vec3 AMBIENT_FACTOR = vec3(.1);
        vec3 diffuse =  clamp(dot(normal, LIGHT_DIR), 0., 1.) * mCol;
    	vec3 ambient = mCol * AMBIENT_FACTOR;
        l += ambient + diffuse;
    }
    
  	return l.rgb;
}

const float DISPLAY_GAMMA_COEFF = 1. / 2.2;
vec3 gammaCorrect(vec3 rgb) {
  return vec3((min(pow(rgb.r, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.g, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.b, DISPLAY_GAMMA_COEFF), 1.)));
}


//w: start time
//s: duration
float scene(in float t, in float w, in float s){
    return clamp(t - w, 0.0, s) / s;  
}


float expEasingIn(float t){
    return pow( 2., 13. * (t - 1.) );
}
float expEasingOut(float t) {
	return -pow( 2., -10. * t) + 1.;
}

float circEasingInOut(float t){
	t /= .5;
	if (t < 1.) return -.5 * (sqrt(1. - t*t) - 1.);
	t -= 2.;
	return .5 * (sqrt(1. - t*t) + 1.);
}

const vec3 up = vec3(0, 1, 0);
float fov = radians(60.);
const float SAMPLE_NUM = 1.;
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    float r = 800.;
    float t = mod(iTime, PI * 12.) * .5;
    
    //planes = vec4(posZ, distance, twist, size);
    planes.x = 350. + 80. * sin(iTime);
    planes.y = 2. * planes.x;
    planes.z = (PI/2.) * sin(iTime);
    planes.w = 800.;
    vec3 center = vec3(0, 0, 0);
    vec3 target = vec3(0, 0, 1000. * cos(t ));
    /*
    vec3 eye = vec3(500. * sin(iTime) , r * cos(iTime), 
                    300. * cos(iTime) ) + center;

    	eye = vec3(600. * sin(t), 300. * cos(t), 
                   0. * cos(t) ) + center;
	*/
    vec3 eye;
    float start = PI;
    float dur = 1.;
    eye = mix(vec3(1200, 700, 0), vec3(500, 400, 300), 
             (scene(t, start, dur)));
    planes.w = mix(800., 1., scene(t, start, dur));

    start += dur + PI;
    dur = 3.;
	eye = mix(eye, vec3(500, 400, 1200), 
             scene(t, start, dur));

    start += dur + PI;
  	eye = mix(eye, vec3(1200, 700, 0), 
             scene(t, start, dur));
    planes.w = mix(planes.w, 800.,
                  scene(t, start, dur));

    vec3 sum = vec3(0);
    
  	for(float i = 0. ; i < SAMPLE_NUM ; i++){
    	vec2 coordOffset = rand2n(gl_FragCoord.xy, i);
    	vec3 ray = calcRay(eye, target, up, fov,
        	               iResolution.x, iResolution.y,
            	           gl_FragCoord.xy + coordOffset);
          
    	sum += calcColor(t, eye, ray);
	}
	vec3 col = (sum/SAMPLE_NUM);

	fragColor = vec4(gammaCorrect(col), 1.);
}

