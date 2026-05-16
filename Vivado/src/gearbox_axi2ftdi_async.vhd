library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gearbox_axi2ftdi_async is
    Generic (
        CLK_FREQ_MHZ    : integer := 100 
    );
    Port (
        clk             : in  std_logic;
        rst_n           : in  std_logic;

        -- AXI Interface
        s_axis_tdata    : in  std_logic_vector(31 downto 0);
        s_axis_tkeep    : in STD_LOGIC_VECTOR(3 downto 0);
        s_axis_tlast    : in  std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tvalid   : in  std_logic;

        -- ftdi physic interface (Async mode)
        ftdi_data       : out std_logic_vector(7 downto 0);
        ftdi_wr_n       : out std_logic; -- write enable (active low)
        ftdi_txe_n      : in  std_logic  -- TX empty (low = can read)
    );
end gearbox_axi2ftdi_async;

architecture Behavioral of gearbox_axi2ftdi_async is
    type state_type is (IDLE, FETCH, SEND_BYTE, WAIT_TXE, NEXT_BYTE);
    signal state        : state_type := IDLE;

    signal data_reg     : std_logic_vector(31 downto 0);
    signal byte_idx     : integer range 0 to 3 := 0;
    signal wr_n_int     : std_logic := '1';

begin

    ftdi_wr_n <= wr_n_int;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= IDLE;
                s_axis_tready <= '0';
                wr_n_int <= '1';
                byte_idx <= 0;
            else
                case state is
                    -- Wait for data in FiFo
                    when IDLE => 
                        wr_n_int <= '1';
                        byte_idx <= 0;
                        if s_axis_tvalid = '1' then
                            if s_axis_tkeep = "1111" then
                                s_axis_tready <= '1'; -- word is accepted
                                state <= FETCH;
                            else
                                s_axis_tready <= '1';
                                state <= IDLE;
                            end if;
                        else
                            s_axis_tready <= '0';
                        end if;
                    -- capture 32 bits and close the FiFo
                    when FETCH =>
                        data_reg <= s_axis_tdata;
                        s_axis_tready <= '0';
                        state <= SEND_BYTE;
                    -- Prepare current byte and verify the FTDI
                    when SEND_BYTE =>
                        if ftdi_txe_n = '0' then -- chip has space
                            -- select the byte (Little Endian: B0 -> B1 -> B2 -> B3)
                            case byte_idx is
                                when 0 => ftdi_data <= data_reg(7 downto 0);
                                when 1 => ftdi_data <= data_reg(15 downto 8);
                                when 2 => ftdi_data <= data_reg(23 downto 16);
                                when 3 => ftdi_data <= data_reg(31 downto 24);
                            end case;
                            wr_n_int <= '0'; -- Generate write pulse (low)
                            state <= WAIT_TXE;
                        end if;
                    -- Maintain WR pulse active one cycle (Setup/Hold FTDI)
                    when WAIT_TXE => 
                        wr_n_int <= '1'; -- rise WR (FTDI captures rising edge)
                        state <= NEXT_BYTE;
                    -- Decide next byte or next 32 bits word
                    when NEXT_BYTE =>
                        if byte_idx = 3 then
                            state <= IDLE;
                        else
                            byte_idx <= byte_idx + 1;
                            state <= SEND_BYTE; -- go for the next byte
                        end if;
                    when others => 
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
