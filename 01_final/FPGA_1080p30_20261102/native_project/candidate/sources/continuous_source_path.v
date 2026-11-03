`timescale 1ns/1ps
`default_nettype none
module continuous_source_path #(
 parameter MARKER_MODE=1,LOW_LATENCY_ADMISSION=0,ADMISSION_FAST_FPS=60,
 parameter SRC_W=1920,SRC_H=1080,MIN_PIXELS=64,MAX_PIXELS=16384,MAX_SPAN=256,FIFO_ADDR_BITS=9,
 parameter BLACK_RMIN=0,BLACK_RMAX=64,BLACK_GMIN=0,BLACK_GMAX=64,BLACK_BMIN=0,BLACK_BMAX=64,
 parameter P0_XMIN=0,P0_XMAX=SRC_W/2-1,P0_YMIN=0,P0_YMAX=SRC_H/2-1,
 parameter P1_XMIN=SRC_W/2,P1_XMAX=SRC_W-1,P1_YMIN=0,P1_YMAX=SRC_H/2-1,
 parameter P2_XMIN=SRC_W/2,P2_XMAX=SRC_W-1,P2_YMIN=SRC_H/2,P2_YMAX=SRC_H-1,
 parameter P3_XMIN=0,P3_XMAX=SRC_W/2-1,P3_YMIN=SRC_H/2,P3_YMAX=SRC_H-1,
 parameter IN_W=1920,IN_H=1080,DATA_FIFO_ADDR_BITS=10,BURST_BEATS=8,PROC_CYCLES_PER_MS=54000,
 parameter[27:0]SOURCE_BASE0=28'd0,SOURCE_BASE1=28'h0800000
)(

 input wire rx_clk,proc_clk,ui_clk,rst_n,enabled,raw_requested,rx_vs,rx_de,input wire[23:0]rx_rgb,
 output wire frame_valid,input wire frame_ready,output wire frame_bank,
 output wire[31:0]frame_generation,output wire[95:0]frame_corners,output wire frame_geometry_valid,
 output wire[DATA_FIFO_ADDR_BITS:0]data_fifo_peak,output wire[31:0]frame_capture_ms,output wire[511:0]reject_reason_counts,output wire[31:0]admitted_frames,
 input wire release_valid,release_bank,input wire[31:0]release_generation,
 output wire[31:0]rejected_frames,dropped_frames,output wire[3:0]last_failure_reason,output wire fault,output wire[3:0]fault_components,
 output wire cmd_valid,input wire cmd_ready,output wire cmd_write,output wire[27:0]cmd_addr,
 output wire[255:0]cmd_wdata,output wire[31:0]cmd_wstrb,output wire[BURST_BEATS*256-1:0]cmd_burst_data,
 input wire rsp_valid,rsp_write
);
 wire packet_valid,packet_ready;wire[319:0]packet;
 wire terminal_valid,terminal_ready;wire[37:0]terminal_data;
 wire sample_valid,sample_first,sample_bank,close_valid,close_bank,close_ok;
 wire[11:0]sample_x,sample_y;wire[31:0]sample_generation,close_generation;wire[3:0]close_reason;
 wire credit_valid,credit_ready,credit_bank;wire[31:0]credit_generation;
 wire rx_fault,writer_fault,manager_fault,geometry_fault;
 wire[31:0]dropped_rx,admitted_rx;
 (* ASYNC_REG="TRUE" *)reg[2:0]rx_fault_sync,writer_fault_sync;
 (* ASYNC_REG="TRUE" *)reg[31:0]drop_gray_q0,drop_gray_q1,drop_gray_q2;
 (* ASYNC_REG="TRUE" *)reg[31:0]admit_gray_q0,admit_gray_q1,admit_gray_q2;
 reg[31:0]drop_gray,admit_gray;
 always @(posedge rx_clk or negedge rst_n)begin
 if(!rst_n)begin drop_gray<=0;admit_gray<=0;end
 else begin drop_gray<=(dropped_rx>>1)^dropped_rx;admit_gray<=(admitted_rx>>1)^admitted_rx;end
 end
 genvar bit_n;
 generate for(bit_n=0;bit_n<32;bit_n=bit_n+1)begin: drop_decode
 assign dropped_frames[bit_n]=^(drop_gray_q2>>bit_n);
 assign admitted_frames[bit_n]=^(admit_gray_q2>>bit_n);
 end endgenerate
 always @(posedge proc_clk or negedge rst_n)begin
 if(!rst_n)begin rx_fault_sync<=0;writer_fault_sync<=0;drop_gray_q0<=0;drop_gray_q1<=0;drop_gray_q2<=0;admit_gray_q0<=0;admit_gray_q1<=0;admit_gray_q2<=0;end
 else begin rx_fault_sync<={rx_fault_sync[1:0],rx_fault};writer_fault_sync<={writer_fault_sync[1:0],writer_fault};drop_gray_q0<=drop_gray;drop_gray_q1<=drop_gray_q0;drop_gray_q2<=drop_gray_q1;admit_gray_q0<=admit_gray;admit_gray_q1<=admit_gray_q0;admit_gray_q2<=admit_gray_q1;end
 end
 assign fault_components={geometry_fault,manager_fault,writer_fault_sync[2],rx_fault_sync[2]};
 assign fault=rx_fault_sync[2]||writer_fault_sync[2]||manager_fault||geometry_fault;
 // Admission changes BEGIN only. The capture receiver completes the active
 // frame and emits its terminal record even while this enable is low.
 wire capture_enabled,capture_begin,capture_blocked;
 generate if(LOW_LATENCY_ADMISSION)begin: late_admission
  wire permit;
  capture_admission_control #(.PROC_CYCLES_PER_MS(PROC_CYCLES_PER_MS),.FAST_FPS(ADMISSION_FAST_FPS)) admission(
   .proc_clk(proc_clk),.rx_clk(rx_clk),.rst_n(rst_n),.raw_requested(raw_requested),.rx_vs(rx_vs),
   .rearm((frame_valid&&frame_ready)||(terminal_valid&&terminal_ready&&!terminal_data[4])),.ready_source_pending(frame_valid),
   .frame_begin(capture_begin),.frame_blocked(capture_blocked),.bad_close(close_valid&&!close_ok),.permit(permit));
  assign capture_enabled=enabled&&permit;
 end else begin: normal_admission
  assign capture_enabled=enabled;
 end endgenerate
 continuous_capture_rx #(.IN_W(IN_W),.IN_H(IN_H),.SRC_W(SRC_W),.SRC_H(SRC_H)) capture(
 .clk(rx_clk),.rst_n(rst_n),.enabled(capture_enabled),.rx_vs(rx_vs),.rx_de(rx_de),.rx_rgb(rx_rgb),
 .release_valid(credit_valid),.release_bank(credit_bank),.release_generation(credit_generation),
 .packet_valid(packet_valid),.packet_ready(packet_ready),.packet_data(packet),
 .sample_valid(sample_valid),.sample_first(sample_first),.sample_x(sample_x),.sample_y(sample_y),.sample_bank(sample_bank),.sample_generation(sample_generation),
 .close_valid(close_valid),.close_bank(close_bank),.close_ok(close_ok),.close_generation(close_generation),.close_reason(close_reason),
 .dropped_frames(dropped_rx),.admitted_frames(admitted_rx),.fault(rx_fault),.owned_banks(),.frame_begin(capture_begin),.frame_blocked(capture_blocked));
 assign credit_ready=1'b1;
 wire alloc_valid,alloc_ready;wire[32:0]alloc_data;
 wire ui_packet_valid,ui_packet_ready;wire[319:0]ui_packet;
 wire queue_ready,alloc_source_ready;wire[DATA_FIFO_ADDR_BITS:0]rx_fifo_peak;
 snapshot_cdc #(.WIDTH(DATA_FIFO_ADDR_BITS+1)) fifo_peak_crossing(.s_clk(rx_clk),.d_clk(proc_clk),.rst_n(rst_n),.s_data(rx_fifo_peak),.d_data(data_fifo_peak),.d_valid());
 wire is_begin=packet[319:318]==0;
 assign packet_ready=queue_ready&&(!is_begin||alloc_source_ready);
 async_packet_stream_monitored #(.DATA_WIDTH(320),.ADDR_BITS(DATA_FIFO_ADDR_BITS)) data_crossing(
 .wr_clk(rx_clk),.rd_clk(ui_clk),.rst_n(rst_n),
 .wr_peak(rx_fifo_peak),.s_valid(packet_valid&&(!is_begin||alloc_source_ready)),.s_ready(queue_ready),.s_data(packet),
 .m_valid(ui_packet_valid),.m_ready(ui_packet_ready),.m_data(ui_packet));
 async_packet_stream #(.DATA_WIDTH(33),.ADDR_BITS(2)) allocation_crossing(
 .wr_clk(rx_clk),.rd_clk(proc_clk),.rst_n(rst_n),
 .s_valid(packet_valid&&is_begin&&queue_ready),.s_ready(alloc_source_ready),.s_data(packet[317:285]),
 .m_valid(alloc_valid),.m_ready(alloc_ready),.m_data(alloc_data));
 wire writer_terminal_valid,writer_terminal_ready;wire[37:0]writer_terminal;
 continuous_capture_writer #(.SRC_W(SRC_W),.SRC_H(SRC_H),.BURST_BEATS(BURST_BEATS),.SOURCE_BASE0(SOURCE_BASE0),.SOURCE_BASE1(SOURCE_BASE1)) writer(
 .clk(ui_clk),.rst_n(rst_n),.packet_valid(ui_packet_valid),.packet_ready(ui_packet_ready),.packet_data(ui_packet),
 .cmd_valid(cmd_valid),.cmd_ready(cmd_ready),.cmd_write(cmd_write),.cmd_addr(cmd_addr),.cmd_wdata(cmd_wdata),.cmd_wstrb(cmd_wstrb),.cmd_burst_data(cmd_burst_data),
 .rsp_valid(rsp_valid),.rsp_write(rsp_write),.terminal_valid(writer_terminal_valid),.terminal_ready(writer_terminal_ready),.terminal_data(writer_terminal),.fault(writer_fault));
 async_packet_stream #(.DATA_WIDTH(38),.ADDR_BITS(2)) completion_crossing(
 .wr_clk(ui_clk),.rd_clk(proc_clk),.rst_n(rst_n),
 .s_valid(writer_terminal_valid),.s_ready(writer_terminal_ready),.s_data(writer_terminal),
 .m_valid(terminal_valid),.m_ready(terminal_ready),.m_data(terminal_data));
 wire metadata_valid,metadata_ready;wire[129:0]metadata_data;
 // Fixed lens profile uses no marker metadata. Admission remains gated by
 // the complete source frame and terminal DDR writer ACK in the manager.
 // Do not clock an unused pixel/marker CDC path or make it a fault source.
 assign metadata_valid=1'b0;
 assign metadata_data=130'd0;
 assign geometry_fault=1'b0;
 wire return_valid,return_ready;wire[32:0]return_data;
 continuous_capture_manager #(.PROC_CYCLES_PER_MS(PROC_CYCLES_PER_MS)) manager(
 .clk(proc_clk),.rst_n(rst_n),.raw_requested(1'b1),.allocation_valid(alloc_valid),.allocation_ready(alloc_ready),.allocation_data(alloc_data),
 .terminal_valid(terminal_valid),.terminal_ready(terminal_ready),.terminal_data(terminal_data),
 .metadata_valid(metadata_valid),.metadata_ready(metadata_ready),.metadata_data(metadata_data),
 .frame_valid(frame_valid),.frame_ready(frame_ready),.frame_bank(frame_bank),.frame_generation(frame_generation),.frame_corners(frame_corners),.frame_geometry_valid(frame_geometry_valid),
 .frame_capture_ms(frame_capture_ms),.reject_reason_counts(reject_reason_counts),
 .release_valid(release_valid),.release_bank(release_bank),.release_generation(release_generation),
 .return_valid(return_valid),.return_ready(return_ready),.return_data(return_data),
 .rejected_frames(rejected_frames),.last_failure_reason(last_failure_reason),.fault(manager_fault));
 async_packet_stream #(.DATA_WIDTH(33),.ADDR_BITS(2)) credit_crossing(
 .wr_clk(proc_clk),.rd_clk(rx_clk),.rst_n(rst_n),
 .s_valid(return_valid),.s_ready(return_ready),.s_data(return_data),
 .m_valid(credit_valid),.m_ready(credit_ready),.m_data({credit_bank,credit_generation}));
endmodule

// One BEGIN permit is replenished by an actual source-descriptor acceptance.
// In the measured fast-input/corrected mode this prevents capture of the frame
// immediately following the source currently entering processing. Its next VS
// is already past before the acceptance round trip can replenish the permit.
// RAW and input rates below FAST_FPS retain original continuous admission.
// Default60 restricts this experiment to measured >=60fps input. In particular
// 59.94,55,50 and30fps must keep continuous admission to avoid a sub30fps cap.
module capture_admission_control #(
 parameter PROC_CYCLES_PER_MS=54000,FAST_FPS=60
)(
 input wire proc_clk,rx_clk,rst_n,raw_requested,rx_vs,rearm,ready_source_pending,frame_begin,frame_blocked,bad_close,
 output wire permit
);
 localparam integer FAST_LIMIT=PROC_CYCLES_PER_MS*1000/FAST_FPS;
 reg rx_vs_d,vs_toggle;
 always @(posedge rx_clk or negedge rst_n)begin
  if(!rst_n)begin rx_vs_d<=0;vs_toggle<=0;end
  else begin rx_vs_d<=rx_vs;if(rx_vs&&!rx_vs_d)vs_toggle<=~vs_toggle;end
 end
 (* ASYNC_REG="TRUE" *)reg[2:0]vs_sync;
 reg vs_seen,have_start,fast_input;
 reg[31:0]period_ticks;
 // Saturation also detects disappearance/slowing of the input before its
 // next VS. The next slow frame is therefore never suppressed by stale rate.
 always @(posedge proc_clk or negedge rst_n)begin
  if(!rst_n)begin vs_sync<=0;vs_seen<=0;have_start<=0;period_ticks<=0;fast_input<=0;end
  else begin
   vs_sync<={vs_sync[1:0],vs_toggle};
   if(period_ticks<FAST_LIMIT+1)period_ticks<=period_ticks+1'b1;
   if(period_ticks>=FAST_LIMIT)fast_input<=0;
   if(vs_sync[2]!=vs_seen)begin
    vs_seen<=vs_sync[2];have_start<=1;period_ticks<=0;
    fast_input<=have_start&&period_ticks+1<=FAST_LIMIT;
   end
  end
 end
 // Acknowledged event mailbox. An event held while the mailbox is busy is
 // coalesced into one pending permit, never a counted backlog of early frames.
 reg request_toggle,rearm_pending;
 (* ASYNC_REG="TRUE" *)reg[2:0]ack_sync;
 reg ack_toggle;
 always @(posedge proc_clk or negedge rst_n)begin
  if(!rst_n)begin request_toggle<=0;rearm_pending<=0;ack_sync<=0;end
  else begin
   ack_sync<={ack_sync[1:0],ack_toggle};
   if(rearm)rearm_pending<=1;
   if(request_toggle==ack_sync[2]&&rearm_pending)begin
    request_toggle<=~request_toggle;rearm_pending<=rearm;
   end
  end
 end
 (* ASYNC_REG="TRUE" *)reg[2:0]request_sync,fast_sync,raw_sync,ready_sync;
 reg token,bootstrap_pending,active_d,begin_d;
 reg[1:0]missed_vs;
 reg[31:0]recovery_grants;
 // Internal diagnostic only. The public capture dropped_frames counter keeps
 // its original no-free-bank meaning; this counts VS held by admission policy.
 reg[31:0]suppressed_frames;
 wire active=fast_sync[2]&&!raw_sync[2];
 // Consume only final synchronizer stages. Remember a coincident BEGIN so
 // the delayed local entry observation cannot regrant an already consumed
 // bootstrap on the following edge.
 wire entering_active=active&&!active_d;
 // Ordinary grants may expire while a processing source and the previous
 // RAW display lease occupy both banks. Their later releases do not generate
 // another acceptance event. Two consecutive VS without a successful BEGIN
 // restore one persistent bootstrap, covering that transition and bad-frame
 // retry/credit races. Normal60->30 cadence has a BEGIN at every second VS.
 wire recover_permit=active&&rx_vs&&!rx_vs_d&&missed_vs>=1&&!ready_sync[2]&&
                     !bootstrap_pending&&(!token||frame_blocked);
 wire new_permit=request_sync[2]!=ack_toggle;
 assign permit=!active||token;
 always @(posedge rx_clk or negedge rst_n)begin
  if(!rst_n)begin request_sync<=0;fast_sync<=0;raw_sync<=0;ready_sync<=0;ack_toggle<=0;token<=1;bootstrap_pending<=1;active_d<=0;begin_d<=0;missed_vs<=0;recovery_grants<=0;suppressed_frames<=0;end
  else begin
   request_sync<={request_sync[1:0],request_toggle};
   fast_sync<={fast_sync[1:0],fast_input};
   raw_sync<={raw_sync[1:0],raw_requested};
   ready_sync<={ready_sync[1:0],ready_source_pending};
   active_d<=active;begin_d<=frame_begin;
   if(!active||frame_begin)missed_vs<=0;
   else if(rx_vs&&!rx_vs_d&&missed_vs<2)missed_vs<=missed_vs+1'b1;
   if(rx_vs&&!rx_vs_d&&active&&!token)suppressed_frames<=suppressed_frames+1'b1;
   if(!active)begin token<=1;bootstrap_pending<=1;end
   if(new_permit)begin ack_toggle<=request_sync[2];token<=1;end
   if(bad_close)token<=1;
   // A mode-entry bootstrap must survive an occupied-bank VS. In particular,
   // the last RAW publication can own both banks until display ACK, without
   // any later descriptor acceptance available to rearm an expired token.
   // Once a BEGIN succeeds, ordinary per-frame grants still expire on a
   // blocked opportunity, preserving the low-latency phase selection.
   // Successful BEGIN has priority even on the mode-entry edge itself.
   if(frame_begin)begin token<=0;bootstrap_pending<=0;end
   else if(entering_active&&!begin_d)begin token<=1;bootstrap_pending<=1;end
   else if(recover_permit)begin token<=1;bootstrap_pending<=1;recovery_grants<=recovery_grants+1'b1;end
   else if(frame_blocked&&!bootstrap_pending)token<=0;
  end
 end
 // synthesis translate_off
 initial if(FAST_FPS<1||PROC_CYCLES_PER_MS<1||FAST_LIMIT<8)$fatal(1,"invalid admission rate parameters");
 // synthesis translate_on
endmodule
`default_nettype wire
