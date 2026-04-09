library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sistema_control_acceso_top is
    port(
        CLOCK_50         : in  std_logic;
        RESET            : in  std_logic;

        SW               : in  std_logic_vector(3 downto 0);
        KEY0             : in  std_logic;

        INTRUSION_IN     : in  std_logic;

        HEX0             : out std_logic_vector(6 downto 0);
        HEX1             : out std_logic_vector(6 downto 0);
        HEX2             : out std_logic_vector(6 downto 0);
        HEX3             : out std_logic_vector(6 downto 0);

        LED_ABRIR_PUERTA : out std_logic;
        LED_ALARMA       : out std_logic;
        LED_BLOQUEO      : out std_logic
    );
end sistema_control_acceso_top;

architecture arquitectura_sistema_control_acceso_top of sistema_control_acceso_top is

    component antirrebote_activo_bajo
        generic(
            COUNT_MAX : integer := 50000
        );
        port(
            clk    : in  std_logic;
            rst    : in  std_logic;
            btn_in : in  std_logic;
            btn_db : out std_logic
        );
    end component;

    component detector_flanco_bajada
        port(
            clk    : in  std_logic;
            rst    : in  std_logic;
            sig_in : in  std_logic;
            pulso  : out std_logic
        );
    end component;

    component registro_corrimiento_4_digitos
        port(
            clk             : in  std_logic;
            rst             : in  std_logic;
            limpiar         : in  std_logic;
            cargar_digito   : in  std_logic;
            digito_in       : in  std_logic_vector(3 downto 0);
            hex0_out        : out std_logic_vector(3 downto 0);
            hex1_out        : out std_logic_vector(3 downto 0);
            hex2_out        : out std_logic_vector(3 downto 0);
            hex3_out        : out std_logic_vector(3 downto 0);
            clave_out       : out std_logic_vector(15 downto 0);
            cuenta_digitos  : out integer range 0 to 4;
            completo        : out std_logic
        );
    end component;

    component comparador_clave_4_digitos
        port(
            clave_ingresada : in  std_logic_vector(15 downto 0);
            clave_guardada  : in  std_logic_vector(15 downto 0);
            coincide        : out std_logic
        );
    end component;

    component contador_intentos_fallidos
        port(
            clk              : in  std_logic;
            rst              : in  std_logic;
            limpiar          : in  std_logic;
            incrementar      : in  std_logic;
            cuenta           : out integer range 0 to 3;
            maximo_alcanzado : out std_logic
        );
    end component;

    component generador_tick_1s
        generic(
            CLK_FREQ : integer := 50000000
        );
        port(
            clk     : in  std_logic;
            rst     : in  std_logic;
            tick_1s : out std_logic
        );
    end component;

    component temporizador_descendente
        generic(
            MAX_VALUE : integer := 59
        );
        port(
            clk        : in  std_logic;
            rst        : in  std_logic;
            iniciar    : in  std_logic;
            tick_1s    : in  std_logic;
            preset     : in  integer range 0 to MAX_VALUE;
            corriendo  : out std_logic;
            terminado  : out std_logic;
            valor_out  : out integer range 0 to MAX_VALUE
        );
    end component;

    component maquina_estados_principal
        port(
            clk                 : in  std_logic;
            rst                 : in  std_logic;
            cantidad_digitos    : in  integer range 0 to 4;
            clave_completa      : in  std_logic;
            clave_correcta      : in  std_logic;
            intentos_actuales   : in  integer range 0 to 3;
            intrusion           : in  std_logic;
            tiempo_apertura_fin : in  std_logic;
            tiempo_bloqueo_fin  : in  std_logic;
            tiempo_error_fin    : in  std_logic;
            estado_out          : out std_logic_vector(2 downto 0);
            limpiar_clave       : out std_logic;
            incrementar_intento : out std_logic;
            limpiar_intentos    : out std_logic;
            iniciar_apertura    : out std_logic;
            iniciar_bloqueo     : out std_logic;
            iniciar_error       : out std_logic;
            activar_alarma      : out std_logic;
            abrir_puerta        : out std_logic
        );
    end component;

    component fiveb
        port(
            entrada : in  std_logic_vector(3 downto 0);
            seg     : out std_logic_vector(6 downto 0)
        );
    end component;

    component decodificador_7seg_alfanumerico
        port(
            codigo : in  std_logic_vector(2 downto 0);
            seg    : out std_logic_vector(6 downto 0)
        );
    end component;

    signal boton_limpio        : std_logic;
    signal pulso_carga         : std_logic;

    signal dig_hex0            : std_logic_vector(3 downto 0);
    signal dig_hex1            : std_logic_vector(3 downto 0);
    signal dig_hex2            : std_logic_vector(3 downto 0);
    signal dig_hex3            : std_logic_vector(3 downto 0);

    signal clave_ingresada     : std_logic_vector(15 downto 0);
    signal clave_completa      : std_logic;
    signal cantidad_digitos    : integer range 0 to 4;

    signal clave_correcta      : std_logic;

    signal intentos            : integer range 0 to 3;
    signal maximo_intentos     : std_logic;

    signal tick_1s             : std_logic;

    signal apertura_fin        : std_logic;
    signal apertura_valor      : integer range 0 to 59;

    signal bloqueo_fin         : std_logic;
    signal bloqueo_valor       : integer range 0 to 59;

    signal error_fin           : std_logic;
    signal error_valor         : integer range 0 to 59;

    signal dummy_apertura      : std_logic;
    signal dummy_bloqueo       : std_logic;
    signal dummy_error         : std_logic;

    signal estado_sistema      : std_logic_vector(2 downto 0);

    signal limpiar_clave_s     : std_logic;
    signal incrementar_int_s   : std_logic;
    signal limpiar_intentos_s  : std_logic;
    signal iniciar_apertura_s  : std_logic;
    signal iniciar_bloqueo_s   : std_logic;
    signal iniciar_error_s     : std_logic;
    signal activar_alarma_s    : std_logic;
    signal abrir_puerta_s      : std_logic;

    signal seg_h0_num          : std_logic_vector(6 downto 0);
    signal seg_h1_num          : std_logic_vector(6 downto 0);
    signal seg_h2_num          : std_logic_vector(6 downto 0);
    signal seg_h3_num          : std_logic_vector(6 downto 0);

    signal seg_a               : std_logic_vector(6 downto 0);
    signal seg_b               : std_logic_vector(6 downto 0);
    signal seg_r               : std_logic_vector(6 downto 0);
    signal seg_l               : std_logic_vector(6 downto 0);
    signal seg_e               : std_logic_vector(6 downto 0);
    signal seg_i               : std_logic_vector(6 downto 0);
    signal seg_d               : std_logic_vector(6 downto 0);
    signal seg_blanco          : std_logic_vector(6 downto 0);

    signal unidad_temp         : std_logic_vector(3 downto 0);
    signal seg_unidad          : std_logic_vector(6 downto 0);

    constant CLAVE_FIJA        : std_logic_vector(15 downto 0) := x"1234";
    constant TIEMPO_APERTURA   : integer := 5;
    constant TIEMPO_BLOQUEO    : integer := 10;
    constant TIEMPO_ERROR      : integer := 2;

begin

    u_antirrebote : antirrebote_activo_bajo
        port map(
            clk    => CLOCK_50,
            rst    => RESET,
            btn_in => KEY0,
            btn_db => boton_limpio
        );

    u_flanco : detector_flanco_bajada
        port map(
            clk    => CLOCK_50,
            rst    => RESET,
            sig_in => boton_limpio,
            pulso  => pulso_carga
        );

    u_registro_clave : registro_corrimiento_4_digitos
        port map(
            clk            => CLOCK_50,
            rst            => RESET,
            limpiar        => limpiar_clave_s,
            cargar_digito  => pulso_carga,
            digito_in      => SW,
            hex0_out       => dig_hex0,
            hex1_out       => dig_hex1,
            hex2_out       => dig_hex2,
            hex3_out       => dig_hex3,
            clave_out      => clave_ingresada,
            cuenta_digitos => cantidad_digitos,
            completo       => clave_completa
        );

    u_comparador : comparador_clave_4_digitos
        port map(
            clave_ingresada => clave_ingresada,
            clave_guardada  => CLAVE_FIJA,
            coincide        => clave_correcta
        );

    u_contador_intentos : contador_intentos_fallidos
        port map(
            clk              => CLOCK_50,
            rst              => RESET,
            limpiar          => limpiar_intentos_s,
            incrementar      => incrementar_int_s,
            cuenta           => intentos,
            maximo_alcanzado => maximo_intentos
        );

    u_tick_1s : generador_tick_1s
        port map(
            clk     => CLOCK_50,
            rst     => RESET,
            tick_1s => tick_1s
        );

    u_tiempo_apertura : temporizador_descendente
        port map(
            clk       => CLOCK_50,
            rst       => RESET,
            iniciar   => iniciar_apertura_s,
            tick_1s   => tick_1s,
            preset    => TIEMPO_APERTURA,
            corriendo => dummy_apertura,
            terminado => apertura_fin,
            valor_out => apertura_valor
        );

    u_tiempo_bloqueo : temporizador_descendente
        port map(
            clk       => CLOCK_50,
            rst       => RESET,
            iniciar   => iniciar_bloqueo_s,
            tick_1s   => tick_1s,
            preset    => TIEMPO_BLOQUEO,
            corriendo => dummy_bloqueo,
            terminado => bloqueo_fin,
            valor_out => bloqueo_valor
        );

    u_tiempo_error : temporizador_descendente
        port map(
            clk       => CLOCK_50,
            rst       => RESET,
            iniciar   => iniciar_error_s,
            tick_1s   => tick_1s,
            preset    => TIEMPO_ERROR,
            corriendo => dummy_error,
            terminado => error_fin,
            valor_out => error_valor
        );

    u_fsm : maquina_estados_principal
        port map(
            clk                 => CLOCK_50,
            rst                 => RESET,
            cantidad_digitos    => cantidad_digitos,
            clave_completa      => clave_completa,
            clave_correcta      => clave_correcta,
            intentos_actuales   => intentos,
            intrusion           => INTRUSION_IN,
            tiempo_apertura_fin => apertura_fin,
            tiempo_bloqueo_fin  => bloqueo_fin,
            tiempo_error_fin    => error_fin,
            estado_out          => estado_sistema,
            limpiar_clave       => limpiar_clave_s,
            incrementar_intento => incrementar_int_s,
            limpiar_intentos    => limpiar_intentos_s,
            iniciar_apertura    => iniciar_apertura_s,
            iniciar_bloqueo     => iniciar_bloqueo_s,
            iniciar_error       => iniciar_error_s,
            activar_alarma      => activar_alarma_s,
            abrir_puerta        => abrir_puerta_s
        );

    u_hex0_num : fiveb port map(entrada => dig_hex0, seg => seg_h0_num);
    u_hex1_num : fiveb port map(entrada => dig_hex1, seg => seg_h1_num);
    u_hex2_num : fiveb port map(entrada => dig_hex2, seg => seg_h2_num);
    u_hex3_num : fiveb port map(entrada => dig_hex3, seg => seg_h3_num);

    u_letra_a : decodificador_7seg_alfanumerico port map(codigo => "001", seg => seg_a);
    u_letra_b : decodificador_7seg_alfanumerico port map(codigo => "010", seg => seg_b);
    u_letra_r : decodificador_7seg_alfanumerico port map(codigo => "011", seg => seg_r);
    u_letra_l : decodificador_7seg_alfanumerico port map(codigo => "100", seg => seg_l);
    u_letra_e : decodificador_7seg_alfanumerico port map(codigo => "101", seg => seg_e);
    u_letra_i : decodificador_7seg_alfanumerico port map(codigo => "110", seg => seg_i);
    u_letra_d : decodificador_7seg_alfanumerico port map(codigo => "111", seg => seg_d);
    u_blanco  : decodificador_7seg_alfanumerico port map(codigo => "000", seg => seg_blanco);

    process(estado_sistema, apertura_valor, bloqueo_valor)
        variable temp : integer range 0 to 9;
    begin
        if estado_sistema = "010" then
            temp := apertura_valor mod 10;
        elsif estado_sistema = "100" then
            temp := bloqueo_valor mod 10;
        else
            temp := 0;
        end if;

        unidad_temp <= std_logic_vector(to_unsigned(temp, 4));
    end process;

    u_unidad : fiveb
        port map(
            entrada => unidad_temp,
            seg     => seg_unidad
        );

    process(estado_sistema, cantidad_digitos, seg_h0_num, seg_h1_num, seg_h2_num, seg_h3_num,
            seg_a, seg_b, seg_r, seg_l, seg_e, seg_i, seg_d, seg_blanco, seg_unidad)
    begin
        if estado_sistema = "001" then
            if cantidad_digitos = 0 then
                HEX0 <= seg_blanco;
                HEX1 <= seg_blanco;
                HEX2 <= seg_blanco;
                HEX3 <= seg_blanco;
            else
                HEX0 <= seg_h0_num;
                HEX1 <= seg_h1_num;
                HEX2 <= seg_h2_num;
                HEX3 <= seg_h3_num;
            end if;

        elsif estado_sistema = "010" then
            -- AbrX
            HEX3 <= seg_a;
            HEX2 <= seg_b;
            HEX1 <= seg_r;
            HEX0 <= seg_unidad;

        elsif estado_sistema = "011" then
            -- Err
            HEX3 <= seg_e;
            HEX2 <= seg_r;
            HEX1 <= seg_r;
            HEX0 <= seg_blanco;

        elsif estado_sistema = "100" then
            -- ALrX
            HEX3 <= seg_a;
            HEX2 <= seg_l;
            HEX1 <= seg_r;
            HEX0 <= seg_unidad;

        else
            -- IdLE
            HEX3 <= seg_i;
            HEX2 <= seg_d;
            HEX1 <= seg_l;
            HEX0 <= seg_e;
        end if;
    end process;

    LED_ABRIR_PUERTA <= abrir_puerta_s;
    LED_ALARMA       <= '1' when (activar_alarma_s = '1' or estado_sistema = "100") else '0';
    LED_BLOQUEO      <= '1' when estado_sistema = "100" else '0';

end arquitectura_sistema_control_acceso_top;