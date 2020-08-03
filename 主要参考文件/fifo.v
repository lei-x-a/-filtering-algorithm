`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        Tronlong
// Engineer:       Felix
// 
// Create Date:    18:51:52 12/12/2013 
// Design Name:    uart_test
// Module Name:    fifo 
// Project Name:   uart_test
// Target Devices: xa7a100tfgg484-2I
// Tool versions:  vivado 2015.2
// Description:     FIFO��СĬ��Ϊ4���ֽڣ��ɸ���ʵ����Ҫ�޸�B��Wֵ
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fifo
#(
	parameter B=8,//����λ��
				 W=3 //��ַλ��
)
(
	input  wire clk, reset,
	input  wire rd, wr,
	input  wire [B-1:0]w_data,
	output wire empty, full,
	output wire [B-1:0]r_data
);

//�ź�����
reg[B-1:0]array_reg[2**W-1:0];//�Ĵ�������
reg[W-1:0]w_ptr_reg, w_ptr_next,	w_ptr_succ;
reg[W-1:0]r_ptr_reg, r_ptr_next,	r_ptr_succ;
reg full_reg, empty_reg, full_next,	empty_next;
wire wr_en;

//���岿��

//�Ĵ����ļ�д����
always @(posedge clk)
	if(wr_en)
		array_reg[w_ptr_reg] <= w_data;
		
//�Ĵ����ļ�������
assign r_data = array_reg[r_ptr_reg];

//������ʱ��дʹ����Ч
assign wr_en = wr&~full_reg;
 
//FIFO�����߼�

//�Ĵ�����дָ��
always @(posedge clk, negedge reset)
	if(!reset)
		begin
			w_ptr_reg <= 0;
			r_ptr_reg <= 0;
			full_reg  <= 1'b0;
			empty_reg <= 1'b1;
		end
	else
		begin
			w_ptr_reg <= w_ptr_next;
			r_ptr_reg <= r_ptr_next;
			full_reg  <= full_next;
			empty_reg <= empty_next;
		end
		
//��дָ�����һ״̬�߼�
always @*
	begin 
		//ָ���1����
		w_ptr_succ = w_ptr_reg + 1'b1;
		r_ptr_succ = r_ptr_reg + 1'b1;
		//Ĭ�ϱ���ԭֵ
		w_ptr_next = w_ptr_reg;
		r_ptr_next = r_ptr_reg;
		full_next  = full_reg;
		empty_next = empty_reg;
		case({wr,rd})
			//2'b00:��������
			2'b01://������
				if(~empty_reg)//�ǿ�
					begin
						r_ptr_next = r_ptr_succ;
						full_next = 1'b0;
						if(r_ptr_succ == w_ptr_reg)
							empty_next = 1'b1;
					end
			2'b10://д����
				if(~full_reg)//����
					begin
						w_ptr_next = w_ptr_succ;
						empty_next = 1'b0;
						if(w_ptr_succ == r_ptr_reg)
							full_next = 1'b1;
					end
			2'b11://д�Ͷ�
				begin
					w_ptr_next = w_ptr_succ;
					r_ptr_next = r_ptr_succ;
				end
		endcase	
	end

//���
assign full = full_reg;
assign empty = empty_reg;

endmodule


