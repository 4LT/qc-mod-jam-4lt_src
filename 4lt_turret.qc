// -- Forward declarations --

vector(float a, float b, float c) fourl_quadratic;

// -- Constants --

float FOURL_TURRET_WAKE_RADIUS = 800;
float FOURL_TURRET_TRACK_RADIUS = 1200;
float FOURL_TURRET_SEARCH_DELAY = 0.3;
float FOURL_TURRET_ACTIVE_DELAY = 0.1;
// Number of times to look for targetted player
float FOURL_TURRET_FORGET_CT = floor(3.0 / FOURL_TURRET_ACTIVE_DELAY);

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

vector() FourL_TurretLeadTarget = {
    vector vel = self.enemy.velocity;
    vector targ_pos, roots;
    float a, b, c, dt;

    if (vel == '0 0 0') {
        targ_pos = self.enemy.origin;
    } else {
        a = vel * vel - FOURL_LASER_SPEED * FOURL_LASER_SPEED;
        b = 2 * vel * (self.enemy.origin - self.origin);
        c = self.enemy.origin * self.enemy.origin
            + self.origin * self.origin
            - 2 * self.enemy.origin * self.origin; 

        roots = fourl_quadratic(a, b, c);
        dt = roots_y;
        targ_pos = self.enemy.origin + vel * dt;
    }

    return normalize(targ_pos - self.origin);
};

void() FourL_TurretFire = {
    sound(self, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM);
    LaunchLaser(self.origin, FourL_TurretLeadTarget());
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
            FourL_TurretFire();
            self.pausetime = time + self.wait;
        }
    }

    // Set up next think; save frames if there's no target
    if (self.enemy) {
        self.nextthink = time + FOURL_TURRET_ACTIVE_DELAY;
    } else {
        self.nextthink = time + FOURL_TURRET_SEARCH_DELAY;
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
    self.nextthink = FOURL_TURRET_SEARCH_DELAY;
};
