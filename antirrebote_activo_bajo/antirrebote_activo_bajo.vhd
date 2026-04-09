library ieee;                              
use ieee.std_logic_1164.all;               
use ieee.numeric_std.all;                  

entity antirrebote_activo_bajo is          
    generic(
        COUNT_MAX : integer := 50000       -- Cantidad de ciclos para validar estabilidad
    );
    port(
        clk    : in  std_logic;            -- Reloj principal
        rst    : in  std_logic;            -- Reset del sistema
        btn_in : in  std_logic;            -- Entrada del boton fisico
        btn_db : out std_logic             -- Salida del boton ya limpia
    );
end antirrebote_activo_bajo;

architecture arquitectura_antirrebote_activo_bajo of antirrebote_activo_bajo is

    signal btn_sync_0 : std_logic := '1';  -- Primera etapa de sincronizacion
    signal btn_sync_1 : std_logic := '1';  -- Segunda etapa de sincronizacion
    signal btn_estable : std_logic := '1'; -- Estado estable aceptado del boton
    signal contador   : integer range 0 to COUNT_MAX := 0; -- Cuenta tiempo de estabilidad

begin

    process(clk, rst)                      -- Proceso secuencial con clk y reset
    begin
        if rst = '1' then                  -- Si el reset esta activo
            btn_sync_0  <= '1';            -- Se asume boton no presionado
            btn_sync_1  <= '1';            -- Se asume boton no presionado
            btn_estable <= '1';            -- Estado estable inicial = no presionado
            contador    <= 0;              -- Reinicia contador

        elsif rising_edge(clk) then        -- En cada flanco de subida del reloj

            btn_sync_0 <= btn_in;          -- Primera captura de la entrada
            btn_sync_1 <= btn_sync_0;      -- Segunda captura para sincronizar mejor

            if btn_sync_1 = btn_estable then   -- Si coincide con el estado estable
                contador <= 0;                 -- No hay cambio valido, reinicia contador
            else                                -- Si es distinto al estado estable
                if contador = COUNT_MAX then    -- Si aguanto suficiente tiempo
                    btn_estable <= btn_sync_1;  -- Acepta el nuevo valor como valido
                    contador    <= 0;           -- Reinicia contador
                else
                    contador <= contador + 1;   -- Sigue contando estabilidad
                end if;
            end if;
        end if;
    end process;

    btn_db <= btn_estable;                 -- La salida es el valor filtrado

end arquitectura_antirrebote_activo_bajo;