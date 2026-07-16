if (_value_ != 0.0) {
    float centerHitYWeight = strumLineID < 0.5
        ? (strumID + 1.0) / 4.0
        : (5.0 - strumID) / 5.0;
    y += _value_ * clamp(centerHitYWeight, 0.0, 1.0);
}
