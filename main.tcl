package require Tk
source utils.tcl

# to start things rolling display a "splash screen"
# see "Effective Tcl/Tk Programming" book, page 254-247 for reference
wm withdraw .
toplevel .splash -borderwidth 4 -relief raised
wm overrideredirect .splash 1

centre_window .splash

label .splash.info -text "https://github.com/pythonbrad/eduboard" -font {Arial 9}
pack .splash.info -side bottom -fill x

label .splash.title -text "-- EduBoard --" -font {Arial 18 bold} -fg blue
pack .splash.title -fill x -padx 8 -pady 8

set splash_status "Loading ..."
label .splash.status -textvariable splash_status -font {Arial 9} -width 50 -fg darkred
pack .splash.status -fill x -pady 8

update


source eduboard.tcl

proc launch {} {
	if [catch {
		Board create board board [.config.e1 get] [.config.e2 get] [.config.e3 get]
		destroy .config
	} err] {
		tk_messageBox -title Error -message $err -icon error
	}
}

set test 1

if $test {
	Board create board board white 0
} else {
	pack [frame .config]
	pack [ttk::label .config.l1 -text Width:]
	pack [ttk::entry .config.e1 -textvariable width]
	pack [ttk::label .config.l2 -text Height:]
	pack [ttk::entry .config.e2 -textvariable height]
	pack [ttk::label .config.l3 -text "Background Color:"]
	pack [ttk::entry .config.e3 -textvariable bgcolor]
	pack [ttk::button .config.b -text Create -command launch]
}

destroy .splash
wm deiconify .