library ieee;                               
use ieee.std_logic_1164.all;                
use ieee.numeric_std.all;                  

entity contador_intentos_fallidos is       
    port(
        clk              : in  std_logic;   -- Reloj principal
        rst              : in  std_logic;   -- Reset del sistema
        limpiar          : in  std_logic;   -- Reinicia el contador
        incrementar      : in  std_logic;   -- Suma un intento fallido
        cuenta           : out integer range 0 to 3; -- Valor actual del contador
        maximo_alcanzado : out std_logic    -- Vale 1 cuando llega a 3
    );
end contador_intentos_fallidos;

architecture arquitectura_contador_intentos_fallidos of contador_intentos_fallidos is

    signal contador : integer range 0 to 3 := 0; -- Guarda la cantidad de errores

begin

    process(clk, rst)                       -- Proceso secuencial
    begin
        if rst = '1' then                   -- Si reset activo
            contador <= 0;                  -- Reinicia el contador

        elsif rising_edge(clk) then         -- En cada flanco de subida

            if limpiar = '1' then           -- Si se ordena limpiar
                contador <= 0;              -- Vuelve a cero

            elsif incrementar = '1' then    -- Si se ordena sumar intento
                if contador < 3 then        -- Si aun no llego al maximo
                    contador <= contador + 1; -- Aumenta en 1
                end if;
            end if;
        end if;
    end process;

    cuenta <= contador;                     -- Entrega el valor actual
    maximo_alcanzado <= '1' when contador = 3 else '0';
    -- Se activa cuando ya hubo 3 errores

end arquitectura_contador_intentos_fallidos;