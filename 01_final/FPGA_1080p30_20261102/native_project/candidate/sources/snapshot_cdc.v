`timescale 1ns/1ps
`default_nettype none
// Atomic latest-state snapshot. Payload is held until the destination ACK;
// updates may coalesce. Both endpoints require common asynchronous reset.
module snapshot_cdc #(parameter WIDTH=32)(
 input wire s_clk,d_clk,rst_n,input wire[WIDTH-1:0]s_data,
 output reg[WIDTH-1:0]d_data,output reg d_valid
);
 wire s_rst_n,d_rst_n;
 // Keep each local release chain independent through synthesis and Device Map.
 // The shared reset still asserts asynchronously when either clock is stopped.
 snapshot_cdc_local_reset source_release(
  .clk(s_clk),.arst_n(rst_n),.local_rst_n(s_rst_n));
 snapshot_cdc_local_reset destination_release(
  .clk(d_clk),.arst_n(rst_n),.local_rst_n(d_rst_n));
 reg[WIDTH-1:0]held;reg request,ack;
 (* ASYNC_REG="TRUE" *)reg[2:0]ack_sync,req_sync;
 always @(posedge s_clk or negedge s_rst_n)begin
 if(!s_rst_n)begin held<=0;request<=0;ack_sync<=0;end
 else begin ack_sync<={ack_sync[1:0],ack};if(ack_sync[2]==request)begin held<=s_data;request<=~request;end end
 end
 always @(posedge d_clk or negedge d_rst_n)begin
 if(!d_rst_n)begin d_data<=0;d_valid<=0;ack<=0;req_sync<=0;end
 else begin req_sync<={req_sync[1:0],request};if(req_sync[2]!=ack)begin d_data<=held;d_valid<=1;ack<=req_sync[2];end end
 end
endmodule

module snapshot_cdc_local_reset(input wire clk,arst_n,output wire local_rst_n);
 (* ASYNC_REG="TRUE" *) reg[1:0]release_pipe /* synthesis syn_preserve=1 syn_allow_retiming=0 */;
 always @(posedge clk or negedge arst_n)begin
  if(!arst_n)release_pipe<=0;
  else release_pipe<={release_pipe[0],1'b1};
 end
 assign local_rst_n=release_pipe[1];
endmodule
`default_nettype wire
