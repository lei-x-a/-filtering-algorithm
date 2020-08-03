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
// Description:    ģM�����������ڲ��������ʣ������ϲ���޸�
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
	parameter N=4, //������λ��
				 M=10 //ģ10������
)
(
	input wire clk, reset,
	output wire max_tick,
	output wire [N-1:0]q
);

//�ź�����
reg  [N-1:0]r_reg;
wire  [N-1:0]r_next;
//���岿��
//�Ĵ�������
always@(posedge clk,negedge reset)
	if(!reset)
		r_reg<=0;
	else
		r_reg<=r_next;
//��һ״̬�߼�
assign r_next = (r_reg==(M-1))?1'b0:r_reg+1'b1;

//����߼�
assign q = r_reg;
assign max_tick = (r_reg==(M-1))?1'b1:1'b0;
endmodule
