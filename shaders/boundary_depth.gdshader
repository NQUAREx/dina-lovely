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
float clouds(vec2 p,float size,float seed){
 vec2 cell=floor(p/size);float density=0.;
 for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
  vec2 id=cell+vec2(float(x),float(y));
  float a=hash21(id+seed),b=hash21(id+seed+19.);
  vec2 centre=(id+vec2(.15+.7*a,.15+.7*b))*size;
  vec2 q=(p-centre)/(size*vec2(.42+.27*b,.30+.22*a));
  // Several unequal overlapping lobes give every cluster its own silhouette.
  float body=exp(-2.3*dot(q,q));
  vec2 l=q-vec2(.65,-.25);vec2 r=q+vec2(.55,.10);
  body=max(body,max(exp(-3.8*dot(l,l)),exp(-3.1*dot(r,r))));
  density+=body*(.65+.35*a);
 }
 return clamp(density,0.,1.);
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
 // Stable world-space clouds: no reseeding when crossing a corridor seam.
 vec2 world=floor((p+world_origin)/2.)*2.;
 float broad=clouds(world,132.,5.);
 float middle=clouds(world+vec2(31.,-47.),64.,37.);
 float detail=clouds(world,29.,91.);
 float relief=clamp(broad*.55+middle*.32+detail*.13,0.,1.);
 vec3 shade=vec3(.31,.32,.40),light=vec3(.69,.70,.76);
 vec3 colour=mix(shade,light,smoothstep(.12,.86,relief));
 COLOR=vec4(colour,fog);
}
