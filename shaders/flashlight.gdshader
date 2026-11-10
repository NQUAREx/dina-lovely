shader_type canvas_item;
render_mode unshaded;
uniform float room_opacity = 1.0;
uniform vec2 room_band = vec2(-10000.0,10000.0);
uniform vec2 light_pos = vec2(270.0,480.0);
uniform vec2 view_size = vec2(540.0,960.0);
uniform vec2 hero_pos = vec2(270.0,480.0);
uniform vec2 light_dir = vec2(0.0,-1.0);
uniform bool enabled = false;
void fragment(){
 vec2 pixel=UV*view_size;
 vec2 offset=pixel-light_pos;
 vec2 direction=normalize(light_dir+vec2(.00001));
 float along=dot(offset,direction);
 float across=abs(offset.x*direction.y-offset.y*direction.x);
 // Broad Gaussian angular falloff and a long penumbra; no hard cone rim.
 float width=12.0+max(0.0,along)*.58;
 float angular=exp(-1.8*pow(across/width,2.0))*(1.0-smoothstep(width*.6,width*1.8,across));
 float beam=angular*smoothstep(-16.0,18.0,along)*(1.0-smoothstep(20.0,158.0,along));
 float lens_spill=(1.0-smoothstep(0.0,55.0,length(offset)))*.56;
 // Reflected light reaches the dress along the lens-to-body segment, no hero halo.
 vec2 body=hero_pos-light_pos;
 float body_t=clamp(dot(offset,body)/max(dot(body,body),1.0),0.0,1.0);
 vec2 reflected=offset-body*body_t;
 float bounce=(1.0-smoothstep(0.0,34.0,length(reflected)))*(.42-.18*body_t);
 float light=enabled?max(beam*.97,max(lens_spill,bounce)):0.0;
 float in_room=smoothstep(room_band.x-64.0,room_band.x+64.0,pixel.y)*(1.0-smoothstep(room_band.y-64.0,room_band.y+64.0,pixel.y));
 COLOR=vec4(vec3(.08,.043,.016)*max(beam,bounce)*(enabled?1.0:0.0),(1.0-light)*max(room_opacity,in_room));
}
