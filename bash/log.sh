log() {
    level=$1
    message=$2
    echo -e "${level^^}: $message"
}
log info "success compress"