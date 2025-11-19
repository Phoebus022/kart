module buttons(
    input clk,
    input btn,
    output wire btn_pulse
);
    wire btn_db;
    debounce db_inst(
        .clk(clk),
        .pb(btn),
        .pb_debounced(btn_db)
    );

    one_pulse op_inst(
        .clk(clk),
        .pb_in(btn_db),
        .pb_out(btn_pulse)
    );

    
endmodule