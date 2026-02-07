export SQL_PATH=/home/bernd/Desktop/SQL
function searchSQL(){
    grep -Ri -- "--$1" "$SQL_PATH"
}

function getSQL() {
    SEARCH_RESULTS=$(searchSQL "$1")
    if [ -z "$SEARCH_RESULTS" ]; then
        echo "No SQL code found"
        return 1
    elif [[ $(echo "$SEARCH_RESULTS" | wc -l) > 2 ]]; then
        echo "More than one file found:"
        searchSQL "$1"
        return 2
    fi
    SQL_FILE=$(echo $SEARCH_RESULTS | cut -d: -f1)
    arg_upper=$(echo "$1" | tr [a-z] [A-Z])
    sed -n "/--$arg_upper/,/--\/\/\//p" $SQL_FILE | sed '1d;$d' | tee >(xclip -selection clipboard -i)
    return 0
}

