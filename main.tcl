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

source eduboard.tcl

proc launch {} {
	if [catch {
		Board create board board [.config.e1 get] [.config.e2 get]
		destroy .config
	} err] {
		tk_messageBox -title Error -message $err -icon error
	}
}

set test 1

if $test {
	set splash_status "Building gui ..."
	Board create board board white 0
	set splash_status "Scaling gui ..."
} else {
	centre_window .
	frame .config
	ttk::label .config.l -text "First Config" -font "{} 16"
	ttk::label .config.l1 -text "Background Color:"
	ttk::entry .config.e1
	ttk::label .config.l2 -text "Fullscreen Mode:"
	ttk::combobox .config.e2 -values "yes no"
	ttk::label .config.l3 -text "Using Mode:"
	ttk::combobox .config.e3 -values "normal client server"
	ttk::label .config.l4 -text "Host:"
	ttk::entry .config.e4
	.config.e4 insert end http://
	ttk::button .config.b -text Save -command launch
	pack .config .config.l .config.l1 .config.e1 .config.l2 .config.e2 .config.l3 .config.l4 .config.e4 .config.b
}

# We wait the scaling
vwait ::auto_ajust::stable
destroy .splash
wm deiconify .