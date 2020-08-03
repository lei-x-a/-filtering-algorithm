`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        Tronlong
// Engineer:       yuzhijun
// 
// Create Date:    23:14:29 01/03/2014 
// Design Name:    uart_test
// Module Name:    uart_tx 
// Project Name:   uart_test
// Target Devices: xc7a100tfgg484-2I
// Tool versions:  vivado 2015.2
// Description:    UART发送模块，默认数据位8位，1个停止位
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_tx
#(
	parameter DBIT = 8,
				 SB_TICK = 16
)
(
	input wire clk,reset,
	input wire tx_start,s_tick,
	input wire [7:0]din,
	output reg tx_done_tick,
	output wire tx
 );
  
 //状态机状态定义
localparam[1:0]
	idle  = 2'b00,
	start = 2'b01,
	data  = 2'b10,
	stop  = 2'b11;
  
//信号声明
reg[1:0]state_reg,state_next;
reg[3:0]s_reg,s_next;
reg[2:0]n_reg,n_next;
reg[7:0]b_reg,b_next;
reg tx_reg,tx_next;

//FSMD状态及数据寄存器
always@(posedge clk,negedge reset)
	if(!reset)
		begin
			state_reg <= idle;
			s_reg  <= 0;
			n_reg  <= 0;
			b_reg  <= 0;
			tx_reg <= 1'b1;
		end
	else 
		begin
			state_reg <= state_next;
			s_reg <= s_next;
			n_reg <= n_next;
			b_reg <= b_next;
			tx_reg <= tx_next;
		end

//FSMD 下一状态逻辑及功能单元
always@*
	begin
		state_next   = state_reg;
		tx_done_tick = 1'b0;
		s_next  = s_reg;
		n_next  = n_reg;
		b_next  = b_reg;
		tx_next = tx_reg;
		case(state_reg)
			idle:
				begin
					tx_next = 1'b1;
					if(tx_start)
						begin
							state_next = start;
							s_next = 0;
							b_next = din;
						end
				end
			start:
				begin
					tx_next = 1'b0;
					if(s_tick)
						if(s_reg==15)
							begin
								state_next = data;
								s_next = 0;
								n_next = 0;
							end
				       else
							 s_next = s_reg + 1'b1;
				end
			data:
				begin
					tx_next = b_reg[0];
					if(s_tick)
						if(s_reg==15)
							begin
								s_next = 0;
								b_next = b_reg >>1;
								if(n_reg==(DBIT-1))
									state_next = stop;
								else
									n_next = n_reg + 1'b1;
							end
						else
							s_next = s_reg + 1'b1;
				end
			stop:
			   begin
					tx_next = 1'b1;
					if(s_tick)
						if(s_reg==(SB_TICK-1))
							begin
								state_next = idle;
								tx_done_tick = 1'b1;
							end
						else
							s_next = s_reg + 1'b1;
				end
		endcase 
	end
	
//输出逻辑
assign tx = tx_reg;

endmodule
