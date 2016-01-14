library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity mod8 is
	port(
		clock : in std_logic;
		reset : in std_logic;
		ce : in std_logic;
		AN : out std_logic_vector(7 downto 0);
		sortie : out std_logic_vector(2 downto 0));
end mod8;

architecture arc of mod8 is

signal cmp : unsigned(2 downto 0);

begin

	process(clock) -- compteur modulo 8
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				cmp <= "000";
			elsif(ce = '1') then
				if(cmp = "111") then
					cmp <= "000";
				else
					cmp <= cmp + "001";
				end if;
			end if;
		end if;
	end process;
	
	sortie <= std_logic_vector(cmp);
	
	with cmp select
		AN <=	"11111110" when "000",
				"11111101" when "001",
				"11111011" when "010",
				"11110111" when "011",
				"11101111" when "100",
				"11011111" when "101",
				"10111111" when "110",
				"01111111" when others;
				
end arc;

