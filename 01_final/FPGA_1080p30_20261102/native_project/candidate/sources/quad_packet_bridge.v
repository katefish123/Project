`timescale 1ns/1ps
`default_nettype none
module quad_packet_bridge #(
 parameter SRC_W=1920,SRC_H=1080,OUT_W=768,OUT_H=1080,FIFO_ADDR_BITS=9
)(
 input wire proc_clk,ui_clk,rst_n,
 input wire q_valid,output wire q_ready,input wire q_inside,q_nearest,
 input wire[23:0]q_addr00,q_addr10,q_addr01,q_addr11,q_tag,
 input wire[7:0]q_fx,q_fy,input wire[31:0]q_generation,input wire[27:0]q_base,
 output reg fault,
 output wire req_valid,input wire req_ready,
 output wire[27:0]req_base,output wire[31:0]req_generation,
 output wire[11:0]req_x,req_y,output wire req_nearest,req_inside,
 output wire[23:0]req_tag,output wire[7:0]req_fx,req_fy,
 input wire rsp_valid,output wire rsp_ready,input wire rsp_inside,
 input wire[23:0]rsp_p00,rsp_p10,rsp_p01,rsp_p11,rsp_tag,
 input wire[7:0]rsp_fx,rsp_fy,input wire[31:0]rsp_generation,
 output wire r_valid,input wire r_ready,output wire r_inside,
 output wire[23:0]r_p00,r_p10,r_p01,r_p11,r_tag,
 output wire[7:0]r_fx,r_fy,output wire[31:0]r_generation
);
 // Five elastic stages separate capture, reciprocal product, exact decode,
 // expected neighbours and validation/packet construction. All sustain one packet
 // per proc clock; a stall holds the full descriptor with its decoded position.
 reg raw_valid,divide_valid,decoded_valid,verify_valid,packet_valid;
 reg[197:0]raw_payload;reg[245:0]decoded_payload;reg[125:0]packet_payload;
 wire packet_ready;
 wire cooked_ready=!packet_valid||packet_ready;
 wire verify_ready=!verify_valid||cooked_ready;
 wire decoded_ready=!decoded_valid||verify_ready;
 wire divide_ready=!divide_valid||decoded_ready;
 assign q_ready=rst_n&&(!raw_valid||divide_ready);
 wire[23:0]raw_addr00=raw_payload[137:114];
 
 //1920=128*15. For all65536 unsigned16-bit values n,
 // floor(n/15)=(n*34953)>>19. All legal1920x<=4096 source addresses
 // have bit23=0; that bit remains in the descriptor's independent range check.
 localparam FAST_DECODE=(SRC_W==1920&&SRC_H<=4096);
 reg[197:0]divide_payload;reg[31:0]divide_product;
 wire[31:0]raw_product=raw_addr00[22:7]*16'd34953;
 wire[23:0]divide_addr=divide_payload[137:114];
 wire[23:0]raw_y=FAST_DECODE?(divide_product>>19):(divide_addr/SRC_W);
 wire[23:0]remainder_words={8'd0,divide_addr[22:7]}-raw_y*24'd15;
 wire[23:0]raw_x=FAST_DECODE?{13'd0,remainder_words[3:0],divide_addr[6:0]}:(divide_addr%SRC_W);
 wire[27:0]h_base;wire[31:0]h_generation;
 wire[23:0]h_addr00,h_addr10,h_addr01,h_addr11,h_tag;
 wire[7:0]h_fx,h_fy;wire h_inside,h_nearest;
 assign {h_base,h_generation,h_addr00,h_addr10,h_addr01,h_addr11,h_tag,h_fx,h_fy,h_inside,h_nearest}=decoded_payload[245:48];
 wire[23:0]source_x=decoded_payload[47:24],source_y=decoded_payload[23:0];
 wire[23:0]next_x=!h_nearest&&source_x<SRC_W-1?source_x+1:source_x;
 wire[23:0]next_y=!h_nearest&&source_y<SRC_H-1?source_y+1:source_y;
 // Preserve the original32-bit neighbour equations. Arithmetic and equality /
 // sticky-fault fanout cross separate registers; no range guard is weakened.
 reg[197:0]verify_payload;
 reg[23:0]verify_x,verify_y;
 reg[31:0]expected10,expected01,expected11;
 reg verify_bad_tag,verify_out_of_range;
 wire[27:0]v_base;wire[31:0]v_generation;
 wire[23:0]v_addr00,v_addr10,v_addr01,v_addr11,v_tag;
 wire[7:0]v_fx,v_fy;wire v_inside,v_nearest;
 assign {v_base,v_generation,v_addr00,v_addr10,v_addr01,v_addr11,v_tag,v_fx,v_fy,v_inside,v_nearest}=verify_payload;
 wire bad_address=v_inside&&(verify_out_of_range||
  {8'd0,v_addr10}!=expected10||{8'd0,v_addr01}!=expected01||{8'd0,v_addr11}!=expected11);
 wire inside_checked=v_inside&&!bad_address&&!verify_bad_tag;
 wire[11:0]checked_x=inside_checked?verify_x[11:0]:12'd0;
 wire[11:0]checked_y=inside_checked?verify_y[11:0]:12'd0;
 always @(posedge proc_clk or negedge rst_n)begin
  if(!rst_n)begin fault<=0;raw_valid<=0;divide_valid<=0;divide_payload<=0;divide_product<=0;decoded_valid<=0;verify_valid<=0;verify_payload<=0;verify_x<=0;verify_y<=0;expected10<=0;expected01<=0;expected11<=0;verify_bad_tag<=0;verify_out_of_range<=0;packet_valid<=0;raw_payload<=0;decoded_payload<=0;packet_payload<=0;end
  else begin
   if(cooked_ready)begin
    packet_valid<=verify_valid;
    if(verify_valid)begin
     packet_payload<={v_base,v_generation,checked_x,checked_y,v_nearest,inside_checked,v_tag,v_fx,v_fy};
     if(verify_bad_tag||bad_address)fault<=1;
    end
   end
   if(verify_ready)begin
    verify_valid<=decoded_valid;
    if(decoded_valid)begin
     verify_payload<=decoded_payload[245:48];verify_x<=source_x;verify_y<=source_y;
     expected10<=source_y*SRC_W+next_x;
     expected01<=next_y*SRC_W+source_x;
     expected11<=next_y*SRC_W+next_x;
     verify_bad_tag<=h_tag[11:0]>=OUT_W||h_tag[23:12]>=OUT_H;
     verify_out_of_range<=h_addr00>=SRC_W*SRC_H;
    end
   end
   if(decoded_ready)begin
    decoded_valid<=divide_valid;
    if(divide_valid)decoded_payload<={divide_payload,raw_x,raw_y};
   end
   if(divide_ready)begin
    divide_valid<=raw_valid;
    if(raw_valid)begin divide_payload<=raw_payload;divide_product<=raw_product;end
   end
   if(q_ready)begin
    raw_valid<=q_valid;
    if(q_valid)raw_payload<={q_base,q_generation,q_addr00,q_addr10,q_addr01,q_addr11,q_tag,q_fx,q_fy,q_inside,q_nearest};
   end
  end
 end
 async_packet_stream #(.DATA_WIDTH(126),.ADDR_BITS(FIFO_ADDR_BITS)) requests(
 .wr_clk(proc_clk),.rd_clk(ui_clk),.rst_n(rst_n),
 .s_valid(packet_valid),.s_ready(packet_ready),.s_data(packet_payload),
 .m_valid(req_valid),.m_ready(req_ready),.m_data({req_base,req_generation,req_x,req_y,req_nearest,req_inside,req_tag,req_fx,req_fy}));
 async_packet_stream #(.DATA_WIDTH(169),.ADDR_BITS(FIFO_ADDR_BITS)) responses(
 .wr_clk(ui_clk),.rd_clk(proc_clk),.rst_n(rst_n),
 .s_valid(rsp_valid),.s_ready(rsp_ready),.s_data({rsp_generation,rsp_inside,rsp_p00,rsp_p10,rsp_p01,rsp_p11,rsp_tag,rsp_fx,rsp_fy}),
 .m_valid(r_valid),.m_ready(r_ready),.m_data({r_generation,r_inside,r_p00,r_p10,r_p01,r_p11,r_tag,r_fx,r_fy}));
endmodule
`default_nettype wire
