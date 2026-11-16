shader_type canvas_item;
render_mode unshaded;
uniform vec2 world_origin=vec2(0.);
uniform vec2 view_size=vec2(540,960);
uniform vec4 visible_areas[20];
uniform int area_count=0;
uniform float fade_widths[20];
float distance_to_area(vec2 p,vec4 r){
 return length(max(max(r.xy-p,p-r.zw),vec2(0.)));
}
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
uniform sampler2D cloud_atlas:filter_nearest,repeat_disable;
vec4 cloud_layer(vec2 p,float pitch,float seed){
 vec2 cell=floor(p/pitch);vec4 colour=vec4(0.);
 // Stable back-to-front packing, like overlapping hedge crowns.
 for(int y=-2;y<=2;y++)for(int x=-2;x<=2;x++){
  vec2 id=cell+vec2(float(x),float(y));
  float a=hash21(id+seed),b=hash21(id+seed+19.);
  float variant=floor(a*8.);
  vec2 centre=(id+vec2(.5+(a-.5)*.65,.5+(b-.5)*.65))*pitch;
  float scale=1.35+b*.65;
  vec2 uv=(p-centre)/(pitch*scale)+.5;
  if(any(lessThan(uv,vec2(0.)))||any(greaterThanEqual(uv,vec2(1.))))continue;
  if(b>.5)uv.x=1.-uv.x;
  vec4 stamp=texture(cloud_atlas,vec2((variant+uv.x)/8.,uv.y));
  colour=mix(colour,vec4(stamp.rgb,1.),stamp.a);
 }
 return colour;
}
void fragment(){
 vec2 p=UV*view_size;
 float distance=10000.;
 float fade_distance=10000.;
 for(int i=0;i<20;i++){
  if(i>=area_count)break;
  float d=distance_to_area(p,visible_areas[i]);
  distance=min(distance,d);
  fade_distance=min(fade_distance,d/max(fade_widths[i],1.));
 }
 // One distance field for rooms and corridors. There is no switch
 // at a floor edge: alpha and its derivative both start at zero there.
 float fog=smoothstep(0.,1.,fade_distance);
 vec2 world=floor((p+world_origin)/2.)*2.;
 vec4 back=cloud_layer(world+vec2(37.,19.),88.,5.);
 vec4 front=cloud_layer(world,68.,71.);
 vec3 colour=mix(vec3(.39,.41,.49),back.rgb,back.a);
 colour=mix(colour,front.rgb,front.a);
 COLOR=vec4(colour,fog);
}
