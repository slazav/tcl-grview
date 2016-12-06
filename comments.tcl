package require BLT 2.4

package require xBlt

set oscomments 0

proc init_comments_view {} {
    global scom
    set scom(started) 0
    set scom(move,s) 0
    set scom(cur) {}
    set scom(curl) {}
    bind .p <Control-ButtonPress-1> {comment_operation %x %y %X %Y}
    bind scomment <Motion> {comment_create_drag %x %y}
    bind scomment <ButtonRelease-1> {comment_create_finish %x %y %X %Y}
    bind scomment <B1-ButtonPress-3> {comment_create_cancel %x %y}
    bind scomment <ButtonPress-2> {com_move_start %x %y}
    bind scomment <B2-Motion> {com_move_do %x %y}
    bind scomment <ButtonRelease-2> {com_move_end %x %y}
    bind scomment <B2-ButtonPress-3> {com_move_cancel %x %y}
    bind scomment <ButtonPress-3> {com_edit %X %Y}
    xblt::bindtag::add .p scomment
    .p axis create zx -hide 1 -min 0 -max 1
}

proc init_comments {} {
    global scom
    set scom(n) 0
    load_comments_file
    foreach {nx n} [array get scom *,id] {
      create_comment_marker $n
    }
}

proc load_comments_file {} {
    set fn "comments.txt"
    if [file exists $fn] {
      uplevel \#0 [list source $fn]
    } else {
      set fn "comments.txt" ; # look in current dir
      if [file exists $fn] {
        uplevel \#0 [list source $fn]
      }
    }
}

proc comments_version {vers txt} {
    global files_version
    if {$vers > $files_version} return
    uplevel \#0 $txt
}

proc save_comments {} {
    global scom files_version
    set fo [open "comments.txt" "w"]
    puts $fo "comments_version $files_version {"
    puts $fo "array set scom {[array get scom]}"
    puts $fo "}"
    close $fo
}

proc comments_changed {} {
    # save after each change
    catch {save_comments} ; # do not panic yet on errors
}

proc comment_operation {x y X Y} {
    global oscomments scom
    if {$oscomments} return
    if {$scom(cur) != ""} {
	com_delete $scom(cur)
	return -code break
    }
     if {$scom(curl) != ""} {
	 comline_delete [lindex $scom(curl) 0] [lindex $scom(curl) 1] 
	 return -code break
    }
    .p element closest $x $y ee -interpolate no
    if {$ee(name) == ""} {
	set n [comment_create_do \
		   [.p axis invtransform x $x] \
		   [.p axis invtransform zy $y] $X $Y]
	if {$n>=0} {create_comment_marker $n}
    } else {
	set scom(c,e) $ee(name)
	set scom(c,x0) $ee(x)
	set scom(c,y0) $ee(y)
	.p element create cscom -symbol {} -label {} \
	    -color [.p element cget $ee(name) -color] \
	    -dashes {5 2} -linewidth 1 -mapx x -mapy $ee(name)
	set scom(started) 1
    }
    return -code break
}

proc comment_create_drag {x y} {
    global scom
    if {! $scom(started)} return
    .p element configure cscom \
	-xdata [list $scom(c,x0) [.p axis invtransform x $x]] \
	-ydata [list $scom(c,y0) [.p axis invtransform $scom(c,e) $y]]
    return -code break
}

proc comment_create_finish {x y X Y} {
    global scom
    if {! $scom(started)} return
    set scom(started) 0
    if {$scom(cur) == ""} {
	set n [comment_create_do \
		   [.p axis invtransform x $x] \
		   [.p axis invtransform zy $y] $X $Y]
    } else {
	set n $scom(cur)
    }
    .p element delete cscom
    if {$n >= 0} {
	comment_attach_line $n $scom(c,e) $scom(c,x0) $scom(c,y0)
	create_comment_marker $n
    }
    return -code break
}

proc comment_create_cancel {x y} {
    global scom
    if {! $scom(started)} return
    .p element delete cscom
    set scom(started) 0
    return -code break
}

proc comment_create_do {x y X Y} {
    global scom
    set s [ask_comment_text {} $X $Y]
    if {$s == ""} {return -1}
    set n $scom(n)
    incr scom(n)
    set scom($n,id) $n
    set scom($n,txt) $s
    set scom($n,t0) $x
    set scom($n,y0) $y
    set scom($n,nl) 0
    comments_changed
    return $n
}

proc comment_attach_line {n e x0 y0} {
    global scom
    set nl $scom($n,nl)
    incr scom($n,nl)
    set scom($n,l$nl,n) $nl
    set scom($n,l$nl,e) $e
    set scom($n,l$nl,x0) $x0
    set scom($n,l$nl,y0) $y0
    set scom($n,l$nl,dx) [expr {[ax_to_z x $scom($n,t0)] - [ax_to_z x $x0]}]
    set scom($n,l$nl,dy) [expr {$scom($n,y0) - [ax_to_z $e $y0]}]
    comments_changed
}

proc create_comment_marker {n} {
    global scom oscomments
    if {![.p marker exists scom$n]} {
	.p marker create text -name scom$n -hide $oscomments \
	    -background LightGoldenrodYellow \
	    -justify left -anchor c \
	    -mapy zy -text $scom($n,txt)
	.p marker bind scom$n <Enter> [list comment_marker_enter $n]
	.p marker bind scom$n <Leave> [list comment_marker_leave $n]
    }
    foreach {nlx nl} [array get scom $n,l*,n] {
	if {![.p marker exists scom${n}_$nl]} {
	    .p marker create line -name scom${n}_$nl -hide $oscomments \
		-mapy zy -outline [.p element cget $scom($n,l$nl,e) -color] \
		-dashes {5 2} -linewidth 1 -element $scom($n,l$nl,e)
	    .p marker bind scom${n}_$nl <Enter> [list set scom(curl) "$n $nl"]
	    .p marker bind scom${n}_$nl <Leave> [list set scom(curl) {}]
	    .p marker before scom${n}_$nl scom$n
	}
    }
    position_comment $n
}

proc comment_marker_enter {n} {
    global scom
    set scom(cur) $n
    .p marker before scom$n
    .p marker configure scom$n -background bisque
}

proc comment_marker_leave {n} {
    global scom
    set scom(cur) {}
    .p marker configure scom$n -background LightGoldenrodYellow
}

proc position_comment {n} {
    global scom
    if {[llength [array names scom $n,l*]] != 0} {
	set x 0
	set y 0
	set m 0
	foreach {nlx nl} [array get scom $n,l*,n] {
	    set x [expr {$x + $scom($n,l$nl,x0)+ [dz_to_ax x $scom($n,l$nl,dx)]}]
	    set y [expr {$y + [ax_to_z $scom($n,l$nl,e) $scom($n,l$nl,y0)] + $scom($n,l$nl,dy)}]
	    incr m
	}
	set scom($n,t0) [expr {$x/$m}]
	set scom($n,y0) [expr {$y/$m}]
    }
    .p marker configure scom$n -coords [list $scom($n,t0) $scom($n,y0)]
    foreach {nlx nl} [array get scom $n,l*,n] {
	set yl [ax_to_z $scom($n,l$nl,e) $scom($n,l$nl,y0)]
	.p marker configure scom${n}_$nl \
	    -coords [list $scom($n,t0) $scom($n,y0) $scom($n,l$nl,x0) $yl]
    }
}

proc recalc_com_pos {n x y} {
    global scom
    set scom($n,t0) $x
    set scom($n,y0) $y
    if {[llength [array names scom $n,l*]] != 0} {
	foreach {nlx nl} [array get scom $n,l*,n] {
	    set scom($n,l$nl,dx) [expr {[ax_to_z x $x] - [ax_to_z x $scom($n,l$nl,x0)]}]
	    set scom($n,l$nl,dy) [expr {$y - [ax_to_z $scom($n,l$nl,e) $scom($n,l$nl,y0)]}]
	}
    }
}

proc position_all_comments {} {
    global scom
    foreach {nx n} [array get scom *,id] {
	position_comment $n
    }
}

proc ax_to_z {ax a} {
    axlims .p $ax amin amax
    expr {($a-$amin)/($amax-$amin)}
}

proc z_to_ax {ax z} {
    axlims .p $ax amin amax
    expr {$amin + $z * ($amax - $amin)}
}

proc dz_to_ax {ax dz} {
    axlims .p $ax amin amax
    expr {$dz * ($amax - $amin)}
}

proc ask_comment_text {inis X Y} {
    global scom
    set scom(dlgres) {}
    set w .cominput
    if {![winfo exists $w]} {
      toplevel $w
      label $w.l -text "Comment text:"

      text $w.t -background white -width 40 -height 6 \
          -font {helvetica 12}
      bind $w.t <Alt-Key-Return> {set scom(dlgres) 1 ; break}
      bind $w.t <Key-Escape> {set scom(dlgres) 0 ; break}

      button $w.ok -text OK -width 7 -command {set scom(dlgres) 1}
      button $w.can -text Cancel -width 7 -command {set scom(dlgres) 0}
      grid $w.l -column 0 -row 0 -columnspan 2 -sticky w -padx 2 -pady 2
      grid $w.t -column 1 -row 0 -columnspan 2 -padx 2 -pady 2
      grid $w.ok -column 2 -row 0 -sticky e -padx 5 -pady 2
      grid $w.can -column 2 -row 1 -sticky w -padx 5 -pady 2
      wm transient $w .
      wm protocol $w WM_DELETE_WINDOW {set scom(dlgres) 0}
    }
    if {$inis == ""} { wm title $w "Create comment" }\
    else { wm title $w "Edit comment" }
    wm geometry $w +$X+$Y
    wm state $w normal
    $w.t delete 1.0 end
    $w.t insert end $inis
    update idletasks

    focus $w.t
    grab $w
    tkwait variable scom(dlgres)
    grab release $w
    wm state $w withdrawn

    if {$scom(dlgres) == 0} { return $inis }\
    else { return [string trim [$w.t get 1.0 end]] }
}

proc show_scomments {} {
    global oscomments
    foreach m [.p marker names scom*] {
      .p marker configure $m -hide $oscomments
    }
    update_markers
}

proc com_move_start {x y} {
    global scom
    if {$scom(cur) == ""} return
    set scom(move,s) 1
    set scom(move,n) $scom(cur)
    set scom(move,ip) [.p marker cget scom$scom(cur) -coords]
    set scom(move,x0) [expr {[lindex $scom(move,ip) 0] - [.p axis invtransform x $x]}]
    set scom(move,y0) [expr {[lindex $scom(move,ip) 1] - [.p axis invtransform zy $y]}]
    return -code break
}

proc com_move_do {x y} {
    global scom
    if {!$scom(move,s)} return
    .p marker configure scom$scom(move,n) \
	-coords [list [expr {$scom(move,x0) + [.p axis invtransform x $x]}] \
		     [expr {$scom(move,y0) + [.p axis invtransform zy $y]}]]
    return -code break
}

proc com_move_end {x y} {
    global scom
    if {!$scom(move,s)} return
    recalc_com_pos $scom(move,n) \
	[expr {$scom(move,x0) + [.p axis invtransform x $x]}] \
	[expr {$scom(move,y0) + [.p axis invtransform zy $y]}]
    position_comment $scom(move,n)
    set scom(move,s) 0
    comments_changed
    return -code break
}

proc com_move_cancel {x y} {
    global scom
    if {!$scom(move,s)} return
    .p marker configure scom$scom(move,n) -coords $scom(move,ip)
    set scom(move,s) 0
    return -code break
}

proc com_edit {X Y} {
    global scom
    set n $scom(cur)
    if { $n == ""} return
    set s [ask_comment_text $scom($n,txt) $X $Y]
    if {$s != ""} {
      set scom($n,txt) $s
      .p marker configure scom$n -text $s
      comments_changed
    }
    return -code break
}

proc com_delete {n} {
    global scom
    .p marker configure scom$n -background red -foreground white
    if {[tk_messageBox -type yesno -message "Delete comment?"] == "yes"} {
	foreach m [array names scom $n,*] {
	    unset scom($m)
	}
	foreach m [.p marker names scom$n*] {
	    .p marker delete $m
	}
	set scom(cur) {}
	comments_changed
    } else {
	.p marker configure scom$n -background LightGoldenrodYellow -foreground black
    }
}

proc comline_delete {n nl} {
    global scom
    .p marker configure scom${n}_$nl -linewidth 3
    if {[tk_messageBox -type yesno -message "Delete line?"] == "yes"} {
      foreach m [array names scom $n,l$nl*] {
        unset scom($m)
      }
      .p marker delete scom${n}_$nl
      set scom(curl) {}
      set mc [.p marker cget scom$n -coords]
      recalc_com_pos $n [lindex $mc 0] [lindex $mc 1]
      comments_changed
    } else {
      .p marker configure scom${n}_$nl -linewidth 1
    }
}

