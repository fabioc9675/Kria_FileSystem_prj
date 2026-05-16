library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity master_irq_ps is
    Port ( 
        clk      : in  STD_LOGIC;  -- 100 MHz
        reset_n  : in  STD_LOGIC;
        en_irq   : in  STD_LOGIC;  -- Habilitacion global de IRQs (CORE0 desde AXI GPIO)
        irq_out  : out STD_LOGIC_VECTOR(5 downto 0) -- [0]=BlockSync, [1]=WritePhase
    );
end master_irq_ps;

architecture Behavioral of master_irq_ps is
    -- Constantes para 100MHz
    -- 10ms = 1,000,000 ciclos
    -- 5ms  =   500,000 ciclos
    constant MAX_10MS    : integer := 1000000; 
    constant DELAY_5MS   : integer := 500000;
    constant PULSE_WIDTH : integer := 10; -- 100ns de ancho de pulso
    
    -- Master Counter para sincronia perfecta
    signal master_cnt    : integer range 0 to 1000000 := 0;
    signal running       : std_logic := '0'; -- Indica si el contador esta activo (despues del reset)
    
    -- Registros de IRQ
    signal reg_block_sync  : std_logic := '0';
    signal reg_write_phase : std_logic := '0';

begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            master_cnt <= 0;
            running <= '0';
            reg_block_sync <= '0';
            reg_write_phase <= '0';
        elsif rising_edge(clk) then

            -- Logica de activacion controlada
            if en_irq = '1' then
                running <= '1'; -- Habilita el contador maestro
            else
                running <= '0'; -- Detiene el contador maestro
                master_cnt <= 0; -- Reinicia el contador si se deshabilita
            end if;

            -- Generacion de senales solo si 'running' es '1'
            if running = '1' then         
                -- --- CONTADOR MAESTRO (10ms) ---
                if master_cnt < (MAX_10MS - 1) then
                    master_cnt <= master_cnt + 1;
                else
                    master_cnt <= 0;
                end if;

                -- --- GENERACION DE BLOCK_SYNC_IRQ (T = 0ms) ---
                -- Se dispara al inicio del ciclo del contador maestro
                if master_cnt < PULSE_WIDTH then
                    reg_block_sync <= '1';
                else
                    reg_block_sync <= '0';
                end if;

                -- --- GENERACION DE WRITE_PHASE_IRQ (T = 5ms) ---
                -- Se dispara exactamente a la mitad del ciclo del maestro
                if master_cnt >= DELAY_5MS and master_cnt < (DELAY_5MS + PULSE_WIDTH) then
                    reg_write_phase <= '1';
                else
                    reg_write_phase <= '0';
                end if;  
            else
                reg_block_sync <= '0'; -- Asegura que las salidas esten en '0' si no se esta ejecutando
                reg_write_phase <= '0'; -- Asegura que las salidas esten en '0' si no se esta ejecutando
                master_cnt <= 0; -- Reinicia el contador si no se esta ejecutando
            end if;          
        end if;
    end process;

    -- Asignacion segun requerimientos de Arch-A_PS
    irq_out(0) <= reg_block_sync;  -- Block_Sync_IRQ (Para Core 0)
    irq_out(1) <= reg_block_sync;  -- Block_Sync_IRQ (Para Core 1)
    irq_out(2) <= reg_block_sync;  -- Block_Sync_IRQ (Para Core 3)
    irq_out(3) <= reg_write_phase; -- Write_Phase_IRQ (Para Core 0, retardado 5ms)
    irq_out(4) <= reg_write_phase; -- Write_Phase_IRQ (Para Core 1, retardado 5ms)
    irq_out(5) <= reg_write_phase; -- Write_Phase_IRQ (Para Core 3, retardado 5ms)    

    -- Los demas canales quedan en '0' para futuras implementaciones
    -- irq_out(5 downto 3) <= (others => '0'); 

end Behavioral;