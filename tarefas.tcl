set fp [open "contador_netlist.v" r]
set file_data [read $fp]
close $fp

set AND2 0
set XOR2 0
set flipflop_D 0
set total 0

set AND2 [llength [regexp -all -inline {AND2\s+\w+} $file_data]]
set XOR2 [llength [regexp -all -inline {XOR2\s+\w+} $file_data]]
set flipflop_D [llength [regexp -all -inline {flipflop_D\s+\w+} $file_data]]

set total [expr $AND2 + $XOR2 + $flipflop_D]

puts "=== RELATÓRIO DE CÉLULAS ==="
puts "AND2:        $AND2 instâncias"
puts "XOR2:        $XOR2 instâncias"
puts "flipflop_D:  $flipflop_D instâncias"
puts "Total:       $total instâncias" 
