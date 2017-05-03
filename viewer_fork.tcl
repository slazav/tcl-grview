#!/usr/bin/wish

source viewer.tcl

set db_dev db_exp
Device $db_dev
graphene::viewer viewer

viewer add_data\
   -name     fork0\
   -conn     $db_dev\
   -cnames   {amp freq tau}\
   -ctitles  {"Amplitude" "Frequency" "Decay time"}\
   -ccolors  {magenta blue red}\
   -cfmts    {%.2f %.6f %.5f}\
   -ncols    3

viewer add_comments\
   -name cpu_comm.txt

viewer on_change 0 1 0 0 1024

