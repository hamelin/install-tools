__path_no_timc__="$PATH"


function deactivate() {
    PATH="$__path_no_timc__"
    export PATH
}


PATH="<DIRINSTALL>:$PATH"
export PATH
