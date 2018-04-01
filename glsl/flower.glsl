vec3 rcol(float i){
    return vec3(mod(cos(i*i*.631)*772.3,1.0),mod(cos(i*235.631)*472.0,1.0),mod(cos(i*i*.691+i*442.7)*775.2,1.0));
}

float rint(float i){
    return floor(2.+mod(cos(.2047219*i*i+43.962*i+56.)*336.,6.));
}

float rval(float divides,float angle){
    float nangle=abs(mod(angle,2.*3.14159/divides)-3.14159/divides)*divides/3.14159;
    float ptime=iTime;
    vec2 picka=.07*vec2(sin(ptime*.042+.9),cos(ptime*.03119));
    vec2 pickb=.08*vec2(sin(ptime*.04962),cos(ptime*.02619));
    
    return texture(iChannel0,picka*nangle+pickb*(1.-nangle)).x;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-iResolution.xy*.5)/iResolution.xx;
    float angle = atan(uv.x,uv.y)+iTime*.03;
    float vtime=iTime-length(uv+.07*vec2(sin(iTime*.3),cos(iTime*.3)))*29.;
    float colortime=.5;
    
    float rtime=floor(vtime/colortime);
    float ntime=rtime+1.;
    float lapse=mod(vtime/colortime,1.0);
    vec3 ncol=cos((rcol(ntime)*lapse+rcol(rtime)*(1.-lapse))*3.14159)*.5+.5;

    float diva=rint(floor(iTime*.05));
    float divb=rint(1.+floor(iTime*.05));
    float divc=diva*divb;
    float divd;
    float divstep=mod(iTime*.05,1.);
    if(divstep<.9){
        divd=diva;
    }
    else{
        divd=divb;
    }
    float cweight=clamp(1.-10.*abs(divstep-.9),0.,1.);
    float rvalue=rval(divc,angle)*cweight+rval(divd,angle)*(1.-cweight);
    
    float ring=clamp((.08-abs(.1+rvalue*.3-length(uv)))*19.,.0,1.);
    vec2 tile=floor(fragCoord*.01+0.01*vec2(1000.*sin(iTime*.5)+iTime*5.,1000.*cos(iTime*.5)));
    vec3 rtile=rcol(tile.x+59.*tile.y);
    vec3 tilecol=vec3(.1*sin(rtile.x*iTime));
    fragColor = vec4(ncol*ring+tilecol*(1.-ring),1.0);
}
