library ieee;                               
use ieee.std_logic_1164.all;                
use ieee.numeric_std.all;                   

entity registro_corrimiento_4_digitos is    
    port(
        clk             : in  std_logic;    -- Reloj principal
        rst             : in  std_logic;    -- Reset del sistema
        limpiar         : in  std_logic;    -- Borra todos los digitos guardados
        cargar_digito   : in  std_logic;    -- Pulso para cargar un nuevo digito
        digito_in       : in  std_logic_vector(3 downto 0); -- Digito desde switches

        hex0_out        : out std_logic_vector(3 downto 0); -- Display HEX0
        hex1_out        : out std_logic_vector(3 downto 0); -- Display HEX1
        hex2_out        : out std_logic_vector(3 downto 0); -- Display HEX2
        hex3_out        : out std_logic_vector(3 downto 0); -- Display HEX3

        clave_out       : out std_logic_vector(15 downto 0); -- Clave completa
        cuenta_digitos  : out integer range 0 to 4;          -- Cuantos digitos van
        completo        : out std_logic                      -- Vale 1 cuando ya hay 4
    );
end registro_corrimiento_4_digitos;

architecture arquitectura_registro_corrimiento_4_digitos of registro_corrimiento_4_digitos is

    signal d0 : std_logic_vector(3 downto 0) := (others => '0'); -- Guarda HEX0
    signal d1 : std_logic_vector(3 downto 0) := (others => '0'); -- Guarda HEX1
    signal d2 : std_logic_vector(3 downto 0) := (others => '0'); -- Guarda HEX2
    signal d3 : std_logic_vector(3 downto 0) := (others => '0'); -- Guarda HEX3

    signal contador : integer range 0 to 4 := 0; -- Cuenta cuantos digitos se han cargado

begin

    process(clk, rst)                        -- Proceso secuencial
    begin
        if rst = '1' then                    -- Si reset activo
            d0 <= (others => '0');           -- Borra HEX0
            d1 <= (others => '0');           -- Borra HEX1
            d2 <= (others => '0');           -- Borra HEX2
            d3 <= (others => '0');           -- Borra HEX3
            contador <= 0;                   -- Reinicia cantidad de digitos

        elsif rising_edge(clk) then          -- En cada flanco de subida

            if limpiar = '1' then            -- Si se ordena limpiar
                d0 <= (others => '0');       -- Borra HEX0
                d1 <= (others => '0');       -- Borra HEX1
                d2 <= (others => '0');       -- Borra HEX2
                d3 <= (others => '0');       -- Borra HEX3
                contador <= 0;               -- Reinicia contador

            elsif cargar_digito = '1' then   -- Si llega pulso de carga
                d0 <= d1;                    -- Lo que estaba en HEX1 pasa a HEX0
                d1 <= d2;                    -- Lo que estaba en HEX2 pasa a HEX1
                d2 <= d3;                    -- Lo que estaba en HEX3 pasa a HEX2
                d3 <= digito_in;             -- El nuevo digito entra a HEX3

                if contador < 4 then         -- Si aun no se llenaron 4 posiciones
                    contador <= contador + 1;-- Aumenta cantidad de digitos validos
                end if;
            end if;
        end if;
    end process;

    hex0_out <= d0;                          -- Manda d0 al display HEX0
    hex1_out <= d1;                          -- Manda d1 al display HEX1
    hex2_out <= d2;                          -- Manda d2 al display HEX2
    hex3_out <= d3;                          -- Manda d3 al display HEX3

    clave_out <= d0 & d1 & d2 & d3;         -- Forma la clave completa de 16 bits

    cuenta_digitos <= contador;             -- Informa cuantos digitos hay cargados
    completo <= '1' when contador = 4 else '0'; -- Indica si ya se completaron 4 digitos

end arquitectura_registro_corrimiento_4_digitos;