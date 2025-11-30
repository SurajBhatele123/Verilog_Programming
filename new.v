// ---------- i2c_master (synthesizable Verilog) ----------
`timescale 1ns / 1ps
module i2c_master(
    input        clk,
    input        rst,
    input        newd,
    input  [6:0] addr,
    input        op,       // 1 = read, 0 = write
    inout        sda,
    output       scl,
    input  [7:0] din,
    output [7:0] dout,
    output reg   busy,
    output reg   ack_err,
    output reg   done
);

    // internal signals
    reg scl_t;
    reg sda_t;
    reg sda_en;

    // timing parameters
    parameter sys_freq  = 40000000; // 40 MHz
    parameter i2c_freq  = 100000;   // 100 kHz
    localparam integer clk_count4 = (sys_freq / i2c_freq);    // 400
    localparam integer clk_count1 = (clk_count4 / 4);         // 100
    localparam integer mid_count  = (clk_count4 / 2);         // 200

    integer count1;
    reg [1:0] pulse; // 0..3

    // generate 4-phase pulse (counts clock cycles)
    always @(posedge clk) begin
        if (rst) begin
            pulse  <= 2'd0;
            count1 <= 0;
        end else if (busy == 1'b0) begin
            pulse  <= 2'd0;
            count1 <= 0;
        end else if (count1 == clk_count1 - 1) begin
            pulse  <= 2'd1;
            count1 <= count1 + 1;
        end else if (count1 == clk_count1*2 - 1) begin
            pulse  <= 2'd2;
            count1 <= count1 + 1;
        end else if (count1 == clk_count1*3 - 1) begin
            pulse  <= 2'd3;
            count1 <= count1 + 1;
        end else if (count1 == clk_count1*4 - 1) begin
            pulse  <= 2'd0;
            count1 <= 0;
        end else begin
            count1 <= count1 + 1;
        end
    end

    // state encoding (4-bit to match original)
    localparam [3:0]
        S_IDLE       = 4'd0,
        S_START      = 4'd1,
        S_WRITE_ADDR = 4'd2,
        S_ACK_1      = 4'd3,
        S_WRITE_DATA = 4'd4,
        S_READ_DATA  = 4'd5,
        S_STOP       = 4'd6,
        S_ACK_2      = 4'd7,
        S_MASTER_ACK = 4'd8;

    reg [3:0] state;

    // registers
    reg [3:0] bitcount;
    reg [7:0] data_addr;
    reg [7:0] data_tx;
    reg r_ack;
    reg [7:0] rx_data;

    integer i;

    // main FSM
    always @(posedge clk) begin
        if (rst) begin
            bitcount  <= 4'd0;
            data_addr <= 8'h00;
            data_tx   <= 8'h00;
            scl_t     <= 1'b1;
            sda_t     <= 1'b1;
            sda_en    <= 1'b0;
            state     <= S_IDLE;
            busy      <= 1'b0;
            ack_err   <= 1'b0;
            done      <= 1'b0;
            r_ack     <= 1'b0;
            rx_data   <= 8'h00;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    sda_en <= 1'b0;
                    if (newd) begin
                        data_addr <= {addr, op}; // LSB is R/W
                        data_tx   <= din;
                        busy      <= 1'b1;
                        ack_err   <= 1'b0;
                        bitcount  <= 4'd0;
                        state     <= S_START;
                    end else begin
                        data_addr <= 8'h00;
                        data_tx   <= 8'h00;
                        busy      <= 1'b0;
                        state     <= S_IDLE;
                    end
                end

                S_START: begin
                    // send START: SDA goes low while SCL high
                    sda_en <= 1'b1;
                    case (pulse)
                        2'd0: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                        2'd1: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                        2'd2: begin scl_t <= 1'b1; sda_t <= 1'b0; end
                        2'd3: begin scl_t <= 1'b1; sda_t <= 1'b0; end
                    endcase

                    if (count1 == clk_count1*4 - 1) begin
                        state <= S_WRITE_ADDR;
                        scl_t <= 1'b0;
                        bitcount <= 4'd0;
                    end else begin
                        state <= S_START;
                    end
                end

                S_WRITE_ADDR: begin
                    sda_en <= 1'b1; // driving
                    if (bitcount <= 4'd7) begin
                        case (pulse)
                            2'd0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                            2'd1: begin scl_t <= 1'b0; sda_t <= data_addr[7 - bitcount]; end
                            2'd2: begin scl_t <= 1'b1; end
                            2'd3: begin scl_t <= 1'b1; end
                        endcase
                        if (count1 == clk_count1*4 - 1) begin
                            state <= S_WRITE_ADDR;
                            scl_t <= 1'b0;
                            bitcount <= bitcount + 1;
                        end else begin
                            state <= S_WRITE_ADDR;
                        end
                    end else begin
                        state <= S_ACK_1;
                        bitcount <= 4'd0;
                        sda_en <= 1'b0; // release SDA to allow slave to ack
                    end
                end

                S_ACK_1: begin
                    sda_en <= 1'b0; // read ack
                    case (pulse)
                        2'd0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                        2'd1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                        2'd2: begin scl_t <= 1'b1; sda_t <= 1'b0; r_ack <= sda; end
                        2'd3: begin scl_t <= 1'b1; end
                    endcase

                    if (count1 == clk_count1*4 - 1) begin
                        // if ack = 0 and write op -> write_data
                        if (r_ack == 1'b0 && data_addr[0] == 1'b0) begin
                            state <= S_WRITE_DATA;
                            sda_en <= 1'b1;
                            sda_t <= 1'b0;
                            bitcount <= 4'd0;
                        end else if (r_ack == 1'b0 && data_addr[0] == 1'b1) begin
                            // read operation
                            state <= S_READ_DATA;
                            sda_en <= 1'b0;
                            bitcount <= 4'd0;
                        end else begin
                            // no ack -> stop and error
                            state <= S_STOP;
                            sda_en <= 1'b1;
                            sda_t <= 1'b0;
                            ack_err <= 1'b1;
                        end
                    end else begin
                        state <= S_ACK_1;
                    end
                end

                S_WRITE_DATA: begin
                    // write 8-bit data to slave
                    if (bitcount <= 4'd7) begin
                        case (pulse)
                            2'd0: begin scl_t <= 1'b0; end
                            2'd1: begin scl_t <= 1'b0; sda_en <= 1'b1; sda_t <= data_tx[7 - bitcount]; end
                            2'd2: begin scl_t <= 1'b1; end
                            2'd3: begin scl_t <= 1'b1; end
                        endcase
                        if (count1 == clk_count1*4 - 1) begin
                            state <= S_WRITE_DATA;
                            scl_t <= 1'b0;
                            bitcount <= bitcount + 1;
                        end else begin
                            state <= S_WRITE_DATA;
                        end
                    end else begin
                        state <= S_ACK_2;
                        bitcount <= 4'd0;
                        sda_en <= 1'b0; // release for ack
                    end
                end

                S_READ_DATA: begin
                    // read 8-bit data from slave
                    sda_en <= 1'b0;
                    if (bitcount <= 4'd7) begin
                        case (pulse)
                            2'd0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                            2'd1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                            2'd2: begin scl_t <= 1'b1;
                                     // sample at mid_count
                                     if (count1 == mid_count) begin
                                         rx_data <= {rx_data[6:0], sda};
                                     end
                                   end
                            2'd3: begin scl_t <= 1'b1; end
                        endcase

                        if (count1 == clk_count1*4 - 1) begin
                            state <= S_READ_DATA;
                            scl_t <= 1'b0;
                            bitcount <= bitcount + 1;
                        end else begin
                            state <= S_READ_DATA;
                        end
                    end else begin
                        // after reading 8 bits: send NACK from master (master_ack)
                        state <= S_MASTER_ACK;
                        bitcount <= 4'd0;
                        sda_en <= 1'b1; // will drive to send NACK
                    end
                end

                S_MASTER_ACK: begin
                    // send NACK (master typically sends NACK after single-byte read)
                    sda_en <= 1'b1;
                    case (pulse)
                        2'd0: begin scl_t <= 1'b0; sda_t <= 1'b1; end
                        2'd1: begin scl_t <= 1'b0; sda_t <= 1'b1; end
                        2'd2: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                        2'd3: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                    endcase

                    if (count1 == clk_count1*4 - 1) begin
                        // prepare to stop and present data
                        sda_t <= 1'b0;
                        state <= S_STOP;
                        sda_en <= 1'b1;
                        // publish rx_data to output
                        rx_data <= rx_data; // already stored
                    end else begin
                        state <= S_MASTER_ACK;
                    end
                end

                S_ACK_2: begin
                    // receive ACK after write data
                    sda_en <= 1'b0;
                    case (pulse)
                        2'd0: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                        2'd1: begin scl_t <= 1'b0; sda_t <= 1'b0; end
                        2'd2: begin scl_t <= 1'b1; sda_t <= 1'b0; r_ack <= sda; end
                        2'd3: begin scl_t <= 1'b1; end
                    endcase

                    if (count1 == clk_count1*4 - 1) begin
                        sda_t <= 1'b0;
                        sda_en <= 1'b1; // send stop
                        if (r_ack == 1'b0) begin
                            ack_err <= 1'b0;
                        end else begin
                            ack_err <= 1'b1;
                        end
                        state <= S_STOP;
                    end else begin
                        state <= S_ACK_2;
                    end
                end

                S_STOP: begin
                    // STOP condition: SDA goes high while SCL is high
                    sda_en <= 1'b1;
                    case (pulse)
                        2'd0: begin scl_t <= 1'b1; sda_t <= 1'b0; end
                        2'd1: begin scl_t <= 1'b1; sda_t <= 1'b0; end
                        2'd2: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                        2'd3: begin scl_t <= 1'b1; sda_t <= 1'b1; end
                    endcase

                    if (count1 == clk_count1*4 - 1) begin
                        state <= S_IDLE;
                        scl_t <= 1'b0;
                        busy <= 1'b0;
                        sda_en <= 1'b1;
                        done <= 1'b1;
                    end else begin
                        state <= S_STOP;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // output assignments
    // emulate open-drain: drive 0 when sda_en==1 && sda_t==0, else high-Z
    assign sda = (sda_en && (sda_t == 1'b0)) ? 1'b0 : 1'bz;
    assign scl = scl_t;
    assign dout = rx_data;

endmodule


// ---------- i2c_Slave (synthesizable Verilog) ----------
`timescale 1ns / 1ps
module i2c_Slave(
    input        scl,
    input        clk,
    input        rst,
    inout        sda,
    output reg   ack_err,
    output reg   done
);

    // memory
    reg [7:0] mem [0:127];
    reg [7:0] dout_reg;
    reg [7:0] din_reg;
    reg [6:0] addr_reg;
    reg r_mem;
    reg w_mem;

    // timing parameters (same as master)
    parameter sys_freq  = 40000000;
    parameter i2c_freq  = 100000;
    localparam integer clk_count4 = (sys_freq / i2c_freq);
    localparam integer clk_count1 = (clk_count4 / 4);
    localparam integer mid_count  = (clk_count4 / 2);

    integer count1;
    reg [1:0] pulse;
    reg busy;

    // state encodings
    localparam [3:0]
        S_IDLE       = 4'd0,
        S_READ_ADDR  = 4'd1,
        S_SEND_ACK1  = 4'd2,
        S_SEND_DATA  = 4'd3,
        S_MASTER_ACK = 4'd4,
        S_READ_DATA  = 4'd5,
        S_SEND_ACK2  = 4'd6,
        S_WAIT_P     = 4'd7,
        S_DETECT_STOP= 4'd8;

    reg [3:0] state;

    // SDA control
    reg sda_t;
    reg sda_en;
    reg [3:0] bitcnt;
    reg [6:0] r_addr; // shifted-in address (7 bits) + R/W LSB handled separately
    reg r_ack;

    integer i;

    // initialize memory and registers on reset (synthesizable)
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 128; i = i + 1) begin
                mem[i] <= i[7:0];
            end
            dout_reg <= 8'h00;
            din_reg  <= 8'h00;
            addr_reg <= 7'h00;
            r_mem    <= 1'b0;
            w_mem    <= 1'b0;
            sda_t    <= 1'b0;
            sda_en   <= 1'b0;
            bitcnt   <= 4'd0;
            ack_err  <= 1'b0;
            done     <= 1'b0;
            busy     <= 1'b0;
            state    <= S_IDLE;
            r_addr   <= 7'h00;
            count1   <= 0;
            pulse    <= 2'd2; // idle value
        end else begin
            // memory read/write actions
            if (r_mem) begin
                dout_reg <= mem[addr_reg];
            end else if (w_mem) begin
                mem[addr_reg] <= din_reg;
            end

            // pulse generator (synchronised to clk)
            if (busy == 1'b0) begin
                pulse <= 2'd2;
                count1 <= clk_count4/2; // keep it offset when idle
            end else if (count1 == clk_count1 - 1) begin
                pulse <= 2'd1;
                count1 <= count1 + 1;
            end else if (count1 == clk_count1*2 - 1) begin
                pulse <= 2'd2;
                count1 <= count1 + 1;
            end else if (count1 == clk_count1*3 - 1) begin
                pulse <= 2'd3;
                count1 <= count1 + 1;
            end else if (count1 == clk_count1*4 - 1) begin
                pulse <= 2'd0;
                count1 <= 0;
            end else begin
                count1 <= count1 + 1;
            end

            // detect start: start = falling edge of SDA while SCL=1
            // We can't detect edge directly on sda in a synth-friendly way without previous sample;
            // so capture previous sda in a register by sampling on clk.
            // We'll sample sda into sda_prev on every clk and detect ~sda & sda_prev when scl==1
            // For simplicity, use a small register to track previous sda.
        end
    end

    // We need a sampled copy of sda and scl to detect edges
    reg sda_prev, scl_prev;
    always @(posedge clk) begin
        sda_prev <= sda;
        scl_prev <= scl;
    end

    wire start;
    assign start = (scl == 1'b1) && (sda_prev == 1'b1) && (sda == 1'b0); // falling edge detected while SCL high

    // main slave FSM
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            bitcnt <= 4'd0;
            r_addr <= 7'h00;
            sda_en <= 1'b0;
            sda_t <= 1'b0;
            addr_reg <= 7'h00;
            r_mem <= 1'b0;
            din_reg <= 8'h00;
            ack_err <= 1'b0;
            done <= 1'b0;
            busy <= 1'b0;
            r_ack <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (scl == 1'b1 && sda == 1'b0) begin
                        busy <= 1'b1;
                        state <= S_WAIT_P;
                    end else begin
                        state <= S_IDLE;
                    end
                end

                S_WAIT_P: begin
                    // wait until the pulses align (roughly end of start condition)
                    if (pulse == 2'b11 && count1 == clk_count4 - 1) begin
                        state <= S_READ_ADDR;
                        bitcnt <= 4'd0;
                        r_addr <= 7'h00;
                    end else begin
                        state <= S_WAIT_P;
                    end
                end

                S_READ_ADDR: begin
                    sda_en <= 1'b0; // release, reading address bits
                    if (bitcnt <= 4'd7) begin
                        if (pulse == 2'd2) begin
                            // sample at mid of bit
                            if (count1 == mid_count) begin
                                r_addr <= {r_addr[5:0], sda}; // shift in bit (we will later treat LSB as R/W)
                            end
                        end

                        if (count1 == clk_count1*4 - 1) begin
                            bitcnt <= bitcnt + 1;
                            state <= S_READ_ADDR;
                        end else begin
                            state <= S_READ_ADDR;
                        end
                    end else begin
                        // r_addr contains 7 MSBs and one extra shift; original code used r_addr[7:1] as address
                        // to reproduce behavior, we will use r_addr as 8-bit shift, with LSB being R/W
                        state <= S_SEND_ACK1;
                        bitcnt <= 4'd0;
                        sda_en <= 1'b1; // drive ACK
                        addr_reg <= r_addr[6:0]; // top 7 bits are slave address
                    end
                end

                S_SEND_ACK1: begin
                    // send ACK (drive SDA low for one clock)
                    case (pulse)
                        2'd0: begin sda_t <= 1'b0; end // pull low
                        default: begin end
                    endcase

                    if (count1 == clk_count1*4 - 1) begin
                        // check R/W bit: assume the last shifted-in bit (we replicate original behavior)
                        // original used r_addr[0] to indicate read; our shifting used lowest bit as last received
                        if (r_addr[0] == 1'b1) begin
                            state <= S_SEND_DATA;
                            r_mem <= 1'b1;
                        end else begin
                            state <= S_READ_DATA;
                            r_mem <= 1'b0;
                        end
                    end else begin
                        state <= S_SEND_ACK1;
                    end
                end

                S_READ_DATA: begin
                    // master writes data to slave; slave receives and stores
                    sda_en <= 1'b0; // release to read bits
                    if (bitcnt <= 4'd7) begin
                        if (pulse == 2'd2 && count1 == mid_count) begin
                            din_reg <= {din_reg[6:0], sda};
                        end

                        if (count1 == clk_count1*4 - 1) begin
                            bitcnt <= bitcnt + 1;
                            state <= S_READ_DATA;
                        end else begin
                            state <= S_READ_DATA;
                        end
                    end else begin
                        // all bits received
                        state <= S_SEND_ACK2;
                        bitcnt <= 4'd0;
                        sda_en <= 1'b1; // send ack
                        w_mem <= 1'b1;
                    end
                end

                S_SEND_ACK2: begin
                    // drive ACK low
                    case (pulse)
                        2'd0: begin sda_t <= 1'b0; end
                        2'd1: begin w_mem <= 1'b0; end // write to memory cleared after ack
                        default: begin end
                    endcase

                    if (count1 == clk_count1*4 - 1) begin
                        state <= S_DETECT_STOP;
                        sda_en <= 1'b0;
                    end else begin
                        state <= S_SEND_ACK2;
                    end
                end

                S_SEND_DATA: begin
                    // send stored data to master
                    sda_en <= 1'b1;
                    if (bitcnt <= 4'd7) begin
                        r_mem <= 1'b0;
                        if (pulse == 2'd1 && count1 == clk_count1/2) begin
                            // place next bit on SDA (stable during SCL high)
                            sda_t <= dout_reg[7 - bitcnt];
                        end

                        if (count1 == clk_count1*4 - 1) begin
                            bitcnt <= bitcnt + 1;
                            state <= S_SEND_DATA;
                        end else begin
                            state <= S_SEND_DATA;
                        end
                    end else begin
                        state <= S_MASTER_ACK;
                        bitcnt <= 4'd0;
                        sda_en <= 1'b0; // release to sample master's ack/nack
                    end
                end

                S_MASTER_ACK: begin
                    // read ack/nack from master
                    if (pulse == 2'd2 && count1 == mid_count) begin
                        r_ack <= sda;
                    end

                    if (count1 == clk_count1*4 - 1) begin
                        if (r_ack == 1'b1) begin
                            // master sent NACK (1) -> done reading
                            ack_err <= 1'b0;
                            state <= S_DETECT_STOP;
                            sda_en <= 1'b0;
                        end else begin
                            // master sent ACK (0) -> master expects more data or will proceed
                            ack_err <= 1'b1; // keeping parity with original code's logic
                            state <= S_DETECT_STOP;
                            sda_en <= 1'b0;
                        end
                    end else begin
                        state <= S_MASTER_ACK;
                    end
                end

                S_DETECT_STOP: begin
                    // wait for bus idle or STOP; approximate with pulse alignment
                    if (pulse == 2'b11 && count1 == clk_count4 - 1) begin
                        state <= S_IDLE;
                        busy <= 1'b0;
                        done <= 1'b1;
                    end else begin
                        state <= S_DETECT_STOP;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // SDA open-drain behavior for slave: drive low when sda_en==1 and sda_t==0
    assign sda = (sda_en && (sda_t == 1'b0)) ? 1'b0 : 1'bz;

endmodule


// ---------- i2c_top ----------
`timescale 1ns / 1ps
module i2c_top(
    input        clk,
    input        rst,
    input        newd,
    input        op,        // 1=read,0=write
    input  [6:0] addr,
    input  [7:0] din,
    output [7:0] dout,
    output       busy,
    output       ack_err,
    output       done
);

    wire sda;
    wire scl;
    wire ack_errm, ack_errs;
    wire done_s;

    i2c_master master_inst (
        .clk    (clk),
        .rst    (rst),
        .newd   (newd),
        .addr   (addr),
        .op     (op),
        .sda    (sda),
        .scl    (scl),
        .din    (din),
        .dout   (dout),
        .busy   (busy),
        .ack_err(ack_errm),
        .done   (done)
    );

    i2c_Slave slave_inst (
        .scl    (scl),
        .clk    (clk),
        .rst    (rst),
        .sda    (sda),
        .ack_err(ack_errs),
        .done   (done_s)
    );

    assign ack_err = ack_errs | ack_errm;

endmodule
