#!/usr/bin/tclsh

# RELATÓRIO DE CÉLULAS

set filename "contador_netlist.v"
set fp [open $filename r]
set data [read $fp]
close $fp

set and2 0
set xor2 0
set ff 0

foreach line [split $data "\n"] {
    set line [string trim $line]
    if {[regexp {^AND2\s+} $line]} { incr and2 }
    if {[regexp {^XOR2\s+} $line]} { incr xor2 }
    if {[regexp {^flipflop_D\s+} $line]} { incr ff }
}

puts "--- RELATÓRIO DE CÉLULAS ---"
puts "AND2: $and2 instâncias"
puts "XOR2: $xor2 instâncias"
puts "flipflop_D: $ff instâncias"
puts "TOTAL: [expr $and2 + $xor2 + $ff] instâncias"

# HIERARQUIA DO DESIGN

set filename "contador_netlist.v"

set and2 0
set xor2 0
set ff 0

set palavras_ignoradas {"if" "else" "always" "wire" "reg" "input" "output" "begin" "end" "module"}
set portas_logicas {"AND2" "XOR2" "OR2" "NOT"}

array set contador_pecas {}
set achou_porta_logica 0

puts "=== HIERARQUIA DO DESIGN ===\n"

set arquivo [open $filename r]

while {[gets $arquivo linha] >= 0} {
    set linha_limpa [string trim $linha]
    
    if {[regexp {^\s*//} $linha]} { continue }

    if {[regexp {^AND2\s+} $linha_limpa]} { incr and2 }
    if {[regexp {^XOR2\s+} $linha_limpa]} { incr xor2 }
    if {[regexp {^flipflop_D\s+} $linha_limpa]} { incr ff }

    if {[regexp {^\s*module\s+(\w+)} $linha -> nome_modulo]} {
        puts $nome_modulo
        array unset contador_pecas
        set achou_porta_logica 0
        continue
    }

    if {[regexp {^\s*endmodule} $linha]} {
        set qtd_pecas [array size contador_pecas]

        if {$qtd_pecas == 0 && $achou_porta_logica == 0} {
            puts "  |-- (módulo primitivo - sem submódulos)\n"
        } elseif {$qtd_pecas == 0 && $achou_porta_logica == 1} {
            puts "  |-- (apenas células primitivas)\n"
        } else {
            foreach peca [array names contador_pecas] {
                puts "  |-- $peca ($contador_pecas($peca) instâncias)"
            }

            if {$achou_porta_logica == 1} {
                puts "  |-- (células primitivas)"
            }
            puts "" 
        }
        continue
    }

    if {[regexp {^\s*([A-Za-z_]\w*)\s+[A-Za-z_]\w*\s*\w*\(} $linha -> nome_da_peca]} {
        if {[lsearch -exact $palavras_ignoradas $nome_da_peca] != -1} { 
            continue 
        }

        if {[lsearch -exact $portas_logicas $nome_da_peca] != -1} {
            set achou_porta_logica 1
        } else {
            if {![info exists contador_pecas($nome_da_peca)]} {
                set contador_pecas($nome_da_peca) 1
            } else {
                incr contador_pecas($nome_da_peca)
            }
        }
    }
}

close $arquivo

set filename "contador_netlist.v"

# --- Leitura e pré-processamento ---
if {![file exists $filename]} {
    puts "ERRO: Arquivo '$filename' não encontrado."
    exit 1
}
set fp [open $filename r]
set content [read $fp]
close $fp

# Remove comentários de linha (// ...)
regsub -all {//[^\n]*} $content "" content
# Remove comentários de bloco (/* ... */)
regsub -all {/\*.*?\*/} $content "" content


array set net_fanout  {};# numero de loads
array set net_drivers {};# numero de drivers

proc register_net {name} {
    global net_fanout net_drivers
    set name [string trim $name]
    if {$name eq ""} { return }
    if {[regexp {^[01]'b} $name] || [regexp {^\d+$} $name]} { return }
    if {![info exists net_fanout($name)]} {
        set net_fanout($name) 0
        set net_drivers($name) 0
    }
}

# Expande um barramento [H:L] em nets individuais: base[L], base[L+1] ... base[H]
proc expand_bus {base high low} {
    set h [expr {int($high)}]
    set l [expr {int($low)}]
    if {$h < $l} { set tmp $h ; set h $l ; set l $tmp }
    set nets {}
    for {set i $l} {$i <= $h} {incr i} {
        lappend nets "${base}\[${i}\]"
    }
    return $nets
}

# Varre declarações de ports e wires para coletar nets
foreach line [split $content "\n"] {
    set line [string trim $line]
    if {$line eq ""} { continue }

    if {![regexp {^\s*(input|output(?:\s+reg)?|wire)\s+(.*)} $line -> _kw rest]} {
        continue
    }

    regsub {\breg\b} $rest "" rest

    set bh "" ; set bl ""
    if {[regexp {^\s*\[(\d+):(\d+)\]\s*(.*)} $rest -> bh bl rest]} { }

    regsub {[;)][^\n]*} $rest "" rest
    set rest [string trim $rest]
    if {$rest eq ""} { continue }

    foreach raw_name [split $rest ","] {
        set raw_name [string trim $raw_name]
        regsub -all {\s*\[[^\]]*\]} $raw_name "" base
        set base [string trim $base]
        if {$base eq "" || [string match "(*" $base]} { continue }

        if {$bh ne "" && $bl ne ""} {
            foreach net [expand_bus $base $bh $bl] { register_net $net }
        } else {
            register_net $base
        }
    }
}

# Varrer instâncias de células pra calcular fanout

set output_port_re {^(y|out|cout|co|sum|carry|z)$}

set skip_line_re {^\s*(module\b|endmodule\b|always\b|begin\b|end\b|if\b|else\b|assign\b)}

foreach line [split $content "\n"] {
    set line [string trim $line]
    if {$line eq ""} { continue }

    # Pula palavras-chave comportamentais e declarações
    if {[regexp $skip_line_re $line]} { continue }
    if {[regexp {<=} $line]}          { continue }
    if {[regexp {^\s*(input|output|wire)} $line]} { continue }

    # Extrai todos os pares .porta(sinal) da linha
    set matches [regexp -all -inline {\.(\w+)\s*\(\s*([^\)]+?)\s*\)} $line]

    foreach {_ porta sinal} $matches {
        set sinal [string trim $sinal]

        # Filtra constantes Verilog
        if {[regexp {^[01]'b} $sinal] || [regexp {^\d+$} $sinal]} { continue }

        # Garante que o net existe (descobre nets implícitos como w_carry1, w1..w11)
        register_net $sinal

        # Classifica: porta de saída de célula (driver) ou de entrada (load)
        if {[regexp $output_port_re $porta] || $porta eq "Q"} {
            incr net_drivers($sinal)
        } else {
            incr net_fanout($sinal)
        }
    }
}

#Ordenar nets por fanout

set net_list [array names net_fanout]

set pairs {}
foreach n $net_list {
    lappend pairs [list $net_fanout($n) $n]
}
set sorted_pairs [lsort -decreasing -integer -index 0 \
                      [lsort -ascii -index 1 $pairs]]

set sorted_nets {}
foreach p $sorted_pairs { lappend sorted_nets [lindex $p 1] }

set top_n    10
set top_nets [lrange $sorted_nets 0 [expr {$top_n - 1}]]

# Gerar relatório

puts ""
puts "=== TOP $top_n NETS COM MAIOR FANOUT ==="
#puts $sep_wide
puts [format "  | %-4s | %-18s | %-6s |" "Rank" "Net" "Fanout"]
#puts $sep_wide

set rank 1
foreach n $top_nets {
    puts [format "  | #%-3d | %-18s | %6d |" $rank $n $net_fanout($n)]
    incr rank
}
#puts $sep_wide

# FANOUT ZERO
set zero_nets {}
foreach n [lsort -ascii $net_list] {
    if {$net_fanout($n) == 0} { lappend zero_nets $n }
}
set zero_count [llength $zero_nets]

puts ""
puts "  NETS COM FANOUT ZERO (POSSIVEIS ERROS)"
#puts $sep_zero
puts [format "  | %-18s | %-32s |" "Net" "Diagnóstico"]
#puts $sep_zero

if {$zero_count == 0} {
    puts [format "  | %-18s | %-32s |" "(nenhuma)" ""]
} else {
    foreach n $zero_nets {
        if {$net_drivers($n) == 0} {
            set diag "sem driver e sem load"
        } else {
            set diag "driven mas sem load (dangling)"
        }
        puts [format "  | %-18s | %-32s |" $n $diag]
    }
}
#puts $sep_zero

# --- RESUMO ---
set total [llength $net_list]
set top_net  [lindex $sorted_nets 0]
set top_val  $net_fanout($top_net)

puts ""
puts "  RESUMO"
puts "  -------------------------------------------------------------"
puts [format "  %-38s : %d" "Total de nets identificados" $total]
puts [format "  %-38s : %d" "Nets com fanout > 0" [expr {$total - $zero_count}]]
puts [format "  %-38s : %d" "Nets com fanout zero" $zero_count]
puts [format "  %-38s : %d  (%s)" "Maior fanout" $top_val $top_net]
puts "  ============================================================="