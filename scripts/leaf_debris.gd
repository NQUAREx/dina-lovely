extends RefCounted
## Ground-plane drift and separate height: leaves rise briefly, flutter, then settle.
static func spawn(origin: Vector2, petal: bool) -> Dictionary:
    var angle := randf_range(-PI,PI)
    var speed := randf_range(52,88) if petal else randf_range(82,155)
    return {"pos":origin+Vector2(randf_range(-4,4),randf_range(-3,3)),"vel":Vector2.from_angle(angle)*speed,"life":randf_range(2.8,3.8),"color":Color("e1b8df") if petal else Color.WHITE,"heart":false,"foliage":true,"spin":randf_range(-PI,PI),"variant":randi_range(4,5) if petal else randi_range(0,3),"size":randf_range(1.25,1.7) if petal else randf_range(1.6,2.35),"leaf_height":randf_range(9,16) if petal else randf_range(20,34),"leaf_vz":randf_range(14,27) if petal else randf_range(20,36),"gravity":randf_range(52,78),"terminal":randf_range(30,44),"drag":randf_range(1.65,2.65),"phase":randf_range(0,TAU),"flutter":randf_range(3,7),"wind":randf_range(6,15),"angular_velocity":randf_range(-3.5,3.5),"age":0.0,"landed":false}

static func step(part: Dictionary, delta: float) -> void:
    var steps := clampi(ceili(delta*90),1,12)
    var dt := delta/steps
    for _step in range(steps):
        part.age+=dt
        if part.landed:
            part.vel*=exp(-dt*11)
            part.pos+=part.vel*dt
            part.angular_velocity*=exp(-dt*8)
        else:
            var air: Vector2 = Vector2(sin(part.age*part.flutter+part.phase),sin(part.age*part.flutter*.63+part.phase+1))*part.wind
            var old_velocity: Vector2 = part.vel
            part.vel=air/part.drag+(old_velocity-air/part.drag)*exp(-part.drag*dt)
            part.pos+=(old_velocity+Vector2(part.vel))*(dt*.5)
            var old_vertical: float = part.leaf_vz
            part.leaf_vz=maxf(-part.terminal,old_vertical-part.gravity*dt)
            part.leaf_height+=(old_vertical+float(part.leaf_vz))*(dt*.5)
            part.angular_velocity=(part.angular_velocity+sin(part.age*part.flutter+part.phase)*dt*.4)*exp(-dt*.5)
            if part.leaf_height<=0 and part.leaf_vz<0:
                part.leaf_height=0.0
                part.leaf_vz=0.0
                part.landed=true
                part.vel*=.12
                part.angular_velocity*=.15
        part.spin+=part.angular_velocity*dt
