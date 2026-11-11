shader_type canvas_item;
render_mode unshaded;
uniform float room_opacity = 1.0;
uniform vec2 room_band = vec2(-10000.0,10000.0);
uniform vec2 light_pos = vec2(270.0,480.0);
uniform vec2 view_size = vec2(540.0,960.0);
uniform vec2 hero_pos = vec2(270.0,480.0);
uniform vec2 light_dir = vec2(0.0,-1.0);
uniform float light_time = 0.0;
uniform float walking = 0.0;
uniform bool enabled = false;
void fragment(){
 vec2 pixel=UV*view_size;
 vec2 offset=pixel-light_pos;
 vec2 direction=normalize(light_dir+vec2(.00001));
 float along=dot(offset,direction);
 float across=abs(offset.x*direction.y-offset.y*direction.x);
 // Broad Gaussian angular falloff and a long penumbra; no hard cone rim.
 float breathing=1.0+sin(light_time*1.7)*.018+walking*sin(light_time*10.0)*.035;
 float focus=1.0+sin(light_time*.83)*.035+walking*sin(light_time*5.0)*.055;
 float width=(12.0+max(0.0,along)*.44)*focus;
 float angular=exp(-1.35*pow(across/width,2.0));
 float reach=175.82*breathing;
 // A soft elliptical cap rounds the far end instead of a sharp triangular cone.
 float cap=length(vec2((along-reach*.40)/(reach*.60),across/(width*1.7)));
 float beam=angular*smoothstep(-18.0,16.0,along)*(1.0-smoothstep(.30,1.0,cap));
 float lens_spill=(1.0-smoothstep(0.0,55.0,length(offset)))*.56;
 // Reflected light reaches the dress along the lens-to-body segment, no hero halo.
 vec2 body=hero_pos-light_pos;
 float body_t=clamp(dot(offset,body)/max(dot(body,body),1.0),0.0,1.0);
 vec2 reflected=offset-body*body_t;
 float bounce=(1.0-smoothstep(0.0,34.0,length(reflected)))*(.42-.18*body_t);
 // Occasional paired battery dips, with smooth recovery and no full blackout.
 float interval=floor(light_time/3.8);
 float chance=fract(sin(interval*12.9898+41.0)*43758.5453);
 float phase=mod(light_time,3.8);
 float dip=step(.42,chance)*(.28*exp(-pow((phase-1.0)/.085,2.0))+.16*exp(-pow((phase-1.25)/.10,2.0)));
 float intensity=.96+sin(light_time*3.2)*.025+sin(light_time*9.7)*.012-dip;
 float light=enabled?clamp(max(beam*.97,max(lens_spill,bounce))*intensity,0.0,1.0):0.0;
 float in_room=smoothstep(room_band.x-64.0,room_band.x+64.0,pixel.y)*(1.0-smoothstep(room_band.y-64.0,room_band.y+64.0,pixel.y));
 COLOR=vec4(vec3(.08,.043,.016)*max(beam,bounce)*(enabled?1.0:0.0),(1.0-light)*max(room_opacity,in_room));
}
