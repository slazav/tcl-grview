#!/usr/bin/wish

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

  ## expand global range
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
  ## It loads data, but did not update plot limits.
  method on_change {x1 x2 t1 t2 w} {
    foreach d $data_sources { $d update_data $t1 $t2 $w }
    if {$comm_source!={}} { $comm_source update_data $t1 $t2 $w }
  }

  method full_scale {} {
    set min [$graph axis cget x -scrollmin]
    set max [$graph axis cget x -scrollmax]
    on_change 0 0 $min $max $maxwidth
  }

  ## This function is called from autoupdater
  method update {} {
    set now [expr [clock milliseconds]/1000.0]
    expand_range {} $now
    foreach d $data_sources { $d reset_data_info}
    if {$comm_source!={}} { $comm_source reset_data_info }
    xblt::scroll::cmd moveto 1
  }

  method finish {} { exit }

}
}
