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
uniform vec2 lining_tiles[2];
uniform vec2 dress_nodes[63];
uniform vec2 mantle_nodes[63];
uniform vec2 cloth_row_ranges[18];
uniform int hero_tile_count = 0;
uniform vec2 gate_lights[4];
uniform int gate_light_count=0;
vec2 cloth_node(int garment,int index){
 return garment==0?dress_nodes[index]:mantle_nodes[index];
}

vec2 triangle_weights(vec2 offset,vec2 b,vec2 c){
 float area=b.x*c.y-b.y*c.x;
 if(abs(area)<0.0001)return vec2(-1.0);
 vec2 weights=vec2(offset.x*c.y-offset.y*c.x,b.x*offset.y-b.y*offset.x)/area;
 if(min(weights.x,weights.y)<-0.00001 || weights.x+weights.y>1.00001)return vec2(-1.0);
 return weights;
}

// Find the same mesh triangle that covers this pixel in the outfit draw.
vec2 cloth_source(vec2 point,int garment){
 float waist=garment==0?20.0:0.0;
 vec2 cell=vec2(32.0/6.0,(40.0-waist)/8.0);
 for(int row=0;row<8;row++){
  int band=garment*9+row;
  vec2 top=cloth_row_ranges[band],bottom=cloth_row_ranges[band+1];
  if(point.y<min(top.x,bottom.x) || point.y>max(top.y,bottom.y))continue;
  int index=row*7;
  vec2 tl=cloth_node(garment,index),bl=cloth_node(garment,index+7);
  for(int col=0;col<6;col++){
   vec2 tr=cloth_node(garment,index+col+1),br=cloth_node(garment,index+col+8);
   if(point.x>=min(min(tl.x,bl.x),min(tr.x,br.x)) && point.x<=max(max(tl.x,bl.x),max(tr.x,br.x))){
    vec2 origin=vec2(8.0,waist)+vec2(float(col),float(row))*cell;
    vec2 w=triangle_weights(point-tl,tr-tl,br-tl);
    if(w.x>=-0.00001)return origin+cell*vec2(w.x+w.y,w.y);
    w=triangle_weights(point-tl,br-tl,bl-tl);
    if(w.x>=-0.00001)return origin+cell*vec2(w.x,w.x+w.y);
   }
   tl=tr;
   bl=br;
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
 if(hero_occludes_light && hero_alpha<1.0 && all(greaterThanEqual(cloth_pixel,vec2(0.0))) && all(lessThan(cloth_pixel,vec2(48.0,40.0)))){
  vec2 atlas_size=vec2(textureSize(cloth_atlas,0));
  vec2 tile_size=vec2(48.0,40.0);
  for(int garment=0;garment<2;garment++){
   if(cloth_tiles[garment].x<0.0)continue;
   vec2 lining=lining_tiles[garment]*tile_size+cloth_pixel;
   hero_alpha=max(hero_alpha,texture(cloth_atlas,lining/atlas_size).a);
   if(hero_alpha>=1.0)break;
   vec2 source=cloth_source(cloth_pixel,garment);
   if(source.x<0.0 || source.y<0.0 || source.y>=tile_size.y)continue;
   vec2 shell=cloth_tiles[garment]*tile_size+source;
   hero_alpha=max(hero_alpha,texture(cloth_atlas,shell/atlas_size).a);
   if(hero_alpha>=1.0)break;
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
