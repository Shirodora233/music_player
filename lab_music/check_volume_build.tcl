set project_dir [file normalize [file dirname [info script]]]
set source_dir [file join $project_dir lab_music.srcs sources_1 new]

read_verilog [glob [file join $source_dir *.v]]
read_xdc [file join $project_dir lab_music.srcs constrs_1 new music.xdc]
synth_design -top music_top -part xc7k325tffg900-2

puts "CHECK: constrained package pins = [llength [get_ports -filter {PACKAGE_PIN != {}}]]"
puts "CHECK: total top-level ports = [llength [get_ports]]"

opt_design
place_design
report_drc -file [file join $project_dir volume_check_drc.rpt]
report_timing_summary -file [file join $project_dir volume_check_timing.rpt]
puts "CHECK: volume design synthesis and placement completed"
exit
