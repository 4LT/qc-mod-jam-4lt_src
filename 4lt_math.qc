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
