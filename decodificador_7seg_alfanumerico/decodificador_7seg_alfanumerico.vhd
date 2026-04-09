library ieee;
use ieee.std_logic_1164.all;

entity decodificador_7seg_alfanumerico is
    port(
        codigo : in  std_logic_vector(2 downto 0);
        seg    : out std_logic_vector(6 downto 0)
    );
end decodificador_7seg_alfanumerico;

architecture arquitectura_decodificador_7seg_alfanumerico of decodificador_7seg_alfanumerico is
begin
   

  

    with codigo select
    seg <=
        "1111111" when "000", -- blanco
        "0001000" when "001", -- A
        "0000011" when "010", -- b
        "0101111" when "011", -- r
        "1000111" when "100", -- L
        "0000110" when "101", -- E
        "1111001" when "110", -- I 
        "0100001" when "111"; -- d
end arquitectura_decodificador_7seg_alfanumerico;