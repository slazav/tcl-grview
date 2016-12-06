package provide GrapheneViewer 1.0
package require Itcl
package require xBlt 3

namespace eval graphene {

######################################################################
itcl::class viewer_panel {

  public variable wp  {}; # window path
  public variable dbs {}; # extended graphene database names
  variable xv;
  variable yv;

  constructor {wp_ dbs_} {
    set wp $wp_
    set dbs $dbs_
    blt::graph $wp
  }
  destructor {
    foreach d $dbs {
      blt::vector destroy $xv($d)
      blt::vector destroy $yv($d)
    }
  }

  # find min/max timestamps for all plots
  method get_lim {dbcon} {
    set t1 {}
    set t2 {}
    foreach d $dbs {
      set o1 [graphene::cmd $dbcon "get_next $d"]
      set o2 [graphene::cmd $dbcon "get_prev $d"]
      regexp {^\S+} [lindex $o1 0] o1
      regexp {^\S+} [lindex $o2 0] o2
      if {$t1=="" || $t1 > $o1} {set t1 $o1}
      if {$t2=="" || $t2 < $o2} {set t2 $o2}
    }
    return [list $t1 $t2]
  }

  method plot {dbcon t1 t2} {
    set N 200; # TODO - screen width
    set dt [expr {($t2-$t1)/$N}]
    foreach d $dbs {
      set xv($d) [blt::vector create \#auto]
      set yv($d) [blt::vector create \#auto]
      foreach o [graphene::cmd $dbcon "get_range $d $t1 $t2 $dt"] {
        regexp {^(\S+)\s+(\S+)} $o {} xp yp
        $xv($d) append $xp
        $yv($d) append $yp
      }
      $wp element create $d -xdata $xv($d) -ydata $yv($d)\
                            -symbol {} -color blue
    }
  }

}

######################################################################
itcl::class viewer {
  variable dbcon  {}; # database connection
  variable panels {}; # panels
  variable t1 0
  variable t2 0

  constructor { dbcon_ } {
    set dbcon $dbcon_
  }

  # add new panel
  method add {dbs} {
    set n [llength $panels]
    lappend panels [graphene::viewer_panel "pan$n" ".pan$n" $dbs]
    pack ".pan$n"
  }

  # set min/max limits
  method auto_lim {} {
    set t1 {}
    set t2 {}
    foreach p $panels {
      set o [$p get_lim $dbcon]
      set o1 [lindex $o 0]
      set o2 [lindex $o 1]
      if {$t1=="" || $t1 > $o1} {set t1 $o1}
      if {$t2=="" || $t2 < $o2} {set t2 $o2}
    }
    foreach p $panels { $p plot $dbcon $t1 $t2 }
  }

}

######################################################################
}