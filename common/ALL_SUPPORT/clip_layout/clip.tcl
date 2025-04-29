set gdsfile "/usrhome/chenanping/for_pv/clip_case/layout0.gds"
set L [layout create $gdsfile -dt_expand -preserveProperties]
set topcell "TOPCELL"
set L_copy2 [layout copy2 $L $topcell -3u 0u 5.5u 5.5u]
$L_copy2 gdsout test.gds
