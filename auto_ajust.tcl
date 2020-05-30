#!/usr/bin/wish
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

source resize.tcl

namespace eval ::auto_ajust {
	# canvas represent a list of an couple (canvas widget and percent)
	# percent should be on the form .1 for 10% and it represent 10% of the width or height of the window
	variable canvas ""
	# image represent a list of couple (image and percent)
	variable images ""
	# width and height represent old geometry
	variable old_width 0
	variable old_height 0
	# this variable is a bool to invert geometry, if need
	variable geometry_invert 0
	# We config the marge of geometry to ignore, should be in percent
	variable margin .01;#~1% of the geometry
	# this variable permit to know if auto ajust completed
	variable stable 0
}

# This function permit to make a window responsive
proc ::auto_ajust::run {} {
	variable canvas
	variable images
	variable old_height
	variable old_width
	variable geometry_invert
	variable margin
	variable stable
	# We get the geometry
	set geometry [split [lindex [split [wm geometry .] +] 0] x]
	if $geometry_invert {
		set geometry [lreverse $geometry]
	}
	set current_width [lindex $geometry 0]
	set current_height [lindex $geometry 1]
	# We verify if geometry has changed (We ignore the minor changing)
	if {[expr abs($current_width-$old_width)] > $old_width*$margin | [expr abs($current_height-$old_height)] > $old_height*$margin} {
		# We mark not stable
		if $stable {variable stable 0}
		########
		#    DO NOT USE ALL THE SCREEN (100%), BECAUSE CAN CAUSED PROBLEM OF AJUST
		########
		# We resize the canvas
		foreach "can percentx percenty" $canvas {
			# We get the size in function of the percent given
			if {[string equal $percentx height]} {
				set sizex [set sizey [expr int($current_height * $percenty)]]
			} elseif {[string equal $percenty width]} {
				set sizey [set sizex [expr int($current_width * $percentx)]]
			} else {
				set sizex [expr int($current_width * $percentx)]
				set sizey [expr int($current_height * $percenty)]
			}
			$can config -width $sizex -height $sizey
		}
		# We resize the tools buttons
		foreach "image percentx percenty" $images {
			# We get the size in function of the percent given
			if {[string equal $percentx height]} {
				set sizex [set sizey [expr int($current_height * $percenty)]]
			} elseif {[string equal $percenty width]} {
				set sizey [set sizex [expr int($current_width * $percentx)]]
			} else {
				set sizex [expr int($current_width * $percentx)]
				set sizey [expr int($current_height * $percenty)]
			}
			# We create the tempory image with the origin file to have good quality after resize
			set tmp [image create photo -file [lindex [$image config -file] end]]
			# We clean the image
			$image blank
			# We copy the original image
			# We restore the original geometry
			$image config -width [image width $tmp] -height [image height $tmp]
			$image copy $tmp
			image delete $tmp
			# We resize with geometry of power of 2 enabled
			# to improve the perfomance for the next resize of this image
			::imgResize::resize $image $sizex $sizey 1
		}
	} else {
		# We marl stable
		if !$stable {variable stable 1}
	}
	variable old_height $current_height
	variable old_width $current_width
	# We repeat the process
	after 50 ::auto_ajust::run
}

proc ::auto_ajust::test {} {
	variable canvas
	variable images
	# We config the geometry
	wm geometry . 100x100
	# We build canvas
	pack [canvas .a -background white]
	pack [canvas .b -background red]
	# We create an img and loading it
	::tk::icons::warning write image.tempory
	set img [image create photo -file image.tempory]
	pack [label .c -image $img]
	# We build an other canvas
	pack [canvas .d -background yellow]
	# We add each canvas and their percent in the window
	lappend canvas .a 1 .24 .b 1 .24 .d 1 .24
	# We add image and his percent in the window
	lappend images $img .24 .24
	# We ajust
	run
}

#::auto_ajust::test