`timescale 1ns/1ps
`default_nettype none
// UI-clock four-neighbour cache. Addresses are 32-bit source WORD addresses.
// Tiles are128x2 pixels; paired64-pixel reads reuse one128-pixel engine prefetch.
// Source rows must be multiples of128 words and frame height a multiple of2.
// Fill interface returns one aligned128-word row per command. Shared hard
// reset must also reset its owner/DDR engine; soft abort does not reset cache.
module ddr_quad_tile_cache #(
 parameter SRC_W=1920, SRC_H=1080, LINES=64, WATCHDOG_CYCLES=8192
)(
 input wire clk,rst_n,
 input wire req_valid, output wire req_ready,
 input wire[27:0]req_base,input wire[31:0]req_generation,
 input wire[11:0]req_x,req_y,input wire req_inside,req_nearest,
 input wire[23:0]req_tag,input wire[7:0]req_fx,req_fy,
 output wire rsp_valid,input wire rsp_ready,output reg rsp_inside,
 output reg[23:0]rsp_p00,rsp_p10,rsp_p01,rsp_p11,rsp_tag,
 output reg[7:0]rsp_fx,rsp_fy,output reg[31:0]rsp_generation,
 output wire cmd_valid,input wire cmd_ready,output wire cmd_block,
 output wire[27:0]cmd_addr,
 input wire mem_rsp_valid,mem_rsp_write,input wire[4095:0]rsp_block,
 output reg fault
);
 localparam WB=$clog2(LINES),AB=WB+5;
 localparam[2:0]F_IDLE=0,F_CMD=1,F_WAIT=2,F_WRITE=3,F_PREP=4,F_SELECT=5,F_CAPTURE=6;
 // Each bank has one write port and the two registered read ports used
 // by the proven cache. Paired fill words have fixed even/odd addresses.
 // DDR source words contain RGB in bits 23:0. Drop each word's unused
 // high byte before storage, preserving all eight pixels per RAM entry.
 (* ram_style="block" *) reg[191:0]ram_even[0:LINES*16-1];
 (* ram_style="block" *) reg[191:0]ram_odd[0:LINES*16-1];
 reg[191:0]even_a,even_b,odd_a,odd_b;
 reg bank_a,bank_b;
 wire[191:0]read_a=bank_a?odd_a:even_a;
 wire[191:0]read_b=bank_b?odd_b:even_b;
 // Keep pixel selection as an explicit eight-way mux. A variable shift by
 // offset*24 would expose unnecessary multiply/add logic to synthesis.
 function[23:0]select_rgb;
  input[191:0]block_rgb;
  input[2:0]offset;
  begin
   case(offset)
    3'd0:select_rgb=block_rgb[23:0];
    3'd1:select_rgb=block_rgb[47:24];
    3'd2:select_rgb=block_rgb[71:48];
    3'd3:select_rgb=block_rgb[95:72];
    3'd4:select_rgb=block_rgb[119:96];
    3'd5:select_rgb=block_rgb[143:120];
    3'd6:select_rgb=block_rgb[167:144];
    3'd7:select_rgb=block_rgb[191:168];
    default:select_rgb=24'hxxxxxx;
   endcase
  end
 endfunction
 reg[LINES-1:0]line_valid;
 // Requests are ordered. A new immutable source-generation key invalidates
 // all tags before its lookup; per-way tags then need only tile coordinates.
 // New frame invalidation waits for the old L RAM issue. M/N/R retain their
 // data independently, and a miss fill waits for M to drain.
 reg[15:0]tags[0:LINES-1];
 reg[59:0]frame_key;
 reg invalidate_pending;
 reg[WB-1:0]replace_way,fill_way;
 reg[75:0]fill_tag;reg[27:0]fill_addr;
 reg fill_victim_found;
 reg[2:0]fill_state;reg fill_row;
 reg[3:0]fill_word;
 reg[3071:0]fill_data;reg[3071:0]incoming_data;
 wire[3071:0]packed_rsp_block;
 genvar rgb_lane;
 generate for(rgb_lane=0;rgb_lane<128;rgb_lane=rgb_lane+1)begin: pack_rgb
  assign packed_rsp_block[rgb_lane*24+:24]=rsp_block[rgb_lane*32+:24];
 end endgenerate
 reg[31:0]watchdog;
 reg s_valid,s_inside,s_nearest;
 reg[27:0]s_base;reg[31:0]s_generation;
 reg[11:0]s_x,s_y,s_x1,s_y1;reg[23:0]s_tag;reg[7:0]s_fx,s_fy;
 // L holds a registered lookup decision and RAM addresses. Neither RAM CE
 // nor input capacity depends on the current combinational tag lookup.
 reg l_valid,l_inside,l_missing,l_relookup,l_lookup_wait,l_boundary;
 reg[27:0]l_base;reg[31:0]l_generation;
 reg[11:0]l_x,l_y,l_x1,l_y1;reg[23:0]l_tag;reg[7:0]l_fx,l_fy;
 reg[2:0]l_left_offset,l_right_offset;
 reg[AB-1:0]l_left_a,l_left_b,l_right_a,l_right_b;
 // Preserve lookup-time protection, replacement pointer and corner.
 // Only misses consume the registered decision tails at fill_start.
 reg[LINES-1:0]l_protected_ways;reg[WB-1:0]l_replace_way;
 reg[1:0]l_miss_corner;
 reg[WB-1:0]l_victim;reg l_victim_found;
 reg[4:0]fill_protection;reg[WB-1:0]fill_replace;integer protection_lane;
 reg m_valid,m_inside,m_boundary,m_phase;
 reg[23:0]m_tag;reg[31:0]m_generation;
 reg[7:0]m_fx,m_fy;reg[2:0]m_left_offset,m_right_offset;
 reg[AB-1:0]m_right_a,m_right_b;
 // N owns complete selected RAM words. Bank selection and the final
 // eight-pixel extraction now cross separate registers. Boundary requests
 // retain their left words before the second RAM read replaces the outputs.
 reg[191:0]left_top_block,left_bot_block;
 reg n_valid,n_inside;
 reg[23:0]n_tag;reg[31:0]n_generation;
 reg[7:0]n_fx,n_fy;reg[2:0]n_left_offset,n_right_offset;
 reg[191:0]n_left_top,n_left_bot,n_right_top,n_right_bot;
 reg r_valid;
 wire r_space=!r_valid||rsp_ready;
 wire n_complete=n_valid&&r_space;
 wire n_space=!n_valid||n_complete;
 wire m_complete=m_valid&&(!m_boundary||m_phase)&&n_space;
 wire m_space=!m_valid||m_complete;
 // The input S slot and retained miss L slot have independent tag compares.
 // Their results are consumed only by their own existing transfer/relookup
 // enables. In particular l_missing no longer selects coordinates that pass
 // through all comparators before feeding back into l_missing itself.
 // Share each row comparison across left/right and each column comparison
 // across top/bottom. S and retained-L remain independent lookup banks.
 reg[LINES-1:0]s_top_match,s_bottom_match,s_left_match,s_right_match;
 reg[LINES-1:0]l_top_match,l_bottom_match,l_left_match,l_right_match;
 reg[WB-1:0]s_ways[0:3],l_ways[0:3];
 reg[3:0]s_hits,l_hits;
 reg[LINES-1:0]s_protected_ways,l_lookup_protected_ways;
 reg s_missing,l_lookup_missing;
 reg[1:0]s_missing_corner,l_lookup_missing_corner;
 // Tag compares are captured with the accepted request. This separates
 // the128-way hit encoding from coordinate/tag comparison while retaining
 // one request per cycle on hits. Held requests refresh their matches while
 // a fill is in flight; re-lookup waits for the new tags to reach this stage.
 wire accept_req=req_valid&&req_ready;
 wire[11:0]probe_x=accept_req?req_x:s_x;
 wire[11:0]probe_y=accept_req?req_y:s_y;
 wire[11:0]probe_x1=accept_req?((req_nearest||req_x==SRC_W-1)?req_x:req_x+1'b1):s_x1;
 wire[11:0]probe_y1=accept_req?((req_nearest||req_y==SRC_H-1)?req_y:req_y+1'b1):s_y1;
 integer match_way;
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
   s_top_match<=0;s_bottom_match<=0;s_left_match<=0;s_right_match<=0;
   l_top_match<=0;l_bottom_match<=0;l_left_match<=0;l_right_match<=0;
  end else for(match_way=0;match_way<LINES;match_way=match_way+1)begin
   s_top_match[match_way]<=!invalidate_pending&&line_valid[match_way]&&tags[match_way][15:5]==probe_y[11:1];
   s_bottom_match[match_way]<=!invalidate_pending&&line_valid[match_way]&&tags[match_way][15:5]==probe_y1[11:1];
   s_left_match[match_way]<=tags[match_way][4:0]==probe_x[11:7];
   s_right_match[match_way]<=tags[match_way][4:0]==probe_x1[11:7];
   l_top_match[match_way]<=line_valid[match_way]&&tags[match_way][15:5]==l_y[11:1];
   l_bottom_match[match_way]<=line_valid[match_way]&&tags[match_way][15:5]==l_y1[11:1];
   l_left_match[match_way]<=tags[match_way][4:0]==l_x[11:7];
   l_right_match[match_way]<=tags[match_way][4:0]==l_x1[11:7];
  end
 end
 integer p,w;
 always @*begin
  s_hits=0;l_hits=0;s_protected_ways=0;l_lookup_protected_ways=0;
  for(p=0;p<4;p=p+1)begin
   s_ways[p]=0;l_ways[p]=0;
   // Keep the original unique-hit OR encoding and four-state IF semantics.
   for(w=0;w<LINES;w=w+1)begin
    if((p[1]?s_bottom_match[w]:s_top_match[w])&&(p[0]?s_right_match[w]:s_left_match[w]))begin s_hits[p]=1;s_ways[p]=s_ways[p]|w;s_protected_ways[w]=1;end
    if((p[1]?l_bottom_match[w]:l_top_match[w])&&(p[0]?l_right_match[w]:l_left_match[w]))begin l_hits[p]=1;l_ways[p]=l_ways[p]|w;l_lookup_protected_ways[w]=1;end
   end
  end
  s_missing=0;s_missing_corner=0;l_lookup_missing=0;l_lookup_missing_corner=0;
  for(p=3;p>=0;p=p-1)begin
   if(!s_hits[p])begin s_missing=1;s_missing_corner=p;end
   if(!l_hits[p])begin l_lookup_missing=1;l_lookup_missing_corner=p;end
  end
 end
 // A miss-only stage captures five protected-way tests before the priority
 // encoder. Candidate order and modulo replacement remain unchanged.
 integer lv;
 always @*begin
  l_victim_found=0;l_victim=fill_replace;
  for(lv=0;lv<5;lv=lv+1)if(!l_victim_found&&!fill_protection[lv])begin l_victim=(fill_replace+lv)%LINES;l_victim_found=1;end
 end
 wire[75:0]l_selected_miss_tag={l_generation,l_base,
  (l_miss_corner[1]?l_y1[11:1]:l_y[11:1]),
  (l_miss_corner[0]?l_x1[11:7]:l_x[11:7])};
 wire l_advance=l_valid&&!l_missing&&!l_relookup&&m_space&&fill_state==F_IDLE&&!fault&&!invalidate_pending;
 wire l_space=!l_valid||l_advance;
 wire s_key_change=s_valid&&l_space&&fill_state==F_IDLE&&frame_key!={s_generation,s_base}&&!fault&&!invalidate_pending;
 wire s_advance=s_valid&&l_space&&fill_state==F_IDLE&&frame_key=={s_generation,s_base}&&!fault&&!invalidate_pending;
 wire fill_start=l_valid&&l_inside&&l_missing&&!l_relookup&&!m_valid&&fill_state==F_IDLE&&!fault&&!invalidate_pending;
 assign req_ready=rst_n&&!fault&&!invalidate_pending&&fill_state==F_IDLE&&(!s_valid||s_advance);
 assign rsp_valid=rst_n&&!fault&&r_valid;
 assign cmd_valid=rst_n&&!fault&&fill_state==F_CMD;
 assign cmd_block=1'b1;
 // Prepare row0 during the existing miss-only F_PREP cycle. Later rows
 // advance at the final RAM write, keeping command arithmetic local to cache.
 assign cmd_addr=fill_addr;
 wire[AB-1:0]s_left_a={s_ways[0],s_y[0],s_x[6:3]};
 wire[AB-1:0]s_left_b={s_ways[2],s_y1[0],s_x[6:3]};
 wire[AB-1:0]s_right_a={s_ways[1],s_y[0],s_x1[6:3]};
 wire[AB-1:0]s_right_b={s_ways[3],s_y1[0],s_x1[6:3]};
 wire[AB-1:0]lookup_left_a={l_ways[0],l_y[0],l_x[6:3]};
 wire[AB-1:0]lookup_left_b={l_ways[2],l_y1[0],l_x[6:3]};
 wire[AB-1:0]lookup_right_a={l_ways[1],l_y[0],l_x1[6:3]};
 wire[AB-1:0]lookup_right_b={l_ways[3],l_y1[0],l_x1[6:3]};
 wire read_right=m_valid&&m_boundary&&!m_phase;
 wire read_en=(read_right||(l_advance&&l_inside))&&!fault;
 wire[AB-1:0]read_addr_a=read_right?m_right_a:l_left_a;
 wire[AB-1:0]read_addr_b=read_right?m_right_b:l_left_b;
 wire fill_we=fill_state==F_WRITE&&!fault;

 // The RAM address may be arbitrary when both enables are low. Select its
 // write address from state, leaving fault qualification on enables only.
 wire[AB-1:0]ram_port_a_addr=fill_state==F_WRITE?{fill_way,fill_row,fill_word}:read_addr_a;
 wire[AB-1:0]ram_port_b_addr=fill_state==F_WRITE?{fill_way,fill_row,fill_word[3:1],1'b1}:read_addr_b;
 // Until the response arrives, the fill buffer is private and unused.
 // Sample it throughout WAIT; the accepted response edge still captures the
 // same data before WRITE. A sticky fault suppresses all observable activity.
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin fill_data<=0;incoming_data<=0;end
  else begin
   if(fill_state==F_WAIT)incoming_data<=packed_rsp_block;
   if(fill_state==F_WRITE)fill_data<={384'd0,fill_data[3071:384]};
   else if(fill_state==F_CAPTURE)fill_data<=incoming_data;
  end
 end
 // Two even/odd banks fill concurrently. Each uses the original
 // inferable single-write/two-read structure. RAM/data outputs have no reset.
 always @(posedge clk)begin
  if(fill_we)ram_even[ram_port_a_addr[AB-1:1]]<=fill_data[191:0];
  else if(read_en)even_a<=ram_even[read_addr_a[AB-1:1]];
  if(read_en)even_b<=ram_even[read_addr_b[AB-1:1]];
 end
 always @(posedge clk)begin
  if(fill_we)ram_odd[ram_port_a_addr[AB-1:1]]<=fill_data[383:192];
  else if(read_en)odd_a<=ram_odd[read_addr_a[AB-1:1]];
  if(read_en)odd_b<=ram_odd[read_addr_b[AB-1:1]];
 end
 // Select the bank with the same registered read latency as the RAM data.
 always @(posedge clk)if(read_en)begin
  bank_a<=read_addr_a[0];bank_b<=read_addr_b[0];
 end

 // These are private payload registers: VALID owns their observability,
 // so no reset or global fault signal is needed on the wide data enables.
 always @(posedge clk)begin
  if(read_right)begin left_top_block<=read_a;left_bot_block<=read_b;end
  if(n_space)begin
   n_left_top<=m_boundary?left_top_block:read_a;
   n_left_bot<=m_boundary?left_bot_block:read_b;
   n_right_top<=read_a;n_right_bot<=read_b;
  end
 end

 // An empty/advancing L slot may receive speculative lookup decisions.
 // l_valid alone determines whether those decisions can be consumed.
 // This removes s_valid/frame-key/fill admission from the decision FF enables.
 // Re-lookup of a retained miss keeps priority and the original cycle timing.
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin l_missing<=0;l_miss_corner<=0;end
  else if(!invalidate_pending&&l_relookup&&!l_lookup_wait&&fill_state==F_IDLE)begin
   l_missing<=l_lookup_missing;l_miss_corner<=l_lookup_missing_corner;
  end else if(!invalidate_pending&&l_space)begin
   l_missing<=s_inside&&s_missing;l_miss_corner<=s_missing_corner;
  end
 end
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
   line_valid<=0;frame_key<=0;invalidate_pending<=0;replace_way<=0;fill_way<=0;fill_tag<=0;fill_addr<=0;fill_state<=F_IDLE;fill_victim_found<=0;fill_protection<=0;fill_replace<=0;fill_row<=0;fill_word<=0;watchdog<=0;fault<=0;
   s_valid<=0;s_inside<=0;s_nearest<=0;s_base<=0;s_generation<=0;s_x<=0;s_y<=0;s_x1<=0;s_y1<=0;s_tag<=0;s_fx<=0;s_fy<=0;
   l_valid<=0;l_inside<=0;l_relookup<=0;l_lookup_wait<=0;l_boundary<=0;
   l_base<=0;l_generation<=0;l_x<=0;l_y<=0;l_x1<=0;l_y1<=0;l_tag<=0;l_fx<=0;l_fy<=0;l_left_offset<=0;l_right_offset<=0;
   l_left_a<=0;l_left_b<=0;l_right_a<=0;l_right_b<=0;l_protected_ways<=0;l_replace_way<=0;
   m_valid<=0;m_inside<=0;m_boundary<=0;m_phase<=0;m_tag<=0;m_generation<=0;m_fx<=0;m_fy<=0;m_left_offset<=0;m_right_offset<=0;m_right_a<=0;m_right_b<=0;
   n_valid<=0;n_inside<=0;n_tag<=0;n_generation<=0;n_fx<=0;n_fy<=0;n_left_offset<=0;n_right_offset<=0;
   r_valid<=0;rsp_inside<=0;rsp_p00<=0;rsp_p10<=0;rsp_p01<=0;rsp_p11<=0;rsp_tag<=0;rsp_generation<=0;rsp_fx<=0;rsp_fy<=0;
  end else if(!fault)begin
   if(l_lookup_wait&&fill_state==F_IDLE)l_lookup_wait<=0;
   if(r_valid&&rsp_ready)r_valid<=0;
   if(n_complete)begin
    r_valid<=1;rsp_inside<=n_inside;rsp_tag<=n_tag;rsp_generation<=n_generation;rsp_fx<=n_fx;rsp_fy<=n_fy;n_valid<=0;
    if(!n_inside)begin rsp_p00<=0;rsp_p10<=0;rsp_p01<=0;rsp_p11<=0;end
    else begin
     rsp_p00<=select_rgb(n_left_top,n_left_offset);rsp_p01<=select_rgb(n_left_bot,n_left_offset);
     rsp_p10<=select_rgb(n_right_top,n_right_offset);rsp_p11<=select_rgb(n_right_bot,n_right_offset);
    end
   end
   if(m_complete)begin
    n_valid<=1;n_inside<=m_inside;n_tag<=m_tag;n_generation<=m_generation;n_fx<=m_fx;n_fy<=m_fy;
    n_left_offset<=m_left_offset;n_right_offset<=m_right_offset;m_valid<=0;
   end
   if(read_right)m_phase<=1;
   if(l_advance)begin
    l_valid<=0;m_valid<=1;m_inside<=l_inside;m_tag<=l_tag;m_generation<=l_generation;m_fx<=l_fx;m_fy<=l_fy;m_phase<=0;
    m_left_offset<=l_left_offset;m_right_offset<=l_right_offset;m_right_a<=l_right_a;m_right_b<=l_right_b;
    m_boundary<=l_boundary;
   end
   if(s_advance)begin
    s_valid<=0;l_valid<=1;l_inside<=s_inside;l_base<=s_base;l_generation<=s_generation;l_x<=s_x;l_y<=s_y;l_x1<=s_x1;l_y1<=s_y1;
    l_tag<=s_tag;l_fx<=s_fx;l_fy<=s_fy;l_left_offset<=s_x[2:0];l_right_offset<=s_x1[2:0];
    l_boundary<=s_inside&&(s_x[11:3]!=s_x1[11:3]);
    l_left_a<=s_left_a;l_left_b<=s_left_b;l_right_a<=s_right_a;l_right_b<=s_right_b;
    l_relookup<=0;l_protected_ways<=s_protected_ways;l_replace_way<=replace_way;
   end
   // A fill changes tags/ways. Recompute and register all lookup/replacement
   // results before the retained L may issue a read or request another fill.
   if(!invalidate_pending&&l_relookup&&!l_lookup_wait&&fill_state==F_IDLE)begin
    l_relookup<=0;
    l_left_a<=lookup_left_a;l_left_b<=lookup_left_b;l_right_a<=lookup_right_a;l_right_b<=lookup_right_b;
    l_protected_ways<=l_lookup_protected_ways;l_replace_way<=replace_way;
   end
   // The old L request may still issue its RAM read on the key-change edge.
   // Register that decision before clearing all valid bits. The pending
   // cycle holds S/L/fill while M/N/R (including a boundary read) may drain.
   // Only after the clear may the new-generation S request enter lookup L.
   if(s_key_change)begin frame_key<={s_generation,s_base};invalidate_pending<=1;end
   if(invalidate_pending)begin line_valid<=0;invalidate_pending<=0;end
   if(req_valid&&req_ready)begin
    s_valid<=1;s_inside<=req_inside;s_nearest<=req_nearest;s_base<=req_base;s_generation<=req_generation;s_x<=req_x;s_y<=req_y;s_tag<=req_tag;s_fx<=req_fx;s_fy<=req_fy;
    s_x1<=(req_nearest||req_x==SRC_W-1)?req_x:req_x+1'b1;
    s_y1<=(req_nearest||req_y==SRC_H-1)?req_y:req_y+1'b1;
    if(req_inside&&(req_x>=SRC_W||req_y>=SRC_H||req_base[6:0]!=0||{1'b0,req_base}+SRC_W*SRC_H>29'h10000000))fault<=1;
   end
   if(fill_start)begin
    // Register replacement success as well as its index. The measured V2B
    // critical path was tags -> protected ways -> victim_found -> fill-row CE.
    // This check belongs to the following miss-only preparation stage.
    fill_replace<=l_replace_way;
    for(protection_lane=0;protection_lane<5;protection_lane=protection_lane+1)
     fill_protection[protection_lane]<=l_protected_ways[(l_replace_way+protection_lane)%LINES];
    fill_tag<=l_selected_miss_tag;fill_row<=0;fill_state<=F_SELECT;watchdog<=0;
   end
   if(fill_state==F_CMD||fill_state==F_WAIT)begin
    watchdog<=watchdog+1'b1;
    if(watchdog>=WATCHDOG_CYCLES-1)fault<=1;
   end

   case(fill_state)
    F_SELECT:begin fill_way<=l_victim;fill_victim_found<=l_victim_found;fill_state<=F_PREP;end
    F_PREP:begin
     if(!fill_victim_found)fault<=1;
     else begin
      fill_addr<=fill_tag[43:16]+(fill_tag[15:5]*2*SRC_W)+{fill_tag[4:0],7'b0};
      line_valid[fill_way]<=0;fill_state<=F_CMD;watchdog<=0;
     end
    end
    F_CMD:if(cmd_ready)begin fill_state<=F_WAIT;watchdog<=0;end
    F_WAIT:if(mem_rsp_valid)begin
     if(mem_rsp_write)fault<=1;
     else begin fill_word<=0;fill_state<=F_CAPTURE;watchdog<=0;end
    end
    F_CAPTURE:fill_state<=F_WRITE;
    F_WRITE:if(fill_word==14)begin
     if(fill_row==1)begin tags[fill_way]<=fill_tag[15:0];line_valid[fill_way]<=1;replace_way<=fill_way+1'b1;fill_state<=F_IDLE;l_relookup<=1;l_lookup_wait<=1;end
     else begin fill_addr<=fill_addr+SRC_W;fill_row<=fill_row+1'b1;fill_state<=F_CMD;watchdog<=0;end
    end else fill_word<=fill_word+4'd2;
    default:begin end
   endcase
  end
 end
endmodule
`default_nettype wire
