// Módulo somador de 4 bits
module somador_4bits (
    input [3:0] A,
    input [3:0] B,
    input Cin,
    output [3:0] S,
    output Cout
);

// Células lógicas básicas
AND2 U1 (.a(A[0]), .b(B[0]), .y(w1));
XOR2 U2 (.a(A[0]), .b(B[0]), .y(w2));
AND2 U3 (.a(w2), .b(Cin), .y(w3));
XOR2 U4 (.a(w2), .b(Cin), .y(S[0]));

AND2 U5 (.a(A[1]), .b(B[1]), .y(w4));
XOR2 U6 (.a(A[1]), .b(B[1]), .y(w5));
AND2 U7 (.a(w5), .b(w3), .y(w6));
XOR2 U8 (.a(w5), .b(w3), .y(S[1]));

AND2 U9 (.a(A[2]), .b(B[2]), .y(w7));
XOR2 U10 (.a(A[2]), .b(B[2]), .y(w8));
AND2 U11 (.a(w8), .b(w6), .y(w9));
XOR2 U12 (.a(w8), .b(w6), .y(S[2]));

AND2 U13 (.a(A[3]), .b(B[3]), .y(w10));
XOR2 U14 (.a(A[3]), .b(B[3]), .y(w11));
AND2 U15 (.a(w11), .b(w9), .y(Cout));
XOR2 U16 (.a(w11), .b(w9), .y(S[3]));

endmodule

// Módulo flip-flop
module flipflop_D (
    input D,
    input clk,
    input rst,
    output reg Q
);
    always @(posedge clk or posedge rst) begin
        if (rst) Q <= 1'b0;
        else Q <= D;
    end
endmodule

// Módulo contador
module contador_4bits (
    input clk,
    input rst,
    output [3:0] count
);
    wire [3:0] next_count;
    
    XOR2 U17 (.a(count[0]), .b(1'b1), .y(next_count[0]));
    AND2 U18 (.a(count[0]), .b(1'b1), .y(w_carry1));
    XOR2 U19 (.a(count[1]), .b(w_carry1), .y(next_count[1]));
    AND2 U20 (.a(count[1]), .b(w_carry1), .y(w_carry2));
    XOR2 U21 (.a(count[2]), .b(w_carry2), .y(next_count[2]));
    AND2 U22 (.a(count[2]), .b(w_carry2), .y(w_carry3));
    XOR2 U23 (.a(count[3]), .b(w_carry3), .y(next_count[3]));
    
    flipflop_D ff0 (.D(next_count[0]), .clk(clk), .rst(rst), .Q(count[0]));
    flipflop_D ff1 (.D(next_count[1]), .clk(clk), .rst(rst), .Q(count[1]));
    flipflop_D ff2 (.D(next_count[2]), .clk(clk), .rst(rst), .Q(count[2]));
    flipflop_D ff3 (.D(next_count[3]), .clk(clk), .rst(rst), .Q(count[3]));
endmodule