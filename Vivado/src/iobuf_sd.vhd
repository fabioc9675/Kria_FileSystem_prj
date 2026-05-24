library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity sd_io_wrapper is
    Port ( 
        -- Puertos descompuestos desde el Zynq (EMIO)
        -- Se agruparán en el Block Design mediante nombres estándar
        emio_sdio1_clk_out    : in  std_logic;
        emio_sdio1_fb_clk_in  : out std_logic;
        emio_sdio1_cmdout     : in  std_logic;
        emio_sdio1_cmdin      : out std_logic;
        emio_sdio1_cmdena     : in  std_logic;
        emio_sdio1_dataout    : in  std_logic_vector(3 downto 0);
        emio_sdio1_datain     : out std_logic_vector(3 downto 0);
        emio_sdio1_dataena    : in  std_logic_vector(3 downto 0);
        emio_sdio1_cd_n       : out std_logic;
        
        -- Estos no los usamos pero el Zynq los pide
        emio_sdio1_wp         : out std_logic;
        emio_sdio1_ledcontrol : in std_logic;
        emio_sdio1_bus_volt   : in std_logic_vector(2 downto 0);
        
        -- Puertos físicos (estos se quedan individuales para el XDC)
        sd_clk_out            : out std_logic;
        sd_clk_fb             : in  std_logic;
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
        I => emio_sdio1_clk_out,
        O => sd_clk_out
    );

    ibuf_clk : IBUF
    port map (
        I => sd_clk_fb,
        O => emio_sdio1_fb_clk_in
    );

    -- El Feedback es esencial para que el controlador sincronice la lectura
    -- emio_sdio1_fb_clk_in <= not emio_sdio1_clk_out;

    -- 2. Constantes de estado (L�gica interna)
    -- Card Detect: '0' indica que la tarjeta est� PRESENTE (l�gica negativa)
    emio_sdio1_cd_n <= '0';
    emio_sdio1_wp <= '0';

    -- 3. Buffer bidireccional para el Comando (CMD)
    -- Invertimos 'ena' porque T=0 es salida y T=1 es entrada (Hi-Z)
    iobuf_cmd : IOBUF
    port map (
        I  => emio_sdio1_cmdout,
        T  => emio_sdio1_cmdena,
        O  => emio_sdio1_cmdin,
        IO => sd_cmd_io
    );

    -- 4. Buffers bidireccionales para los 4 bits de Datos (DATA)
    gen_sd_data: for i in 0 to 3 generate
        iobuf_data : IOBUF
        port map (
            I  => emio_sdio1_dataout(i),
            T  => emio_sdio1_dataena(i),
            O  => emio_sdio1_datain(i),
            IO => sd_data_io(i)
        );
    end generate gen_sd_data;

end Behavioral;