if (_value_ != 0.0) {
    float centerHitXWeight = strumLineID < 0.5
        ? (strumID + 1.0) / 4.0
        : (5.0 - strumID) / 5.0;
    x += _value_ * clamp(centerHitXWeight, 0.0, 1.0);
}
