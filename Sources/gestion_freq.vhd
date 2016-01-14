library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity gestion_freq is
	port (
		clock  : in std_logic;
		reset : in std_logic;
		ce_perception : out std_logic);
end gestion_freq;

architecture arc of gestion_freq is

signal cpt_perception : natural Range 0 to 33332;

begin
	pro_perception : process(clock) -- compteur modulo 33333, 3 kHz
	begin
		if (clock'event and clock = '1') then
			if (reset = '0') then
				cpt_perception <= 0;
				CE_perception <= '0';
			elsif (cpt_perception = 33332) then
				cpt_perception <= 0;
				CE_perception <= '1';
			else
				cpt_perception <= cpt_perception + 1;
				CE_perception <= '0';
			end if;
		end if;
	end process pro_perception;
end arc;

