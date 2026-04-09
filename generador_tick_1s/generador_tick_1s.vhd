library ieee;                                
use ieee.std_logic_1164.all;                 
use ieee.numeric_std.all;                    

entity generador_tick_1s is                  
    generic(
        CLK_FREQ : integer := 50000000       -- Frecuencia del reloj principal
    );
    port(
        clk     : in  std_logic;             -- Reloj principal
        rst     : in  std_logic;             -- Reset del sistema
        tick_1s : out std_logic              -- Pulso de 1 ciclo cada segundo
    );
end generador_tick_1s;

architecture arquitectura_generador_tick_1s of generador_tick_1s is

    signal contador : integer range 0 to CLK_FREQ - 1 := 0; -- Cuenta ciclos del reloj

begin

    process(clk, rst)                        -- Proceso secuencial
    begin
        if rst = '1' then                    -- Si reset activo
            contador <= 0;                   -- Reinicia cuenta interna
            tick_1s <= '0';                  -- Sin pulso

        elsif rising_edge(clk) then          -- En cada flanco de subida

            if contador = CLK_FREQ - 1 then  -- Si ya paso 1 segundo completo
                contador <= 0;               -- Reinicia el contador
                tick_1s <= '1';              -- Genera pulso durante 1 ciclo
            else
                contador <= contador + 1;    -- Sigue contando ciclos de reloj
                tick_1s <= '0';              -- Mientras tanto no hay pulso
            end if;
        end if;
    end process;

end arquitectura_generador_tick_1s;