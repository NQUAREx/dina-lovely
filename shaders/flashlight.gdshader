shader_type canvas_item;
render_mode unshaded;
uniform float room_opacity = 1.0;
uniform vec2 room_band = vec2(-10000.0,10000.0);
uniform vec2 light_pos = vec2(270.0,480.0);
uniform vec2 view_size = vec2(540.0,960.0);
uniform vec2 hero_pos = vec2(270.0,480.0);
uniform vec2 light_dir = vec2(0.0,-1.0);
uniform bool enabled = false;
uniform vec2 pedestal_pos = vec2(-1000.0);
void fragment(){
 vec2 offset=UV*view_size-light_pos;
 vec2 direction=normalize(light_dir+vec2(.00001));
 float along=dot(offset,direction);
 float across=abs(offset.x*direction.y-offset.y*direction.x);
 float width=14.0+max(0.0,along)*.42;
 float core=(1.0-smoothstep(width*.1,width,across))*smoothstep(-12.0,18.0,along)*(1.0-smoothstep(68.0,183.6,along));
 float near_light=.96*(1.0-smoothstep(25.0,65.0,length(UV*view_size-hero_pos)));
 float light=enabled?max(near_light,core*.95):0.0;
 float in_room=smoothstep(room_band.x-64.0,room_band.x+64.0,UV.y*view_size.y)*(1.0-smoothstep(room_band.y-64.0,room_band.y+64.0,UV.y*view_size.y));
 COLOR=vec4(vec3(.0727375,.038,.0137275)*core*(enabled?1.0:0.0), (1.0-light)*max(room_opacity,in_room));
}
