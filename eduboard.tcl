#!/usr/bin/wish
#====================================================================#
#     EduBoard written in Tcl/Tk for editing open source project       #
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
		
		# We config the gui
		if $fullscreen {wm attributes . -fullscreen 1}
		
		# We create the board
		variable master [frame .master]
		# We make the body layout
		frame $master.body
		variable canvas [canvas $master.body.canvas -background $bgcolor]
		
		# We make binding
		bind $canvas <Button-1> "$self mouse_click %x %y"
		bind $canvas <ButtonRelease> "$self mouse_click_release"
		bind $canvas <Motion> "$self mouse_move %x %y"
		
		# We make the tools layout
		frame $master.tools
		
		#
		# USE POST COMMAND WITH MENUBUTTON WHILE THE EVENT INVOKE IF WANT USED AN SIMPLE BUTTON
		#
		
		# We build the color tools
		variable button_color [ttk::menubutton $master.tools.color -compound top -text color -image [my load_image icons/paint.png gui]]
		# We build the color menu
		menu $button_color.menu -tearoff 0
		# We add data
		foreach "color code" "black #000000 white #FFFFFF grey #4D4D4D green #008000 yellow #FFFF00 blue #1E90FF brown #A52A2A eraser $bgcolor more {}" {
			$button_color.menu add command -label $color -command "$self change_color {$code}" -background $code -foreground $code
		}
		# We add the color menu
		$button_color config -menu $button_color.menu
		
		# We build the size tools
		variable button_size [ttk::menubutton $master.tools.size -compound top -text size -image [my load_image icons/size.png gui]]
		# We build the size menu
		menu $button_size.menu -tearoff 0
		# We add data
		foreach size "1 2 4 6 8 10" {
			$button_size.menu add command -label $size -command "$self change_size $size"
		}
		# We add the size menu
		$button_size config -menu $button_size.menu
		
		variable button_image [ttk::button $master.tools.image -compound top -text image -image [my load_image icons/image.png gui] -command "$self add_image {}"]
		
		# We build  the select tools
		variable button_select [ttk::menubutton $master.tools.select -compound top -text select -image [my load_image icons/select.png gui]]
		# We build the select menu
		menu $button_select.menu -tearoff 0
		# We add command
		$button_select.menu add command -label drag -command "$self select_items"
		$button_select.menu add command -label all -command "$self select_all_items"
		# We addd the select menu
		$button_select config -menu $button_select.menu
		
		# We build the move tools
		variable button_move [ttk::button $master.tools.move -compound top -text move -image [my load_image icons/move.png gui] -command "$self move_items_selected"]
		
		# We build the delete tools
		variable button_delete [ttk::button $master.tools.delete -compound top -text delete -image [my load_image icons/cancel.png gui] -command "$self delete_items_selected"]
		
		# We build the duplicate tools
		variable button_duplicate [ttk::button $master.tools.duplicated -compound top -text duplicate -image [my load_image icons/duplicate.png gui] -command "$self duplicate_items_selected"]
		
		# We build the scale tools
		variable button_scale [ttk::menubutton $master.tools.sclale -compound top -text scale -image [my load_image icons/scale.png gui]]
		# We build the scale menu
		menu $button_scale.menu -tearoff 0
		# We add command
		menu $button_scale.menu.factor -tearoff 0
		$button_scale.menu.factor add radiobutton -label 1 -command "$self change_current_scale_factor 1"
		$button_scale.menu.factor add radiobutton -label -1 -command "$self change_current_scale_factor -1"
		$button_scale.menu add cascade -label factor -menu $button_scale.menu.factor
		$button_scale.menu add command -label scale -command "$self scale_items_selected"
		# We addd the scale menu
		$button_scale config -menu $button_scale.menu
		
		# We build the board
		pack $master
		pack $master.body
		pack $canvas
		pack $master.tools
		pack $button_color -side left
		pack $button_size -side left
		pack $button_image -side left
		pack $button_select -side left
		pack $button_move -side left
		pack $button_delete -side left
		pack $button_duplicate -side left
		pack $button_scale -side left
		
		# We update the gui before others operations
		update
		
		# We config and launch the auto ajust
		set ::auto_ajust::canvas "$canvas 1 .9"
		# We config all gui image for the auto ajust
		foreach "tag image" $image_loaded {
			# We verify if image of gui
			if {[string equal $tag gui]} {
				lappend ::auto_ajust::images $image height .05
			}
		}
		# We launch
		::auto_ajust::run
	}
	method change_color color {
		variable button_color
		variable current_color
		variable master
		# We verify if color passed in argument, if not and ask color
		if ![string length $color] {
			set color [tk_chooseColor -parent $master -initialcolor $current_color]
		}
		# If color got, I change
		if [string length $color] {
			variable current_color $color
			# We update the gui
			$button_color config -text $color
		}
	}
	method change_size size {
		variable button_size
		# If size passed in argument, I change
		if [string length $size] {
			variable current_size $size
			# We update the gui
			$button_size config -text $size
		}
	}
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
	method mouse_click_release {} {
		variable current_mode
		variable selected_items
		variable canvas
		# We clean any data
		variable current_item ""
		variable can_draw 0
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
		}
		variable current_mode ""
	}
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
	method select_items {} {
		# We change the mode
		variable current_mode selecting
	}
	method select_all_items {} {
		variable canvas
		# We get all items
		variable selected_items [$canvas find all]
	}
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
	method move_items_selected {} {
		# We change the mode
		variable current_mode moving
	}
	method add_image filename {
		variable master
		variable canvas
		variable selected_items
		# We verify if filename passed in argument
		if ![string length $filename] {
			# We ask filename
			set filename [tk_getOpenFile -parent $master]
		}
		# We verify if filename got
		if [string length $filename] {
			set img [my load_image $filename canvas]
			# We create and mark it selected
			 variable selected_items [$canvas create image [expr [lindex [$canvas config -width] end]/2] [expr [lindex [$canvas config -height] end]/2] -image $img]
		}
	}
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
	method change_current_scale_factor factor {
		variable button_scale
		variable current_scale_factor $factor
		# We update the gui
		$button_scale config -text $factor
	}
	destructor {
		variable master
		# We destroy the gui
		destroy $master
	}
}
