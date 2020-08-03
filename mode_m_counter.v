`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        Tronlong
// Engineer:       Felix
// 
// Create Date:    20:24:25 01/03/2014 
// Design Name:    uart_test
// Module Name:    mode_m_counter 
// Project Name:   uart_test
// Target Devices: xa7a100tfgg484-2I
// Tool versions:  vivado 2015.2
// Description:    模M计数器，用于产生波特率，参数上层可修改
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mode_m_counter
#(
	parameter N=4, //计数器位宽
				 M=10 //模10计数器
)
(
	input wire clk, reset,
	output wire max_tick,
	output wire [N-1:0]q
);

//信号声明
reg  [N-1:0]r_reg;
wire  [N-1:0]r_next;
//主体部分
//寄存器部分
always@(posedge clk,negedge reset)
	if(!reset)
		r_reg<=0;
	else
		r_reg<=r_next;
//下一状态逻辑
assign r_next = (r_reg==(M-1))?1'b0:r_reg+1'b1;

//输出逻辑
assign q = r_reg;
assign max_tick = (r_reg==(M-1))?1'b1:1'b0;
endmodule
