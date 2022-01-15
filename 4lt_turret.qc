// -- Forward declarations --

vector(float a, float b, float c) fourl_quadratic;
float(float x) fourl_sign;
vector(vector in) fourl_normalize_delta_angles;
float(float a, float b) fourl_max;

// -- Constants --

float FOURL_TURRET_WAKE_RADIUS = 800;
float FOURL_TURRET_TRACK_RADIUS = 1200;
float FOURL_TURRET_SEARCH_PERIOD = 0.3;
float FOURL_TURRET_ACTIVE_PERIOD = 0.1;
// Number of times to look for targetted player
float FOURL_TURRET_FORGET_CT = floor(3.0 / FOURL_TURRET_ACTIVE_PERIOD);

float FOURL_BARREL_LENGTH = 28;

// From LaunchLaser
float FOURL_LASER_SPEED = 600;

void(entity target_player) FourL_TurretSetTarget = {
    self.enemy = target_player;
    self.cnt = FOURL_TURRET_FORGET_CT;
};

float() FourL_TurretTargetHidden = {
    entity traced, target;

    // Look for a new target
    target = checkclient();
    traceline(self.origin, target.origin, FALSE, self);
    traced = trace_ent;

    if (traced.classname == "player") {
        FourL_TurretSetTarget(traced);
        return FALSE;
    }

    self.cnt-= 1;

    if (self.cnt <= 0) {
        self.enemy = world;
    }

    return TRUE;
};

vector(vector muzzle_pos) FourL_TurretLeadTarget = {
    vector vel = self.enemy.velocity;
    vector targ_pos, roots;
    float a, b, c, dt;

    if (vel == '0 0 0') {
        targ_pos = self.enemy.origin;
    } else {
        a = vel * vel - FOURL_LASER_SPEED * FOURL_LASER_SPEED;
        b = 2 * vel * (self.enemy.origin - muzzle_pos);
        c = self.enemy.origin * self.enemy.origin
            + muzzle_pos * muzzle_pos
            - 2 * self.enemy.origin * muzzle_pos; 

        roots = fourl_quadratic(a, b, c);
        dt = roots_y;
        targ_pos = self.enemy.origin + vel * dt;
    }

    return normalize(targ_pos - self.origin);
};

// Approximate where the muzzle position will need to be
// (assume target won't move)
//
// Reasonable approx. if target distance >> barrel length
vector(float barrel_len) FourL_MuzzlePos = {
    return normalize(self.enemy.origin - self.origin) * barrel_len
        + self.origin;
};

void(vector pos, vector dir) FourL_TurretFire = {
    LaunchLaser(pos, dir);
    sound(self, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM);
};

vector() FourL_TurretUpdateTarget = {
    vector displacement, direction;
    float distance;
    float in_range;
    float miss_enemy = FALSE;
    entity target, traced;

    if (self.enemy) {
        target = self.enemy;
    } else {
        target = checkclient();
    }

    displacement = target.origin - self.origin;
    distance = vlen(displacement);
    direction = displacement / distance;

    if (self.enemy) {
        in_range = distance < FOURL_TURRET_TRACK_RADIUS;
    } else {
        in_range = distance < FOURL_TURRET_WAKE_RADIUS;
    }

    traced = world;

    if (in_range) {
        traceline(self.origin, target.origin, FALSE, self);
        traced = trace_ent;
    } else {
        if (self.enemy) {
            FourL_TurretTargetHidden();
        }

        return '0 0 0';
    }

    if (self.enemy) {
        if (traced.classname == "player") {
            FourL_TurretSetTarget(traced);
        } else {
            miss_enemy = FourL_TurretTargetHidden();

            if (!miss_enemy) {
                direction = normalize(
                    self.enemy.origin
                    + self.enemy.view_ofs
                    - self.origin
                );
            }
        }
    } else {
        if (traced.classname == "player") {
            FourL_TurretSetTarget(traced);
        }
    }

    if (self.enemy && !miss_enemy) {
        return direction;
    } else {
        return '0 0 0';
    }
};

void() FourL_TurretThink = {
    // Find a target
    vector target_dir = FourL_TurretUpdateTarget();

    // Try to fire if target was found and visible
    if (target_dir != '0 0 0') {
        if (time > self.pausetime) {
            FourL_TurretFire(self.origin, FourL_TurretLeadTarget(self.origin));
            self.pausetime = time + self.wait;
        }
    }

    // Set up next think; save frames if there's no target
    if (self.enemy) {
        self.nextthink = time + FOURL_TURRET_ACTIVE_PERIOD;
    } else {
        self.nextthink = time + FOURL_TURRET_SEARCH_PERIOD;
    }
    self.think = FourL_TurretThink;
};

void() point_lead_turret = {
	precache_model("progs/s_light.spr");
    precache_sound("enforcer/enfire.wav");
    precache_sound("enforcer/enfstop.wav");
    precache_model("progs/laser.mdl");
	setmodel(self, "progs/s_light.spr");

    if (self.wait == 0) {
        self.wait = 0.3;
    }

    self.pausetime = 0;
    self.enemy = world;
    //self.movetype = MOVETYPE_FLY;

    self.think = FourL_TurretThink;
    self.nextthink = FOURL_TURRET_SEARCH_PERIOD;
};

void(vector my_angles) FourL_Turret2ApplyAngles = {
    self.angles = my_angles;
    self.angles_x = 0;
    self.angles_z = 0;
    self.goalentity.angles = my_angles;
};

void(vector angvel) FourL_Turret2ApplyAngVel = {
    self.avelocity = angvel;
    self.avelocity_x = 0;
    self.avelocity_z = 0;
    self.goalentity.avelocity = angvel;
};

vector(vector dest_angles) FourL_Turret2ComputeDeltaAngles = {
    return fourl_normalize_delta_angles(
        dest_angles - self.goalentity.angles);
};

float(vector apprx_muzzle_pos) FourL_Turret2Rotate;

void() FourL_Turret2Think = {
    vector muzzle_pos;
    float target_locked = FALSE;

    if (!self.enemy) {
        self.enemy = checkclient();
    }

    muzzle_pos = FourL_MuzzlePos(FOURL_BARREL_LENGTH);
    target_locked = FourL_Turret2Rotate(muzzle_pos);
    
    if (target_locked) {
        if (time > self.pausetime) {
            FourL_TurretFire(
                muzzle_pos,
                FourL_TurretLeadTarget(muzzle_pos)
            );
            self.pausetime = time + self.wait;
        }
    } 

    self.think = FourL_Turret2Think;
    self.nextthink = time + FOURL_TURRET_ACTIVE_PERIOD;
};

float(vector apprx_muzzle_pos) FourL_Turret2Rotate = {
    vector dest_angles, dest_angles2, dangles, dangles2, travel_time,
        apply_avel, apply_angles, target_dir;
    float max_dangle, max_dangle2, snap_pitch, snap_yaw;

    if (!self.enemy) {
        return FALSE;
    }

    target_dir = FourL_TurretLeadTarget(apprx_muzzle_pos);

    snap_pitch = FALSE;
    snap_yaw = FALSE;

    dest_angles = vectoangles(target_dir);
    dest_angles2_x = -(dest_angles_x - 270) + 270;
    dest_angles2_y = dest_angles_y < 180
        ? dest_angles_y + 180
        : dest_angles_y - 180;
    dest_angles2_z = 0;

    dangles = fourl_normalize_delta_angles(
            dest_angles - self.goalentity.angles);
    dangles2 = fourl_normalize_delta_angles(
            dest_angles2 - self.goalentity.angles);

    max_dangle = fourl_max(fabs(dangles_x), fabs(dangles_y));
    max_dangle2 = fourl_max(fabs(dangles2_x), fabs(dangles2_y));

    if (max_dangle2 < max_dangle) {
        dangles = dangles2;
        dest_angles = dest_angles2;
    }

    travel_time_x = fabs(dangles_x / self.speed);
    travel_time_y = fabs(dangles_y / self.speed);

    apply_avel_x = self.speed * fourl_sign(dangles_x);
    apply_avel_y = self.speed * fourl_sign(dangles_y);
    apply_avel_z = 0;

    if (travel_time_x < FOURL_TURRET_ACTIVE_PERIOD) {
        apply_angles_x = dest_angles_x;
        apply_angles_y = self.goalentity.angles_y;
        apply_angles_z = 0;
        apply_avel_x = 0;
        FourL_Turret2ApplyAngles(apply_angles);
        snap_pitch = TRUE;
    }

    if (travel_time_y < FOURL_TURRET_ACTIVE_PERIOD) {
        apply_angles_x = self.goalentity.angles_x;
        apply_angles_y = dest_angles_y;
        apply_angles_z = 0;
        apply_avel_y = 0;
        FourL_Turret2ApplyAngles(apply_angles);
        snap_yaw = TRUE;
    }

    FourL_Turret2ApplyAngVel(apply_avel);
    return snap_pitch && snap_yaw;
};

void() func_lead_turret = {
    entity barrel;

	precache_model("progs/demon.mdl");
    precache_model("progs/dog.mdl");
    setmodel(self, "progs/demon.mdl");
	setsize (self, '-32 -32 -32', '32 32 8');		
    self.avelocity = '0 0 0';
    self.solid = SOLID_BBOX;
    self.movetype = MOVETYPE_FLY;
   
    if (self.wait == 0) {
        self.wait = 0.3;
    }

    if (self.speed == 0) {
        self.speed = 100;
    }
    
    barrel = spawn();
    setmodel(barrel, "progs/dog.mdl");
    barrel.solid = SOLID_NOT;
    barrel.movetype = MOVETYPE_FLY;
    barrel.origin = self.origin;
    barrel.owner = self;
    self.goalentity = barrel;


    FourL_Turret2ApplyAngles(self.angles);

    self.think = FourL_Turret2Think;
    self.nextthink = 0.3;
};
