## tcl-grview -- Viewer for Graphene database

Libriry for writing viewers for your databases.

### Usage:
```tcl
#!/usr/bin/wish

package require GrapheneViewer 1.0

# open database device - see Device library
Device db

# create a viewer
graphene::viewer viewer

# Add a database to the viewer as a data source.
# Here you can specify number of columns,
# column names, titles, colors, formats.
viewer add_data\
   -name     cpu_load\
   -conn     db\
   -ncols    3\
   -cnames   {"load 1m" "load 5m" "load 10m"}\
   -ctitles  {"CPU load, 10m average" "CPU load, 5m average" "CPU load, 1m average"}\
   -cfmts    {%.3f %.3f %.3f}

# Add a text database to the viewer as a comment source
viewer add_comm\
   -name     cpu_load_comm\
   -conn     db\

# set viewer to full scale
viewer full_scale
```
