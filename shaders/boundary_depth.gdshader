shader_type canvas_item;
render_mode unshaded;
uniform vec2 view_size=vec2(540,960);
uniform vec4 areas[7];
uniform int area_count=0;
float inside_rect(vec2 p,vec4 r){return min(min(p.x-r.x,r.z-p.x),min(p.y-r.y,r.w-p.y));}
void fragment(){
 vec2 p=UV*view_size;
 float depth=-10000.;
 for(int i=0;i<7;i++){if(i>=area_count)break;depth=max(depth,inside_rect(p,areas[i]));}
 // Broad irregular wisps obscure the rectangular outer limit; the outside
 // remains fully black. This overlay never darkens HUD or menu controls.
 float wisps=sin(p.x*.025+p.y*.013)*5.+sin(p.y*.047-p.x*.018)*3.;
 float reveal=smoothstep(0.,200.,max(0.,depth)+wisps*smoothstep(0.,20.,depth));
 COLOR=vec4(.008,.012,.020,1.-pow(reveal,.78));
}
