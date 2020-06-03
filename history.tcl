#!/usr/bin/tclsh

namespace eval ::undoAndRedo {
	variable undo_list ""
	variable redo_list ""
	variable state -1
	variable logfile ""
	variable start_time [clock milli]
}

# This function clear data inutile
proc ::undoAndRedo::clear {} {
	variable undo_list
	variable redo_list
	variable state
	# When action is done, all action after the state should be deleted
	variable undo_list [lrange $undo_list 0 $state]
	variable redo_list [lrange $redo_list 0 $state]
}

# This function save the log
proc ::undoAndRedo::log {data} {
	variable logfile
	variable start_time
	# If logfile given, we save
	if [string length $logfile] {
		set f [open $logfile a+]
		puts $f [list [expr [clock milli] - $start_time] $data]
		close $f
	}
}

# This function save an action and his cancelor
proc ::undoAndRedo::do {action cancelor} {
	variable undo_list
	variable redo_list
	# We clear data inutile
	clear
	# We save the log
	log $action
	# We save data
	lappend redo_list $action
	lappend undo_list $cancelor
	variable state [expr $state+1]
	return $action
}

# This function back to previous state
proc ::undoAndRedo::undo {} {
	variable undo_list
	variable state
	# We return the cancelor
	set cmd [lindex $undo_list $state]
	# We log
	log $cmd
	# If cmd get, we back to previous state
	if [string length $cmd] {
		variable state [expr $state-1]
	}
	return $cmd
}

# This function return to next state
proc ::undoAndRedo::redo {} {
	variable redo_list
	variable state
	# We return the action
	set cmd [lindex $redo_list $state+1]
	# We log
	log $cmd
	# If cmd get, we return to next state
	if [string length $cmd] {
		variable state [expr $state+1]
	}
	return $cmd
}

# Test
proc ::undoAndRedo::test {} {
	set varnames "a b c d e f g"
	foreach varname $varnames {
		eval [do "set $varname 1" "unset $varname"]
	}
	# We verify the presence of each var
	foreach varname $varname {
		if ![info exists $varname] {
			error "$varname undefined, do error"
		}
	}
	# We back to previous state
	eval [undo]
	# We verify the absence of the last var
	set varname [lindex $varnames end]
	if [info exists $varname] {
		error "$varname defined, undo error"
	}
	# We back to next state
	eval [redo]
	# We verify the presence of d var
	if ![info exists $varname] {
		error "$varname undefined, redo error"
	}
	# We test an outlimit of undo
	time "catch {\[eval \[undo\]\]}" 10
	# We verify the absence of each var
	foreach varname $varnames {
		if [info exists $varname] {
			error "$varname defined, undo error"
		}
	}
	# We make a redo to verify the limit
	eval [redo]
	set varname [lindex $varnames 0]
	if ![info exists $varname] {
		error "$varname undefined, undo out limit"
	}
	# We test an outlimit of redo
	time "catch {\[eval \[redo\]\]}" 10
	# We verify the presence of each var
	foreach varname $varnames {
		if ![info exists $varname] {
			error "$varname undefined, redo error"
		}
	}
	# We make an undo to verify the limit
	eval [undo]
	set varname [lindex $varnames end]
	if [info exists $varname] {
		error "$varname defined, redo out limit"
	}
	puts "Test OK"
}

#::undoAndRedo::test