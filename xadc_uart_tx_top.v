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
// Description:    �ö���ģ����ɽ�XADC�ɵ���ֵ���봮��FIFO����ͨ�����ڷ���
//                  ע��ADCֵ12λ����ģ�齫�䵱��16λ��������λ��0��
//                  �ܹ���ֵʮ��ADֵ����20���ֽڣ�ʮ��ADֵ������μ���XADCֵ����.xls��
//                  ���ڷ��ͣ��Դ����ʽ������ÿ��21�ֽڡ�����20�ֽڵ����ݰ�ǰ��������һ���ֽڵİ�ͷ��0x0a��,Ϊ�˻�����ʾ��
//                  ÿ��һ������ʱ200ms���ٷ���һ�������ѭ��
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
    input RESET,//�͵�ƽ��λ                                                                
    input [3:0] VAUXP, VAUXN,  // Auxiliary analog channel inputs������ģ��ͨ����3��0��          
    input VAUXP8,VAUXN8,//����ģ��ͨ��8                                                      
    input VP, VN,// Dedicated and Hardwired Analog Input Pair,ר��ģ��ͨ��
                       
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
            
//���໷   
clk_wiz_0       u_clk_wiz_0
(
    .clk_in1        (CLK),
    .clk_out1       (clk_50mhz)
    );
    
//XADC��ȡģ��
ug480           u_ug480
(
    .DCLK           (clk_50mhz), // Clock input for DRP 50MHZ                                           
    .RESET          (RESET),//�͵�ƽ��λ                                                                
    .VAUXP          (VAUXP), // Auxiliary analog channel inputs������ģ��ͨ����3��0��    
    .VAUXN          (VAUXN),  // Auxiliary analog channel inputs������ģ��ͨ����3��0��          
    .VAUXP8         (VAUXP8),
    .VAUXN8         (VAUXN8),//����ģ��ͨ��8                                                      
    .VP             (VP), 
    .VN             (VN),// Dedicated and Hardwired Analog Input Pair,ר��ģ��ͨ��                   
                                                                                       
    //XADC���ݲɼ�ʹ���źţ�����Ч��һ��DCLKʱ�ӣ�                                                       
    .XADC_data_en   (),                                                     
    //�����ź������ڷ���FIFO
    .tx_fifo_wr     (tx_fifo_wr),
    .tx_fifo_data   (tx_fifo_data),
    .chang_row_en   (chang_row_en)
    );
    
//���ڷ���ģ��  
uart_tx_top     u_uart_tx_top
(
    .clk        (clk_50mhz),
    .reset      (RESET),//�͵�ƽ��λ
    .w_data     (w_data),//����FIFO����������
    .wr_uart    (wr_uart),//����FIFO����������ʹ��
    .tx         (tx)
    );
    
    //��ԭ����һ���ֽڵ�ʹ�ֳܷ����ֽ�ʹ��
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
    
    
    //��12λ��ADCֵ�������ֽڴ�������λ��0,�ҽ�ʮ������ֵת��ASCII��
    //ע�����ֽڵ�ʮ��������ת��ASCII�뽫������ֽ�
    always @ (posedge clk_50mhz)
    begin
        //ADC[15:12]����λ����0��λ����0ֵתASCII
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
            w_data <= 8'h0a;//��ͷֵ�����з�
    end
    
    assign      wr_uart     = tx_fifo_wr_reg0 | tx_fifo_wr_reg2 | tx_fifo_wr_reg4 | tx_fifo_wr_reg6 | chang_row_en;
        
    
    
endmodule
