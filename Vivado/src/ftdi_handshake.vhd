library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity ftdi_handshake is
    port (
        clk : in STD_LOGIC;
        rst_n : in STD_LOGIC;
        -- Pins FTDI PMOD FT245 FIFO
        ftdi_data : inout STD_LOGIC_VECTOR(7 downto 0);
        ftdi_rxf : in STD_LOGIC;
        ftdi_txe : in STD_LOGIC;
        ftdi_rd : out STD_LOGIC;
        ftdi_wr : out STD_LOGIC;
        -- Test output
        led_h : out STD_LOGIC
    );
end ftdi_handshake;

architecture Behavioral of ftdi_handshake is
    type state_type is (
        IDLE,
        TX_SETUP,
        TX_WRITE_LOW,
        TX_WRITE_HIGH,
        TX_HOLD,
        WAIT_RX,
        RX_ASSERT_RD,
        RX_WAIT_DATA,
        RX_READ,
        RX_RELEASE
    );
    signal state_rx    : state_type := IDLE;
    signal state_tx    : state_type := IDLE;
    signal counter_rx  : INTEGER := 0;
    signal counter_tx  : INTEGER := 0;

    signal ftdi_rd_int : std_logic := '1';
    signal ftdi_wr_int : std_logic := '1';
    signal drive_bus   : std_logic := '0';
    signal reg_led     : STD_LOGIC := '0';
    signal tx_data     : std_logic_vector(7 downto 0) := x"41"; -- 'A'
begin

    -- Tri-state for the ADBUS lines
    -- only drive the bus when drive_bus is '1'
    ftdi_rd <= ftdi_rd_int;
    ftdi_wr <= ftdi_wr_int;
    led_h   <= reg_led;

    -- arbitrate the bus
    ftdi_data <= tx_data when (drive_bus = '1' and ftdi_rd_int = '1') else (others => 'Z');

    transmission:  process (clk, rst_n)
    begin
        if rst_n = '0' then
            state_tx <= IDLE;
            ftdi_wr_int <= '1';
            drive_bus <= '0';
        elsif rising_edge(clk) then
            case state_tx is
                    -- ============= TX ============= 
                when IDLE =>
                    ftdi_wr_int <= '1'; -- Ensure write is deasserted
                    -- Wait for FTDI to be ready to accept data
                    if ftdi_txe = '0' and ftdi_wr_int = '1' then -- FTDI ready to accept data
                        drive_bus <= '1'; -- Drive the bus with data
                        state_tx <= TX_SETUP;
                    else 
                        drive_bus <= '0';
                    end if;

                when TX_SETUP =>
                    state_tx <= TX_WRITE_LOW;

                when TX_WRITE_LOW =>
                    ftdi_wr_int <= '0'; -- Deassert write after one cycle
                    counter_tx <= 0;
                    state_tx <= TX_WRITE_HIGH;

                when TX_WRITE_HIGH =>
                    if counter_tx < 2 then
                        counter_tx <= counter_tx + 1;
                    else
                        ftdi_wr_int <= '1'; -- drive WR to high, FTDI makes capture here
                        state_tx <= TX_HOLD; -- go to the intermediate state
                    end if;

                when TX_HOLD =>
                    drive_bus <= '0'; -- freedom bus
                    state_tx <= IDLE;

                when others =>
                    state_tx <= IDLE;
            end case;
        end if;
    end process transmission;

    reception:  process (clk, rst_n)
    begin
        if rst_n = '0' then
            state_rx <= IDLE;
            ftdi_rd_int <= '1';
            reg_led <= '0';
        elsif rising_edge(clk) then
            case state_rx is
                    -- ============= TX ============= 
                when IDLE =>
                    ftdi_rd_int <= '1'; -- Ensure read is deasserted
                    -- Wait for the PC response
                    if ftdi_rxf = '0' then -- FTDI has data to read
                        state_rx <= RX_ASSERT_RD;
                    end if;
                    -- =================== RX ==================

                when RX_ASSERT_RD =>
                    ftdi_rd_int <= '0';
                    counter_rx <= 0;
                    state_rx <= RX_WAIT_DATA;

                when RX_WAIT_DATA =>
                    if counter_rx < 2 then
                        counter_rx <= counter_rx + 1;
                    else
                        state_rx <= RX_READ;
                    end if;

                when RX_READ =>
                    -- data is valid while RD is low 
                    if ftdi_data = x"48" then -- Check if we received 'H' (0x48)
                        reg_led <= '1'; -- Indicate we received 'H'
                    else
                        reg_led <= '0'; -- Clear LED if not 'H'
                    end if;
                    state_rx <= RX_RELEASE;

                when RX_RELEASE =>
                    ftdi_rd_int <= '1'; -- Deassert read after one cycle
                    state_rx <= IDLE;

                when others =>
                    state_rx <= IDLE;
            end case;
        end if;
    end process reception;

end Behavioral;