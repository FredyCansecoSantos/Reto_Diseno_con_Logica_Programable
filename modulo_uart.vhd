----------------------------------------------------------------------------------
-- LEE_TX_LISTO          en X"11";
-- ESCRIBE_DATO_TX       en X"12";
-- LEE_DATO_RX           en X"13"
-- LEE_DATO_LISTO_RX     en X"14"
-- ESCRIBE_DATO_RX_LEIDO en X"15"
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

entity modulo_uart is
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
                      RX : in STD_LOGIC
                      );
end modulo_uart;

architecture Behavioral of modulo_uart is
--se declaran los componentes internos
component baud_rate_clock is
    Port ( 
                    CLK : in  STD_LOGIC;
           EN_16_X_BAUD : out  STD_LOGIC
           );
end component;

component uart_tx6 is
  Port (             data_in : in std_logic_vector(7 downto 0);
                en_16_x_baud : in std_logic;
                  serial_out : out std_logic;
                buffer_write : in std_logic;
         buffer_data_present : out std_logic;
            buffer_half_full : out std_logic;
                 buffer_full : out std_logic;
                buffer_reset : in std_logic;
                         clk : in std_logic);
  end component;

component uart_rx6 is
  Port (           serial_in : in std_logic;
                en_16_x_baud : in std_logic;
                    data_out : out std_logic_vector(7 downto 0);
                 buffer_read : in std_logic;
         buffer_data_present : out std_logic;
            buffer_half_full : out std_logic;
                 buffer_full : out std_logic;
                buffer_reset : in std_logic;
                         clk : in std_logic);
  end component;
  
--declaración de señales para uart_tx
signal tx_buffer_write, tx_buffer_full : std_logic;
signal tx_data_in : std_logic_vector(7 downto 0);
type fsm_tx_edos is (S1, S2);
signal fsm_tx_sig, fsm_tx_pres : fsm_tx_edos;
signal tx_busy : std_logic;
signal dato_tx_sig, dato_tx_pres : std_logic_vector(7 downto 0);
constant LEE_TX_LISTO    : std_logic_vector(7 downto 0) := X"11";
constant ESCRIBE_DATO_TX : std_logic_vector(7 downto 0) := X"12";

--declaración de señales para uart_rx
signal rx_data_out : std_logic_vector(7 downto 0);
signal rx_buffer_read, rx_buffer_data_present : std_logic;
signal rx_buffer_read_pres, rx_buffer_read_sig : std_logic;
constant LEE_DATO_RX           : std_logic_vector(7 downto 0) := X"13";
constant LEE_DATO_LISTO_RX     : std_logic_vector(7 downto 0) := X"14";
constant ESCRIBE_DATO_RX_LEIDO : std_logic_vector(7 downto 0) := X"15";


--declaración de señales del baud rate generator
signal s_en_16_x_baud : std_logic;

--declaración de señales temporales
signal temporal_tx, temporal_rx : std_logic_vector(7 downto 0); 

begin
        baud_rate_generator : baud_rate_clock
                              port map(
                                                 CLK => CLK,
                                        EN_16_X_BAUD => s_en_16_x_baud 
                              );
                              
        uart_tx :   uart_tx6
                    port map(
                                        data_in => tx_data_in,
                                   en_16_x_baud => s_en_16_x_baud,
                                     serial_out => TX,
                                   buffer_write => tx_buffer_write,
                            buffer_data_present => open,
                               buffer_half_full => open,
                                    buffer_full => tx_buffer_full,
                                   buffer_reset => '0',
                                            clk => CLK
                    );
                    
        uart_rx :   uart_rx6
                    port map(
                                          serial_in => RX,
                                       en_16_x_baud => s_en_16_x_baud,
                                           data_out => rx_data_out,
                                        buffer_read => rx_buffer_read,
                                buffer_data_present => rx_buffer_data_present,
                                   buffer_half_full => open,
                                        buffer_full => open,
                                       buffer_reset => '0',
                                                clk => CLK 
                    );
                    
       --lectura del estado del buffer de TX y del estado de la máquina para TX
       --lectura si hay dato RX nuevo, lectura del dato RX e informe que nuevo dato RX ha sido leído
       temporal_tx <= "0000000" & (tx_buffer_full or tx_busy);
       temporal_rx <= "0000000" & (rx_buffer_data_present);
       OUTPUT_PORT <= temporal_tx    when (PORT_ID = LEE_TX_LISTO)      else
                      temporal_rx    when (PORT_ID = LEE_DATO_LISTO_RX) else
                      rx_data_out    when (PORT_ID = LEE_DATO_RX)       else
                      (others => '0');
                      
       --escritura del dato al buffer de tx
       dato_tx_sig <= INPUT_PORT when (PORT_ID = ESCRIBE_DATO_TX and WRITE_STROBE = '1') else
                      dato_tx_pres;
                      
       --fsm para escribir un dato a tx, tx está siempre habilitado
       tx_data_in <= dato_tx_pres;
       maquina_tx : process(PORT_ID, WRITE_STROBE, fsm_tx_pres)
                    begin
                            --valores por omisión
                            tx_busy <= '0';
                            fsm_tx_sig <= S1;
                            tx_buffer_write <= '0';
                            
                            case (fsm_tx_pres) is
                                 when S1 => --en espera de que se escriba el dato TX
                                            if(PORT_ID = ESCRIBE_DATO_TX and WRITE_STROBE = '1') then
                                                    fsm_tx_sig <= S2;
                                                    tx_busy <= '1';
                                            end if;
                                 when S2 => --dato listo, aplica escritura, tx aún ocupado
                                            tx_busy <= '1';
                                            tx_buffer_write <= '1';
                                            
                            end case;
                    end process maquina_tx;
                    
       --informa que dato RX actual ya ha sido leído
       rx_buffer_read_sig <= '1' when (PORT_ID = ESCRIBE_DATO_RX_LEIDO and WRITE_STROBE = '1') else
                               '0';
       rx_buffer_read <= rx_buffer_read_pres;
                           
       
       --proceso secuencial              
       secuencial : process(CLK, RST)
                    begin
                            if(RST = '1') then
                                                fsm_tx_pres <= S1;
                                                dato_tx_pres <= (others => '0');
                                                rx_buffer_read_pres <= '0';
                            elsif(CLK'event and CLK = '1') then
                                                fsm_tx_pres <= fsm_tx_sig;
                                                dato_tx_pres <= dato_tx_sig;
                                                rx_buffer_read_pres <= rx_buffer_read_sig;
                            end if;
                    end process secuencial; 


end Behavioral;