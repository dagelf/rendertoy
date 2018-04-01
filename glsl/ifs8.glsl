
//parameters
const int iterations=27;
const float scale=1.3;
const vec2 fold=vec2(.5);
const vec2 translate=vec2(1.5);
const float zoom=.25;
const float brightness=7.;
const float saturation=.65;
const float texturescale=.15;
const float rotspeed=.001;
const float colspeed=.005;
const float antialias=2.;


vec2 rotate(vec2 p, float angle) {
return vec2(p.x*cos(angle)-p.y*sin(angle),
		   p.y*cos(angle)+p.x*sin(angle));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec3 aacolor=vec3(0.);
	vec2 pos=fragCoord.xy / iResolution.xy-.5;
	float aspect=iResolution.y/iResolution.x;
	pos.y*=aspect;
	pos/=zoom; 
	vec2 pixsize=max(1./zoom,100.-iTime*50.)/iResolution.xy;
	pixsize.y*=aspect;
	for (float aa=0.; aa<25.; aa++) {
		if (aa+1.>antialias*antialias) break;
		vec2 aacoord=floor(vec2(aa/antialias,mod(aa,antialias)));
		vec2 p=pos+aacoord*pixsize/antialias;
		p+=fold;
		float expsmooth=0.;
		vec2 average=vec2(0.);
		float l=length(p);
		for (int i=0; i<iterations; i++) {
			p=abs(p-fold)+fold-iMouse.y/99.;
			p=p*scale-translate;
			if (length(p)>20.) break;
			p=rotate(p,iTime*rotspeed+iMouse.x/77.+27.5);
			average+=p;
		}
		average/=float(iterations);
		vec2 coord=average+vec2(iTime*colspeed+33.);
		vec3 color=texture(iChannel0,coord*texturescale).xyz;
		color*=min(1.1,length(average)*brightness);
		color=mix(vec3(length(color)),color,saturation);
		aacolor+=color;
	}
	fragColor = vec4(aacolor/(antialias*antialias),1.0);
}

