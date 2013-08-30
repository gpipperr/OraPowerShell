#========== Start sqlplus and set the Title in the window =====

$Host.UI.RawUI.WindowTitle = "OraPowerShell --  sqlplus $args"

# ==== Call SQL Plus
sqlplus $args[0] 