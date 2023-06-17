// -- Forward declarations --

vector(float a, float b, float c) quadratic;
float(float x) sign;
vector(vector in) normalize_delta_angles;
float(float a, float b) max;
float(float a, float b) min;

// -- Constants --

float TURRET_WAKE_RADIUS = 1500;
float TURRET_TRACK_RADIUS = 2000;
float TURRET_SEARCH_PERIOD = 0.1;
float TURRET_ACTIVE_PERIOD = 0.1;
float TURRET_TURN_SPEED = 100;
float TURRET_TURN_SPEED_NM = 150;
// Number of times to look for targetted player
float TURRET_FORGET_CT = floor(3.0 / TURRET_ACTIVE_PERIOD);

// Limit pitch angle of barrel
float BARREL_PITCH_LIM = 0;
float BARREL_LENGTH = 24;

// From LaunchLaser
float LASER_SPEED = 600;

float STATE_ASLEEP = 0;
float STATE_WAITING = 1;
float STATE_TARGETTING = 2;
float STATE_TARGET_HIDDEN = 3;

float FLAG_START_OFF = 1;

float LIGHT_ON = 0;
float LIGHT_OFF = 1;


// Max distance to project player to move
float MAX_PROJ_DIST = 350;

void(entity target_player) TurretSetTarget = {
    self.enemy = target_player;
    self.cnt = TURRET_FORGET_CT;
    self.state = STATE_TARGETTING;
    activator = self.enemy;
    SUB_UseTargets();
};

void() TurretTargetUpdateHidden = {
    entity traced, target;

    // Look for a new target
    target = checkclient();
    traceline(self.origin, target.origin, FALSE, self);
    traced = trace_ent;

    if (traced.classname == "player") {
        // sets state to TARGETTING
        TurretSetTarget(traced);
        return;
    }

    self.cnt-= 1;

    if (self.cnt <= 0) {
        self.enemy = world;
        self.state = STATE_WAITING;
    } else {
        self.state = STATE_TARGET_HIDDEN;
    }
};

void() TurretUse = {
    if (self.think == self.think1) {
        self.think = SUB_Null;
    } else {
        self.think = self.think1;
        self.think();
    }
};

vector(vector muzzle_pos) TurretLeadTarget = {
    entity plat = self.enemy.groundentity;
    vector targ_pos, roots, vel;
    float enemy_on_ground = self.enemy.flags & FL_ONGROUND;
    float a, b, c, dt, max_dt;

    if (plat && plat.movetype == MOVETYPE_PUSH && enemy_on_ground) {
        vel = self.enemy.velocity + plat.velocity;
    } else {
        vel = self.enemy.velocity;
    }

    if (!enemy_on_ground) {
        vel_z = 0;
    }

    if (vel == '0 0 0') {
        targ_pos = self.enemy.origin;
    } else {
        a = vel * vel - LASER_SPEED * LASER_SPEED;
        b = 2 * vel * (self.enemy.origin - muzzle_pos);
        c = self.enemy.origin * self.enemy.origin
            + muzzle_pos * muzzle_pos
            - 2 * self.enemy.origin * muzzle_pos; 

        roots = quadratic(a, b, c);
        max_dt = self.t_length / vlen(vel);

        if (roots_z == 0) {
            dt = min(max_dt, roots_y);
        } else {
            dt = max_dt;
        }

        targ_pos = self.enemy.origin + vel * dt;
    }

    return normalize(targ_pos - self.origin);
};

// Approximate where the muzzle position will need to be
// (assume target won't move)
//
// Reasonable approx. if target distance >> barrel length
vector(float barrel_len, vector target_dir) MuzzlePos = {
    return target_dir * barrel_len + self.origin;
};

void(vector pos, vector dir) TurretFire = {
    LaunchLaser(pos, dir);
    sound(self.goalentity, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM);
};

vector() TurretUpdateTarget = {
    vector displacement, direction;
    float distance;
    float in_range;
    entity target, traced;

    if (self.enemy) {
        target = self.enemy;
    } else {
        target = checkclient();
        if ((target.items & IT_INVISIBILITY) || (target.flags & FL_NOTARGET)) {
            return '0 0 0';
        }
    }

    displacement = target.origin - self.origin;
    distance = vlen(displacement);
    direction = displacement / distance;

    if (self.enemy) {
        in_range = distance < self.waitmax;
    } else {
        in_range = distance < self.waitmin;
    }

    traced = world;

    if (in_range) {
        traceline(self.origin, target.origin, FALSE, self);
        traced = trace_ent;
    } else {
        if (self.enemy) {
            TurretTargetUpdateHidden();
        }

        return direction;
    }

    if (self.enemy) {
        if (traced.classname == "player") {
            TurretSetTarget(traced);
        } else {
            TurretTargetUpdateHidden();
        }
    } else {
        if (traced.classname == "player") {
            TurretSetTarget(traced);
        }
    }

    if (self.enemy) {
        return direction;
    } else {
        return '0 0 0';
    }
};

void() TurretThink = {
    // Find a target
    vector target_dir = TurretUpdateTarget();

    // Try to fire if target was found and visible
    if (target_dir != '0 0 0') {
        if (time > self.pausetime && self.state == STATE_TARGETTING) {
            TurretFire(self.origin, TurretLeadTarget(self.origin));
            self.pausetime = time + self.wait;
        }
    }

    // Set up next think; save frames if there's no target
    if (self.enemy) {
        self.nextthink = time + TURRET_ACTIVE_PERIOD;
    } else {
        self.nextthink = time + TURRET_SEARCH_PERIOD;
    }
    self.think = self.think1;
};

void() TurretInit = {
    precache_sound("enforcer/enfire.wav");
    precache_sound("enforcer/enfstop.wav");
    precache_model("progs/laser.mdl");

    if (self.wait == 0) {
        self.wait = 0.3;
    }

    self.pausetime = 0;
    self.enemy = world;
    self.state = STATE_WAITING;

    if (self.waitmin <= 0) {
        self.waitmin = TURRET_WAKE_RADIUS;
    }

    if (self.waitmax <= 0) {
        self.waitmax = TURRET_TRACK_RADIUS;
    }

    if (self.waitmax < self.waitmin) {
        self.waitmax = self.waitmin;
    }

    if (self.t_length <= 0) {
        self.t_length = MAX_PROJ_DIST;
    }
};

void() trap_turret_point = {
    TurretInit();

    precache_model("progs/s_light.spr");
    setmodel(self, "progs/s_light.spr");
    self.use = TurretUse;

    self.nextthink = 0.3;
    self.think = self.think1 = TurretThink;

    if (self.spawnflags & FLAG_START_OFF) {
        self.think = SUB_Null;
    }
};

void(vector my_angles) Turret2ApplyAngles = {
    self.angles = my_angles;
    self.angles_x = 0;
    self.angles_z = 0;
    self.goalentity.angles = my_angles;
};

void(vector angvel) Turret2ApplyAngVel = {
    self.avelocity = angvel;
    self.avelocity_x = 0;
    self.avelocity_z = 0;
    self.goalentity.avelocity = angvel;
};

vector(vector dest_angles) Turret2ComputeDeltaAngles = {
    return normalize_delta_angles(
        dest_angles - self.goalentity.angles);
};

float(vector apprx_muzzle_pos) Turret2Rotate;

void() Turret2Think = {
    vector muzzle_pos, target_dir;
    float target_locked = FALSE;

    target_dir = TurretUpdateTarget();

    if (target_dir == '0 0 0') {
        self.avelocity = '0 0 0';
        self.goalentity.avelocity = '0 0 0';
    } else {
        muzzle_pos = MuzzlePos(BARREL_LENGTH, target_dir);
        target_locked = Turret2Rotate(muzzle_pos);
        
        if (target_locked) {
            if (
                time > self.pausetime
                && self.state == STATE_TARGETTING
            ) {
                TurretFire(
                    muzzle_pos,
                    TurretLeadTarget(muzzle_pos)
                );
                self.pausetime = time + self.wait;
            }
        } 
    }

    // Set up next think; save frames if there's no target
    if (self.enemy) {
        self.nextthink = time + TURRET_ACTIVE_PERIOD;
    } else {
        self.nextthink = time + TURRET_SEARCH_PERIOD;
    }
    self.think = Turret2Think;
};

float(vector apprx_muzzle_pos) Turret2Rotate = {
    vector dest_angles, dest_angles2, dangles, dangles2, travel_time,
        apply_avel, apply_angles, target_dir;
    float max_dangle, max_dangle2, snap_pitch, snap_yaw, pitch_in_bounds,
          pitch_lower, pitch_upper, turn_speed;

    if (!self.enemy) {
        return FALSE;
    }

    if (skill < 3) {
        turn_speed = TURRET_TURN_SPEED;
    } else {
        turn_speed = TURRET_TURN_SPEED_NM;
    }

    target_dir = TurretLeadTarget(apprx_muzzle_pos);

    snap_pitch = FALSE;
    snap_yaw = FALSE;

    dest_angles = vectoangles(target_dir);
    pitch_lower = BARREL_PITCH_LIM;
    pitch_upper = 180 - BARREL_PITCH_LIM;

    if (dest_angles_x > pitch_lower && dest_angles_x < pitch_upper) {
        pitch_in_bounds = FALSE;
        if (dest_angles_x > 90) {
            dest_angles_x = pitch_upper;
        } else {
            dest_angles_x = pitch_lower;
        }
    } else {
        pitch_in_bounds = TRUE;
    }

    dest_angles2_x = -(dest_angles_x - 270) + 270;
    dest_angles2_y = dest_angles_y < 180
        ? dest_angles_y + 180
        : dest_angles_y - 180;
    dest_angles2_z = 0;

    dangles = normalize_delta_angles(
            dest_angles - self.goalentity.angles);
    dangles2 = normalize_delta_angles(
            dest_angles2 - self.goalentity.angles);

    max_dangle = max(fabs(dangles_x), fabs(dangles_y));
    max_dangle2 = max(fabs(dangles2_x), fabs(dangles2_y));

    if (max_dangle2 < max_dangle) {
        dangles = dangles2;
        dest_angles = dest_angles2;
    }

    travel_time_x = fabs(dangles_x / turn_speed);
    travel_time_y = fabs(dangles_y / turn_speed);

    apply_avel_x = turn_speed * sign(dangles_x);
    apply_avel_y = turn_speed * sign(dangles_y);
    apply_avel_z = 0;

    if (travel_time_x < TURRET_ACTIVE_PERIOD/2) {
        apply_angles_x = dest_angles_x;
        apply_angles_y = self.goalentity.angles_y;
        apply_angles_z = 0;
        apply_avel_x = 0;
        Turret2ApplyAngles(apply_angles);
        snap_pitch = TRUE;
    }

    if (travel_time_y < TURRET_ACTIVE_PERIOD/2) {
        apply_angles_x = self.goalentity.angles_x;
        apply_angles_y = dest_angles_y;
        apply_angles_z = 0;
        apply_avel_y = 0;
        Turret2ApplyAngles(apply_angles);
        snap_yaw = TRUE;
    }

    Turret2ApplyAngVel(apply_avel);
    return snap_pitch && snap_yaw && pitch_in_bounds;
};


void() Turret2Use = {
    TurretUse();
    
    if (self.think == self.think1) {
        self.goalentity.skin = LIGHT_ON;
        sound(self, CHAN_VOICE, "4lt/beep_s.wav", 1, ATTN_NORM);
    } else {
        Turret2ApplyAngVel('0 0 0');
        self.goalentity.skin = LIGHT_OFF;
        sound(self, CHAN_VOICE, "4lt/beep_f.wav", 1, ATTN_NORM);
    }
};

void() trap_turret_solid = {
    entity barrel;

    TurretInit();

    precache_sound("4lt/beep_s.wav");
    precache_sound("4lt/beep_f.wav");
    precache_model("progs/4lt/base.mdl");
    precache_model("progs/4lt/barrel.mdl");
    setmodel(self, "progs/4lt/base.mdl");
    setsize (self, '-16 -16 -16', '16 16 8');       
    self.avelocity = '0 0 0';
    self.solid = SOLID_BBOX;
    self.movetype = MOVETYPE_NOCLIP;
    self.use = Turret2Use;

    barrel = spawn();
    setmodel(barrel, "progs/4lt/barrel.mdl");
    barrel.solid = SOLID_NOT;
    barrel.movetype = MOVETYPE_NOCLIP;
    barrel.origin = self.origin;
    barrel.owner = self;
    self.goalentity = barrel;

    Turret2ApplyAngles(self.angles);

    self.think = self.think1 = Turret2Think;
    self.nextthink = 0.3;

    if (self.spawnflags & FLAG_START_OFF) {
        self.think = SUB_Null;
        self.goalentity.skin = LIGHT_OFF;
    }
};
