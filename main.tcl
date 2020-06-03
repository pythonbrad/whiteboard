# network and recoder should be extern function (script extern and call)
# client will be call in the main, server and recoder in the eduboard via history (used only do with undo empty)
# the recoder start create the file in the name (recoder_[clock click]) mode a+
# the recoder stop, stop the recoder

package require Tk
source utils.tcl

# to start things rolling display a "splash screen"
# see "Effective Tcl/Tk Programming" book, page 254-247 for reference
wm withdraw .
toplevel .splash -borderwidth 4 -relief raised
centre_window .splash
wm overrideredirect .splash 1

label .splash.info -text "https://github.com/pythonbrad/eduboard" -font {Arial 9}
pack .splash.info -side bottom -fill x

label .splash.title -text "-- EduBoard --" -font {Arial 18 bold} -fg blue
pack .splash.title -fill x -padx 8 -pady 8

set splash_status "Loading library ..."
label .splash.status -textvariable splash_status -font {Arial 9} -width 50 -fg darkred
pack .splash.status -fill x -pady 8

update

# We load data
source eduboard.tcl

# We build board
set splash_status "Building board ..."
Board create board board white 0
set splash_status "Scaling board ..."

# We wait the scaling
vwait ::auto_ajust::stable
destroy .splash
wm deiconify .