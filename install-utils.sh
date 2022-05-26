# Common functions used by SAT product install scripts

# Print a message with extra emphasis to indicate a stage.
function print_stage(){
    msg="$1"
    echo "====> ${msg}"
}

# Exit with an error message and an exit code of 1.
function exit_with_error() {
    msg="$1"
    >&2 echo "${msg}"
    exit 1
}
