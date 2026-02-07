if [ -z $SQL_PATH ]; then
    export SQL_PATH=/home/bernd/Desktop/SQL
fi

path_error_string="File/Directory '$SQL_PATH' does not exist (set SQL_PATH correctly)"

function sql_search(){
    if [ ! -e $SQL_PATH ]; then
        echo "$path_error_string"
        return 1
    fi
    grep -Ri -- "--$1" "$SQL_PATH"

}

function sql() {
    if [ ! -e $SQL_PATH ]; then
        echo "$path_error_string"
        return 1
    fi
    SEARCH_RESULTS=$(searchSQL "$1")
    if [ -z "$SEARCH_RESULTS" ]; then
        echo "No SQL code found"
        return 2
    elif [[ $(echo "$SEARCH_RESULTS" | wc -l) > 2 ]]; then
        echo "More than one file found:"
        searchSQL "$1"
        return 3
    fi
    SQL_FILE=$(echo $SEARCH_RESULTS | cut -d: -f1)
    arg_upper=$(echo "$1" | tr [a-z] [A-Z])
    sed -n "/--$arg_upper/,/--\/\/\//p" $SQL_FILE | sed '1d;$d' | tee >(xclip -selection clipboard -i)
    return 0
}

