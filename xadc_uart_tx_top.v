`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2015/11/23 20:29:16
// Design Name: 
// Module Name: xadc_uart_tx_top
// Project Name: 
// Target Devices: xc7a100tfgg484-2I
// Tool versions:  vivado 2015.2
// Description:    该顶层模块完成将XADC采到的值填入串口FIFO，并通过串口发出
//                  注：ADC值12位，该模块将其当作16位处理，高四位补0，
//                  总共采值十个AD值，共20个字节，十个AD值含义请参见“XADC值计算.xls”
//                  串口发送，以打包形式发出，每包21字节。【在20字节的数据包前，加入了一个字节的包头（0x0a）,为了换行显示】
//                  每发一包，延时200ms，再发下一包，如此循环
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module xadc_uart_tx_top
(
    input CLK, // 25MHZ                                           
    input RESET,//低电平复位                                                                
    input [3:0] VAUXP, VAUXN,  // Auxiliary analog channel inputs，辅助模拟通道【3：0】          
    input VAUXP8,VAUXN8,//辅助模拟通道8                                                      
    input VP, VN,// Dedicated and Hardwired Analog Input Pair,专用模拟通道
                       
    output tx                                                                               
                                                                                                         
    );
    
    wire            wr_uart;
    wire            tx_fifo_wr;
    wire [11:0]     tx_fifo_data;
    
    reg  [7:0]      w_data;
    reg             tx_fifo_wr_reg0;
    reg             tx_fifo_wr_reg1;
    reg             tx_fifo_wr_reg2;
    reg             tx_fifo_wr_reg3;
    reg             tx_fifo_wr_reg4;
    reg             tx_fifo_wr_reg5;
    reg             tx_fifo_wr_reg6;
            
//锁相环   
clk_wiz_0       u_clk_wiz_0
(
    .clk_in1        (CLK),
    .clk_out1       (clk_50mhz)
    );
    
//XADC读取模块
ug480           u_ug480
(
    .DCLK           (clk_50mhz), // Clock input for DRP 50MHZ                                           
    .RESET          (RESET),//低电平复位                                                                
    .VAUXP          (VAUXP), // Auxiliary analog channel inputs，辅助模拟通道【3：0】    
    .VAUXN          (VAUXN),  // Auxiliary analog channel inputs，辅助模拟通道【3：0】          
    .VAUXP8         (VAUXP8),
    .VAUXN8         (VAUXN8),//辅助模拟通道8                                                      
    .VP             (VP), 
    .VN             (VN),// Dedicated and Hardwired Analog Input Pair,专用模拟通道                   
                                                                                       
    //XADC数据采集使能信号，高有效（一个DCLK时钟）                                                       
    .XADC_data_en   (),                                                     
    //以下信号连串口发送FIFO
    .tx_fifo_wr     (tx_fifo_wr),
    .tx_fifo_data   (tx_fifo_data),
    .chang_row_en   (chang_row_en)
    );
    
//串口发送模块  
uart_tx_top     u_uart_tx_top
(
    .clk        (clk_50mhz),
    .reset      (RESET),//低电平复位
    .w_data     (w_data),//发送FIFO的数据输入
    .wr_uart    (wr_uart),//发送FIFO的数据输入使能
    .tx         (tx)
    );
    
    //将原来的一个字节的使能分成两字节使能
    always @ (posedge clk_50mhz)
    begin
        tx_fifo_wr_reg0 <= tx_fifo_wr;
        tx_fifo_wr_reg1 <= tx_fifo_wr_reg0;
        tx_fifo_wr_reg2 <= tx_fifo_wr_reg1;
        tx_fifo_wr_reg3 <= tx_fifo_wr_reg2;
        tx_fifo_wr_reg4 <= tx_fifo_wr_reg3;
        tx_fifo_wr_reg5 <= tx_fifo_wr_reg4;
        tx_fifo_wr_reg6 <= tx_fifo_wr_reg5;
    end
    
    
    //将12位的ADC值当作两字节处理，高四位补0,且将十六进制值转成ASCII码
    //注：两字节的十六进制码转成ASCII码将变成四字节
    always @ (posedge clk_50mhz)
    begin
        //ADC[15:12]高四位（补0的位）的0值转ASCII
        if(tx_fifo_wr)
        begin
            w_data <= 4'h0 + 8'h30;
        end
        //ADC[11:8]
        else if(tx_fifo_wr_reg1)
        begin
            if((tx_fifo_data[11:8] >= 4'h0) && (tx_fifo_data[11:8] <= 4'h9))
                w_data <= tx_fifo_data[11:8] + 8'h30;
            else
                w_data <= tx_fifo_data[11:8] + 8'h57;
        end
        //ADC[7:4]
        else if(tx_fifo_wr_reg3)
        begin
             if((tx_fifo_data[7:4] >= 4'h0) && (tx_fifo_data[7:4] <= 4'h9))
                 w_data <= tx_fifo_data[7:4] + 8'h30;
             else
                 w_data <= tx_fifo_data[7:4] + 8'h57;
        end
        //ADC[3:0]
        else if(tx_fifo_wr_reg5)
        begin                                                              
             if((tx_fifo_data[3:0] >= 4'h0) && (tx_fifo_data[3:0] <= 4'h9))
                 w_data <= tx_fifo_data[3:0] + 8'h30;                      
             else                                                          
                 w_data <= tx_fifo_data[3:0] + 8'h57;                      
        end                                                                
        else
            w_data <= 8'h0a;//包头值，换行符
    end
    
    assign      wr_uart     = tx_fifo_wr_reg0 | tx_fifo_wr_reg2 | tx_fifo_wr_reg4 | tx_fifo_wr_reg6 | chang_row_en;
        
    
    
endmodule
