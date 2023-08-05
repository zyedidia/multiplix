module config;

bool ismonitor() {
    version (monitor) {
        return true;
    } else {
        return false;
    }
}
