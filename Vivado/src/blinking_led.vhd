library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blinking_led is
    generic ( 
        CLK_FREQ : integer := 100000000; -- Frecuencia del reloj en Hz
        BLINK_TIME : integer := 50000000  -- Tiempo de parpadeo en ns (0.5s)
    );
    Port ( clk   : in  STD_LOGIC;  -- Reloj de 100MHz
           rst   : in  STD_LOGIC;  -- Reset
           led   : out STD_LOGIC); -- Salida al LED
end blinking_led;

architecture Behavioral of blinking_led is
    -- 100MHz = 10ns por ciclo. 
    -- Para 0.5s necesitamos 50,000,000 ciclos.
    signal counter : integer range 0 to BLINK_TIME-1 := 0;
    signal led_state : std_logic := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then  -- Se activa cuando la señal cae a 0V
                counter <= 0;
                led_state <= '0';
            elsif counter = BLINK_TIME-1 then
                counter <= 0;
                led_state <= not led_state;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    led <= led_state;

end Behavioral;