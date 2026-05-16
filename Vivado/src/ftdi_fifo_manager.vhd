library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ftdi_fifo_manager is
    Port (
        clk           : in  STD_LOGIC; -- Reloj del sistema (ej. 100MHz)
        rst_n         : in  STD_LOGIC;
        
        -- Interfaz AXI-Stream SLAVE (PS -> FTDI / PC)
        s_axis_tdata  : in  STD_LOGIC_VECTOR(31 downto 0);        
        s_axis_tkeep  : in  STD_LOGIC_VECTOR(3 downto 0);
        s_axis_tlast  : in  STD_LOGIC;
        s_axis_tready : out STD_LOGIC;
        s_axis_tvalid : in  STD_LOGIC;

        -- Interfaz AXI-Stream MASTER (PC / FTDI -> DMA -> PS)
        m_axis_tdata  : out STD_LOGIC_VECTOR(31 downto 0);
        m_axis_tkeep  : out STD_LOGIC_VECTOR(3 downto 0);
        m_axis_tlast  : out STD_LOGIC;
        m_axis_tready : in  STD_LOGIC;
        m_axis_tvalid : out STD_LOGIC;
        
        -- Pines Físicos FTDI (Modo FIFO Asíncrono)
        ftdi_data     : inout STD_LOGIC_VECTOR(7 downto 0);
        ftdi_rxf_n    : in  STD_LOGIC; -- Bajo = Hay datos para leer
        ftdi_txe_n    : in  STD_LOGIC; -- Bajo = Se puede transmitir
        ftdi_rd_n     : out STD_LOGIC;
        ftdi_wr_n     : out STD_LOGIC;
        
        -- Diagnóstico
        led_rx_h      : out STD_LOGIC; -- Se enciende si recibe 'H' (0x48)
        sample_cnt    : out STD_LOGIC_VECTOR(10 downto 0)
    );
end ftdi_fifo_manager;

architecture Behavioral of ftdi_fifo_manager is

    -- Estados de la FSM Unificada
    type state_type is (
        IDLE, 
        AXI_FETCH,      -- Capturar 32-bit del bus AXI
        TX_PREPARE,     -- Seleccionar byte (0 a 3)
        -- TX_DRIVE,       -- Poner datos en el bus
        TX_PULSE_LOW,   -- Bajar WR#
        TX_PULSE_HIGH,  -- Subir WR# (Captura del FTDI)
        TX_HOLD,        -- Tiempo de espera entre bytes
        RX_START,       -- Bajar RD#
        RX_WAIT,        -- Tiempo de acceso del FTDI
        RX_CAPTURE,     -- Leer el bus y subir RD#
        RX_RECOVERY,    -- Tiempo de recuperación del bus
        AXI_MASTER_SEND -- Envia datos a traves de axi master
    );

    signal state            : state_type := IDLE;
    signal tx_data_reg      : std_logic_vector(31 downto 0);
    signal rx_data_reg      : std_logic_vector(31 downto 0);

    signal rx_idx : integer range 0 to 3 := 0;
    signal tx_idx : integer range 0 to 3 := 0;
    signal wait_counter     : integer range 0 to 15 := 0;
    signal sample_counter   : integer range 0 to 2047 := 0; -- Para la ventana de 10ms (8KB)
    
    -- Señales internas para el bus tri-state
    signal drive_bus        : std_logic := '0';
    signal tx_byte_out      : std_logic_vector(7 downto 0);

begin

    -- Control del Bus de Datos (Tri-state)
    -- Solo manejamos el bus si NO estamos en un estado de lectura (RD# debe ser '1')
    ftdi_data <= tx_byte_out when (drive_bus = '1') else (others => 'Z');

    -- TKEEP fijo en 1111 para el Master (Siempre mandamos 4 bytes)
    m_axis_tkeep <= "1111";

    -- Asignacion continua para el ILA
    sample_cnt <= std_logic_vector(to_unsigned(sample_counter, 11));

    -- Lógica Principal
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= IDLE;
                s_axis_tready <= '0';
                m_axis_tvalid <= '0';
                m_axis_tlast  <= '0';
                ftdi_rd_n <= '1';
                ftdi_wr_n <= '1';
                drive_bus <= '0';
                rx_idx <= 0;
                tx_idx <= 0;
                sample_counter <= 0;
                led_rx_h <= '0';
            else
                case state is

                    when IDLE =>
                        ftdi_rd_n <= '1';
                        ftdi_wr_n <= '1';
                        drive_bus <= '0';
                        rx_idx <= 0;
                        tx_idx <= 0;
                        m_axis_tvalid <= '0';
                        m_axis_tlast <= '0';
                        
                        -- PRIORIDAD 1: Transmisión (DMA -> PC)
                        -- Si el FIFO AXI tiene datos y el FTDI tiene espacio
                        if s_axis_tvalid = '1' and ftdi_txe_n = '0' then
                            if s_axis_tkeep = "1111" then
                                s_axis_tready <= '1'; -- word is accepted
                                state <= AXI_FETCH;
                            else
                                s_axis_tready <= '1';
                                state <= IDLE;
                            end if;
                        
                        -- PRIORIDAD 2: Recepción (PC -> FPGA)
                        elsif ftdi_rxf_n = '0' and m_axis_tready = '1' then
                            state <= RX_START;
                        end if;

                    -- ---------------------------------------------------
                    -- TRANSMISION (TX: FPGA -> PC)
                    -- ---------------------------------------------------
                    when AXI_FETCH =>
                        tx_data_reg <= s_axis_tdata;
                        s_axis_tready <= '0'; -- Cerramos el grifo del FIFO
                        rx_idx <= 0;
                        led_rx_h <= '0';
                        state <= TX_PREPARE;

                    when TX_PREPARE =>
                        -- Selección de byte (Little Endian)
                        case rx_idx is
                            when 0 => tx_byte_out <= tx_data_reg(7 downto 0);
                            when 1 => tx_byte_out <= tx_data_reg(15 downto 8);
                            when 2 => tx_byte_out <= tx_data_reg(23 downto 16);
                            when 3 => tx_byte_out <= tx_data_reg(31 downto 24);
                        end case;
                        drive_bus <= '1';
                        state <= TX_PULSE_LOW;

                    when TX_PULSE_LOW =>
                        if ftdi_txe_n = '0' then -- Doble check de seguridad
                            ftdi_wr_n <= '0'; -- Iniciamos pulso de escritura
                            wait_counter <= 0;
                            state <= TX_PULSE_HIGH;
                        end if;

                    when TX_PULSE_HIGH =>
                        if wait_counter < 5 then -- Pulso de ~40ns a 100MHz
                            wait_counter <= wait_counter + 1;
                        else
                            ftdi_wr_n <= '1'; -- Finalizamos pulso (Flanco de subida captura)
                            state <= TX_HOLD;
                            wait_counter <= 0;
                        end if;

                    when TX_HOLD =>
                        -- Breve espera para que el FTDI procese el byte
                        if wait_counter < 3 then
                            wait_counter <= wait_counter + 1;
                        else
                            if rx_idx = 3 then
                                drive_bus <= '0'; -- Liberamos el bus tras el float completo
                                state <= IDLE; 
                            else
                                rx_idx <= rx_idx + 1;
                                state <= TX_PREPARE; -- Siguiente byte del mismo float
                            end if;
                        end if;

                    -- ----------------------------------------------------
                    -- RECEPCION (RX: PC -> FPGA -> DMA)
                    -- ----------------------------------------------------
                    when RX_START =>
                        drive_bus <= '0'; -- ASEGURAR que la FPGA no maneja el bus
                        ftdi_rd_n <= '0'; -- Pedimos datos al chip
                        wait_counter <= 0;
                        led_rx_h <= '1';
                        state <= RX_WAIT;

                    when RX_WAIT =>
                        if wait_counter < 5 then -- Tiempo de acceso (Tacc) del FTDI
                            wait_counter <= wait_counter + 1;
                        else
                            state <= RX_CAPTURE;
                        end if;

                    when RX_CAPTURE =>
                        -- Empaquetar byte en registro de 32 bits
                        case tx_idx is
                            when 0 => rx_data_reg(7 downto 0)   <= ftdi_data;
                            when 1 => rx_data_reg(15 downto 8)  <= ftdi_data;
                            when 2 => rx_data_reg(23 downto 16) <= ftdi_data;
                            when 3 => rx_data_reg(31 downto 24) <= ftdi_data;
                        end case;
                        ftdi_rd_n <= '1'; -- Cerramos la lectura
                        state <= RX_RECOVERY;

                    when RX_RECOVERY =>
                        if tx_idx = 3 then
                            state <= AXI_MASTER_SEND; -- Palabra de 32 bits completa
                        else
                            tx_idx <= tx_idx + 1;
                            state <= RX_START;
                        end if;

                    when AXI_MASTER_SEND => 
                        m_axis_tdata <= rx_data_reg;
                        m_axis_tvalid <= '1';

                        -- Generar TLAST al final de los 8KB (2048 muestras)
                        if sample_counter = 2047 then
                            m_axis_tlast <= '1';
                        else
                            m_axis_tlast <= '0';
                        end if;

                        if m_axis_tready = '1' then
                            tx_idx <= 0;

                            if sample_counter = 2047 then
                                sample_counter <= 0;
                            else
                                sample_counter <= sample_counter + 1;
                            end if;
                            state <= IDLE; -- Pequeña pausa antes de volver a IDLE
                        else
                            state <= AXI_MASTER_SEND;                        
                        end if;

                    when others => state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;