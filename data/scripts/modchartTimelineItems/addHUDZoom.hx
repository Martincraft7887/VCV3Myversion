//

trace("Loaded Item Script: addHUDZoom");

function getItemTypeName() {
    return "addHUDZoom";
}
function getEventNameFromItem(item) {
    return "addHUDZoom";
}

function setupDefaultsEditor() {
    createTimelineItem("addHUDZoom", "addHUDZoom", null);
}

function setupDefaultsGame() {
    createModchartItem("addHUDZoom", "", getItemTypeName(), 0, null);
}
