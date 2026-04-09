library ieee; 
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
entity compa_test is
    port(
        a  : in  std_logic_vector(3 downto 0);
        b  : in  std_logic_vector(3 downto 0);
        gt : out std_logic; -- a > b
        eq : out std_logic; -- a = b
        lt : out std_logic  -- a < b
    );
end compa_test;

architecture arch_compa_test of compa_test is
begin
    process(a, b)
    begin
        if unsigned(a) > unsigned(b) then
            gt <= '1';
            eq <= '0';
            lt <= '0';
        elsif unsigned(a) = unsigned(b) then
            gt <= '0';
            eq <= '1';
            lt <= '0';
        else
            gt <= '0';
            eq <= '0';
            lt <= '1';
        end if;
    end process;
end arch_compa_test ;