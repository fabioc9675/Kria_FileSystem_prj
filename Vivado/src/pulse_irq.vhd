library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pulse_irq is
    Port ( 
        clk           : in  STD_LOGIC;  -- 100 MHz (Sistema)
        reset_n       : in  STD_LOGIC;
        audio_sample_tick : in STD_LOGIC; -- El reloj de 96kHz (o el "tick" del generador)
        irq_out       : out STD_LOGIC_VECTOR(1 downto 0) -- 0: Bloque, 1: Mitad
    );
end pulse_irq;

architecture Behavioral of pulse_irq is
    -- Constantes para Dave
    constant BLOCK_SIZE   : integer := 1024;
    constant HALF_BLOCK   : integer := 512;
    constant PULSE_WIDTH  : integer := 20; -- 20 ciclos a 100MHz para que el GIC lo vea bien

    -- Senales de control
    signal sample_reg     : std_logic_vector(2 downto 0) := (others => '0');
    signal tick_detected  : std_logic;
    signal sample_counter : integer range 0 to 1023 := 0;
    
    -- Registros de salida
    signal hold_block, hold_half : integer range 0 to 31 := 0;
    
begin

    -- 1. Detector de flanco para el audio (Traemos 96kHz al dominio de 100MHz)
    process(clk)
    begin
        if rising_edge(clk) then
            sample_reg <= sample_reg(1 downto 0) & audio_sample_tick;
        end if;
    end process;
    
    -- Detecta flanco de subida
    tick_detected <= '1' when sample_reg(1) = '1' and sample_reg(2) = '0' else '0';

    -- 2. Logica de conteo de muestras y generacion de IRQs
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                sample_counter <= 0;
                hold_block <= 0;
                hold_half <= 0;
            else
                -- Logica de contadores de pulso (Hold)
                if hold_block > 0 then hold_block <= hold_block - 1; end if;
                if hold_half  > 0 then hold_half  <= hold_half  - 1; end if;

                -- Conteo de muestras de audio
                if tick_detected = '1' then
                    if sample_counter = (BLOCK_SIZE - 1) then
                        sample_counter <= 0;
                        hold_block <= PULSE_WIDTH; -- IRQ de Bloque Completo (1024)
                    else
                        sample_counter <= sample_counter + 1;
                        
                        -- Interrupcion en la mitad (Muestra 512)
                        if sample_counter = (HALF_BLOCK - 1) then
                            hold_half <= PULSE_WIDTH;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Asignación de salidas
    irq_out(0) <= '1' when hold_block > 0 else '0'; -- Interrupción 1024
    irq_out(1) <= '1' when hold_half  > 0 else '0'; -- Interrupción 512 (Mitad)

end Behavioral;