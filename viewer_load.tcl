#!/usr/bin/wish

source viewer.tcl

set db_dev db_local
Device $db_dev
graphene::viewer viewer

viewer add_data\
   -name     cpu_load\
   -conn     $db_dev\
   -cnames   {"load 1m" "load 5m" "load 10m"}\
   -ctitles  {"CPU load, 10m average" "CPU load, 5m average" "CPU load, 1m average"}\
   -cfmts    {%.3f %.3f %.3f}\
   -ncols    3

viewer full_scale

