library verilog;
use verilog.vl_types.all;
entity reg_file is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        addr1           : in     vl_logic_vector(2 downto 0);
        addr2           : in     vl_logic_vector(2 downto 0);
        addr3           : in     vl_logic_vector(2 downto 0);
        din             : in     vl_logic_vector(15 downto 0);
        dout1           : out    vl_logic_vector(15 downto 0);
        dout2           : out    vl_logic_vector(15 downto 0);
        we              : in     vl_logic
    );
end reg_file;
