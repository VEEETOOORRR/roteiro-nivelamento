set palavras_ignoradas {"if" "else" "always" "wire" "reg" "input" "output" "begin" "end" "module"}
set portas_logicas {"AND2" "XOR2" "OR2" "NOT"}

set arquivo [open "contador_netlist.v" r]
puts "=== HIERARQUIA DO DESIGN ===\n"

array set contador_pecas {}
set achou_porta_logica 0

while {[gets $arquivo linha] >= 0} {
    
    if {[regexp {^\s*//} $linha]} { continue }

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