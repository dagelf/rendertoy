void mainImage( out vec4 pixColor, in vec2 pixCoord )
{
    float zoom = 1.2;
    
	vec2 ratio = (pixCoord.xy / iResolution.xy)* zoom;
    
    float Pi = 3.1415;
    float pi4 = Pi/4.0 - mod(iTime/20.0,2.0*Pi);
    
    vec2 camera = vec2(1.0,0.5);
    
    vec2 oldPos = vec2((ratio.x*1.8)-camera.x,(ratio.y)-camera.y);
    vec2 newPos = vec2 (oldPos.x * cos(pi4) + oldPos.y*sin(pi4),-oldPos.x * sin(pi4) + oldPos.y * cos(pi4));
    
    vec3 circle1 = vec3 (0.0,0.0,1.0);
    float rayon1 = 0.2;
    
    vec3 circle2 = vec3 ( sin(iTime)/2.0,0.0,cos(iTime)/2.0+circle1.z);
    float rayon2 = circle2.z * 0.07;
    
    vec3 circle3 = vec3 ( circle2.x + circle2.z* 2.0 * rayon2 * sin(iTime*3.0),0.0,circle2.z + (0.2 * rayon2 * cos(iTime*3.0)) );
    float rayon3 = circle3.z * 0.01;
    
    vec2 delta1 = vec2 (newPos.x-circle1.x,newPos.y-circle1.y);
    vec2 delta2 = vec2 (newPos.x-circle2.x,newPos.y-circle2.y);
    vec2 delta3 = vec2 (newPos.x-circle3.x,newPos.y-circle3.y);
    
    float dist1 = length(delta1);
    float dist2 = length(delta2);
    float dist3 = length(delta3);
    
    float color1 = 1.0;
    float color2 = 0.8;
    float color3 = 0.6;
    
    vec4 shader1 = vec4(color1-dist1/rayon1/2.0);
    vec4 shader2 = vec4(color2-dist2/rayon2/2.0);
    vec4 shader3 = vec4(color3-dist3/rayon3/1.25);
	
    if (dist3<rayon3) {
        
        if (dist1<rayon1 && dist3<rayon3) {
            
            if (circle1.z > circle3.z ) pixColor = shader1;
            else pixColor = pixColor = shader3;
        }
        else if (dist2<rayon2 && dist3<rayon3) {
            
        	if (circle2.z > circle3.z ) pixColor = shader2;
            else pixColor = shader3;
        }
        else pixColor = shader3;
    }
    else if (dist2<rayon2) {
        
        if (dist1<rayon1 && dist2<rayon2) {
            if (circle1.z > circle2.z )  pixColor = shader1;
            else pixColor = shader2;
        }
        else pixColor = shader2;
    }
    else if (dist1<rayon1) pixColor = shader1;
    else pixColor = vec4(0.1);
}
