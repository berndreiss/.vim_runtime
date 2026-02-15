COLOR_MODE=never
if [ -z $LINUX_PATH ]; then
    export LINUX_PATH=~/LINUX
fi
if [ -z $SQL_PATH ]; then
    export SQL_PATH=~/SQL
fi

path_error_string="File/Directory '$target_path' does not exist (set path correctly)"

function general_search_pretty(){
    COLOR_MODE=always
    general_search "$@"
    COLOR_MODE=never
}

function general_search(){
    #IF MULTIPLE ARGUMENTS HAVE BEEN PASSED WE WANT TO USE REGEX
    if [[ "$MULTI_MODE" == TRUE ]]; then
        grep -rPin --color="$COLOR_MODE" -- "^$2.*\K$1" "$3" | grep -v -- "$2\/\/\/$"
    else
        grep -rPin --color="$COLOR_MODE" -- "^$2.*\K\Q$1\E" "$3" | grep -v -- "$2\/\/\/$"
    fi
}

function general_find() {

    #SET UP VARIABLES
    delim_line="##############################################################\n"
    search_term="$1"
    prefix="$2"
    unset target_path

    #GET THE TARGET PATH: IF NOT PROVIDED AS THIRD ARGUMENT -> DEDUCE FROM PREFIX
    if [ ! -z "$3" ]; then
        target_path="$3"
    elif [[ "$prefix" == "--" && ! -z "$SQL_PATH" ]]; then
        target_path="$SQL_PATH"
    elif [[ "$prefix" == "#" && ! -z "$LINUX_PATH" ]]; then
        target_path="$LINUX_PATH"
    fi

    #ABORT IF TARGET PATH WAS NOT PROVIDED
    if [ -z $target_path ]; then
        echo "No path to search for provided."
        return 1
    fi

    #ABORT IF TARGET PATH DOES NOT EXIST
    if [ ! -e $target_path ]; then
        echo "$path_error_string"
        return 2
    fi

    search_results=$(general_search "$search_term" "$prefix" "$target_path")

    #HANDLE RESULTS:
    #  - CASE 1 (NO RESULTS) -> RETURN
    #  - CASE 2 (MORE THAN 1 RESULT) -> ASK USER WHICH RESULT TO HANDLE
    #  - CASE 3 (ONE RESULT) -> DO NOTHING (JUST UNSET THE DELIM_LINE)
    if [ -z "$search_results" ]; then
        echo "No code found"
        return 3
    elif [[ $(echo "$search_results" | wc -l) > 1 ]]; then
        echo "More than one entry found:"

        #PRINT PRETTY
        general_search_pretty "$search_term" "$prefix" "$target_path" | nl
        read -p "Which entry to use? " input
        echo ""

        #ABORT ON EMPTY INPUT, GET LINE ON NUMBER, DO ENTIRELY NEW SEARCH ELSE
        if [ -z "$input" ]; then
            return 0;
        elif [[ "$input" =~ ^[0-9]+$ ]]; then
            #RETRIEVE SINGLE RESULT FROM RESULTS
            search_results=$(echo "$search_results" | nl | grep -E "^[[:space:]]+$input[[:space:]]" | sed -E "s/^[[:space:]]+$input[[:space:]]+//")
        else
            if [[ "$(echo $input | awk '{$1=$1};1' | grep -c [[:space:]])" > 0 ]]; then
                MULTI_MODE=TRUE
            fi
            general_find $(echo "$input" | sed -E 's/[[:space:]]+/.*/g') "$prefix"
            unset MULTI_MODE
            return 0;
        fi
    else
        delim_line=""
    fi

    #GET FIELDS FROM RESULTS
    target_file=$(echo "$search_results" | cut -d: -f1)
    match_term=$(echo "$search_results" | cut -d: -f3)
    line_number=$(echo "$search_results" | cut -d: -f2)

    #OPEN VIM IF FUNCTION WAS CALLED WITH VIM_MODE=TRUE, COPY TO CLIPBOARD OTHERWISE
    if [[ "$VIM_MODE" == "TRUE" ]]; then
        vim +"$line_number" "$target_file"
    else
        echo -ne "$delim_line"

        #GREP THE PATTERN FROM THE FILE
        #start by only considering content from line number where pattern was found
        sed -n  "$line_number,\$p" $target_file | \
            #do some perl magic: seds pattern matching is too aggressive and searches
            #until the last match of prefix///
            #  -> -0777: slurp whole input, so matches can span lines
            #  -> .*?: non-greedy, stops at first match
            #  -> \Q...\E: escape any regex special characters
            #  s flas: make . match new lines
            perl -0777 -ne "print \$1 if /\\Q\$match_term\\E(.*?)\\Q\$prefix\\E\/\/\//s"  | \
            #remove commented lines
            grep -v -- "^$prefix" | \
            #print and copy to clipboard
            tee >(perl -pe 'chomp if eof' | xclip -selection clipboard -i)
        echo -ne "$delim_line"
    fi
    return 0
}

function linux() {
    if [ -z "$1" ]; then
        cd $LINUX_PATH
        return 0;
    fi
    query="$1"
    get_term "$@"
    general_find "$query" "#"
    unset MULTI_MODE
}
function linuxe(){
    linux "$@"
    exit
}
function sql() {
    if [ -z "$1" ]; then
        cd $SQL_PATH
        return 0;
    fi
    query="$1"
    get_term "$@"
    general_find "$query" "--"
    unset MULTI_MODE
}
function sqle() {
    sql "$@"
    exit
}

function vimlinux() {
    VIM_MODE=TRUE
    linux "$@"
    unset VIM_MODE
}

function vimsql() {
    VIM_MODE=TRUE
    sql "$@"
    unset VIM_MODE
}

get_term(){
    if [ $# -gt 1 ]; then
        MULTI_MODE=TRUE
        i=0
        while [ $i -lt $# ]; do
            shift
            query="$query.*$1"
            i=$((i+1))
        done
    fi
}
