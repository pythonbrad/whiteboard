source eduboard.tcl

#button scale (all obj) selected and normal scale (select item while the click). A window will be show to select enter the height and width


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
	Board create board board 320 600 white
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