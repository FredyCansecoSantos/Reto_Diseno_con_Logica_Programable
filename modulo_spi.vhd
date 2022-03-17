----------------------------------------------------------------------------------
-- LEE_X_LSB en X"41";
-- LEE_X_MSB en X"42";
-- LEE_Y_LSB en X"43";
-- LEE_Y_MSB en X"44";
-- LEE_Z_LSB en X"45";
-- LEE_Z_MSB en X"46";
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity modulo_spi is
    Port (         CLK : in STD_LOGIC;
                   RST : in STD_LOGIC;
               PORT_ID : in STD_LOGIC_VECTOR (7 downto 0);
           OUTPUT_PORT : out STD_LOGIC_VECTOR (7 downto 0);
                  MISO : in  STD_LOGIC;                     
                  SCLK : buffer STD_LOGIC;                      
                  SS_N : buffer STD_LOGIC_VECTOR(0 DOWNTO 0);  
                  MOSI : out    STD_LOGIC);
end modulo_spi;

architecture Behavioral of modulo_spi is
--declaración de componentes
component pmod_accelerometer_adxl345 IS
  GENERIC(
    clk_freq   : INTEGER := 50;              --system clock frequency in MHz
    data_rate  : STD_LOGIC_VECTOR := "0100"; --data rate code to configure the accelerometer
    data_range : STD_LOGIC_VECTOR := "00");  --data range code to configure the accelerometer
  PORT(
    clk            : IN      STD_LOGIC;                      --system clock
    reset_n        : IN      STD_LOGIC;                      --active low asynchronous reset
    miso           : IN      STD_LOGIC;                      --SPI bus: master in, slave out
    sclk           : BUFFER  STD_LOGIC;                      --SPI bus: serial clock
    ss_n           : BUFFER  STD_LOGIC_VECTOR(0 DOWNTO 0);   --SPI bus: slave select
    mosi           : OUT     STD_LOGIC;                      --SPI bus: master out, slave in
    acceleration_x : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);  --x-axis acceleration data
    acceleration_y : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);  --y-axis acceleration data
    acceleration_z : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0)); --z-axis acceleration data
END component;

--declaración de señales
signal accel_x, accel_y, accel_z : std_logic_vector(15 downto 0);
--signal not_rst : std_logic;
constant LEE_X_LSB : std_logic_vector(7 downto 0) := X"41";
constant LEE_X_MSB : std_logic_vector(7 downto 0) := X"42";
constant LEE_Y_LSB : std_logic_vector(7 downto 0) := X"43";
constant LEE_Y_MSB : std_logic_vector(7 downto 0) := X"44";
constant LEE_Z_LSB : std_logic_vector(7 downto 0) := X"45";
constant LEE_Z_MSB : std_logic_vector(7 downto 0) := X"46";

begin
        --negación del RST para conectarse al pmod
        --not_rst <= not RST;
        
        pmod_accel : pmod_accelerometer_adxl345
                     generic map(
                                    clk_freq => 100,
                                    data_rate => "1101",
                                    data_range => "00"
                                )
                     port map(
                                           clk => CLK,
                                       reset_n => RST,
                                          miso => MISO,
                                          sclk => SCLK,
                                          ss_n => SS_N,
                                          mosi => MOSI,
                                acceleration_x => accel_x,
                                acceleration_y => accel_y,
                                acceleration_z => accel_z
                                );

        --acceso a los 6 bytes del accelerómetro
        OUTPUT_PORT <=  accel_x(7  downto 0) when (PORT_ID = LEE_X_LSB) else
                        accel_x(15 downto 8) when (PORT_ID = LEE_X_MSB) else
                        accel_y(7  downto 0) when (PORT_ID = LEE_Y_LSB) else
                        accel_y(15 downto 8) when (PORT_ID = LEE_Y_MSB) else
                        accel_z(7  downto 0) when (PORT_ID = LEE_Z_LSB) else
                        accel_z(15 downto 8) when (PORT_ID = LEE_Z_MSB) else
                        (others => '0');
end Behavioral;
