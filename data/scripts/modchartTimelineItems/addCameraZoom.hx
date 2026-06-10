//

trace("Loaded Item Script: addCameraZoom");

function getItemTypeName() {
    return "addCameraZoom";
}
function getEventNameFromItem(item) {
    return "addCameraZoom";
}

function setupDefaultsEditor() {
    createTimelineItem("addCameraZoom", "addCameraZoom", null);
}

function setupDefaultsGame() {
    createModchartItem("addCameraZoom", "", getItemTypeName(), 0, null);
}
