----------------------------------------------------------------------------------
-- Registro con carga paralela que conecta la salida del multiplexor
-- al IN_PORT del embedded kcpsm3
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity registro_puerto_entrada is
	 generic(
				n : integer := 8			--ancho del registro
	 );
    Port ( 
			  CLK  : in  STD_LOGIC;
           RST  : in  STD_LOGIC;
           D    : in  STD_LOGIC_VECTOR(n-1 downto 0);
           Q    : out STD_LOGIC_VECTOR(n-1 downto 0));
end registro_puerto_entrada;

architecture Behavioral of registro_puerto_entrada is

signal est_pres, est_sig : std_logic_vector(n-1 downto 0);

begin
		est_sig <= D;
							
	   secuencial : process(CLK, RST)
						begin
								if(RST = '1') then est_pres <= (others => '0');
								elsif(CLK'event and CLK = '1') then
														 est_pres <= est_sig;
								end if;
						end process secuencial;
						
		Q <= est_pres;
end Behavioral;

