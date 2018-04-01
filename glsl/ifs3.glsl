/*///////////////////////////////////////////////////////////////////////////////
 Distance estimation for (very) simple IFS. by knighty (nov. 2013).
 
 Computing DE for IFS requires normally a priority list or at least a stack. (references later)
It happens that there is a correspondance between a n generators IFS and the base n representation
of a number in [0,1[. That is there is a /bijection/(Edit: that is not true in the limit) between the IFS
and the [0,1[ interval. So we can we call any IFS a CURVE?

 This fact is used here to discard whole subtrees in the evaluation of the DE.

? This method could be used to compute distance to any curve provided we have a way to compute
a bounding volume to any segment of that curve (for example a curve is contained in the circle
which radius is the length of that curve and centred at any point inside the curve).
This is the case of Bezier curves (obviously the length of it's skeleton).

 This method could be applied in principle to other IFS.

 For fragmentarium scripts see: 
http://www.fractalforums.com/ifs-iterated-function-systems/dragonkifs-promising-formula-but-help-needed/msg68853/#msg68853

///////////////////////////////////////////////////////////////////////////////*/

#define DEPTH 10
#define ITER_NUM pow(2., float(DEPTH))

//Bounding radius to bailout. must be >1. higher values -> more accurate but slower
#define BR2BO 64.
vec2 A = vec2( 1.);//Computed in main(). Stores the similarity of the transformation
float scl = 1.414;//scale of the IFS. must be >1. Smaller values -> slower.
float Findex=0.;//mapping of IFS point to [0,1[
float minFindex=0.;//
float BR=2.;//Computed in main(). Bounding circle radius. The smaller, the better (that is faster) but it have to cover the fractal
float BO=16.;//Computed in main(). Bailout value. it should be = (BR*s)^2 where s>1. bigger s give more accurate results but is slower.
float od=1000.;//computed object trap DE
float otR;//=0.3*(sin(iTime*5.)+2.);//object trap is a disc with radius otR;
//Complex multiplication
vec2 Cmult(vec2 a, vec2 b){ return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);}

//Original. very slow.
/*float dragonSample1(vec2 p, float lastDist){
	float q=rnd;
	float d=length(p)-BR;
	float dd=1.;
	for(int i=0; i<iterNum; i++){
		if(d>lastDist) break;//continue;//
		float sgn=2.*floor(q*2.)-1.; q=fract(q*2.);
		p=Cmult(A,p); p.x+=sgn;
		dd*=lA;
		d=(length(p)-BR)/dd;
	}
	rnd = fract( rnd + 1./256. );//fract( rnd * 8.13 );
	return min(d,lastDist);
}*/

//Estimate the distance to the fractal by using a simple mathod
//it gives the exact result when A is pure real or pure imaginary
float dragonSampleEst(vec2 p){
	float dd=1.;
	float q=0.,j=1.;
	for(int i=0; i<DEPTH; i++){
		if(dot(p,p)>BO) break;//continue;//
		p=Cmult(A,p);
		float l0=dot(p+vec2(1.,0.), p+vec2(1.,0.));
		float l1=dot(p-vec2(1.,0.), p-vec2(1.,0.));
		q*=2.;j*=0.5;
		if(min(l0,l1)==l0) {p.x+=1.; q+=1.;} 
		else p.x-=1.;//select nearest branche
		dd*=scl;
	}
	minFindex=q*j;
	float d=(length(p)-BR)/dd;
	return d;
}

//Computes distance to the point in the IFS which index is the current index.
//lastDist is a given DE. If at some level the computed distance is bigger than lastDist
//that means the current index point is not the nearest so we bail out and discard all
//children of the current index point.
//We also use a static Bail out value to speed things up a little while accepting less accurate DE.
float dragonSample(vec2 p, float lastDist){
	float q=Findex;//Get the index of the current point
	float dd=1.;//running scale
	float j=ITER_NUM;
	for(int i=0; i<DEPTH; i++){
		float temp=BR+lastDist*dd;//this id to avoid computing length (sqrt)
		float l2=dot(p,p);
		if(l2>0.0001+temp*temp || l2>BO) break;//continue;//continue is too slow here
		
		//get the sign of the translation from the binary representation of the index
		float sgn=2.*floor(q*2.)-1.; q=fract(q*2.); j*=.5;
		
		p=Cmult(A,p);//similarity
		p.x+=sgn;    //translation
		dd*=scl;
	}
	//update current index. it is not necessary to check the next j-1 points.
	//This is the main optimization
	Findex = ( Findex + j*1./ITER_NUM );
	float d=(length(p)-BR)/dd;//distance to current point
	if(d<lastDist) minFindex=Findex;
	return min(d,lastDist);
}

float dragonSample1(vec2 p, float lastDist){
	float q=Findex;//Get the index of the current point
	float dd=1.;//running scale
	float d=(length(p)-BR);
	float j=ITER_NUM;
	for(int i=0; i<DEPTH; i++){
		//float temp=BR+lastDist*dd;//this id to avoid computing length (sqrt)
		float l2=dot(p,p);
		if(d>0.0001+lastDist || l2>BO) break;//continue;//continue is too slow here
		
		//get the sign of the translation from the binary representation of the index
		float sgn=2.*floor(q*2.)-1.; q=fract(q*2.); j*=.5;
		
		p=Cmult(A,p);//similarity
		p.x+=sgn;    //translation
		dd*=scl;
		d=(length(p)-BR)/dd;
	}
	//update current index. it is not necessary to check the next j-1 points.
	//This is the main optimization
	Findex = ( Findex + j*1./ITER_NUM );
	//float d=(length(p)-BR)/dd;//distance to current point
	if(d<lastDist) minFindex=Findex;
	return min(d,lastDist);
}

float dragonSampleOT(vec2 p, float lastDist){
	float q=Findex;//Get the index of the current point
	float dd=1.;//running scale
	float d=(length(p)-BR);
	od=min(od,(length(p)-otR));//length(p)-0.33;
	float j=ITER_NUM;
	for(int i=0; i<DEPTH; i++){
		//float temp=BR+lastDist*dd;//this is to avoid computing length (sqrt)
		float l2=dot(p,p);
		if(d>0.0001+lastDist || l2>BO) break;//continue;//
		
		//get the sign of the translation from the binary representation of the index
		float sgn=2.*floor(q*2.)-1.; q=fract(q*2.); j*=.5;
		
		p=Cmult(A,p);//similarity
		p.x+=sgn;    //translation
		dd*=scl;
		d=(length(p)-BR)/dd;
		od=min(od,(length(p)-otR)/dd);//object trap. you could replace it with another shape. Just make it sure it fits inside bounding circle!
	}
	Findex = ( Findex + j*1./ITER_NUM );
	//float d=(length(p)-BR)/dd;//distance to current point
	if(d<lastDist) minFindex=Findex;
	return min(d,lastDist);
}

float dragonSampleKali(vec2 p, float lastDist){
	float q=Findex;//Get the index of the current point
	float d=(length(p)-BR);
	float dd=1.;//running scale
	float j=ITER_NUM;
	for(int i=0; i<DEPTH; i++){
		float l2=dot(p,p);
		if(d>lastDist || l2>BO) break;//continue;//continue is too slow here
		
		//get the sign of the translation from the binary representation of the index
		float sgn=2.*floor(q*2.)-1.; q=fract(q*2.); j*=.5;
		//float lp=(sgn*p.x+0.)/dd;
		p=Cmult(A,p);//similarity
		dd*=scl;
		float lp=(sgn*p.x-0.)/dd;
		p.x+=sgn;    //translation
		
		d=max(d,max(lp,(length(p)-BR)/dd));
	}
	//update current index. it is not necessary to check the next j-1 points.
	//This is the main optimization
	Findex = ( Findex + j*1./ITER_NUM );
	//float d=(length(p)-BR)/dd;//distance to current point
	return min(d,lastDist);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	otR=0.3*(sin(iTime*5.)+2.);
    //construct similarity using angle ang and scale scl
	float ang=0.1*iTime;
	A = scl*vec2(cos(ang), sin(ang));
	//compute bounding circle's radius. it's that simple :)
	BR=1./(scl-1.);
	//Compute bail out value
	BO=BR*BR*BR2BO;
	//coordinates of current pixel in object space. 
	vec2 uv = 2.*BR *(fragCoord.xy-0.5*iResolution.xy) / iResolution.y;
	//Get an estimate. not necessary, but it's faster this way.
	float d=dragonSampleEst(uv);//1.;//0.01;//
	//refine the DE
	for(int i=0; i<120; i++){//experiment: try other values
	// In principle max number of iteration should be ITER_NUM but we actually
	//do much less iterations. Maybe less than O(DEPTH^2). Depends also on scl.
		d=dragonSampleOT(uv,d);
		if(Findex==1.) break;
	}
	if(mod(iTime,10.)<5.) d=od;//switch between regular IFS and object trap
	fragColor = vec4(pow(abs(d),0.33))*(0.9+0.1*sin(vec4(10.,6.5,3.25,1.)*minFindex));//
}
