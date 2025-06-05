module divider(
  input wire                      calculation_clk,

  input  wire                      rst_n,
  input  wire                      slow_clk,
  input  logic [7:0]               denominator_i ,
  input  logic [7:0]               numerator_i   ,
  output logic [7:0]               remainder_o   ,
  output logic [7:0]               quotient_o    ,
  input  logic                     control_i     ,
  output logic [2:0]               status_o      
);



  logic [31:0] addr_internal ;

  logic [7:0] denominator_d ;
  logic [7:0] numerator_d   ;
  logic [7:0] remainder_d   ;
  logic [7:0] quotient_d    ;
  logic       control_d     ;
  logic [2:0] status_d      ;

  
  logic start_sclk, start_cclk, start_q3, start_q2, start_q1, start_d;
  logic busy_sclk ,             busy_q3 , busy_q2 , busy_q1 , busy_d ;

  logic busy_cclk_d, busy_cclk_q;
  
  logic start_strobe;

  logic [7:0] calc_quotient_q    , calc_quotient_d    ;
  logic [7:0] calc_remainder_q   , calc_remainder_d   ;
  logic [7:0] calc_denominator_q , calc_denominator_d ;
  logic [7:0] calc_numerator_q   , calc_numerator_d   ;
  



  always_comb begin
    status_d = status_o;

    if ( busy_sclk  )                 status_d[0] = 1'b1;
    else                              status_d[0] = 1'b0;

    if ( '0 == denominator_i )        status_d[1] = 1'b1;
    else                              status_d[1] = 1'b0;

    if ( 2'b10 == {busy_q3, busy_q2}) status_d[2] = 1'b1;
    else if ( control_i )             status_d[2] = 1'b0;
  end

  always_ff @( posedge slow_clk or negedge rst_n ) begin
    if (!rst_n) begin
      status_o      <= '0;
    end else begin
      status_o      <= status_d;
    end
  end


  // Only start if the divider is not zero
  assign start_sclk = control_i && !status_o[1];

  // Synching start signal to the calculation clock domain 
  assign start_d = start_sclk;

  always_ff @( posedge calculation_clk or negedge rst_n ) begin
    if (!rst_n) begin
      start_q1 <= '0;
      start_q2 <= '0;
      start_q3 <= '0;
    end else begin
      start_q1 <= start_d;
      start_q2 <= start_q1;
      start_q3 <= start_q2;
    end
  end
  
  // Get start strobe from posedge of the metastable filter
  assign start_strobe = 2'b01 == {start_q3, start_q2};
  assign start_cclk   = start_q2;

  // Synching busy signal back to the slow_clk clock domain
  assign busy_d  = busy_cclk_q;

  always_ff @( posedge slow_clk or negedge rst_n ) begin
    if (!rst_n) begin
      busy_q1  <= '0;
      busy_q2  <= '0;
      busy_q3  <= '0;
    end else begin
      busy_q1  <= busy_d ;
      busy_q2  <= busy_q1 ;
      busy_q3  <= busy_q2 ;
    end
  end
  
  assign busy_sclk  = busy_q2 ;


  /////////////////////////////////////////////////
  // slow_clk region
  //////////////
  always_comb begin
    // Normally, allow data forwarding
    //Only allow update, if the divider can't take (metastable) data
    //and the bus can't take (metastable) data
    calc_denominator_d = denominator_i;
    calc_numerator_d   = numerator_i  ;
    quotient_d         = calc_quotient_q  ;
    remainder_d        = calc_remainder_q ;

    if (start_sclk || busy_sclk) begin
      // If start is requested or still busy, loop back itself like a latch
      calc_denominator_d  = calc_denominator_q;
      calc_numerator_d    = calc_numerator_q  ;
      quotient_d          = quotient_o        ;
      remainder_d         = remainder_o       ;
    end
  end

  always_ff @( posedge slow_clk or negedge rst_n ) begin
    if (!rst_n) begin
      calc_denominator_q <= '0;
      calc_numerator_q   <= '0;
      remainder_o        <= '0;
      quotient_o         <= '0;
    end else begin
      calc_denominator_q <= calc_denominator_d;
      calc_numerator_q   <= calc_numerator_d  ;
      remainder_o        <= remainder_d       ;
      quotient_o         <= quotient_d        ;
    end
  end

  /////////////////////////////////////////////////
  // Calc CLK region
  //////////////

  always_comb begin
    // Normally, loop back the register as default
    calc_quotient_d     = calc_quotient_q;
    calc_remainder_d    = calc_remainder_q;
    busy_cclk_d         = busy_cclk_q;

    // If start is requested or still busy, loop back itself
    if (start_cclk || busy_cclk_q) begin
      if (start_strobe) begin
        busy_cclk_d      = 1'b1             ; 
        calc_quotient_d  = '0               ;
        calc_remainder_d = calc_numerator_q ;
      end else begin
        if (calc_remainder_q >= calc_denominator_q) begin
          calc_remainder_d  = calc_remainder_q - calc_denominator_q;
          calc_quotient_d   = calc_quotient_q + 1'b1;
        end else if (!start_cclk) begin
          // Only enable going back to idle if start is cleared by busy
          // Prevents nonstarting / no finish division if num < den
          busy_cclk_d = 1'b0;
        end
      end
    end
  end

  always_ff @( posedge calculation_clk or negedge rst_n ) begin
    if (!rst_n) begin
      busy_cclk_q        <= '0;
      calc_quotient_q    <= '0;
      calc_remainder_q   <= '0;
    end else begin
      busy_cclk_q        <= busy_cclk_d      ;
      calc_quotient_q    <= calc_quotient_d  ;
      calc_remainder_q   <= calc_remainder_d ;
    end
  end
  
endmodule
