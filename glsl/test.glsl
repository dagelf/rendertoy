out vec4 c;

void mainImage(vec4 b,vec2 a)
{
    c = vec4(iMouse.y/iResolution.y, iMouse.x/iResolution.x, 0.2, 0.0);
}
