#!/usr/bin/wish

package require Itcl
package require ParseOptions 2.0
package require xBlt 3
package require Device

source data_source.tcl
#source comment_source.tcl

namespace eval graphene {

######################################################################
itcl::class viewer {

  variable data_sources; # data source objects

  # Range source
  # contain fields:
  # - name - file/db name
  # - conn - graphene connection for a database source
    variable ranges

  # Comment source
  # contain fields:
  # - name - file/db name
  # - conn - graphene connection for a database source
    variable comments

  # widgets: root, plot, top menu, scrollbar:
    variable rwid
    variable pwid
    variable mwid
    variable swid

  # updater handler
    variable updater

  ######################################################################

  constructor {} {
    set data_sources {}
    set names     {}
    set comments  {}
    set ranges    {}
    set update_state 0

    ### create and pack interface elements:
#    set rwid $root_widget
    set rwid {}
    if {$rwid ne {}} {frame $rwid}
    set pwid $rwid.p
    set mwid $rwid.f
    set swid $rwid.sb

    frame $mwid
    button $mwid.exit -command "$this finish" -text Exit
    pack $mwid.exit -side right -padx 2
    pack $mwid -side top -fill x -padx 4 -pady 4
    scrollbar $swid -orient horizontal
    pack $swid -side bottom -fill x

    ## set window size
    set swidth [winfo screenwidth .]
    set pwidth [expr {$swidth - 80}]
    if {$pwidth > 1520} {set pwidth 1520}

    blt::graph $pwid -width $pwidth -height 600 -leftmargin 60
    pack $pwid -side top -expand yes -fill both

    $pwid legend configure -activebackground white

    # configure standard xBLT things:
    xblt::plotmenu   $pwid -showbutton 1 -buttonlabel Menu -buttonfont {Helvetica 12} -menuoncanvas 0
    xblt::legmenu    $pwid
    xblt::hielems    $pwid
    xblt::crosshairs $pwid -variable v_crosshairs
    xblt::measure    $pwid
    xblt::readout    $pwid -variable v_readout -active 1;
    xblt::zoomstack  $pwid -scrollbutton 2 -axes x -recttype x
    xblt::elemop     $pwid
    xblt::scroll     $pwid $swid -on_change [list $this on_change] -timefmt 1
    xblt::xcomments  $pwid

    bind . <Alt-Key-q>     "$this finish"
    bind . <Control-Key-q> "$this finish"
    wm protocol . WM_DELETE_WINDOW "$this finish"
  }

  destructor {
  }

  ######################################################################
  method message {args} {
    puts "$args"
  }
  method show_rect {graph x1 x2 y1 y2} {
    puts " rect selected $x1 -- $x2"
  }


  ######################################################################

  # add data source
  method add_data {args} {
    lappend data_sources [DataSource #auto $pwid {*}$args] }



  method add_comments {args} {
    set opts {
      -name    name    {} {name}
      -conn    conn    {} {open database connection}
    }
    if {[catch {parse_options "graphene::viewer::add_fdata" \
      $args $opts} err]} { error $err }
    set comments [dict create\
      name $name\
      conn $conn\
    ]
  }

  method add_ranges {args} {
    set opts {
      -name    name    {} {}
      -conn    conn    {} {}
    }
    if {[catch {parse_options "graphene::viewer::add_fdata" \
      $args $opts} err]} { error $err }
    set ranges [dict create\
      name $name\
      conn $conn\
    ]
  }

  ######################################################################

  method on_change {x1 x2 t1 t2 w} {
    foreach d $data_sources {
      $d update_data $x1 $x2 $w
    }
  }


  method finish {} { exit }

}
}
