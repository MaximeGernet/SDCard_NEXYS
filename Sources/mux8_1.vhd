library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity mux8_1 is
	port(
		commande : in std_logic_vector(2 downto 0);
		E0, E1, E2, E3, E4, E5, E6, E7 : in std_logic_vector(6 downto 0);
		S : out std_logic_vector(6 downto 0));
end mux8_1;

architecture arc of mux8_1 is

begin

	with commande select
		S <= 	E0 when "000",
				E1 when "001",
				E2 when "010",
				E3 when "011",
				E4 when "100",
				E5 when "101",
				E6 when "110",
				E7 when others;

end arc;

