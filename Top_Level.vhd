----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.03.2022 11:08:11
-- Design Name: 
-- Module Name: Top_Level - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
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

entity Top_Level is
  Port ( clk : in std_logic;
         rst : in std_logic;
         MISO : in std_logic;
         sclk : buffer std_logic; 
         ss_n : buffer std_logic_vector(0 downto 0);  
         MOSI : out std_logic;
         rx : in std_logic;
         tx : out std_logic );
end Top_Level;

architecture Behavioral of Top_Level is

--Declaración de componentes ->

-- Componente del módulo SPI
component modulo_spi is
    Port (         CLK : in STD_LOGIC;
                   RST : in STD_LOGIC;
               PORT_ID : in STD_LOGIC_VECTOR (7 downto 0);
           OUTPUT_PORT : out STD_LOGIC_VECTOR (7 downto 0);
                  MISO : in  STD_LOGIC;                     
                  SCLK : buffer STD_LOGIC;                      
                  SS_N : buffer STD_LOGIC_VECTOR(0 DOWNTO 0);  
                  MOSI : out    STD_LOGIC);
end component;


-- Componente del registro del puerto de entrada
component registro_puerto_entrada is
	 generic(
				n : integer := 8			--ancho del registro verificar si se tiene que borrar
	 );
    Port ( 
			  CLK  : in  STD_LOGIC;
              RST  : in  STD_LOGIC;
                D  : in  STD_LOGIC_VECTOR(n-1 downto 0);
                Q  : out STD_LOGIC_VECTOR(n-1 downto 0)
          );
end component;

component embedded_kcpsm6 is
  port (                   
                             in_port : in std_logic_vector(7 downto 0);
                            out_port : out std_logic_vector(7 downto 0);
                             port_id : out std_logic_vector(7 downto 0);
                        write_strobe : out std_logic;
                      --k_write_strobe : out std_logic;
                        -- read_strobe : out std_logic;
                           --interrupt : in std_logic;
                       --interrupt_ack : out std_logic;
                           --    sleep : in std_logic;
                                 clk : in std_logic;
                                 rst : in std_logic);
end component;


-- Componente del módulo UART
component modulo_uart is
    Port ( 
                     CLK : in STD_LOGIC;
                     RST : in STD_LOGIC;
                     --pines de comunicación con PicoBlaze
                 PORT_ID : in STD_LOGIC_VECTOR (7 downto 0);
              INPUT_PORT : in STD_LOGIC_VECTOR (7 downto 0);
             OUTPUT_PORT : out STD_LOGIC_VECTOR (7 downto 0);
            WRITE_STROBE : in STD_LOGIC;
                      --pines de comunicación serial
                      TX : out STD_LOGIC;
                      RX : in STD_LOGIC);
end component;

-- Declaración de Señales
--Señal entre PORT ID's
signal puerto_ID :  std_logic_vector(7 downto 0);
--Señal entre el Out de picoblaze y la entrada de UART
signal input_puertos : std_logic_vector(7 downto 0);
signal write :  std_logic;
signal dato1_MUX : std_logic_vector(7 downto 0);
signal dato2_MUX : std_logic_vector(7 downto 0);
signal puerto_D :  std_logic_vector(7 downto 0);
signal puerto_Q :  std_logic_vector(7 downto 0);


begin
 
 puerto_D <= dato1_MUX when (puerto_ID(6) = '1') else
 dato2_MUX when (puerto_ID(4) = '1') else
 (others => '0');
 
 
 
 moduloSPI : modulo_spi port map(
		                                CLK => clk,
                                        RST => rst,
                                        PORT_ID => puerto_ID,
                                        OUTPUT_PORT => dato1_MUX,
                                        MISO => MISO,                  
                                        SCLK => sclk,                   
                                        SS_N => ss_n,
                                        MOSI => MOSI );
    
 registroPuertoEntrada : registro_puerto_entrada port map(
		                                 CLK => clk,
                                         RST => rst,
                                         D  => puerto_D,
                                         Q =>  puerto_Q );
                                         
 moduloUART : modulo_uart port map(
		                                CLK => clk,
                                        RST => rst,
                                        --pines de comunicación con PicoBlaze
                                        PORT_ID => puerto_ID,
                                        INPUT_PORT => input_puertos,
                                        OUTPUT_PORT => dato2_MUX,
                                        WRITE_STROBE => write,
                                        --pines de comunicación serial
                                        TX => tx,
                                        RX => rx);
                                    
                                        
  modulo_PICO_BLAZE : embedded_kcpsm6 port map (                   
                                        in_port => puerto_Q,
                                        out_port => input_puertos,
                                        port_id => puerto_ID,
                                        write_strobe => write,
                                        clk => clk,
                                        rst => rst);

end Behavioral;