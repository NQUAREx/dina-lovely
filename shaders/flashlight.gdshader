shader_type canvas_item;
render_mode unshaded;
uniform float room_opacity = 1.0;
uniform vec2 room_band = vec2(-10000.0,10000.0);
uniform vec2 light_pos = vec2(270.0,480.0);
uniform vec2 view_size = vec2(540.0,960.0);
uniform vec2 hero_pos = vec2(270.0,480.0);
uniform vec2 light_dir = vec2(0.0,-1.0);
// Width, reach, penumbra and intensity arrive as smooth, seed-based motion.
uniform vec4 optics = vec4(1.0);
uniform bool enabled = false;
uniform bool ground_light = false;
void fragment(){
 vec2 pixel=UV*view_size;
 vec2 offset=pixel-light_pos;
 vec2 direction=normalize(light_dir+vec2(.00001));
 float along=dot(offset,direction);
 float across=abs(offset.x*direction.y-offset.y*direction.x);
 float reach=175.82*optics.y;
 float width=(12.0+max(0.0,along)*.41)*optics.x;
 // Gaussian falloff has no cut-off rim, either at the tip or along the sides.
 vec2 ray=vec2(across/(width*optics.z),(along-reach*.18)/(reach*.56*optics.z));
 float beam=exp(-1.4*dot(ray,ray))*smoothstep(-18.0,18.0,along);
 vec2 spread=vec2((along-reach*.36)/(reach*.59),across/(reach*.34*optics.z));
 float scatter=exp(-2.1*dot(spread,spread))*.16*smoothstep(-24.0,24.0,along);
 beam=beam*.88+scatter;
 float lens_spill=exp(-dot(offset,offset)/(28.0*28.0))*.5;
 // Light reflected from the lens reaches the dress without a separate hero halo.
 vec2 body=hero_pos-light_pos;
 float body_t=clamp(dot(offset,body)/max(dot(body,body),1.0),0.0,1.0);
 vec2 reflected=offset-body*body_t;
 float bounce=(ground_light?0.0:1.0)*exp(-dot(reflected,reflected)/(26.0*26.0))*(.34-.14*body_t);
 float light=enabled?clamp(max(beam,max(lens_spill,bounce))*optics.w,0.0,1.0):0.0;
 float in_room=smoothstep(room_band.x-64.0,room_band.x+64.0,pixel.y)*(1.0-smoothstep(room_band.y-64.0,room_band.y+64.0,pixel.y));
 COLOR=vec4(vec3(.08,.043,.016)*max(beam,bounce)*(enabled?1.0:0.0),(1.0-light)*max(room_opacity,in_room));
}
