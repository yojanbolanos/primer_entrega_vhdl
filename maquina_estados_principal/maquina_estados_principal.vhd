library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 

entity maquina_estados_principal is 
    port(
        clk                 : in  std_logic; -- Señal de reloj
        rst                 : in  std_logic; -- Reinicio del sistema

        cantidad_digitos    : in  integer range 0 to 4; -- Cantidad de dígitos ingresados
        clave_completa      : in  std_logic; -- Indica que ya se ingresó toda la clave
        clave_correcta      : in  std_logic; -- Indica si la clave es correcta
        intentos_actuales   : in  integer range 0 to 3; -- Número de intentos fallidos
        intrusion           : in  std_logic; -- Detección de intrusión
        tiempo_apertura_fin : in  std_logic; -- Fin del tiempo de apertura
        tiempo_bloqueo_fin  : in  std_logic; -- Fin del tiempo de bloqueo
        tiempo_error_fin    : in  std_logic; -- Fin del tiempo de error

        estado_out          : out std_logic_vector(2 downto 0); -- Estado actual codificado

        limpiar_clave       : out std_logic; -- Borra la clave ingresada
        incrementar_intento : out std_logic; -- Aumenta el contador de intentos
        limpiar_intentos    : out std_logic; -- Reinicia el contador de intentos

        iniciar_apertura    : out std_logic; -- Inicia temporizador de apertura
        iniciar_bloqueo     : out std_logic; -- Inicia temporizador de bloqueo
        iniciar_error       : out std_logic; -- Inicia temporizador de error

        activar_alarma      : out std_logic; -- Activa la alarma
        abrir_puerta        : out std_logic -- Abre la puerta
    );
end maquina_estados_principal;

architecture arquitectura_maquina_estados_principal of maquina_estados_principal is

    type tipo_estado is (IDLE, INGRESO, ABRIR, ERROR_CLAVE, BLOQUEO); -- Estados del sistema

    signal estado_actual    : tipo_estado := IDLE; -- Estado presente
    signal estado_siguiente : tipo_estado := IDLE; -- Próximo estado

begin

    process(clk, rst) -- Proceso secuencial
    begin
        if rst = '1' then -- Si hay reset
            estado_actual <= IDLE; -- Vuelve al estado inicial
        elsif rising_edge(clk) then -- En flanco de subida
            estado_actual <= estado_siguiente; -- Actualiza el estado
        end if;
    end process;

    process(estado_actual, cantidad_digitos, clave_completa, clave_correcta, -- Proceso combinacional
            intentos_actuales, intrusion, tiempo_apertura_fin,
            tiempo_bloqueo_fin, tiempo_error_fin)
    begin
        limpiar_clave       <= '0'; -- Valor por defecto
        incrementar_intento <= '0'; -- Valor por defecto
        limpiar_intentos    <= '0'; -- Valor por defecto
        iniciar_apertura    <= '0'; -- Valor por defecto
        iniciar_bloqueo     <= '0'; -- Valor por defecto
        iniciar_error       <= '0'; -- Valor por defecto
        activar_alarma      <= '0'; -- Valor por defecto
        abrir_puerta        <= '0'; -- Valor por defecto

        estado_siguiente    <= estado_actual; -- Mantiene el estado si no cambia

        case estado_actual is -- Evalúa el estado actual

            when IDLE => -- Estado en espera
                -- Se queda en IDLE hasta que el usuario comience a ingresar al menos 1 dígito
                if intrusion = '1' then -- Si detecta intrusión
                    iniciar_bloqueo  <= '1'; -- Inicia bloqueo
                    activar_alarma   <= '1'; -- Activa alarma
                    estado_siguiente <= BLOQUEO; -- Va a bloqueo
                elsif cantidad_digitos > 0 then -- Si empezó a escribir la clave
                    estado_siguiente <= INGRESO; -- Va a ingreso
                end if;

            when INGRESO => -- Estado de ingreso de clave
                if intrusion = '1' then -- Si detecta intrusión
                    iniciar_bloqueo  <= '1'; -- Inicia bloqueo
                    activar_alarma   <= '1'; -- Activa alarma
                    estado_siguiente <= BLOQUEO; -- Va a bloqueo

                elsif cantidad_digitos = 0 then -- Si ya no hay dígitos
                    -- Si se limpió la clave, vuelve a IDLE
                    estado_siguiente <= IDLE; -- Regresa a espera

                elsif clave_completa = '1' then -- Si ya ingresó la clave completa
                    if clave_correcta = '1' then -- Si la clave es correcta
                        iniciar_apertura <= '1'; -- Inicia apertura
                        limpiar_intentos <= '1'; -- Reinicia intentos
                        estado_siguiente <= ABRIR; -- Va a abrir
                    else -- Si la clave es incorrecta
                        incrementar_intento <= '1'; -- Suma intento fallido

                        if intentos_actuales = 2 then -- Si ya iba en el tercer intento
                            iniciar_bloqueo  <= '1'; -- Inicia bloqueo
                            activar_alarma   <= '1'; -- Activa alarma
                            estado_siguiente <= BLOQUEO; -- Va a bloqueo
                        else -- Si aún no llega al límite
                            iniciar_error    <= '1'; -- Inicia tiempo de error
                            estado_siguiente <= ERROR_CLAVE; -- Va a error
                        end if;
                    end if;
                end if;

            when ABRIR => -- Estado de puerta abierta
                abrir_puerta <= '1'; -- Mantiene la puerta abierta

                if intrusion = '1' then -- Si detecta intrusión
                    iniciar_bloqueo  <= '1'; -- Inicia bloqueo
                    activar_alarma   <= '1'; -- Activa alarma
                    estado_siguiente <= BLOQUEO; -- Va a bloqueo

                elsif tiempo_apertura_fin = '1' then -- Si terminó el tiempo de apertura
                    limpiar_clave    <= '1'; -- Borra la clave
                    estado_siguiente <= IDLE; -- Regresa a espera
                end if;

            when ERROR_CLAVE => -- Estado de error por clave incorrecta
                if tiempo_error_fin = '1' then -- Si terminó el tiempo de error
                    limpiar_clave    <= '1'; -- Borra la clave
                    estado_siguiente <= IDLE; -- Regresa a espera
                end if;

            when BLOQUEO => -- Estado de bloqueo
                activar_alarma <= '1'; -- Mantiene alarma encendida

                if tiempo_bloqueo_fin = '1' then -- Si terminó el bloqueo
                    limpiar_clave    <= '1'; -- Borra la clave
                    limpiar_intentos <= '1'; -- Reinicia intentos
                    estado_siguiente <= IDLE; -- Regresa a espera
                end if;

            when others => -- Caso de seguridad
                estado_siguiente <= IDLE; -- Va al estado inicial

        end case;
    end process;

    with estado_actual select -- Codificación del estado
        estado_out <=
            "000" when IDLE, -- IDLE
            "001" when INGRESO, -- INGRESO
            "010" when ABRIR, -- ABRIR
            "011" when ERROR_CLAVE, -- ERROR
            "100" when BLOQUEO, -- BLOQUEO
            "000" when others; -- Valor por defecto

end arquitectura_maquina_estados_principal;