# Explicit invocation only. Temporary CRAM; no Flash/eFuse operations.
set review_root [file normalize [file join [file dirname [info script]] ..]]
set bit_file [file join $review_root bitstream video_correct_ddr_top.sbit]
cfg_set_tcl_break -flag true
cfg_connect -ip 127.0.0.1 -port 65420
cfg_set_cable_property -index 0 -freq 1MHz
cfg_scan_chain
cfg_assign_file -file $bit_file -device_index 0
cfg_set_device_property -device_index 0 -program 1 -readback 1
cfg_program -device_index 0
if {[file isfile [file rootname $bit_file].smsk]} {
 cfg_verify -device_index 0
} else {
 puts "VERIFY_NOT_PERFORMED: matching V4S mask absent from supplied release"
}
cfg_read_device_property -device_index 0 -mode 3
cfg_disconnect
cfg_close
