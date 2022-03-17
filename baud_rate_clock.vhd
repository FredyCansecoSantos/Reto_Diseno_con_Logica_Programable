----------------------------------------------------------------------------------
-- Reloj que determina la velocidad de transmision del RX y TX
-- La senal de reloj alimenta a los modulos RX y TX a una velocidad
-- de 16 x la velocidad de transmision
-- Este bloque recibe un reloj de 100MHz y genera un reloj de 16 x 115200
-- De esta manera la velocidad de comunicacion es de 115200 baudios
-- El factor de division del reloj de entrada es de 100M / (16*115200)= 54.25 (redondeado a 54)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity baud_rate_clock is
    Port ( 
                    CLK : in  STD_LOGIC;
           EN_16_X_BAUD : out  STD_LOGIC
           );
end baud_rate_clock;

architecture Behavioral of baud_rate_clock is

signal baud_count : integer range 0 to 53 := 0;

begin
		process(CLK)
		begin
				if(CLK'event and CLK = '1') then
						if(baud_count = 53) then
								baud_count <= 0;
								EN_16_X_BAUD <= '1';
						else
								baud_count <= baud_count + 1;
								EN_16_X_BAUD <= '0';
						end if;
				end if;
		end process;

end Behavioral;

