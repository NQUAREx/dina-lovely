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
// Atlas frames use the same pixel geometry as the heroine's world sprites.
uniform sampler2D hero_atlas : filter_nearest, repeat_disable;
uniform bool hero_occludes_light = false;
uniform vec2 hero_top_left = vec2(0.0);
uniform vec2 hero_tiles[7];
uniform sampler2D cloth_atlas : filter_nearest, repeat_disable;
uniform vec2 cloth_tiles[2];
uniform vec2 dress_nodes[20];
uniform int hero_tile_count = 0;
uniform vec2 gate_lights[4];
uniform int gate_light_count=0;
vec2 dress_rest(int vertex){
 return vec2(8.0+float(vertex%4)*(32.0/3.0),21.0+float(vertex/4)*4.75);
}
vec2 dress_uv(vec2 p,int ia,int ib,int ic){
 vec2 a=dress_nodes[ia], b=dress_nodes[ib]-a, c=dress_nodes[ic]-a;
 float determinant=b.x*c.y-b.y*c.x;
 if(abs(determinant)<.001)return vec2(-1.0);
 vec2 d=p-a;
 float u=(d.x*c.y-d.y*c.x)/determinant;
 float v=(b.x*d.y-b.y*d.x)/determinant;
 if(min(u,v)<-.0001 || u+v>1.0001)return vec2(-1.0);
 return dress_rest(ia)*(1.0-u-v)+dress_rest(ib)*u+dress_rest(ic)*v;
}
vec2 dress_sample(vec2 p){
 if(p.y<21.0)return p;
 for(int y=0;y<4;y++){
  for(int x=0;x<3;x++){
   int i=y*4+x;
   vec2 uv=dress_uv(p,i,i+1,i+5);
   if(uv.x>=0.0)return uv;
   uv=dress_uv(p,i,i+5,i+4);
   if(uv.x>=0.0)return uv;
  }
 }
 return vec2(-1.0);
}
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
 float hero_alpha=0.0;
 vec2 hero_uv=(pixel-hero_top_left)/vec2(64.0,96.0);
 if(hero_occludes_light && all(greaterThanEqual(hero_uv,vec2(0.0))) && all(lessThan(hero_uv,vec2(1.0)))){
  vec2 atlas_size=vec2(textureSize(hero_atlas,0));
  for(int i=0;i<7;i++){
   if(i>=hero_tile_count)break;
   vec2 sprite_pixel=hero_tiles[i]*vec2(32.0,48.0)+hero_uv*vec2(32.0,48.0);
   hero_alpha=max(hero_alpha,texture(hero_atlas,sprite_pixel/atlas_size).a);
  }
 }
 vec2 cloth_pixel=(pixel-hero_top_left)*0.5+vec2(8.0,-7.0);
 if(hero_occludes_light && all(greaterThanEqual(cloth_pixel,vec2(0.0))) && all(lessThan(cloth_pixel,vec2(48.0,40.0)))){
  vec2 cloth_size=vec2(textureSize(cloth_atlas,0));
  for(int i=0;i<2;i++){
   if(cloth_tiles[i].x<0.0)continue;
   vec2 source=i==0?dress_sample(cloth_pixel):cloth_pixel;
   if(source.x<0.0)continue;
   vec2 sprite_pixel=cloth_tiles[i]*vec2(48.0,40.0)+source;
   hero_alpha=max(hero_alpha,texture(cloth_atlas,sprite_pixel/cloth_size).a);
  }
 }
 if(hero_occludes_light){
  // Keep just enough indirect light to read the sprite in the dark; the beam
  // and its warm tint stay behind the body and its worn accessories.
  light=mix(light,min(light,0.12),hero_alpha);
 }
 float gate_light=0.0;
 for(int i=0;i<4;i++){
  if(i>=gate_light_count)break;
  vec2 delta=pixel-gate_lights[i];
  float width=9.0+max(0.0,delta.y)*.30;
  float spill=pow(max(0.0,1.0-abs(delta.x)/width),2.0)*pow(max(0.0,1.0-delta.y/44.0),1.6);
  gate_light=max(gate_light,delta.y>=0.0?spill*.12:0.0);
 }
 light=max(light,gate_light);
 float in_room=smoothstep(room_band.x-64.0,room_band.x+64.0,pixel.y)*(1.0-smoothstep(room_band.y-64.0,room_band.y+64.0,pixel.y));
 COLOR=vec4(vec3(.08,.043,.016)*max(beam,bounce)*(enabled?1.0:0.0)*(1.0-hero_alpha),(1.0-light)*max(room_opacity,in_room));
}
