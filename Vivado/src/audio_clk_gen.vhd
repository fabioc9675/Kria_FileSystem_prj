library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audio_clk_gen is
    generic (
        CLK_IN_FREQ  : integer := 100000000; -- 100 MHz
        CLK_OUT_FREQ : integer := 96000      -- 96 kHz
    );
    port (
        clk          : in  std_logic;
        reset_n      : in  std_logic;
        audio_clk_96 : out std_logic
    );
end audio_clk_gen;

architecture Behavioral of audio_clk_gen is
    -- Calculamos el limite para el contador (mitad del periodo para duty cycle 50%)
    constant COUNT_MAX : integer := (CLK_IN_FREQ / CLK_OUT_FREQ);
    constant HALF_PERIOD : integer := COUNT_MAX / 2;
    
    signal counter : integer range 0 to COUNT_MAX := 0;
    signal clk_reg : std_logic := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                counter <= 0;
                clk_reg <= '0';
            else
                if counter >= (COUNT_MAX - 1) then
                    counter <= 0;
                    clk_reg <= '1';
                elsif counter = (HALF_PERIOD - 1) then
                    clk_reg <= '0';
                    counter <= counter + 1;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

    audio_clk_96 <= clk_reg;

end Behavioral;