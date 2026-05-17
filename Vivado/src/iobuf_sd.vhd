library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity sd_io_wrapper is
    Port ( 
        -- Puertos desde el Zynq (EMIO SDIO 1)
        emio_sdio_1_clk_out   : in  std_logic;
        emio_sdio_1_clk_in_fb : out std_logic;
        
        emio_sdio_1_cmd_o     : in  std_logic;
        emio_sdio_1_cmd_i     : out std_logic;
        emio_sdio_1_cmd_ena   : in  std_logic;
        
        emio_sdio_1_data_o    : in  std_logic_vector(3 downto 0);
        emio_sdio_1_data_i    : out std_logic_vector(3 downto 0);
        emio_sdio_1_data_ena  : in  std_logic_vector(3 downto 0);
        
        emio_sdio_1_cd_i      : out std_logic; -- Card Detect (Hacia el Zynq)
        emio_sdio_1_wp        : out std_logic; -- Write Protect (Hacia el Zynq)
        
        -- Puertos f�sicos hacia el PMOD
        sd_clk_out            : out std_logic;
        sd_cmd_io             : inout std_logic;
        sd_data_io            : inout std_logic_vector(3 downto 0)
    );
end sd_io_wrapper;

architecture Behavioral of sd_io_wrapper is
begin

    -- 1. Manejo del Reloj y Feedback
    -- El OBUF asegura que la se�al salga con fuerza al PMOD
    obuf_clk : OBUF
    port map (
        I => emio_sdio_1_clk_out,
        O => sd_clk_out
    );
    -- El Feedback es esencial para que el controlador sincronice la lectura
    emio_sdio_1_clk_in_fb <= emio_sdio_1_clk_out;

    -- 2. Constantes de estado (L�gica interna)
    -- Card Detect: '0' indica que la tarjeta est� PRESENTE (l�gica negativa)
    emio_sdio_1_cd_i <= '0';
    -- Write Protect: '0' indica que la tarjeta NO est� protegida (permite escritura)
    emio_sdio_1_wp   <= '0';

    -- 3. Buffer bidireccional para el Comando (CMD)
    -- Invertimos 'ena' porque T=0 es salida y T=1 es entrada (Hi-Z)
    iobuf_cmd : IOBUF
    port map (
        I  => emio_sdio_1_cmd_o,
        T  => emio_sdio_1_cmd_ena,
        O  => emio_sdio_1_cmd_i,
        IO => sd_cmd_io
    );

    -- 4. Buffers bidireccionales para los 4 bits de Datos (DATA)
    gen_sd_data: for i in 0 to 3 generate
        iobuf_data : IOBUF
        port map (
            I  => emio_sdio_1_data_o(i),
            T  => emio_sdio_1_data_ena(i),
            O  => emio_sdio_1_data_i(i),
            IO => sd_data_io(i)
        );
    end generate gen_sd_data;

end Behavioral;