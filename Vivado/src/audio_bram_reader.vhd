library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audio_bram_reader is
    generic (
        SAMPLES_PER_BLOCK : integer := 1024
    );
    port (
        -- Reloj Maestro desde el PS (Dominio AXI)
        clk           : in  std_logic; -- 100 MHz
        reset_n       : in  std_logic;
        
        -- Reloj de Muestreo desde Cristal Externo (PMOD)
        ext_audio_clk : in  std_logic; -- El cristal externo
        
        -- Interfaz hacia la BRAM (Block Memory Generator)
        addra         : out std_logic_vector(9 downto 0);
        douta         : in  std_logic_vector(31 downto 0);
        ena           : out std_logic;
        wea           : out std_logic_vector(0 downto 0);
        dina          : out std_logic_vector(31 downto 0);
        
        -- Interfaz AXI-Stream (Hacia FIFO/DMA)
        m_axis_tdata  : out std_logic_vector(31 downto 0);
        m_axis_tkeep  : out std_logic_vector(3 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tlast  : out std_logic;
        m_axis_tready : in  std_logic
    );
end audio_bram_reader;

architecture Behavioral of audio_bram_reader is
    -- Señales para Sincronizacion de Dominios (CDC)
    signal ext_clk_sync : std_logic_vector(2 downto 0) := (others => '0');
    signal sample_trigger : std_logic;
    
    -- Control de direccion y estado
    signal addr_cnt : unsigned(9 downto 0) := (others => '0');
    type state_type is (IDLE, FETCH, WAIT_BRAM, VALID);
    signal state : state_type := IDLE;
    signal wait_cnt : integer range 0 to 2 := 0;

begin
    -- Configuracion fija BRAM (Solo lectura)
    wea  <= "0";
    dina <= (others => '0');
    ena  <= '1';
    m_axis_tkeep <= "1111"; -- Siempre enviamos 4 bytes válidos

    -- Sincronizador: Trae el reloj de cristal externo al dominio de 100MHz
    process(clk)
    begin
        if rising_edge(clk) then
            ext_clk_sync <= ext_clk_sync(1 downto 0) & ext_audio_clk;
        end if;
    end process;
    
    -- Detector de flanco: Crea un pulso de 1 ciclo de 100MHz
    sample_trigger <= '1' when ext_clk_sync(1) = '1' and ext_clk_sync(2) = '0' else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                addr_cnt <= (others => '0');
                m_axis_tvalid <= '0';
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        m_axis_tvalid <= '0';
                        if sample_trigger = '1' then
                            state <= FETCH;
                        end if;

                    when FETCH =>
                        addra <= std_logic_vector(addr_cnt);
                        wait_cnt <= 0;
                        state <= WAIT_BRAM;

                    when WAIT_BRAM =>
                        -- Esperamos 2 ciclos por el "Primitives Output Register"
                        if wait_cnt = 1 then
                            state <= VALID;
                        else
                            wait_cnt <= wait_cnt + 1;
                        end if;

                    when VALID =>
                        if m_axis_tready = '1' then
                            m_axis_tdata <= douta;
                            m_axis_tvalid <= '1';
                            
                            -- Gestion de TLAST y Loop Circular
                            if addr_cnt = to_unsigned(SAMPLES_PER_BLOCK - 1, 10) then
                                m_axis_tlast <= '1';
                                addr_cnt <= (others => '0');
                            else
                                m_axis_tlast <= '0';
                                addr_cnt <= addr_cnt + 1;
                            end if;
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;
end Behavioral;