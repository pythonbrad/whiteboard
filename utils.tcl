proc centre_window { w } {
	after idle "
		update idletasks

		# centre
		set xmax \[winfo screenwidth $w\]
		set ymax \[winfo screenheight $w\]
		set x \[expr \{(\$xmax - \[winfo reqwidth $w\]) / 2\}\]
		set y \[expr \{(\$ymax - \[winfo reqheight $w\]) / 2\}\]

		wm geometry $w \"+\$x+\$y\""
}