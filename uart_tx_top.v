`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:     Tronlong
// Engineer:    yuzhijun
// 
// Create Date: 2015/11/15 10:08:13
// Design Name: 
// Module Name: uart_tx_top
// Project Name: 
// Target Devices: xc7a100tfgg484-2I
// Tool versions:  vivado 2015.2
// Description: 串口发送模块
//              使用方法，通过clk,当wr_uart为高电平时，将w_data写入发送FIFO即可
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx_top
#(
	//默认设置
	//115200波特率，8位数据位宽，1位停止位，2的6次方的FIFO
	parameter  DBIT = 8,  	   //数据位宽
				  SB_TICK = 16,   //根据停止位宽不同脉冲计数值不同，
								      //对应停止位为1/1.5/2,则脉冲计数值分别为16/24/32
				  DVSR = 27,     //波特率分频值 DVSR = 50M/(16X波特率)
				  DVSR_BIT = 8,   //DVSR的位宽
				  FIFO_W = 6	   //FIFO地址位宽
									   //FIFO容量为2的6次方
)

(
    input wire clk,
    input wire reset,//低电平复位
	input wire [7:0]w_data,//发送FIFO的数据输入
	input wire wr_uart,//发送FIFO的数据输入使能
	output wire tx

    );
    
    
    wire tick,tx_done_tick;
    wire tx_empty,tx_fifo_not_empty;
    wire [7:0]tx_fifo_out;
    
    assign tx_fifo_not_empty = ~tx_empty;
 
//波特率产生单元
    mode_m_counter#(.M(DVSR),.N(DVSR_BIT))baud_gen_unit
    (.clk(clk),.reset(reset),.q(),.max_tick(tick));
    
//发送FIFO
     fifo#(.B(DBIT),.W(FIFO_W))fifo_tx_unit
     (.clk(clk),.reset(reset),.rd(tx_done_tick),
      .wr(wr_uart),.w_data(w_data),
      .empty(tx_empty),.full(tx_full),.r_data(tx_fifo_out));
      
 //发送单元
       uart_tx#(.DBIT(DBIT),.SB_TICK(SB_TICK))uart_tx_unit
       (.clk(clk),.reset(reset),.tx_start(tx_fifo_not_empty),
       .s_tick(tick),.din(tx_fifo_out),
       .tx_done_tick(tx_done_tick),.tx(tx));   
   
endmodule
