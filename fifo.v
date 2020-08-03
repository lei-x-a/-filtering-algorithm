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
// Description:     FIFO大小默认为4个字节，可根据实际需要修改B和W值
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
	parameter B=8,//数据位宽
				 W=3 //地址位宽
)
(
	input  wire clk, reset,
	input  wire rd, wr,
	input  wire [B-1:0]w_data,
	output wire empty, full,
	output wire [B-1:0]r_data
);

//信号声明
reg[B-1:0]array_reg[2**W-1:0];//寄存器数组
reg[W-1:0]w_ptr_reg, w_ptr_next,	w_ptr_succ;
reg[W-1:0]r_ptr_reg, r_ptr_next,	r_ptr_succ;
reg full_reg, empty_reg, full_next,	empty_next;
wire wr_en;

//主体部分

//寄存器文件写操作
always @(posedge clk)
	if(wr_en)
		array_reg[w_ptr_reg] <= w_data;
		
//寄存器文件读操作
assign r_data = array_reg[r_ptr_reg];

//不满的时候写使能有效
assign wr_en = wr&~full_reg;
 
//FIFO控制逻辑

//寄存器读写指针
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
		
//读写指针的下一状态逻辑
always @*
	begin 
		//指针加1操作
		w_ptr_succ = w_ptr_reg + 1'b1;
		r_ptr_succ = r_ptr_reg + 1'b1;
		//默认保持原值
		w_ptr_next = w_ptr_reg;
		r_ptr_next = r_ptr_reg;
		full_next  = full_reg;
		empty_next = empty_reg;
		case({wr,rd})
			//2'b00:不做操作
			2'b01://读操作
				if(~empty_reg)//非空
					begin
						r_ptr_next = r_ptr_succ;
						full_next = 1'b0;
						if(r_ptr_succ == w_ptr_reg)
							empty_next = 1'b1;
					end
			2'b10://写操作
				if(~full_reg)//非满
					begin
						w_ptr_next = w_ptr_succ;
						empty_next = 1'b0;
						if(w_ptr_succ == r_ptr_reg)
							full_next = 1'b1;
					end
			2'b11://写和读
				begin
					w_ptr_next = w_ptr_succ;
					r_ptr_next = r_ptr_succ;
				end
		endcase	
	end

//输出
assign full = full_reg;
assign empty = empty_reg;

endmodule


