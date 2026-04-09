/*
 * CMOS INVERTER VISUALIZER - Tiny Tapeout Educational Demo
 * Shows PMOS/NMOS structure, animated current flow, waveform, truth table, and labels
 * Watermark: @electronics-ed
 */

`default_nettype none

module tt_um_cmos_inverter (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire hsync, vsync;
    wire [1:0] R, G, B;
    wire sound;
    
    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    
    // REVERTED: Placed 'sound' back on uio[7] for VGA Playground compatibility
    assign uio_out = {sound, 7'b0}; 
    assign uio_oe  = 8'hFF;
    wire _unused = &{ena, ui_in, uio_in};
    
    // ===== VGA TIMING (640x480 @ 60Hz) =====
    reg [9:0] hpos, vpos;
    wire video_active;
    
    always @(posedge clk) begin
        if (~rst_n) begin
            hpos <= 0; vpos <= 0;
        end else begin
            if (hpos == 799) begin
                hpos <= 0;
                vpos <= (vpos == 524) ? 0 : vpos + 1;
            end else
                hpos <= hpos + 1;
        end
    end
    
    assign hsync = ~(hpos >= 656 && hpos < 752);
    assign vsync = ~(vpos >= 490 && vpos < 492);
    assign video_active = (hpos < 640) && (vpos < 480);
    
    wire [9:0] x = hpos;
    wire [9:0] y = vpos;
    
    // ===== FRAME COUNTER =====
    reg [11:0] frame;
    always @(posedge clk) begin
        if (~rst_n) frame <= 0;
        else if (hpos == 0 && vpos == 0) frame <= frame + 1;
    end
    
    // ===== SCROLLING WAVEFORM LOGIC =====
    wire [9:0] time_offset = {frame[7:0], 2'b00};
    wire [9:0] wave_start_x = 350;
    wire [9:0] wave_end_x = 600;
    wire [9:0] wave_pos = (x - wave_start_x + time_offset);
    
    reg visual_input_val;
    reg is_transition;
    reg live_input_val;

    // Speeds based on frame
    always @(*) begin
        case (frame[10:8])
            3'd0: begin visual_input_val = wave_pos[4]; is_transition = (wave_pos[3:0] == 0); live_input_val = time_offset[4]; end // Fast
            3'd1: begin visual_input_val = wave_pos[5]; is_transition = (wave_pos[4:0] == 0); live_input_val = time_offset[5]; end // Med
            3'd2: begin visual_input_val = wave_pos[6]; is_transition = (wave_pos[5:0] == 0); live_input_val = time_offset[6]; end // Slow
            default: begin visual_input_val = wave_pos[7]; is_transition = (wave_pos[6:0] == 0); live_input_val = time_offset[7]; end // V.Slow
        endcase
    end
    
    wire input_signal = live_input_val;
    wire output_signal = ~input_signal; 
    
    // ===== AUDIO (REVERTED TO KNOWN-WORKING SIMULATOR LOGIC) =====
    reg [11:0] tone_cnt; reg tone_wave;
    wire [11:0] tone_limit = input_signal ? 12'd180 : 12'd300; 

    always @(posedge clk) begin
        if (~rst_n) begin
            tone_cnt <= 0;
            tone_wave <= 0;
        end else if (x == 0) begin
            if (tone_cnt > tone_limit) begin 
                tone_cnt <= 0; 
                tone_wave <= ~tone_wave; 
            end else begin
                tone_cnt <= tone_cnt + 1;
            end
        end
    end
    assign sound = tone_wave;
    
    // ===== DRAWING FUNCTIONS =====
    
    // 1. Draw Text and Labels (Title + A, Y, VDD, GND)
    function [1:0] draw_text_labels;
        input [9:0] px, py;
        begin
            draw_text_labels = 2'b00;
            
            // TITLE: "CMOS INVERTER" (Yellow)
            if (py >= 20 && py <= 40) begin
                // C
                if (px>=100 && px<=120) if (px<=104 || py<=24 || py>=36) draw_text_labels = 2'b01;
                // M
                if (px>=130 && px<=150) if (px<=134 || px>=146 || (py<=28 && px>=138 && px<=142)) draw_text_labels = 2'b01;
                // O
                if (px>=160 && px<=180) if (px<=164 || px>=176 || py<=24 || py>=36) draw_text_labels = 2'b01;
                // S
                if (px>=190 && px<=210) if (py<=24 || py>=36 || (py>=28 && py<=32) || (px<=194 && py<=30) || (px>=206 && py>=30)) draw_text_labels = 2'b01;
                // I
                if (px>=240 && px<=250) draw_text_labels = 2'b01;
                // N
                if (px>=260 && px<=280) if (px<=264 || px>=276 || ((px-260)==(py-20))) draw_text_labels = 2'b01;
                // V
                if (px>=290 && px<=310) if ((px<=294 && py<=30) || (px>=306 && py<=30) || (py>30 && px>=296 && px<=304)) draw_text_labels = 2'b01;
                // E
                if (px>=320 && px<=340) if (px<=324 || py<=24 || py>=36 || (py>=28 && py<=32)) draw_text_labels = 2'b01;
                // R
                if (px>=350 && px<=370) if (px<=354 || py<=24 || (px>=366 && py<=30) || (py>=28 && py<=32) || (px>=360 && py>=30)) draw_text_labels = 2'b01;
                // T
                if (px>=380 && px<=400) if (py<=24 || (px>=388 && px<=392)) draw_text_labels = 2'b01;
                // E
                if (px>=410 && px<=430) if (px<=414 || py<=24 || py>=36 || (py>=28 && py<=32)) draw_text_labels = 2'b01;
                // R
                if (px>=440 && px<=460) if (px<=444 || py<=24 || (px>=456 && py<=30) || (py>=28 && py<=32) || (px>=450 && py>=30)) draw_text_labels = 2'b01;
            end
            
            // NODE LABELS: VDD, GND, A, Y (White)
            if (py>=55 && py<=65) begin
                if (px>=170 && px<=178) if ((px<=172 && py<=60) || (px>=176 && py<=60) || (py>60 && px>=173 && px<=175)) draw_text_labels = 2'b10; // V
                if (px>=182 && px<=190) if (px<=184 || py<=57 || py>=63 || (px>=188 && py>=56 && py<=64)) draw_text_labels = 2'b10; // D
                if (px>=194 && px<=202) if (px<=196 || py<=57 || py>=63 || (px>=200 && py>=56 && py<=64)) draw_text_labels = 2'b10; // D
            end
            
            if (py>=390 && py<=400) begin
                if (px>=170 && px<=178) if (px<=172 || py<=392 || py>=398 || (px>=176 && py>=395) || (py==395 && px>=174)) draw_text_labels = 2'b10; // G
                if (px>=182 && px<=190) if (px<=184 || px>=188 || ((py-390)==(px-182))) draw_text_labels = 2'b10; // N
                if (px>=194 && px<=202) if (px<=196 || py<=392 || py>=398 || (px>=200 && py>=391 && py<=399)) draw_text_labels = 2'b10; // D
            end
            
            if (py>=205 && py<=215 && px>=60 && px<=70) if (px<=62 || px>=68 || py<=207 || py==210) draw_text_labels = 2'b10; // A
            if (py>=205 && py<=215 && px>=290 && px<=300) if ((py<=210 && (px<=292 || px>=298)) || (py>210 && px>=294 && px<=296) || py==210) draw_text_labels = 2'b10; // Y
        end
    endfunction

    // 2. Draw Watermark: "@electronics-ed" (CRISP 2px-THICK FONT)
    function draw_watermark;
        input [9:0] px, py;
        begin
            draw_watermark = 0;
            // Position: y 454-465 (12px high), x 440-615
            if (py >= 454 && py <= 465) begin
                if (px >= 440 && px <= 447) if (px<=441 || px>=446 || py<=455 || py>=464 || (px>=443 && px<=444 && py>=459 && py<=460)) draw_watermark = 1;
                if (px >= 452 && px <= 459) if (px<=453 || py<=455 || py>=464 || (py>=459 && py<=460) || (px>=458 && py<=460)) draw_watermark = 1;
                if (px >= 464 && px <= 471) if (px>=467 && px<=468) draw_watermark = 1;
                if (px >= 476 && px <= 483) if (px<=477 || py<=455 || py>=464 || (py>=459 && py<=460) || (px>=482 && py<=460)) draw_watermark = 1;
                if (px >= 488 && px <= 495) if (px<=489 || py<=455 || py>=464) draw_watermark = 1;
                if (px >= 500 && px <= 507) if ((px>=503 && px<=504) || (py>=457 && py<=458)) draw_watermark = 1;
                if (px >= 512 && px <= 519) if (px<=513 || py<=455) draw_watermark = 1;
                if (px >= 524 && px <= 531) if (px<=525 || px>=530 || py<=455 || py>=464) draw_watermark = 1;
                if (px >= 536 && px <= 543) if (px<=537 || px>=542 || py<=455) draw_watermark = 1;
                if (px >= 548 && px <= 555) if ((px>=551 && px<=552) && (py<=455 || py>=458)) draw_watermark = 1;
                if (px >= 560 && px <= 567) if (px<=561 || py<=455 || py>=464) draw_watermark = 1;
                if (px >= 572 && px <= 579) if (py<=455 || py>=464 || (py>=459 && py<=460) || (px<=573 && py<=460) || (px>=578 && py>=459)) draw_watermark = 1;
                if (px >= 584 && px <= 591) if (py>=459 && py<=460) draw_watermark = 1;
                if (px >= 596 && px <= 603) if (px<=597 || py<=455 || py>=464 || (py>=459 && py<=460) || (px>=602 && py<=460)) draw_watermark = 1;
                if (px >= 608 && px <= 615) if (px>=614 || (px<=609 && py>=459) || py>=464 || (py>=459 && py<=460)) draw_watermark = 1;
            end
        end
    endfunction

    // 3. Draw CMOS Circuit with Animated Voltage Flow
    function [2:0] draw_cmos;
        input [9:0] px, py;
        input in_val;
        input [5:0] anim_frame;
        reg is_pmos_path, is_nmos_path;
        reg [9:0] pmos_dist, nmos_dist;
        begin
            draw_cmos = 0;
            
            // A. Static Geometry (Rails, Plates, Bubble)
            if ((py >= 78 && py <= 82 && px >= 180 && px <= 220) ||   // VDD Rail
                (py >= 378 && py <= 382 && px >= 180 && px <= 220) || // GND Rail
                (px >= 180 && px <= 184 && py >= 140 && py <= 180) || // PMOS Gate Plate
                (px >= 190 && px <= 194 && py >= 140 && py <= 180) || // PMOS Body Plate
                (px >= 180 && px <= 184 && py >= 260 && py <= 300) || // NMOS Gate Plate
                (px >= 190 && px <= 194 && py >= 260 && py <= 300) || // NMOS Body Plate
                (py == 140 && px >= 194 && px <= 200) ||              // P-Source Link
                (py == 180 && px >= 194 && px <= 200) ||              // P-Drain Link
                (py == 260 && px >= 194 && px <= 200) ||              // N-Drain Link
                (py == 300 && px >= 194 && px <= 200) ||              // N-Source Link
                (px == 174 && py >= 158 && py <= 162) ||              // P-Bubble Left
                (px == 178 && py >= 158 && py <= 162) ||              // P-Bubble Right
                (py == 158 && px >= 174 && px <= 178) ||              // P-Bubble Top
                (py == 162 && px >= 174 && px <= 178)                 // P-Bubble Bot
                ) begin
                draw_cmos = 3'd1; // White
            end
            
            // B. Input Wires (Color changes based on state)
            else if ((px >= 80 && px <= 160 && py >= 218 && py <= 222) || // Main In
                     (px >= 158 && px <= 162 && py >= 160 && py <= 280) || // Vert Tie
                     (px >= 160 && px <= 174 && py >= 158 && py <= 162) || // To P-Gate
                     (px >= 160 && px <= 180 && py >= 278 && py <= 282))   // To N-Gate
            begin
                draw_cmos = in_val ? 3'd2 : 3'd3; // Red (High) or Blue (Low)
            end
            
            // C. Current Flow Wires (VDD to Out, Out to GND)
            else begin
                is_pmos_path = (px >= 198 && px <= 202 && py >= 82 && py <= 220) ||
                               (px >= 200 && px <= 280 && py >= 218 && py <= 222);
                               
                is_nmos_path = (px >= 198 && px <= 202 && py >= 220 && py <= 378) ||
                               (px >= 200 && px <= 280 && py >= 218 && py <= 222);
                               
                pmos_dist = (py < 220) ? (py - 80) : (140 + px - 200);
                nmos_dist = (px > 200) ? (280 - px) : (80 + py - 220);

                if (is_pmos_path && !in_val) begin
                    if ((pmos_dist - anim_frame) & 16) draw_cmos = 3'd4; // Yellow dash
                    else draw_cmos = 3'd6; 
                end
                else if (is_nmos_path && in_val) begin
                    if ((nmos_dist - anim_frame) & 16) draw_cmos = 3'd5; // Green dash
                    else draw_cmos = 3'd6; 
                end
                else if (is_pmos_path || is_nmos_path) begin
                    draw_cmos = 3'd6; // Inactive
                end
            end
        end
    endfunction
    
    // 4. Draw Waveform function
    function draw_wave;
        input [9:0] px, py, base_y;
        input is_high, is_edge;
        begin
            draw_wave = 0;
            if (px >= wave_start_x && px <= wave_end_x) begin
                if (is_high && py == base_y - 15) draw_wave = 1;
                if (!is_high && py == base_y + 15) draw_wave = 1;
                if (is_edge && py >= base_y - 15 && py <= base_y + 15) draw_wave = 1;
            end
        end
    endfunction

    // 5. Draw Truth Table Text
    function draw_truth_table;
        input [9:0] px, py;
        begin
            draw_truth_table = 0;
            if (px > 400 && px < 560 && py > 300 && py < 400) begin
                // Borders
                if (px == 406 || px == 554 || py == 306 || py == 394) draw_truth_table = 1;
                if (py == 335 && px > 405 && px < 555) draw_truth_table = 1; // Horiz divider
                if (px == 480 && py > 305 && py < 395) draw_truth_table = 1; // Vert divider
                
                // "A"
                if (py >= 310 && py <= 330 && px >= 430 && px <= 450)
                    if (px < 434 || px > 446 || py < 314 || (py > 320 && py < 324)) draw_truth_table = 1;
                // "Y"
                if (py >= 310 && py <= 330 && px >= 500 && px <= 520)
                    if ((py < 320 && (px < 504 || px > 516)) || (py >= 320 && px >= 508 && px <= 512) || (py >= 318 && py <= 322)) draw_truth_table = 1;
                    
                // Row 1 (0 -> 1)
                if (py >= 345 && py <= 365 && px >= 435 && px <= 445) // "0"
                    if (px < 438 || px > 442 || py < 348 || py > 362) draw_truth_table = 1;
                if (py >= 345 && py <= 365 && px >= 505 && px <= 515) // "1"
                    if (px >= 508 && px <= 512) draw_truth_table = 1;
                    
                // Row 2 (1 -> 0)
                if (py >= 370 && py <= 390 && px >= 435 && px <= 445) // "1"
                    if (px >= 438 && px <= 442) draw_truth_table = 1;
                if (py >= 370 && py <= 390 && px >= 505 && px <= 515) // "0"
                    if (px < 508 || px > 512 || py < 373 || py > 387) draw_truth_table = 1;
            end
        end
    endfunction
    
    // ===== COMBINE VISUALS =====
    wire [9:0] wave_y_input = 100;
    wire [9:0] wave_y_output = 180;
    
    wire [1:0] txt_labels = draw_text_labels(x, y);
    wire watermark_on = draw_watermark(x, y);
    wire [2:0] cmos_pixel = draw_cmos(x, y, input_signal, frame[5:0]);
    wire input_wave_on = draw_wave(x, y, wave_y_input, visual_input_val, is_transition);
    wire output_wave_on = draw_wave(x, y, wave_y_output, ~visual_input_val, is_transition);
    wire truth_on = draw_truth_table(x, y);
    
    // Active Truth Table Row Highlight
    wire hl_row1 = (!input_signal) && (x > 406 && x < 554 && y > 335 && y < 368);
    wire hl_row2 = (input_signal) && (x > 406 && x < 554 && y > 368 && y < 394);
    
    // Engineering Grid Background (Lines every 64 pixels)
    wire grid_on = (x[5:0] == 0) || (y[5:0] == 0);
    
    // ===== COLOR OUTPUT DECODING =====
    reg [1:0] r_out, g_out, b_out;
    
    always @(*) begin
        if (!video_active) begin
            r_out = 2'b00; g_out = 2'b00; b_out = 2'b00;
        end
        else if (txt_labels == 2'b01 || watermark_on) begin // Title Text & Watermark
            r_out = 2'b11; g_out = 2'b11; b_out = 2'b00;  // Yellow
        end
        else if (txt_labels == 2'b10) begin // Node Labels (A, Y, VDD, GND)
            r_out = 2'b11; g_out = 2'b11; b_out = 2'b11;  // White
        end
        else if (cmos_pixel == 3'd1) begin // Static Circuit Elements
            r_out = 2'b11; g_out = 2'b11; b_out = 2'b11;  // White
        end
        else if (cmos_pixel == 3'd2) begin // High Input Wire
            r_out = 2'b11; g_out = 2'b00; b_out = 2'b00;  // Red
        end
        else if (cmos_pixel == 3'd3) begin // Low Input Wire
            r_out = 2'b00; g_out = 2'b00; b_out = 2'b11;  // Blue
        end
        else if (cmos_pixel == 3'd4) begin // PMOS Flow (VDD to Out)
            r_out = 2'b11; g_out = 2'b11; b_out = 2'b00;  // Yellow
        end
        else if (cmos_pixel == 3'd5) begin // NMOS Flow (Out to GND)
            r_out = 2'b00; g_out = 2'b11; b_out = 2'b00;  // Green
        end
        else if (cmos_pixel == 3'd6) begin // Inactive Wire
            r_out = 2'b01; g_out = 2'b01; b_out = 2'b01;  // Dark Grey
        end
        else if (input_wave_on) begin
            r_out = 2'b11; g_out = 2'b01; b_out = 2'b01;  // Red/Pink input wave
        end
        else if (output_wave_on) begin
            r_out = 2'b01; g_out = 2'b11; b_out = 2'b11;  // Cyan output wave
        end
        else if (truth_on) begin
            r_out = 2'b11; g_out = 2'b11; b_out = 2'b11;  // White truth table text
        end
        else if (hl_row1 || hl_row2) begin
            r_out = 2'b01; g_out = 2'b01; b_out = 2'b10;  // Highlight active state
        end
        else if (grid_on) begin
            r_out = 2'b00; g_out = 2'b01; b_out = 2'b01;  // Subdued Dark Cyan Grid
        end
        else begin
            r_out = 2'b00; g_out = 2'b00; b_out = 2'b01;  // Dark Subdued background
        end
    end
    
    assign R = r_out;
    assign G = g_out;
    assign B = b_out;

endmodule
