# Farbiger Log-Tail
flog() {
    tail -f "$1" | awk '
        /ERROR|Error|error|FATAL/ {print "\033[31m" $0 "\033[0m"; next}
        /WARN|Warn|warning/     {print "\033[33m" $0 "\033[0m"; next}
        /INFO|Info|SUCCESS/     {print "\033[32m" $0 "\033[0m"; next}
        {print}
    '
}
