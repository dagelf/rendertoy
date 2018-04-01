#define PI 3.14159
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    float diagonal = length(iResolution.xy);
    
    vec2 center = iResolution.xy / 2.0;
    
    float rad = iResolution.y/4.0;
	float t = 200.0/rad;
    
    
    vec2 planet = vec2(center.x+rad*sin(1.0*iTime),center.y+rad*cos(1.0*iTime));
    //vec2 planet2 = vec2(iMouse.x+rad/2.0*sin(2.83*t*iTime),iMouse.y+rad/2.0*cos(2.83*t*iTime));
    vec2 planet2 = vec2(iMouse.x+rad/2.0*sin(2.83*iTime),iMouse.y+rad/2.0*cos(2.83*iTime));
    
    vec2 distCenter = center-fragCoord.xy;
    vec2 distPlanet = planet-fragCoord.xy;
    vec2 distPlanet2 = planet2-fragCoord.xy;
    vec2 distCursor = abs(iMouse.xy-fragCoord.xy);
    
    float light1 = 1.5*inversesqrt(length(distCursor)); 
    float light2 = 2.0*inversesqrt(length(distCenter));
    float light3 = inversesqrt(length(distPlanet));
    float light4 = inversesqrt(length(distPlanet2));
    
    
    float grav = (light1+light2+light3+light4);
    float c = 30.0*grav-floor(30.0*grav);
    
    vec4 color1 = vec4(1.0, 0.5, 0.5, 0.0);
    vec4 color2 = vec4(1.0, 1.0, 0.4, 0.0);
    vec4 color3 = vec4(.5, .5, 1.0, 0.0);
    vec4 color4 = vec4(.7, .7, .7, 0.0);

    color1*=light1;
    color2*=light2;
    color3*=light3;
    color4*=light4;

    
    vec4 color = (color1+color2+color3+color4);
    
    if (c< .01*grav)
    {
      fragColor = (color)+(color)*2.0*pow(clamp(sin(iTime),0.0, 1.0), 2.0);   
        
    }
    else
      fragColor = color;
    
	
        
}
