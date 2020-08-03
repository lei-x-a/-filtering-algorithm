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
// Description: ���ڷ���ģ��
//              ʹ�÷�����ͨ��clk,��wr_uartΪ�ߵ�ƽʱ����w_dataд�뷢��FIFO����
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx_top
#(
	//Ĭ������
	//115200�����ʣ�8λ����λ��1λֹͣλ��2��6�η���FIFO
	parameter  DBIT = 8,  	   //����λ��
				  SB_TICK = 16,   //����ֹͣλ��ͬ�������ֵ��ͬ��
								      //��ӦֹͣλΪ1/1.5/2,���������ֵ�ֱ�Ϊ16/24/32
				  DVSR = 27,     //�����ʷ�Ƶֵ DVSR = 50M/(16X������)
				  DVSR_BIT = 8,   //DVSR��λ��
				  FIFO_W = 6	   //FIFO��ַλ��
									   //FIFO����Ϊ2��6�η�
)

(
    input wire clk,
    input wire reset,//�͵�ƽ��λ
	input wire [7:0]w_data,//����FIFO����������
	input wire wr_uart,//����FIFO����������ʹ��
	output wire tx

    );
    
    
    wire tick,tx_done_tick;
    wire tx_empty,tx_fifo_not_empty;
    wire [7:0]tx_fifo_out;
    
    assign tx_fifo_not_empty = ~tx_empty;
 
//�����ʲ�����Ԫ
    mode_m_counter#(.M(DVSR),.N(DVSR_BIT))baud_gen_unit
    (.clk(clk),.reset(reset),.q(),.max_tick(tick));
    
//����FIFO
     fifo#(.B(DBIT),.W(FIFO_W))fifo_tx_unit
     (.clk(clk),.reset(reset),.rd(tx_done_tick),
      .wr(wr_uart),.w_data(w_data),
      .empty(tx_empty),.full(tx_full),.r_data(tx_fifo_out));
      
 //���͵�Ԫ
       uart_tx#(.DBIT(DBIT),.SB_TICK(SB_TICK))uart_tx_unit
       (.clk(clk),.reset(reset),.tx_start(tx_fifo_not_empty),
       .s_tick(tick),.din(tx_fifo_out),
       .tx_done_tick(tx_done_tick),.tx(tx));   
   
endmodule
