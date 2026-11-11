extends RefCounted
## Ground-plane drift and separate height: leaves rise briefly, flutter, then settle.
static func spawn(origin: Vector2, petal: bool) -> Dictionary:
    var angle := randf_range(-PI,PI)
    return {"pos":origin+Vector2(randf_range(-4,4),randf_range(-3,3)),"vel":Vector2.from_angle(angle)*randf_range(9 if petal else 14,24 if petal else 36),"life":randf_range(3.2,4.4),"color":Color("e1b8df") if petal else Color.WHITE,"heart":false,"foliage":true,"spin":randf_range(-PI,PI),"variant":randi_range(4,5) if petal else randi_range(0,3),"size":randf_range(.85,1.12),"leaf_height":randf_range(6,11) if petal else randf_range(14,23),"leaf_vz":randf_range(5,13),"gravity":randf_range(33,51),"terminal":randf_range(22,31),"drag":randf_range(2.5,4.5),"phase":randf_range(0,TAU),"flutter":randf_range(3.5,6.5),"wind":randf_range(3,7),"angular_velocity":randf_range(-2.5,2.5),"age":0.0,"landed":false}

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
