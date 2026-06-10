function create() {
    trace("FreeplayState bridge fallback: switching to PortFreeState");
    FlxG.switchState(new ModState("PortFreeState"));
}
