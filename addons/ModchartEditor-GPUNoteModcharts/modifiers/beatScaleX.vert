if (_value_ != 0.0) {
    float frac = curBeat - floor(curBeat);
    float fAmount = sin(frac * PI);
    scaleX += 0.2 * fAmount * _value_;
}