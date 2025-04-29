Calibre Pushdown Marker Script
v7.2

The Pushdown marker script is used to push results from a Calibre ASCII RDB into specified
blocks in the design. The script outputs an updated RDB file and CTO file for RVE debugging.
Optionally, individual RDBs for each specified block may be output and shared with the 
block owner for debug.

#########
# Input #
#########

rdbIn
-----
DRC RDB file


origDB
------
Layout file used for DRC


cellFile
--------
List (one per line) of cells to push results into


##########
# Output #
##########

rdbout
------
Pushed RDB file output from script


#################
# Other Options #
#################

boundaryLayer
-------------

The PRBOUNDARY layer in the cells marking the layout extent of the block in <layer#>.<datatype#>
format. Can be rectangular, or rectilinear (L-shaped for example)


promote
-------
Promotes lower level results before pushing down. Required for nearly every flow - leave it on.


blockRDB
--------
Outputs separate RDB files for the blocks defined in the cell.list if the 'rdbout' file contains
any results for that block name.


debug
-----
Used to generate output for debug assistance.


################
# Edge Results #
################
Edge results are converted to zero width paths. Setting the variable below expands each path
by 4dbu so they are not dropped from the output.

setenv MGC_CWB_CONVERT_ZWPATH_TO_POLYGON 1

EXAMPLE
-------
$MGC_HOME/bin/calibredrv pushdownRDB_v7.2.tcl \
    -rdbIn ./OUTPUT/openMSP430.drc.rdb  \
    -origDB ./LAYOUT/openMSP430.oas \
    -cellFile cell.list \
    -rdbout pushed.rdb \
    -boundaryLayer 108.0 \
    -promote 1  \
    -blockRDB 1 \
    |& tee pushdown.log

