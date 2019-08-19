library verilog;
use verilog.vl_types.all;
entity alu16 is
    port(
        ain             : in     vl_logic_vector(15 downto 0);
        bin             : in     vl_logic_vector(15 downto 0);
        op              : in     vl_logic_vector(3 downto 0);
        dout            : out    vl_logic_vector(15 downto 0)
    );
end alu16;
