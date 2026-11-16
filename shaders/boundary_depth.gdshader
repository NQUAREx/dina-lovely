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
float boundary_distance(vec2 p){
 float d=10000.;
 for(int i=0;i<20;i++){
  if(i>=area_count)break;
  d=min(d,distance_to_area(p,visible_areas[i]));
 }
 return d;
}
vec4 cloud_layer(vec2 p,float pitch,float seed,float min_depth){
 vec2 cell=floor(p/pitch);vec4 colour=vec4(0.);float top=-1.e20;
 for(int y=-2;y<=2;y++)for(int x=-2;x<=2;x++){
  vec2 id=cell+vec2(float(x),float(y));
  float a=hash21(id+seed),b=hash21(id+seed+19.);
  vec2 centre=(id+vec2(.5+(a-.5)*.65,.5+(b-.5)*.65))*pitch;
  float depth=boundary_distance(centre-world_origin);
  if(depth<min_depth)continue;
  float growth=smoothstep(min_depth+2.,min_depth+118.,depth);
  if(hash21(id+seed+47.)>mix(.20,1.,growth))continue;
  float diameter=min(pitch*mix(.30,2.25,growth)*( .85+b*.3),depth*1.65);
  vec2 uv=(p-centre)/diameter+.5;
  if(any(lessThan(uv,vec2(0.)))||any(greaterThanEqual(uv,vec2(1.))))continue;
  if(b>.5)uv.x=1.-uv.x;
  float variant=floor(a*8.);
  // Clamp inside each sprite: never sample an adjacent atlas cell.
  uv=(floor(uv*64.)+.5)/64.;
  vec4 stamp=texture(cloud_atlas,vec2((variant+uv.x)/8.,uv.y));
  // Global per-cloud priority is independent of the current spatial bucket.
  float priority=centre.y+hash21(id+seed+83.)*pitch*.7;
  if(stamp.a>.5&&priority>top){colour=stamp;top=priority;}
 }
 return colour;
}
void fragment(){
 vec2 p=UV*view_size;
 vec2 world=floor((p+world_origin)/2.)*2.;
 vec4 back=cloud_layer(world,62.,5.,10.);
 vec4 front=cloud_layer(world,48.,71.,10.);
 vec4 distant=cloud_layer(world,152.,137.,120.);
 COLOR=distant.a>.5?distant:(front.a>.5?front:back);
}
