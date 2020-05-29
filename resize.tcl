#!/usr/bin/wish
#*
# * resize.tcl
# * 
# * Copyright 2020 pythonbrad <https://github.com/pythonbrad>
# * 
# * This program is free software; you can redistribute it and/or modify
# * it under the terms of the GNU General Public License as published by
# * the Free Software Foundation; either version 2 of the License, or
# * (at your option) any later version.
# * 
# * This program is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# * GNU General Public License for more details.
# * 
# * You should have received a copy of the GNU General Public License
# * along with this program; if not, write to the Free Software
# * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# * MA 02110-1301, USA.
# * 
# * 
#*

package require Tk

namespace eval ::imgResize {}

# This function resize an image
# Argument: We have newx and newy who represent the new size
# convert_geometry is a boolean to enable the converting in power of 2
# It return the ratio of sizing
# Recommanded to use image with power of 2 or enable convert_geometry
# for best result
proc ::imgResize::resize {img newx newy {convert_geometry 0}} {
	# We verify if we convert geometry in power of 2
	if {$convert_geometry} {
		set status 0
		# We init the counter to 1 to evit infinity loop caused by 0
		set i 1
		# represent the double
		set ii 0
		# We search the nearest power of 2 for each newx and newy
		while 1 {
			# We calcul the double
			set ii [expr $i*2]
			if {$ii >= $newx} {
				# We change if newx is not already power of 2
				if {$newx != $ii} {
					set newx $i
				}
				incr status
			}
			if {$ii >= $newy} {
				# We change if newy is not already power of 2
				if {$newy != $ii} {
					set newy $i
				}
				incr status
			}
			if {$status > 1} {
				break
			} else {
				set i $ii
			}
		}
	}
	# We get the old size
	set oldx [image width $img]
	set oldy [image height $img]
	# We calcul the ratio
	set ix [expr 1.*$newx/$oldx]
	set iy [expr 1.*$newy/$oldy]
	# We search which option to apply for x and y
	# and invert the ratio in function of the option
	if {$ix < 1} {
		set ix [expr pow($ix,-1)]
		set optionx -subsample
	} else {
		set optionx -zoom
	}
	if {$iy < 1} {
		set iy [expr pow($iy,-1)]
		set optiony -subsample
	} else {
		set optiony -zoom
	}
	# We convert each ratio in integer
	set ix [expr int($ix+0.5)]
	set iy [expr int($iy+0.5)]
	# We resize x and y individually
	# To do it, we create 2 image tempory
	set tmp [image create photo]
	set tmp2 [image create photo]
	# We resize x
	$tmp copy $img $optionx $ix 1
	# We resize y with data got after resize of x
	$tmp2 copy $tmp $optiony 1 $iy
	$img blank
	# We config the new gemotry
	$img config -width $newx -height $newy
	$img copy $tmp2
	image delete $tmp
	image delete $tmp2
	return [list $ix $iy]
}

proc ::imgResize::test {} {
	set img ::tk::icons::warning
	pack [label .l -image $img]
	after 500 "::imgResize::resize $img 32 32"
	after 1000 "::imgResize::resize $img 64 64"
	after 1500 "::imgResize::resize $img 128 128"
	after 2000 "::imgResize::resize $img 256 256"
	after 2500 "::imgResize::resize $img 512 512"
}

#::imgResize::test