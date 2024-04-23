onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_systolic_array_top/w_o_down_rd_data
add wave -noupdate /tb_systolic_array_top/rst_n
add wave -noupdate /tb_systolic_array_top/r_i_top_wr_en
add wave -noupdate /tb_systolic_array_top/r_i_top_wr_data
add wave -noupdate /tb_systolic_array_top/r_i_top_wr_addr
add wave -noupdate /tb_systolic_array_top/r_i_top_sram_rd_start_addr
add wave -noupdate /tb_systolic_array_top/r_i_top_sram_rd_end_addr
add wave -noupdate /tb_systolic_array_top/r_i_left_wr_en
add wave -noupdate /tb_systolic_array_top/r_i_left_wr_data
add wave -noupdate /tb_systolic_array_top/r_i_left_wr_addr
add wave -noupdate /tb_systolic_array_top/r_i_left_sram_rd_start_addr
add wave -noupdate /tb_systolic_array_top/r_i_left_sram_rd_end_addr
add wave -noupdate /tb_systolic_array_top/r_i_down_sram_rd_start_addr
add wave -noupdate /tb_systolic_array_top/r_i_down_sram_rd_end_addr
add wave -noupdate /tb_systolic_array_top/r_i_down_rd_en
add wave -noupdate /tb_systolic_array_top/r_i_down_rd_addr
add wave -noupdate /tb_systolic_array_top/r_i_ctrl_state
add wave -noupdate /tb_systolic_array_top/j
add wave -noupdate /tb_systolic_array_top/i
add wave -noupdate /tb_systolic_array_top/clk
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {305839 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 365
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {766500 ps}
