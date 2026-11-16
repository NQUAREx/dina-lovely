shader_type canvas_item;
uniform vec2 view_size=vec2(540,960);
uniform sampler2D player_mask:filter_nearest,repeat_disable;
uniform vec4 player_rect=vec4(0.);
uniform bool player_in_front=false;
uniform bool held_enabled=false;
uniform sampler2D held_mask:filter_nearest,repeat_disable;
uniform vec4 held_uv=vec4(0.,0.,1.,1.);
uniform vec4 held_rect=vec4(0.);
uniform vec2 held_origin=vec2(0.);
uniform vec2 held_flip=vec2(1.);
uniform float held_rotation=0.;
uniform sampler2D actor_atlas:filter_nearest,repeat_disable;
uniform vec4 actor_rects[16];
uniform vec4 actor_uvs[16];
uniform int actor_count=0;
float silhouette(vec2 p,vec4 r,sampler2D mask,vec4 uv_rect){
 vec2 uv=(p-r.xy)/r.zw;
 if(any(lessThan(uv,vec2(0.)))||any(greaterThanEqual(uv,vec2(1.))))return 0.;
 return texture(mask,uv_rect.xy+uv*uv_rect.zw).a;
}
void fragment(){
 vec2 p=SCREEN_UV*view_size;
 float cover=0.;
 if(player_in_front){
  cover=silhouette(p,player_rect,player_mask,vec4(0.,0.,1.,1.));
  if(held_enabled){
   vec2 d=p-held_origin;
   float c=cos(held_rotation),s=sin(held_rotation);
   vec2 q=vec2(dot(d,vec2(c,s)),dot(d,vec2(-s,c)))/held_flip;
   cover=max(cover,silhouette(q,held_rect,held_mask,held_uv));
  }
 }
 for(int i=0;i<16;i++){
  if(i>=actor_count)break;
  cover=max(cover,silhouette(p,actor_rects[i],actor_atlas,actor_uvs[i]));
 }
 COLOR.a*=1.-cover;
}
