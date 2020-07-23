#!/usr/bin/wish
#====================================================================#
#     EduBoard written in Tcl/Tk for editing open source project     #
#		            (c) Fomegne Meudje; 25-05-20                     #
#====================================================================#
#    Author: pythonbrad (Fomegne Meudje)
#    Email: fomegnemeudje@outlook.com
#    Github: http://github.com/pythonbrad
# * 
# * Copyright 2020 pythonbrad <fomegnemeudje@outlook.com>
# * 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.


package require Tk 8.6
source resize.tcl
source auto_ajust.tcl
source history.tcl

oo::class create Board {
	constructor {classname bgcolor fullscreen} {
		# We init variable
		variable self $classname
		variable image_loaded ""
		variable current_color #123456
		variable current_size 1
		variable current_mode ""
		variable can_draw 0
		variable current_item ""
		variable selected_items ""
		variable old_cursor_coord ""
		variable current_scale_factor 0
		variable is_playing 0
		
		wm title . EduBoard
		
		# We config the gui
		if $fullscreen {wm attributes . -fullscreen 1}
		
		# We config the history
		set ::undoAndRedo::logfile ""
		
		# We config the menu
		menu .menu -tearoff 0
		
		# We create the color tools
		menu .menu.color -tearoff 0
		# We add data
		foreach "color code" "black #000000 white #FFFFFF grey #4D4D4D green #008000 yellow #FFFF00 blue #1E90FF brown #A52A2A eraser $bgcolor more {}" {
			.menu.color add command -label $color -command "eval \[::undoAndRedo::do {$self change_color {$code}} {}\]" -background $code -foreground $code
		}
		# We add the color tools
		.menu add cascade -menu .menu.color -compound top -label Color -image [my load_image icons/paint.png menu]
		
		# We create the size tools
		menu .menu.size -tearoff 0
		# We add data
		foreach size "1 2 4 6 8 10" {
			.menu.size add command -label $size -command "eval \[::undoAndRedo::do {$self change_size {$size}} {}\]"
		}
		# We add the size tools
		.menu add cascade -menu .menu.size -compound top -label Size -image [my load_image icons/size.png menu]
		
		# We add the image tools
		.menu add command -compound top -label Image -image [my load_image icons/image.png menu] -command "$self add_image {}"
		
		# We create the select tools
		menu .menu.select -tearoff 0
		# We add command
		.menu.select add command -label Drag -command "eval \[::undoAndRedo::do {$self select_items} {}\]"
		.menu.select add command -label All -command "eval \[::undoAndRedo::do {$self select_all_items} {}\]"
		# We add the select menu
		.menu add cascade -menu .menu.select -compound top -label Select -image [my load_image icons/select.png menu]
		
		# We add the move tools
		.menu add command -compound top -label Move -image [my load_image icons/move.png menu] -command "eval \[::undoAndRedo::do {$self move_items_selected} {}\]"
		# We add the delete tools
		.menu add command -compound top -label Delete -image [my load_image icons/cancel.png menu] -command "eval \[::undoAndRedo::do {$self delete_items_selected} {}\]"
		# We add the duplicate tools
		.menu add command -compound top -label Duplicate -image [my load_image icons/duplicate.png menu] -command "eval \[::undoAndRedo::do {$self duplicate_items_selected} {}\]"
		
		# We create the scale tools
		menu .menu.scale -tearoff 0
		# We add command
		menu .menu.scale.factor -tearoff 0
		.menu.scale.factor add radiobutton -label 1 -command "eval \[::undoAndRedo::do {$self change_current_scale_factor 1} {}\]"
		.menu.scale.factor add radiobutton -label -1 -command "eval \[::undoAndRedo::do {$self change_current_scale_factor -1} {}\]"
		.menu.scale add cascade -label Factor -menu .menu.scale.factor
		.menu.scale add command -label Scale -command "eval \[::undoAndRedo::do {$self scale_items_selected} {}\]"
		# We add the scale tools
		.menu add cascade -compound top -label Scale -image [my load_image icons/scale.png menu] -menu .menu.scale

		# We create the draw tools
		menu .menu.draw -tearoff 0
		.menu.draw add command -label Line
		.menu.draw add command -label Arc
		.menu.draw add command -label Oval
		.menu.draw add command -label Polygon
		.menu.draw add command -label Rectangle
		# We add the draw tools
		.menu add cascade -label Draw -menu .menu.draw -image [my load_image icons/move.png menu] -compound top
		
		# We create the network tools
		menu .menu.network -tearoff 0
		.menu.network add command -label Client -command server_connect
		.menu.network add command -label Server -command server_bind
		# We add the network tools
		.menu add cascade -label Network -menu .menu.network -image [my load_image icons/network.png menu] -compound top
		
		# We create the recoder tools
		menu .menu.recoder -tearoff 0
		.menu.recoder add command -label Start -command "$self recoder_start" -image [my load_image icons/dialog-yes.png submenu] -compound left
		.menu.recoder add command -label Stop -command "$self recoder_stop" -image [my load_image icons/dialog-no.png submenu] -compound left
		# We add the recoder tools
		.menu add cascade -label Recoder -menu .menu.recoder -image [my load_image icons/server.png menu] -compound top
		
		# We create the playing tools
		menu .menu.player -tearoff 0
		.menu.player add command -label Start -command "$self play_recording" -image [my load_image icons/media-play.png submenu] -compound left
		.menu.player add command -label Pause -command "$self pause_recording" -image [my load_image icons/media-pause.png submenu] -compound left
		.menu.player add command -label Stop -command "$self stop_recording" -image [my load_image icons/media-stop.png submenu] -compound left
		# We add the recoder tools
		.menu add cascade -label Player -menu .menu.player -image [my load_image icons/media-play.png menu] -compound top
		
		# We add the menu
		. configure -menu .menu
		
		# We create the board
		variable canvas [canvas .canvas -background $bgcolor]
		
		# We set binding
		bind $canvas <Button-1> "if {\[$self can_edit\]} {eval \[::undoAndRedo::do {$self mouse_click %x %y} {}\]}"
		bind $canvas <ButtonRelease> "if {\[$self can_edit\]} {eval \[::undoAndRedo::do {$self mouse_click_release} {}\]}"
		bind $canvas <Motion> "if {\[$self can_edit\]} {eval \[::undoAndRedo::do {$self mouse_move %x %y} {}\]}"
		
		# We build the board
		pack $canvas
		
		# We update the gui before others operations
		update
		
		# We config and launch the auto ajust, the canvas get all the height and width
		set ::auto_ajust::canvas "$canvas 1 1"
		# We config all gui image
		foreach "tag image" $image_loaded {
			# We verify if image of gui
			if {[string equal $tag menu]} {
				::imgResize::resize $image 16 16
			} elseif {[string equal $tag submenu]} {
				::imgResize::resize $image 16 16
			} else {}
		}
		# We launch
		::auto_ajust::run
	}
	# This method permit to change the color of drawing
	# Argument: if color not given, we ask to user to choose a color
	#
	method change_color color {
		variable current_color
		# We verify if color passed in argument, if not and ask color
		if ![string length $color] {
			set color [tk_chooseColor -initialcolor $current_color]
		}
		# If color got, I change
		if [string length $color] {
			variable current_color $color
		}
	}
	# This method permit to change the size of drawing line
	# Argument: size in integer
	#
	method change_size size {
		# If size passed in argument, I change
		if [string length $size] {
			variable current_size $size
		}
	}
	# This method permit to do begin an action in function of the mode choosed
	# It call while the event mouse clicking
	# Argument: x and y represent coord in the canvas
	#
	method mouse_click {x y} {
		variable current_mode
		variable canvas
		variable current_size
		variable current_color
		variable can_draw
		variable selector_init
		variable old_cursor_coord
		# We analyse the current mode
		switch -- $current_mode {
			selecting {
				# We reset the selector
				$canvas create rectangle 0 0 0 0 -tag selector
				$canvas coords selector $x $y $x $y
				$canvas itemconfig selector -outline $current_color
				variable can_draw 1
			}
			moving {
				variable old_cursor_coord "$x $y"
				variable can_draw 1
			}
			default {
				# If mode not found, we draw
				variable current_item [$canvas create line $x $y $x $y -width $current_size -fill $current_color -width $current_size]
				variable can_draw 1
			}
		}
	}
	# This method permet to end a action in function of the mode choosed
	# It call while the event mouse releasing
	#
	method mouse_click_release {} {
		variable current_mode
		variable selected_items
		variable canvas
		variable current_item
		# We analyse the current mode
		switch -- $current_mode {
			selecting {
				set coords [$canvas coords selector]
				variable selected_items [eval $canvas find overlapping $coords]
			}
			moving {
				# We clean the selector
				$canvas delete selector
			}
			deleting {
				# We clean the selector
				$canvas delete selector
			}
			default {
				# We select the drawing
				variable selected_items $current_item
				# We clean any data
				variable current_item ""
				variable can_draw 0
			}
		}
		variable current_mode ""
	}
	# This method permit to do a action in loop while calling
	# It call while the event mouse moving
	# Argument: x and y represent coord in the canvas
	method mouse_move {x y} {
		variable current_mode
		variable current_item
		variable canvas
		variable can_draw
		variable old_cursor_coord
		variable selected_items
		# We verify the current mode
		if $can_draw {
			switch -- $current_mode {
				selecting {
					# We update coords
					set coords [$canvas coords selector]
					eval $canvas coords selector [lrange $coords 0 1] $x $y
				}
				moving {
					# We analyse the moving
					set old_x [lindex $old_cursor_coord 0]
					set old_y [lindex $old_cursor_coord 1]
					set move_x [expr $x - $old_x]
					set move_y [expr $y - $old_y]
					# We move item
					foreach item $selected_items {
						$canvas move $item $move_x $move_y
					}
					# We update old coord
					variable old_cursor_coord "$x $y"
				}
				default {
					# We update coords
					set coords [$canvas coords $current_item]
					eval $canvas coords $current_item $coords $x $y
				}
			}
		}
	}
	# This method active the selecting mode to can selected items
	#
	method select_items {} {
		# We change the mode
		variable current_mode selecting
	}
	# This method select all items in the canavs
	#
	method select_all_items {} {
		variable canvas
		# We get all items
		variable selected_items [$canvas find all]
	}
	# This method delete all items selected
	#
	method delete_items_selected {} {
		# We change the mode
		variable current_mode deleting
		variable selected_items
		variable canvas
		# We delete all items selected
		foreach item $selected_items {
			$canvas delete $item
		}
		variable selected_items ""
	}
	# This method active the moving mode to move items selected
	#
	method move_items_selected {} {
		# We change the mode
		variable current_mode moving
	}
	# This method permit to add image in the canvas
	# Argument: filename represent the destination of this image
	method add_image filename {
		variable canvas
		variable selected_items
		variable self
		# We verify if filename passed in argument
		if ![string length $filename] {
			# We ask filename
			set filename [tk_getOpenFile]
		}
		# We verify if filename got
		if [string length $filename] {
			set img [my load_image $filename canvas]
			# We log the action
			set f [open $filename rb]
			set data [read $f]
			close $f
			::undoAndRedo::do "set filename download/\[clock clicks\];file mkdir download;set f \[open \$filename wb\];puts \$f \[binary decode base64 {[binary encode base64 $data]}\];close \$f;$self add_image \$filename" ""
			# We create and mark it selected
			 variable selected_items [$canvas create image [expr [lindex [$canvas config -width] end]/2] [expr [lindex [$canvas config -height] end]/2] -image $img]
		}
	}
	# This method permit to manage the loading images
	# Argument: filename represent the destination of this image
	#			tag represent an id of this image
	# Return the image created
	#
	method load_image {filename tag} {
		variable image_loaded
		# We load image and catch error if got
		if [catch {
			set img [image create photo -file $filename]
		} err] {
			# We load error icon
			set img [image create photo -data [lindex [tk::icons::error config -data] end]]
			# We advice the user
			tk_messageBox -message "Error while loading image" -title error -detail $err -icon error
		}
		# We add tag to know where the img is used
		lappend image_loaded $tag $img
		return $img
	}
	# This method permit to duplicate all items selected
	#
	method duplicate_items_selected {} {
		variable selected_items
		variable canvas
		# We duplicate each item
		foreach item $selected_items {
			# We verify if item exist
			if [string length [$canvas find withtag $item]] {
				# We get the type, coords and config
				set type [$canvas type $item]
				set coords [$canvas coords $item]
				set config ""
				# We get key and value
				foreach c [$canvas itemconfig $item] {
					lappend config [lindex $c 0] [lindex $c end]
				}
				# We create a new item with same type, config and coord
				set new_item [eval $canvas create $type $coords]
				eval $canvas itemconfig $new_item $config
			}
		}
	}
	# This method permit to resize (double, half) all items selected
	#
	method scale_items_selected {} {
		variable selected_items
		variable canvas
		variable current_scale_factor
		# We scale all items selected
		foreach item $selected_items {
			set factor [expr pow(2, $current_scale_factor)]
			# We verify if image
			if [string equal [$canvas type $item] image] {
				# We resize the image
				set img [lindex [$canvas itemconfig $item -image] end]
				# We get geometry
				set width [expr int([image width $img]*$factor)]
				set height [expr int([image height $img]*$factor)]
				# We resize with geometry of power of 2 enabled
				# to improve the perfomance for the next resize of this image
				::imgResize::resize $img [set width] [set height] 1
			} else {
				# We scale with for origin the middle of the canvas
				$canvas scale $item [expr [lindex [$canvas config -width] end]/2] [expr [lindex [$canvas config -height] end]/2] $factor $factor
			}
		}
	}
	# This method permit to change the factor of scaling
	# Argument: factor
	method change_current_scale_factor factor {
		variable current_scale_factor $factor
	}
	method can_edit {} {
		variable is_playing
		return [expr !$is_playing]
	}
	# This method permit to load an recording
	# Argument: src
	method play_recording {} {
		set src [tk_getOpenFile]
		set type file
		if [string length $src] {
			tk_messageBox -title Playing -message "The playing will start" -icon info
			# We disable the edit mode
			variable is_playing 1
			# We disable the tools
			for {set i 0} {$i < 100} {incr i} {
				.menu entryconf $i -state disable
			}
			# We set the begin time
			set start_time [clock milli]
			# We verify the type
			if {[string equal $type file]} {
				# We read the src
				set f [open $src rb]
				set data [read $f]
				close $f
				# We load each frame
				foreach frame [split $data \n] {
					# We get frame data
					set timer [lindex $frame 0]
					set cmd [lindex $frame 1]
					# We wait the timer and excute cmd after
					while 1 {
						set current_time [clock milli]
						# We verify if timer got
						if {$current_time - $start_time >= $timer} {
							eval $cmd
							break
						}
						# We update the gui
						update
					}
				}
				tk_messageBox -title Playing -message Finish -icon info
			}
			# We enable the tools
			for {set i 0} {$i < 100} {incr i} {
				.menu entryconf $i -state normal
			}
			# We enable the edit mode
			variable is_playing 0
		}
	}
	method recoder_start {} {
		set filename [tk_getSaveFile]
		if [string length $filename] {
			set ::undoAndRedo::logfile $filename
			set ::undoAndRedo::start_time [clock milli]
		}
	}
	method recoder_stop {} {
		set ::undoAndRedo::logfile ""
	}
	destructor {
		variable master
		# We destroy the gui
		destroy $master
	}
}
