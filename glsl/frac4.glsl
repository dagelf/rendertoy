

#define ENABLE_HARD_SHADOWS // turn off to enable faster AO soft shadows 


#define RAY_STEPS 80
#define SHADOW_STEPS 50
#define LIGHT_COLOR vec3(.97,.92,.82)
#define AMBIENT_COLOR vec3(.5,.5,.55)
#define FLOOR_COLOR vec3(.35,.25,.2)
#define ENERGY_COLOR vec3(1.,.7,.4)
#define BRIGHTNESS 1.5
#define GAMMA 1.2
#define SATURATION .9



#define detail .000025
#define t iTime*.1


float cc,ss;
vec3 lightdir=normalize(vec3(0.5,-0.4,-1.));
vec3 ambdir=normalize(vec3(0.,0.,1.));
const vec3 origin=vec3(0.,3.11,0.);
float det=0.0;
vec3 pth1;


float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}


mat2 rot(float a) {
	return mat2(cos(a),sin(a),-sin(a),cos(a));	
}


vec3 path(float ti) {
return vec3(0.,2.5,0.)+vec3(cos(ti),cos(ti*.935485),sin(ti)*1.2);
}


vec4 formula (vec4 p) {
	p.y-=t*.25;
    p.y=abs(3.-mod(p.y-t,6.));
    for (int i=0; i<6; i++) {
		p.xyz = abs(p.xyz)-vec3(.0,2.,.0);
		p=p*2./clamp(dot(p.xyz,p.xyz),.3,1.)-vec4(0.5,1.5,0.5,0.);
		p.xz*=mat2(cc,ss,-ss,cc);
	}
	return p;
}


float textur(vec3 p) {
    p=abs(1.-mod(p,2.));
    vec3 c=vec3(3.,4.,2.);
	float es=1000., l=0.;
	for (int i = 0; i < 12; i++) { 
			p = abs(p + c) - abs(p - c) - p; 
			p/= clamp(dot(p, p), .5, 1.);
			p = p* -1.3 + c;
        	es=min(min(abs(p.x),abs(p.y)),es);
	}
	return es*es*3.;
}


vec2 de(vec3 pos) {
	float aa=smoothstep(0.,1.,clamp(cos(t-pos.y*.4)*1.5,0.,1.))*3.14159;
    cc=cos(aa);ss=sin(aa);
    float hid=0.;
	vec3 tpos=pos;
	//tpos.xz=abs(1.5-mod(tpos.xz,3.))-1.5;
	vec4 p=vec4(tpos,1.);
	float y=max(0.,.3-abs(pos.y-3.3))/.3;
    p=formula(p);
    float fl=pos.y-3.7-length(sin(pos.xz*60.))*.01;
	float fr=max(abs(p.z/p.w)-.01,length(p.zx)/p.w-.002);
	float bl=max(abs(p.x/p.w)-.01,length(p.zy)/p.w-.0005);
    fr=smin(bl,fr,.02);
	fr*=.9;
    //float fr=length(p.xyz)/p.w;
    fl-=(length(p.xz)*.005+length(sin(pos*3.+t*5.))*.15);
    fl*=.9;
	float d=smin(fl,fr,.7);
    if (abs(d-fl)<.2) {
        hid=1.;
    }
    return vec2(d,hid);
}


vec3 normal(vec3 p) {
	vec3 e = vec3(0.0,det,0.0);
	
	return normalize(vec3(
			de(p+e.yxx).x-de(p-e.yxx).x,
			de(p+e.xyx).x-de(p-e.xyx).x,
			de(p+e.xxy).x-de(p-e.xxy).x
			)
		);	
}

float shadow(vec3 pos, vec3 sdir) {//THIS ONLY RUNS WHEN WITH HARD SHADOWS
	float sh=1.0;
	float totdist =2.0*det;
	float dist=5.;
		for (int steps=0; steps<SHADOW_STEPS; steps++) {
			if (totdist<4. && dist>detail) {
				vec3 p = pos - totdist * sdir;
				dist = de(p).x;
				sh = min( sh, max(20.*dist/totdist,0.0) );
				totdist += max(.01,dist);
			}
		}
	
    return clamp(sh,0.1,1.0);
}


float calcAO( const vec3 pos, const vec3 nor ) {
	float aodet=detail*75.;
	float totao = 0.0;
    float sca = 8.0;
    for( int aoi=0; aoi<6; aoi++ ) {
        float hr = aodet*float(aoi*aoi);
        vec3 aopos =  nor * hr + pos;
        float dd = de( aopos ).x;
        totao += -(dd-hr)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - 5.0*totao, 0., 1. );
}


vec3 raymarch(in vec3 from, in vec3 dir) 

{
	float ey=mod(t*.5,1.);
	float glow,eglow,ref,sphdist,totdist=glow=eglow=ref=sphdist=0.;
	vec2 d=vec2(1.,0.);
	vec3 p, col=vec3(0.);
	vec3 origdir=dir,origfrom=from,sphNorm;
	
    for (int i=0; i<RAY_STEPS; i++) {
		if (d.x>det && totdist<6.0) {
			p=from+totdist*dir;
			d=de(p);
			det=detail*(1.+totdist*60.)*(1.+ref*5.);
			totdist+=max(detail,d.x); 
			if (d.y<.5) glow+=max(0.,.02-d.x)/.02;
		}
	}
	vec3 ov=normalize(vec3(1.,.5,1.));
	vec3 sol=dir+lightdir;
    float l=pow(max(0.,dot(normalize(-dir*ov),normalize(lightdir*ov))),1.5)+sin(atan(sol.x,sol.y)*20.+length(from)*50.)*.0015;
    totdist=min(5.9,totdist);
    p=from+dir*(totdist-detail);
    vec3 backg=.4*(1.2-l)+LIGHT_COLOR*l*.75;
	backg*=AMBIENT_COLOR*(1.-max(0.2,dot(normalize(dir),vec3(0.,1.,0.)))*.2);
	float fondo=0.;
	vec3 pp=p*.5+sin(t*2.)*.5;
    for (int i=0; i<10; i++) {
        fondo+=clamp(0.,1.,textur(pp+dir*float(i)*.01))*max(0.,1.-exp(-.05*float(i)))*2.;
    }
    vec3 backg2=backg*(1.+fondo*(FLOOR_COLOR)*2.);
    if (d.x<.01) {
        vec3 norm=normal(p);
		col = mix(col,backg2, 1.0-exp(-.02*pow(abs(totdist),2.)));
	} else { 
		col=backg2;
	}
	vec3 lglow=LIGHT_COLOR*pow(abs(l),30.)*.5;
    col+=glow*(.3+backg+lglow)*.007;
	col+=lglow*min(1.,totdist*totdist*.2)*1.5;
    
	return min(vec3(1.),col); 
}

vec3 move(inout mat2 rotview1,inout mat2 rotview2) {
	vec3 go=path(t);
	vec3 adv=path(t+.5);
	vec3 advec=normalize(adv-go);
	float an=atan(advec.x,advec.z);
	rotview1=mat2(cos(an),sin(an),-sin(an),cos(an));
		  an=advec.y*1.5;
	rotview2=mat2(cos(an),sin(an),-sin(an),cos(an));
	return go;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    pth1 = path(t+.3)+origin+vec3(0.,.01,0.);
	vec2 uv = fragCoord.xy / iResolution.xy*2.-1.;
    vec2 uv2=uv;
	uv.y*=iResolution.y/iResolution.x;
	vec2 mouse=(iMouse.xy/iResolution.xy-.5)*3.;
	if (iMouse.z<1.) mouse=vec2(0.);
	mat2 rotview1, rotview2;
	vec3 from=origin+move(rotview1,rotview2);
	vec3 dir=normalize(vec3(uv,.75));
	dir.yz*=rot(mouse.y);
	dir.xz*=rot(mouse.x-1.);
	dir.yz*=rotview2;
	dir.xz*=rotview1;
	vec3 color=raymarch(from,dir); 
	color=clamp(color,vec3(.0),vec3(1.));
	color=pow(abs(color),vec3(GAMMA))*BRIGHTNESS;
	color=mix(vec3(length(color)),color,SATURATION);
	color*=1.2-length(pow(abs(uv2),vec2(3.)))*.5;
	float fadein=clamp(iTime-.5,0.,1.);
    fragColor = vec4(color*vec3(.93,.95,.91),1.)*fadein;
}