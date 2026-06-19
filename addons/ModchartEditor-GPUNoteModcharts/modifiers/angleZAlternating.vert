if (_value_ != 0.0) {
    if (mod(strumID, 2.0) < 1.0) {
        angleZ -= _value_;
    } else {
        angleZ += _value_;
    }
}
