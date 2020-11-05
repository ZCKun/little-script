#!/usr/bin/env expect
set timeout 600
# today date
set DATE [exec date +%Y%m%d]
# set DATE "20200805"
set DIRS [split [exec pwd] "/"]
set END_KEY [lindex $DIRS [expr [llength $DIRS] - 1]]
#set DATE "20200416"
array set SERVERS { 
    0 "sftp|sftp -P <port|optional> <username>@<ip address>|<password>"
    1 "ssh|ssh <username>@<ip address>|<password>"
    2 "sftp|sftp -P <port|optional> <username>@<ip address>|<password>"
}

set guest_wait "<username>@<some text>"
set operation_passwd "<15 line password>"

set COMMANDS("<server 1>") ""

set COMMANDS("<server 2>") ""

set COMMANDS("<server 3>") "get /path/<some filename>|wait sftp>|bye|wait <some text>|spawn!bash <some shell script>|wait password|<enter passwrod>|wait DONE|spawn!bash upload.sh|eof"

foreach item [array names SERVERS] {
    # 从 SERVERS 取与 item 对应的 value
    set server $SERVERS($item)
    # 以 "|" 切割字符串 server 返回给 contents
    set contents [split $server "|"]
    # 按顺序将 contents 分配到 type cmd pwd
    lassign $contents type cmd pwd
    # 判断 cmd 的长度是不是等于 4
    if {[llength $cmd] == 4} {
        lassign $cmd command option port host
    } else {
        lassign $cmd command host
    }
    puts $host
    # 以 "@" 分割 host
    set _hosts [split $host "@"]
    # 然后获取 username hostname
    lassign $_hosts username hostname

    eval spawn "$cmd"
    if {[regexp -nocase "sftp" $type]} {
        expect "password:"
        send "$pwd\r"
        expect "sftp>"
        foreach _cmd [split $COMMANDS("$host") "|"] {
            # 执行 wait 有关命令
            if {[regexp -nocase "wait*" $_cmd]} {
                lassign [split $_cmd " "] _ text
                expect "$text"
            # 执行交互有关命令
            } elseif {[regexp -nocase "spawn!*" $_cmd]} {
                lassign [split $_cmd "!"] _ text
                eval spawn "$text"
            } elseif {[regexp -nocase "local!*" $_cmd]} {
                lassign [split $_cmd "!"] _ text 
                puts "命令: $text"
                exec "$text" } elseif {[regexp -nocase "eof" $_cmd]} {
                expect "$_cmd"
            } else {
                send "$_cmd\r"
            }
        }
    } elseif {[regexp -nocase "ssh" $type]} {
        expect "$host's password:"
        send "$pwd\r"
        foreach _cmd [split $COMMANDS("$host") "|"] {
            if {[regexp -nocase "wait*" $_cmd]} {
                lassign [split $_cmd " "] _ text
                expect "$text"
            # 执行交互有关命令
            } elseif {[regexp -nocase "spawn!*" $_cmd]} {
                lassign [split $_cmd "!"] _ text
                eval spawn "$text"
            } elseif {[regexp -nocase "local!*" $_cmd]} {
                puts "命令: $_cmd"
                lassign [split $_cmd "!"] _ text 
                puts "本地命令: $text"
                exec "$text"
            } elseif {[regexp -nocase "eof" $_cmd]} {
                expect "$_cmd"
            } else {
                send "$_cmd\r"
            }
        }
    }
    after 3000
}
exit 0

