float FOURL_MIN_ANG = -180;
float FOURL_MAX_ANG = 180;

float(float x, float iterations) fourl_newton_sqrt {
    float approx, pty, ptx, slope;

    if (x < 0) {
        // error code
        return -1;
    }

    if (x < 0.5) {
        approx = 2 * x;
    } else if (x > 2) {
        approx = x/2;
    } else {
        approx = x;
    }
    
    while (iterations > 0) {
        pty = approx;
        ptx = pty * pty;
        slope = 1 / (2 * pty);

        approx = slope * (x - ptx) + pty;

        iterations-= 1;
    }

    return approx;
};

vector(float a, float b, float c) fourl_quadratic {
    float det, det_sqrt;
    vector ret_vec;

    det = b*b - 4 * a * c;
    if (det < 0) {
        return '0 0 1';
    }

    ret_vec = '0 0 0';
    det_sqrt = fourl_newton_sqrt(det, 80);
    ret_vec_x = (-b + det_sqrt) / 2 / a;
    ret_vec_y = (-b - det_sqrt) / 2 / a;

    return ret_vec;
};

float(float x) fourl_sign = {
    if (x < 0) {
        return -1;
    } else if (x > 0) {
        return 1;
    } else {
        return 0;
    }
};

float(float a, float b) fourl_max = {
    if (a > b) {
        return a;
    } else {
        return b;
    }
};

float(float a, float b) fourl_min = {
    if (a < b) {
        return a;
    } else {
        return b;
    }
};

float(float a, float b) fourl_mod = {
    return a - floor(a / b) * b;
};

float(float in, float min, float max) fourl_wrap = {
    return fourl_mod(in - min, max - min) + min;
};

vector(vector in) fourl_normalize_angles = {
    vector out;
    out_x = fourl_wrap(in_x, FOURL_MIN_ANG, FOURL_MAX_ANG);
    
    if (out_x < -90 || out_x > 90) {
        if (out_x < -90) {
            out_x = -180 - out_x;
        } else {
            out_x = 180 - out_x;
        }
        out_y+= 180;
        out_z+= 180;
    }

    out_y = fourl_wrap(in_y, FOURL_MIN_ANG, FOURL_MAX_ANG);
    out_z = fourl_wrap(in_z, FOURL_MIN_ANG, FOURL_MAX_ANG);

    return out;
};

vector(vector in) fourl_normalize_delta_angles = {
    vector out;
    out_x = fourl_wrap(in_x, FOURL_MIN_ANG, FOURL_MAX_ANG);
    out_y = fourl_wrap(in_y, FOURL_MIN_ANG, FOURL_MAX_ANG);
    out_z = fourl_wrap(in_z, FOURL_MIN_ANG, FOURL_MAX_ANG);
    return out;
};
