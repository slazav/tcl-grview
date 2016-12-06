#!/usr/bin/wish

# example of monitoring program
lappend auto_path ..
package require Graphene
package require GrapheneViewer

# local connection to the database, current folder
graphene::viewer V [graphene::open -db_path "."]

V add cpu_temp
V add {cpu_load:0 cpu_load:1 cpu_load:2}

V auto_lim

