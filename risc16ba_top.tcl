set DESIGN_NAME risc16ba
set PROJECT_NAME $DESIGN_NAME\_top
#
project_new $PROJECT_NAME -overwrite
#
set_global_assignment -name FAMILY Cyclone
set_global_assignment -name DEVICE EP1C20F400C8
set_global_assignment -name TOP_LEVEL_ENTITY $PROJECT_NAME
set_global_assignment -name GENERATE_RBF_FILE ON
set_global_assignment -name CYCLONE_CONFIGURATION_SCHEME "PASSIVE SERIAL"
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
set_global_assignment -name USE_TIMEQUEST_TIMING_ANALYZER ON
#
set_global_assignment -name SYSTEMVERILOG_FILE $PROJECT_NAME\.sv
set_global_assignment -name SYSTEMVERILOG_FILE $DESIGN_NAME\.sv
set_global_assignment -name SDC_FILE $PROJECT_NAME\.sdc
#
set_location_assignment PIN_K14 -to clk_ext_in
set_location_assignment PIN_T6 -to n_rst_ext_in
set_location_assignment PIN_K5 -to clk_usb_in
#
set_location_assignment PIN_H3 -to sw_in[0]
set_location_assignment PIN_J3 -to sw_in[1]
set_location_assignment PIN_M3 -to sw_in[2]
set_location_assignment PIN_N3 -to sw_in[3]
set_location_assignment PIN_D3 -to sw_in[4]
set_location_assignment PIN_D4 -to sw_in[5]
set_location_assignment PIN_E3 -to sw_in[6]
set_location_assignment PIN_E4 -to sw_in[7]
#
set_location_assignment PIN_T4 -to usb_n_fwr
set_location_assignment PIN_F3 -to usb_n_frd
set_location_assignment PIN_N2 -to usb_n_cmd
set_location_assignment PIN_P1 -to usb_rg_dt
set_location_assignment PIN_N1 -to usb_n_bulk
set_location_assignment PIN_J2 -to usb_n_ack
set_location_assignment PIN_R1 -to usb_n_ack64
set_location_assignment PIN_F2 -to usb_data[0]
set_location_assignment PIN_H1 -to usb_data[1]
set_location_assignment PIN_E2 -to usb_data[2]
set_location_assignment PIN_G1 -to usb_data[3]
set_location_assignment PIN_D2 -to usb_data[4]
set_location_assignment PIN_F1 -to usb_data[5]
set_location_assignment PIN_C2 -to usb_data[6]
set_location_assignment PIN_D1 -to usb_data[7]
#
set_location_assignment PIN_G20 -to mem_a_addr[0]
set_location_assignment PIN_H17 -to mem_a_addr[1]
set_location_assignment PIN_H18 -to mem_a_addr[2]
set_location_assignment PIN_H19 -to mem_a_addr[3]
set_location_assignment PIN_H20 -to mem_a_addr[4]
set_location_assignment PIN_J17 -to mem_a_addr[5]
set_location_assignment PIN_J18 -to mem_a_addr[6]
set_location_assignment PIN_J19 -to mem_a_addr[7]
set_location_assignment PIN_J20 -to mem_a_addr[8]
set_location_assignment PIN_K19 -to mem_a_addr[9]
set_location_assignment PIN_M17 -to mem_a_addr[10]
set_location_assignment PIN_M18 -to mem_a_addr[11]
set_location_assignment PIN_M19 -to mem_a_addr[12]
set_location_assignment PIN_M20 -to mem_a_addr[13]
set_location_assignment PIN_N17 -to mem_a_addr[14]
set_location_assignment PIN_N18 -to mem_a_addr[15]
set_location_assignment PIN_N19 -to mem_a_addr[16]
set_location_assignment PIN_N20 -to mem_a_addr[17]
set_location_assignment PIN_P17 -to mem_a_n_ce
set_location_assignment PIN_P18 -to mem_a_n_oe
set_location_assignment PIN_P19 -to mem_a_n_we
set_location_assignment PIN_P20 -to mem_a_n_lb
set_location_assignment PIN_R18 -to mem_a_n_ub
set_location_assignment PIN_C18 -to mem_a_data[0]
set_location_assignment PIN_C19 -to mem_a_data[1]
set_location_assignment PIN_D17 -to mem_a_data[2]
set_location_assignment PIN_D18 -to mem_a_data[3]
set_location_assignment PIN_D19 -to mem_a_data[4]
set_location_assignment PIN_D20 -to mem_a_data[5]
set_location_assignment PIN_E17 -to mem_a_data[6]
set_location_assignment PIN_E18 -to mem_a_data[7]
set_location_assignment PIN_E19 -to mem_a_data[8]
set_location_assignment PIN_F17 -to mem_a_data[9]
set_location_assignment PIN_F18 -to mem_a_data[10]
set_location_assignment PIN_F19 -to mem_a_data[11]
set_location_assignment PIN_F20 -to mem_a_data[12]
set_location_assignment PIN_G17 -to mem_a_data[13]
set_location_assignment PIN_G18 -to mem_a_data[14]
set_location_assignment PIN_G19 -to mem_a_data[15]
#
set_location_assignment PIN_F15 -to mem_b_addr[0]
set_location_assignment PIN_F16 -to mem_b_addr[1]
set_location_assignment PIN_G14 -to mem_b_addr[2]
set_location_assignment PIN_G15 -to mem_b_addr[3]
set_location_assignment PIN_G16 -to mem_b_addr[4]
set_location_assignment PIN_H14 -to mem_b_addr[5]
set_location_assignment PIN_H15 -to mem_b_addr[6]
set_location_assignment PIN_H16 -to mem_b_addr[7]
set_location_assignment PIN_J13 -to mem_b_addr[8]
set_location_assignment PIN_J14 -to mem_b_addr[9]
set_location_assignment PIN_J15 -to mem_b_addr[10]
set_location_assignment PIN_J16 -to mem_b_addr[11]
set_location_assignment PIN_K15 -to mem_b_addr[12]
set_location_assignment PIN_K16 -to mem_b_addr[13]
set_location_assignment PIN_M14 -to mem_b_addr[14]
set_location_assignment PIN_M15 -to mem_b_addr[15]
set_location_assignment PIN_M16 -to mem_b_addr[16]
set_location_assignment PIN_N14 -to mem_b_addr[17]
set_location_assignment PIN_T19 -to mem_b_n_ce
set_location_assignment PIN_U18 -to mem_b_n_oe
set_location_assignment PIN_U19 -to mem_b_n_we
set_location_assignment PIN_U20 -to mem_b_n_lb
set_location_assignment PIN_Y17 -to mem_b_n_ub
set_location_assignment PIN_N15 -to mem_b_data[0]
set_location_assignment PIN_N16 -to mem_b_data[1]
set_location_assignment PIN_P14 -to mem_b_data[2]
set_location_assignment PIN_P15 -to mem_b_data[3]
set_location_assignment PIN_P16 -to mem_b_data[4]
set_location_assignment PIN_R15 -to mem_b_data[5]
set_location_assignment PIN_R16 -to mem_b_data[6]
set_location_assignment PIN_R17 -to mem_b_data[7]
set_location_assignment PIN_R19 -to mem_b_data[12]
set_location_assignment PIN_R20 -to mem_b_data[13]
set_location_assignment PIN_T17 -to mem_b_data[14]
set_location_assignment PIN_T18 -to mem_b_data[15]
set_location_assignment PIN_U17 -to mem_b_data[8]
set_location_assignment PIN_V18 -to mem_b_data[9]
set_location_assignment PIN_V19 -to mem_b_data[10]
set_location_assignment PIN_W18 -to mem_b_data[11]
#
set_location_assignment PIN_T14 -to led[0]
set_location_assignment PIN_T13 -to led[1]
set_location_assignment PIN_T12 -to led[2]
set_location_assignment PIN_T11 -to led[3]
set_location_assignment PIN_T10 -to led[4]
set_location_assignment PIN_T9  -to led[5]
set_location_assignment PIN_T8  -to led[6]
set_location_assignment PIN_T7  -to led[7]
set_location_assignment PIN_E5 -to seg_sel[0]
set_location_assignment PIN_F4 -to seg_sel[1]
set_location_assignment PIN_G3 -to seg_sel[2]
set_location_assignment PIN_G4 -to seg_sel[3]
set_location_assignment PIN_H4 -to seg_sel[4]
set_location_assignment PIN_J4 -to seg_sel[5]
set_location_assignment PIN_P3 -to seg_db[0]
set_location_assignment PIN_P4 -to seg_db[1]
set_location_assignment PIN_R3 -to seg_db[2]
set_location_assignment PIN_R4 -to seg_db[3]
set_location_assignment PIN_T3 -to seg_db[4]
set_location_assignment PIN_U3 -to seg_db[5]
set_location_assignment PIN_U4 -to seg_db[6]
set_location_assignment PIN_V3 -to seg_db[7]
#
project_close
