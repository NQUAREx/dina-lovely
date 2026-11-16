shader_type canvas_item;
render_mode unshaded;
uniform vec2 view_size=vec2(540,960);
uniform vec4 areas[7];
uniform int area_count=0;
uniform sampler2D floor_mask0:filter_nearest,repeat_disable;
uniform sampler2D floor_mask1:filter_nearest,repeat_disable;
uniform sampler2D floor_mask2:filter_nearest,repeat_disable;
uniform vec4 floor_rect0;
uniform vec4 floor_rect1;
uniform vec4 floor_rect2;
uniform int floor_count=0;
uniform vec4 protected_halls[2];
uniform int hall_count=0;
float protected_floor(vec2 p,vec4 r,sampler2D mask){
 vec2 uv=(p-r.xy)/r.zw;
 if(any(lessThan(uv,vec2(0.)))||any(greaterThanEqual(uv,vec2(1.))))return 0.;
 return step(.5,texture(mask,uv).r);
}
float inside_rect(vec2 p,vec4 r){return min(min(p.x-r.x,r.z-p.x),min(p.y-r.y,r.w-p.y));}
void fragment(){
 vec2 p=UV*view_size;
 float depth=-10000.;
 for(int i=0;i<7;i++){if(i>=area_count)break;depth=max(depth,inside_rect(p,areas[i]));}
 // Broad irregular wisps obscure the rectangular outer limit; the outside
 // remains fully black. This overlay never darkens HUD or menu controls.
 float wisps=sin(p.x*.025+p.y*.013)*5.+sin(p.y*.047-p.x*.018)*3.;
 float reveal=smoothstep(0.,100.,max(0.,depth)+wisps*smoothstep(0.,20.,depth));
 float safe=protected_floor(p,floor_rect0,floor_mask0);
 if(floor_count>1)safe=max(safe,protected_floor(p,floor_rect1,floor_mask1));
 if(floor_count>2)safe=max(safe,protected_floor(p,floor_rect2,floor_mask2));
 for(int i=0;i<2;i++){if(i>=hall_count)break;if(inside_rect(p,protected_halls[i])>=0.)safe=1.;}
 COLOR=vec4(.008,.012,.020,(1.-pow(reveal,.78))*(1.-safe));
}
