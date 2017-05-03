#!/usr/bin/wish

source viewer.tcl

set db_dev db_exp
Device $db_dev
graphene::viewer viewer

viewer add_data\
   -name     sweep1\
   -conn     $db_dev\
   -cnames   {ch1-iset ch1-imeas ch1-volt}\
   -ctitles  {"Amplitude" "Frequency" "Decay time"}\
   -ccolors  {magenta blue red}\
   -cfmts    {%.2f %.6f %.5f}\
   -ncols    3

viewer add_data\
   -name     sweep2\
   -conn     $db_dev\
   -cnames   {ch2-iset ch2-imeas ch2-volt}\
   -ctitles  {"Amplitude" "Frequency" "Decay time"}\
   -ccolors  {magenta blue red}\
   -cfmts    {%.2f %.6f %.5f}\
   -ncols    3

viewer add_data\
   -name     sweep3\
   -conn     $db_dev\
   -cnames   {ch3-iset ch3-imeas ch3-volt}\
   -ctitles  {"Amplitude" "Frequency" "Decay time"}\
   -ccolors  {magenta blue red}\
   -cfmts    {%.2f %.6f %.5f}\
   -ncols    3

viewer add_comments\
   -name cpu_comm.txt

viewer on_change 0 1 0 0 1024

