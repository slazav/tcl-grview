package require Itcl
package require ParseOptions 2.0
package require xBlt 3
package require Device

source data_source.tcl
source comm_source.tcl
source autoupdater.tcl

namespace eval graphene {

######################################################################
itcl::class viewer {

  variable data_sources; # data source objects
  variable comm_source;  # comment source

  # widgets: root, plot, top menu, scrollbar:
  variable rwid
  variable graph
  variable mwid
  variable swid
  private variable goto_val {}

  variable maxwidth;  # max window size
  variable update_interval;

  ######################################################################

  constructor {} {
    set data_sources {}
    set comm_source {}
    set update_interval 1000
    set maxwidth     1500

    ### create and pack interface elements:
#    set rwid $root_widget
    set rwid {}
    if {$rwid ne {}} {frame $rwid}
    set graph $rwid.p
    set mwid $rwid.f
    set swid $rwid.sb

    ## upper menu frame
    frame $mwid
    button $mwid.exit -command "$this finish" -text Exit
    pack $mwid.exit -side right -padx 2
    pack $mwid -side top -fill x -padx 4 -pady 4

    ## autoupdate checkbutton
    checkbutton $mwid.autoupdate -text "Auto update" -variable autoupdate
    pack $mwid.autoupdate -side right -padx 2
    autoupdater #auto\
      -state_var ::autoupdate\
      -interval  $update_interval\
      -update_proc [list $this update]\

    ## goto window
    label $mwid.goto_l -text "Go to date: "
    entry $mwid.goto -width 20 -textvariable [itcl::scope goto_val]
    bind $mwid.goto <Return> [list $this goto {}]
    pack $mwid.goto   -side right -padx 2
    pack $mwid.goto_l -side right -padx 2

    ## scrollbar
    scrollbar $swid -orient horizontal
    pack $swid -side bottom -fill x

    ## set graph size
    set swidth [winfo screenwidth .]
    set graphth [expr {$swidth - 80}]
    if {$graphth > $maxwidth} {set graphth $maxwidth}

    ## main graph
    blt::graph $graph -width $graphth -height 600 -leftmargin 60
    pack $graph -side top -expand yes -fill both

    $graph legend configure -activebackground white

    # configure standard xBLT things:
    xblt::plotmenu   $graph -showbutton 1 -buttonlabel Menu -buttonfont {Helvetica 12} -menuoncanvas 0
    xblt::legmenu    $graph
    xblt::hielems    $graph
    xblt::crosshairs $graph -variable v_crosshairs
    xblt::measure    $graph
    xblt::readout    $graph -variable v_readout -active 1;
    xblt::zoomstack  $graph -scrollbutton 2 -axes x -recttype x
    xblt::elemop     $graph
    xblt::scroll     $graph $swid -on_change [list $this on_change] -timefmt 1

    ## range menu
    ## create xblt::rubberrect
    xblt::rubberrect::add $graph -type x -modifier Shift \
      -configure {-outline blue} \
      -invtransformx x\
      -command "$this show_rangemenu"\
      -cancelbutton ""
    $graph marker create polygon -name rangemarker -dashes 5 -fill "" \
        -linewidth 2 -mapx x -mapy xblt::unity -outline blue -hide 1
    set rangemenu [menu $graph.rangemenu -tearoff 0]
    bind $rangemenu <Unmap> [list $this on_rangemenu_close]
    $rangemenu add command -label "Zoom" -command [list $this on_range_zoom]
    $rangemenu add command -label "Save data to file" -command [list $this on_range_save]
    $rangemenu add separator
    $rangemenu add command -label "Delete data"       -command [list $this on_range_del_data]
    $rangemenu add command -label "Delete comments"   -command [list $this on_range_del_comm]


    bind . <Alt-Key-q>     "$this finish"
    bind . <Control-Key-q> "$this finish"
    wm protocol . WM_DELETE_WINDOW "$this finish"
  }

  destructor {
  }

  ######################################################################

  # add data source
  method add_data {args} {
    set ds [DataSource #auto $graph {*}$args]
    expand_range {*}[$ds range]
    lappend data_sources $ds
  }

  # add comment source
  method add_comm {args} {
    set comm_source [CommSource #auto $graph {*}$args]
    expand_range {*}[$comm_source range]
  }

  ## expand plot range
  method expand_range {min max} {
    set mino [$graph axis cget x -scrollmin]
    set maxo [$graph axis cget x -scrollmax]
    if {$min != {} && ($mino=={} || $mino > $min)} {
      $graph axis configure x -scrollmin $min
    } else {set min $mino}
    if {$max != {} && ($maxo=={} || $maxo < $max)} {
      $graph axis configure x -scrollmax $max
    } else {set max $maxo}

    # change scrollbal position
    if {$mino!={} && $maxo!={} && $min!={} && $max!={}} {
      set sb [$swid get]
      set sbmin [lindex $sb 0]
      set sbmax [lindex $sb 1]
      set sbmin [expr {($mino-$min + $sbmin*($maxo-$mino))/($max-$min)}]
      set sbmax [expr {($mino-$min + $sbmax*($maxo-$mino))/($max-$min)}]
      $swid set $sbmin $sbmax
    }
  }

  ## This function is called after zooming the graph.
  ## It loads data in a lazy way and do not update data limits.
  method on_change {x1 x2 t1 t2 w} {
    foreach d $data_sources { $d update_data $t1 $t2 $w }
    if {$comm_source!={}} { $comm_source update_data $t1 $t2 $w }
  }

  ## This function is called from autoupdater
  method update {} {
    # expand plot limits to the current time
    set now [expr [clock milliseconds]/1000.0]
    expand_range {} $now
    # update data limits
    foreach d $data_sources { $d reset_data_info}
    if {$comm_source!={}} { $comm_source reset_data_info }
    # scroll the plot to the right limit
    xblt::scroll::cmd moveto 1
  }

  ## Zoom to full range
  method full_scale {} {
    set min [$graph axis cget x -scrollmin]
    set max [$graph axis cget x -scrollmax]
    $graph axis configure x -min $min -max $max
  }

  ## goto year, month, day, hour
  method goto {date} {
    if {$date=={}} {set date $goto_val}
    if     {[ regexp {^\d{4}-\d{1,2}-\d{1,2}\s+\d{1,2}:\S+\d{1,2}} $date]} { set dt 60}\
    elseif {[ regexp {^\d{4}-\d{1,2}-\d{1,2}\s+\d{1,2}$} $date]} { set dt 3600}\
    elseif {[ regexp {^\d{4}-\d{1,2}-\d{1,2}$} $date]} { set dt [expr 24*3600]}\
    elseif {[ regexp {^\d{4}-\d{1,2}$} $date]} {set dt [expr 12*24*3600]; set date "$date-01"}\
    elseif {[ regexp {^\d{4}$} $date]} { set dt [expr 366*24*3600]; set date "$date-01-01"}\
    else { full_scale; return }
    set t1 [clock scan $date]
    puts "goto $t1 [expr $t1+$dt]"
    $graph axis configure x -min $t1 -max [expr $t1+$dt]
  }

  ######################################################################
  ## range menu functions

  variable t1
  variable t2
  variable rangemenu
  method show_rangemenu {graph x1 x2 y1 y2} {
    set t1 $x1
    set t2 $x2
    $graph marker configure rangemarker -hide 0 -coords "$x1 0 $x1 1 $x2 1 $x2 0" 
    tk_popup $rangemenu [winfo pointerx .p] [winfo pointery .p]
  }

  method on_rangemenu_close {} {
    $graph marker configure rangemarker -hide 1
  }

  method on_range_zoom {} {
    $graph axis configure x -min $t1 -max $t2
  }

  method on_range_del_data {} {
    $graph marker configure rangemarker -hide 0
    if {[tk_messageBox -type yesno -message "Delete all data in the range?"] == "yes"} {
      foreach d $data_sources { $d delete_range $t1 $t2 }
    }
    $graph marker configure rangemarker -hide 1
  }

  method on_range_del_comm {} {
    $graph marker configure rangemarker -hide 0
    if {[tk_messageBox -type yesno -message "Delete all comments in the range?"] == "yes"} {
      if {$comm_source!={}} { $comm_source delete_range $t1 $t2 }
    }
    $graph marker configure rangemarker -hide 1
  }

  method on_range_save {} {
    $graph marker configure rangemarker -hide 0
    set fname [tk_getSaveFile]
    if {$fname != {}} {
      foreach d $data_sources { $d save_file ${fname}_${d} $t1 $t2 }
    }
    $graph marker configure rangemarker -hide 1
  }

  ######################################################################

  method finish {} { exit }
}
}
