shader_type canvas_item;
render_mode unshaded;
uniform vec2 view_size=vec2(540,960);
uniform vec4 visible_areas[20];
uniform int area_count=0;
uniform float fade_widths[20];
float distance_to_area(vec2 p,vec4 r){
 return length(max(max(r.xy-p,p-r.zw),vec2(0.)));
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
 // Slate at the near edge fades smoothly into black in the distance.
 vec3 dusk=mix(vec3(.070,.076,.095),vec3(0.),smoothstep(72.,280.,distance));
 COLOR=vec4(dusk,fog);
}
