//////////////////////////////////////////////////////////////////////////////////
// Company: 		 Tronlong
// Engineer: 		 yuzhijun
//          
// Create Date:    14:43:40 11/1/2015
// Design Name:    ug480 
// Module Name:    ug480 
// Project Name:   xadc_test 
// Target Devices: xc7a100tfgg484-2
// Tool versions:  vivado 2015.2
// Description:    XADC寄存器读取,总共读取了十个寄存器，详见状态机对应关系或者"XADC值计算.xls"表
//                 可以加载程序，在线查看采集到XADC的值
//                  XADC的值在顶层通过串口发出
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// 接口使用方法：  当XADC_data_en==1时，DCLK上升沿去采集各寄存器的值（共十个）
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module ug480 (
    input DCLK, // Clock input for DRP 50MHZ
    input RESET,//低电平复位
    input [3:0] VAUXP, VAUXN,  // Auxiliary analog channel inputs，辅助模拟通道【3：0】
    input VAUXP8,VAUXN8,//辅助模拟通道8
    input VP, VN,// Dedicated and Hardwired Analog Input Pair,专用模拟通道
    
    //XADC数据采集使能信号，高有效（一个DCLK时钟）
    output reg       XADC_data_en,
    
    //XADC采集值输出，总共采集十个寄存器
    output reg [11:0] MEASURED_TEMP, MEASURED_VCCINT, 
    output reg [11:0] MEASURED_VCCAUX, MEASURED_VCCBRAM,
    output reg [11:0] MEASURED_AUX0, MEASURED_AUX1, 
    output reg [11:0] MEASURED_AUX2, MEASURED_AUX3,
    output reg [11:0] MEASURED_AUX8,
    output reg [11:0] MEASURED_AUX_VPN,
    
    //以下作为状态警告信号，选用
    output wire [7:0] ALM,//选用
    output wire [4:0]  CHANNEL,//选用       
    output wire        OT,//温度过高警告，选用
    output wire        EOC,//XADC转换结束标志，选用
    output wire        EOS,//XADC连续转换结束标志，选用
   
   //以下信号作输出，便于调试观察
   output   reg [7:0]   state = init_read,
   output   reg [1:0]   den_reg,
   output   reg [1:0]   dwe_reg,
   output   reg [6:0]   daddr,
   
   //以下信号连串口发送FIFO
   output   wire        tx_fifo_wr,
   output   wire  [11:0]tx_fifo_data,
   output   wire        chang_row_en
   
   
    );   
    
    

    wire busy;
    wire [5:0] channel;
    wire drdy;
    wire eoc;
    wire eos;
    wire i2c_sclk_in;
    wire i2c_sclk_ts;
    wire i2c_sda_in;
    wire i2c_sda_ts;
        
        
    //reg [6:0] daddr;
    reg [15:0] di_drp;
    wire [15:0] do_drp;
    wire [15:0] vauxp_active;
    wire [15:0] vauxn_active;
    wire dclk_bufg;
    
    reg [24:0]  delay_cnt;
    //reg [1:0]  den_reg;
    //reg [1:0]  dwe_reg;
    
    parameter    TIME_DELAY       = 10000000;//读十个值后，延时的时间，默认200ms
    //reg [7:0]   state = init_read;
    parameter     init_read       = 8'h00,
                    read_waitdrdy   = 8'h01,
                    write_waitdrdy  = 8'h03,
                    read_reg00      = 8'h04,
                    reg00_waitdrdy  = 8'h05,//读XADC状态寄存器0，对应芯片温度传感器
                    read_reg01      = 8'h06,
                    reg01_waitdrdy  = 8'h07,//读XADC状态寄存器1，对应VCCINT

                    read_reg02      = 8'h08,
                    reg02_waitdrdy  = 8'h09,//读XADC状态寄存器2，对应VCCAUX
                    
                    /*****add by yuzhijun******/
                    read_reg03      = 8'h14,
                    reg03_waitdrdy  = 8'h15,//读XADC状态寄存器3，对应VP，VN
                    /*************************/
                    
                    read_reg06      = 8'h0a,
                    reg06_waitdrdy  = 8'h0b,//读XADC状态寄存器6，对应VCCBRAM
                    read_reg10      = 8'h0c,
                    reg10_waitdrdy  = 8'h0d,//读XADC状态寄存器0x10，对应VAUXP[0],VAUXN[0],
                    read_reg11      = 8'h0e,
                    reg11_waitdrdy  = 8'h0f,//读XADC状态寄存器0x11，对应VAUXP[1],VAUXN[1],
                    read_reg12      = 8'h10,
                    reg12_waitdrdy  = 8'h11,//读XADC状态寄存器0x12，对应VAUXP[2],VAUXN[2],
                    read_reg13      = 8'h12,
                    reg13_waitdrdy  = 8'h13,//读XADC状态寄存器0x13，对应VAUXP[3],VAUXN[3],
                    
                    /*****add by yuzhijun******/
                    read_reg18      = 8'h16,
                    reg18_waitdrdy  = 8'h17,//读XADC状态寄存器0x18，对应VAUXP[8],VAUXN[8],
                    s_delay         = 8'h18,
                    stop            = 8'h19;
                                       
    //生成串口发送FIFO的信号
    assign          tx_fifo_wr      = drdy;
    assign          tx_fifo_data    = do_drp[15:4];
    //生成一个使能，该使能用于将一个数据包头（0xFF）打入串口
    assign          chang_row_en    = (state == stop);

   always @(posedge DCLK)
      if (!RESET) begin
         state   <= init_read;
         den_reg <= 2'h0;
         dwe_reg <= 2'h0;
         di_drp  <= 16'h0000;
      end
      else
         case (state)
         init_read : begin
            daddr <= 7'h40;
            den_reg <= 2'h2; // performing read
            if (busy == 0 ) state <= read_waitdrdy;
            end
         read_waitdrdy : 
            if (eos ==1)  	begin
               di_drp <= do_drp  & 16'h03_FF; //Clearing AVG bits for Configreg0
               daddr <= 7'h40;
               den_reg <= 2'h2;
               dwe_reg <= 2'h2; // performing write
               state <= write_waitdrdy;
            end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;
               state <= state;                
            end
         write_waitdrdy : 
            if (drdy ==1) begin
               state <= read_reg00;
               end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
         read_reg00 : begin
            daddr   <= 7'h00;
            den_reg <= 2'h2; // performing read
            if (eos == 1) state   <=reg00_waitdrdy;
            end
         reg00_waitdrdy : 
            if (drdy ==1)  	begin
               MEASURED_TEMP <= do_drp[15:4]; //IP核数据端口高12位为XADC采集的值
               state <=read_reg01;
               end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
         read_reg01 : begin
            daddr   <= 7'h01;
            den_reg <= 2'h2; // performing read
            state   <=reg01_waitdrdy;
            end
            reg01_waitdrdy : 
           if (drdy ==1)  	begin
               MEASURED_VCCINT = do_drp[15:4]; 
               state <=read_reg02;
               end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
         read_reg02 : begin
            daddr   <= 7'h02;
            den_reg <= 2'h2; // performing read
            state   <=reg02_waitdrdy;
            end
         reg02_waitdrdy : 
            if (drdy ==1)  	begin
               MEASURED_VCCAUX <= do_drp[15:4]; 
               state <=read_reg03;
               end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
         //ADD BY YUZHIJUN
         read_reg03 : begin
                daddr   <= 7'h03;
                den_reg <= 2'h2; // performing read
                state   <=reg03_waitdrdy;
                end
         reg03_waitdrdy : 
              if (drdy ==1) begin
                 MEASURED_AUX_VPN <= do_drp[15:4]; 
                 state <=read_reg06;
                 end
               else begin
                  den_reg <= { 1'b0, den_reg[1] } ;
                  dwe_reg <= { 1'b0, dwe_reg[1] } ;      
                  state <= state;          
                  end
         /*******************/
         
         read_reg06 : begin
            daddr   <= 7'h06;
            den_reg <= 2'h2; // performing read
            state   <=reg06_waitdrdy;
            end
         reg06_waitdrdy : 
            if (drdy ==1)  	begin
               MEASURED_VCCBRAM <= do_drp[15:4]; 
               state <= read_reg10;
            end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
         read_reg10 : begin
               daddr   <= 7'h10;
               den_reg <= 2'h2; // performing read
               state   <= reg10_waitdrdy;
            end
         reg10_waitdrdy : 
            if (drdy ==1)  	begin
               MEASURED_AUX0 <= do_drp[15:4]; 
               state <= read_reg11;
            end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
         read_reg11 : begin
            daddr   <= 7'h11;
            den_reg <= 2'h2; // performing read
            state   <= reg11_waitdrdy;
            end
         reg11_waitdrdy : 
            if (drdy ==1)  	begin
               MEASURED_AUX1 <= do_drp[15:4]; 
               state <= read_reg12;
               end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
         read_reg12 : begin
            daddr   <= 7'h12;
            den_reg <= 2'h2; // performing read
            state   <= reg12_waitdrdy;
            end
         reg12_waitdrdy : 
            if (drdy ==1)  	begin
               MEASURED_AUX2 <= do_drp[15:4]; 
               state <= read_reg13;
               end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
         read_reg13 : begin
            daddr   <= 7'h13;
            den_reg <= 2'h2; // performing read
            state   <= reg13_waitdrdy;
            end
         reg13_waitdrdy :
            if (drdy ==1)  	begin
               MEASURED_AUX3 <= do_drp[15:4]; 
               state <=read_reg18;
            end
            else begin
               den_reg <= { 1'b0, den_reg[1] } ;
               dwe_reg <= { 1'b0, dwe_reg[1] } ;      
               state <= state;          
            end
          
          //ADD BY YUZHIJUN  
          read_reg18 : begin
              daddr   <= 7'h18;
              den_reg <= 2'h2; // performing read
              state   <= reg18_waitdrdy;
              end
          reg18_waitdrdy :
               if (drdy ==1) begin
                   MEASURED_AUX8 <= do_drp[15:4]; 
                   state <= s_delay;//read_reg00;
                   daddr   <= 7'h00;
                   end
                else begin
                   den_reg <= { 1'b0, den_reg[1] } ;
                   dwe_reg <= { 1'b0, dwe_reg[1] } ;      
                   state <= state;          
                   end
          s_delay:
                if(delay_cnt == TIME_DELAY)
                begin
                    state <= stop;
                    daddr <= 7'h00;
                end
                else
                begin
                    state <= s_delay;
                    daddr <= 7'h00;
                end
           stop:
                begin
                    state <= read_reg00;
                end
                
         default : begin
            daddr <= 7'h40;
            den_reg <= 2'h2; // performing read
            state <= init_read;
            end
         endcase
    
    //延时状态的时间控制，默认200ms
    always @ (posedge DCLK)
    begin
        if(state == s_delay)
            delay_cnt <= delay_cnt + 1'b1;
        else
            delay_cnt <= 25'b0;
    end

    always @ (posedge DCLK)
    begin
        XADC_data_en <= drdy;
    end
        
          

XADC #(// Initializing the XADC Control Registers
    .INIT_40(16'h9000),// averaging of 16 selected for external channels //9000
    .INIT_41(16'h8ef0),// Continuous Seq Mode, Disable unused ALMs, Enable calibration  //原来的值‘h2ef0
    .INIT_42(16'h0400),// Set DCLK divides
    .INIT_48(16'h4f01),// CHSEL1 - enable Temp VCCINT, VCCAUX, VCCBRAM, and calibration
    .INIT_49(16'h010f),// CHSEL2 - enable aux analog channels 0 - 3 //原来的值’h000f
    .INIT_4A(16'h0000),// SEQAVG1 disabled
    .INIT_4B(16'h0000),// SEQAVG2 disabled
    .INIT_4C(16'h0000),// SEQINMODE0 
    .INIT_4D(16'h0000),// SEQINMODE1
    .INIT_4E(16'h0000),// SEQACQ0
    .INIT_4F(16'h0000),// SEQACQ1
    .INIT_50(16'hb5ed),// Temp upper alarm trigger 85癈
    .INIT_51(16'h5999),// Vccint upper alarm limit 1.05V
    .INIT_52(16'hA147),// Vccaux upper alarm limit 1.89V
    .INIT_53(16'hdddd),// OT upper alarm limit 125癈 - see Thermal Management
    .INIT_54(16'ha93a),// Temp lower alarm reset 60癈
    .INIT_55(16'h5111),// Vccint lower alarm limit 0.95V
    .INIT_56(16'h91Eb),// Vccaux lower alarm limit 1.71V
    .INIT_57(16'hae4e),// OT lower alarm reset 70癈 - see Thermal Management
    .INIT_58(16'h5999),// VCCBRAM upper alarm limit 1.05V
    .SIM_MONITOR_FILE("c:/xilinx_test/XADC/source_file/design.txt")// Analog Stimulus file for simulation
)
XADC_INST (// Connect up instance IO. See UG480 for port descriptions
    .CONVST (1'b0),// not used
    .CONVSTCLK  (1'b0), // not used
    .DADDR  (daddr),
    .DCLK   (DCLK),
    .DEN    (den_reg[0]),
    .DI     (di_drp),
    .DWE    (dwe_reg[0]),
    .RESET  (!RESET),
    .VAUXN  (vauxn_active ),
    .VAUXP  (vauxp_active ),
    .ALM    (ALM),
    .BUSY   (busy),
    .CHANNEL(CHANNEL),
    .DO     (do_drp),
    .DRDY   (drdy),
    .EOC    (eoc),
    .EOS    (eos),
    .JTAGBUSY   (),// not used
    .JTAGLOCKED (),// not used
    .JTAGMODIFIED   (),// not used
    .OT     (OT),
    .MUXADDR    (),// not used
    .VP     (VP),
    .VN     (VN)
);

    assign vauxp_active = {7'b000000,VAUXP8,4'b0000,VAUXP[3:0]};
    assign vauxn_active = {7'b000000,VAUXN8,4'b0000,VAUXN[3:0]};

    assign EOC = eoc;
    assign EOS = eos;

endmodule