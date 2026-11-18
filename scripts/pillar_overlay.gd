extends Node2D
## Foreground architecture stays above fog, while actor silhouettes preserve
## the world's original depth ordering. No rectangular actor-shaped cutouts.
var g:Node2D
var textures:Dictionary={}
var sprites:Dictionary={}
var masks:Dictionary={}
var atlas_image:Image
func _ready()->void:
 g=get_parent();z_index=101
func player_mask()->Texture2D:
 var face:int=g.visual_facing();var frame:int=g.player_walk_frame()
 var key:=str(face)+":"+str(frame)+":"+str(g.save_data.wearing)
 if not masks.has(key):
  if atlas_image==null:atlas_image=g.atlas.get_image()
  var image:=Image.create(32,48,false,Image.FORMAT_RGBA8)
  var layers:Array=["hero%d_%d"%[face,frame]]
  for item in g.OUTFIT_ORDER:
   if item in g.save_data.wearing:layers.append("wear_%s_%d_%d"%[item,face,frame])
  for layer in layers:
   var id:int=g.sprites[layer]
   image.blend_rect(atlas_image,Rect2i(id%16*32,id/16*48,32,48),Vector2i.ZERO)
  if masks.size()>96:masks.clear()
  masks[key]=ImageTexture.create_from_image(image)
 return masks[key]
func foreground(actor:Vector2,door:Vector2)->bool:
 return actor.y>door.y or (actor.y==door.y and actor.x>door.x)
func player_box()->Rect2:
 var p:Vector2=g.screen(g.player)+g.body_motion()
 if not g.resting.is_empty():p+=Vector2(0,-18+sin(g.time*2.4)*12 if g.resting=="swing" else -18)
 return Rect2(p-Vector2(32,86),Vector2(64,96))
func held_mask(shader:ShaderMaterial)->void:
 var enabled:=false
 var texture:Texture2D=g.atlas
 var uv:=Vector4(0,0,1,1)
 var box:=Rect2()
 var origin:=Vector2.ZERO;var rotation:=0.0;var flip:=Vector2.ONE
 var name:=""
 if (g.level==4 or g.save_data.finished) and not g.weapon.is_empty():
  enabled=true
  origin=g.screen(g.right_hand_position())-g.aim*(g.attack_flash/.22)*(14.0 if g.weapon=="rpg" else 11.5)
  var left:bool=g.aim.x<0
  var swing:float=sin((1-g.attack_flash/.22)*PI)*1.5 if g.weapon=="sword" and g.attack_flash>0 else 0.0
  rotation=((g.aim.angle()+PI/2) if g.weapon=="sword" else (atan2(-g.aim.y,-g.aim.x) if left else g.aim.angle()))+swing
  flip=Vector2(-1 if left and g.weapon!="sword" else 1,1)
  if g.weapon=="rpg":
   texture=g.rpg_textures["empty" if g.rpg_reload>0 else "loaded"]
   box=Rect2(-32,-25.6,76.8,38.4)
  else:
   name="weapon_"+g.weapon
   var grip:=Vector2(15,38) if g.weapon=="sword" else Vector2(13,30)
   box=Rect2(-grip*1.2,Vector2(32,48)*1.2)
 elif g.level==5 and g.held_item in g.garden_quest.TOOLS:
  enabled=true
  var pose:Dictionary=g.garden_quest.held_pose()
  texture=g.garden_quest.texture()
  origin=pose.origin;rotation=pose.rotation;flip=pose.flip;box=pose.box
  var source:Rect2=pose.source
  var size:=Vector2(texture.get_size())
  uv=Vector4(source.position.x/size.x,source.position.y/size.y,source.size.x/size.x,source.size.y/size.y)
 elif g.held_item in ["can","rake","fertilizer","shovel","flashlight","axe","shears","drill","quest_axe","pickaxe"]:
  enabled=true
  var pose:Dictionary=g.held_tool_pose()
  name="fertilizer_open" if g.task_time>0 and g.task_kind.begins_with("fertilize:") else "shears_closed" if g.held_item=="shears" and g.task_time>0 and g.task_time<g.task_duration*.55 else "drill_spin"+str(int(g.time*22)%2) if g.held_item=="drill" and g.world_tools.drilling else g.held_item
  if name=="quest_axe":name="axe"
  if name=="shovel" and g.level==3 and g.dig_quest.state().broken:name="shovel_broken"
  origin=g.screen(pose.hand);rotation=pose.angle;flip=pose.flip
  box=Rect2(-pose.anchor*pose.scale,Vector2(32,48)*pose.scale)
 if not name.is_empty() and not g.sprites.has(name):enabled=false
 if not name.is_empty() and g.sprites.has(name):
  var id:int=g.sprites[name];var size:Vector2=g.atlas.get_size()
  uv=Vector4(float(id%16*32)/size.x,float(id/16*48)/size.y,32./size.x,48./size.y)
 shader.set_shader_parameter("held_enabled",enabled)
 shader.set_shader_parameter("held_mask",texture);shader.set_shader_parameter("held_uv",uv)
 shader.set_shader_parameter("held_rect",Vector4(box.position.x,box.position.y,box.size.x,box.size.y))
 shader.set_shader_parameter("held_origin",origin);shader.set_shader_parameter("held_rotation",rotation);shader.set_shader_parameter("held_flip",flip)
func posts(objects:Array,origin:Vector2,room_id:int)->void:
 for door in objects:
  if door.kind!="doorway":continue
  var world:Vector2=door.pos+origin
  var pos:Vector2=g.screen(world)
  if not Rect2(pos-Vector2(144,160),Vector2(288,224)).intersects(g.get_viewport_rect()):continue
  for side in [-1,1]:
   var key:="junction_stone_stone_%s_%s"%["top" if door.id=="exit" else "bottom","left" if side<0 else "right"]
   if not textures.has(key):textures[key]=load("res://assets/"+key+".png")
   var post_key:=str(room_id)+":"+str(door.id)+":"+str(side)
   if not sprites.has(post_key):
    var sprite:=Sprite2D.new();sprite.centered=false
    var shader:=ShaderMaterial.new();shader.shader=preload("res://shaders/pillar_occlusion.gdshader")
    sprite.material=shader;add_child(sprite);sprites[post_key]=sprite
   var sprite:Sprite2D=sprites[post_key]
   # Lower entrance posts already participate in world depth sorting.
   # Repainting them above everything covers the foreground wall.
   sprite.visible=door.id=="exit";sprite.texture=textures[key]
   sprite.position=pos+Vector2(side*96-48,-160)
   var shader:ShaderMaterial=sprite.material
   var box:=player_box()
   shader.set_shader_parameter("view_size",g.get_viewport_rect().size)
   shader.set_shader_parameter("player_mask",player_mask())
   shader.set_shader_parameter("player_rect",Vector4(box.position.x,box.position.y,box.size.x,box.size.y))
   shader.set_shader_parameter("player_in_front",foreground(g.player,world))
   held_mask(shader)
   var actor_rects:Array[Vector4]=[];var actor_uvs:Array[Vector4]=[]
   var bounds:=Rect2(sprite.position,Vector2(96,224))
   for enemy in g.enemies:
    if not foreground(enemy.pos,world):continue
    var kind:String="enemy_rocketeer" if enemy.type==7 else "enemy_gunner" if enemy.type in [5,6] else "enemy"+str(int(enemy.type)%3)
    var factor:=1.8 if enemy.get("boss",false) else 1.2 if enemy.type==4 else .72 if enemy.type==5 else .85 if enemy.type==3 else 1.0
    var ep:Vector2=g.screen(enemy.pos)+Vector2(0,sin(g.time*5+enemy.pos.x)*3)
    var eb:=Rect2(ep-Vector2(32,86)*factor,Vector2(64,96)*factor)
    if not bounds.intersects(eb):continue
    var id:int=g.sprites[kind];var atlas_size:Vector2=g.atlas.get_size()
    actor_rects.append(Vector4(eb.position.x,eb.position.y,eb.size.x,eb.size.y))
    actor_uvs.append(Vector4(float(id%16*32)/atlas_size.x,float(id/16*48)/atlas_size.y,32./atlas_size.x,48./atlas_size.y))
    if actor_rects.size()==16:break
   shader.set_shader_parameter("actor_count",actor_rects.size())
   while actor_rects.size()<16:actor_rects.append(Vector4.ZERO);actor_uvs.append(Vector4.ZERO)
   shader.set_shader_parameter("actor_rects",actor_rects);shader.set_shader_parameter("actor_uvs",actor_uvs)
   shader.set_shader_parameter("actor_atlas",g.atlas)
func _process(_delta:float)->void:
 for sprite in sprites.values():sprite.visible=false
 if g==null or g.grid.is_empty():return
 posts(g.objects,Vector2.ZERO,g.level)
 for next in [g.level-1,g.level+1]:
  if next<0 or next>6 or not g.room_cache.has(next):continue
  var state:Dictionary=g.room_cache[next]
  var north:bool=next>g.level
  var center:float=(15.5 if g.level==0 else 13.5)*48 if north else 13.5*48
  var other:float=13.5*48 if north else (15.5 if next==0 else 13.5)*48
  posts(state.objects,Vector2(center-other,-state.grid.size()*48 if north else g.grid.size()*48),next)
