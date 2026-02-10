set inputdb input.oas
set outputdb output.oas
set topcell fake_top
set cell_ref_list Dummy_fake_top
set layout_list dummy_merged.oas

set L [layout create $inputdb -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]

# Ref crreate for the next movement
foreach ref_cell $cell_ref_list {
    $L create cell $ref_cell
    $L create ref $topcell $ref_cell 0 0 0 0 1
}

foreach ref_layout $layout_list {
    $L import layout $ref_layout FALSE overwrite -dt_expand -preservePaths -reserveTextAttributes -preserveProperties
}

$L oasisout $outputdb $topcell
