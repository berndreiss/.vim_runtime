if [ -z $LINUX_PATH ]; then
    export LINUX_PATH=/home/bernd/Desktop/LINUX
fi
if [ -z $SQL_PATH ]; then
    export SQL_PATH=/home/bernd/Desktop/SQL
fi

path_error_string="File/Directory '$TARGET_PATH' does not exist (set path correctly)"

function general_search(){
    grep -Rin -- "$2$1" "$3"
}

function general_find() {
    SEARCH_TERM="$1"
    PREFIX="$2"
    unset TARGET_PATH

    if [ ! -z $3 ]; then
        TARGET_PATH="$3"
    elif [[ "$PREFIX" == "--" && ! -z "$SQL_PATH" ]]; then
        TARGET_PATH="$SQL_PATH"
    elif [[ "$PREFIX" == "#" && ! -z "$LINUX_PATH" ]]; then
        TARGET_PATH="$LINUX_PATH"
    fi
    if [ -z $TARGET_PATH ]; then
        echo "No path to search for provided."
        return 1
    fi
    if [ ! -e $TARGET_PATH ]; then
        echo "$path_error_string"
        return 2
    fi
    SEARCH_RESULTS=$(general_search "$SEARCH_TERM" "$PREFIX" "$TARGET_PATH")
    if [ -z "$SEARCH_RESULTS" ]; then
        echo "No code found"
        return 3
    elif [[ $(echo "$SEARCH_RESULTS" | wc -l) > 1 ]]; then
        echo "More than one file found:"
        general_search "$SEARCH_TERM" "$PREFIX" "$TARGET_PATH"
        return 4
    fi
    TARGET_FILE=$(echo $SEARCH_RESULTS | cut -d: -f1)
    arg_upper=$(echo "$SEARCH_TERM" | tr [a-z] [A-Z])
    sed -n "/$PREFIX$arg_upper/,/$PREFIX\/\/\//p" $TARGET_FILE | sed '1d;$d' | tee >(xclip -selection clipboard -i)
    return 0
}

function linux() {
    if [ -z $1 ]; then
        cd $LINUX_PATH
        return 0;
    fi
    general_find "$1" "#" "$2"
}
function sql() {
    if [ -z $1 ]; then
        cd $SQL_PATH
        return 0;
    fi
    general_find "$1" "--" "$2"
}

function vimsql() {
    if [ ! -e $SQL_PATH ]; then
        echo "$path_error_string"
        return 1
    fi
    SEARCH_RESULTS=$(general_search "$1" "--" "$SQL_PATH")
    if [ -z "$SEARCH_RESULTS" ]; then
        echo "No SQL code found"
        return 2
    elif [[ $(echo "$SEARCH_RESULTS" | wc -l) > 2 ]]; then
        echo "More than one file found:"
        general_search "$1" "--" "$SQL_PATH"
        return 3
    fi
    SQL_FILE=$(echo $SEARCH_RESULTS | cut -d: -f1)
    LINE_NUMBER=$(echo $SEARCH_RESULTS | cut -d: -f2)
    cd $(dirname $SQL_FILE)
    vim +$LINE_NUMBER $SQL_FILE
}
