if (_value_ != 0.0) {
    float centerHitZWeight = strumLineID < 0.5
        ? (strumID + 1.0) / 4.0
        : (5.0 - strumID) / 5.0;
    z += _value_ * clamp(centerHitZWeight, 0.0, 1.0);
}
