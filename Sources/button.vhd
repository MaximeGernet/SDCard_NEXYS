library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity button_control is
	port(
		clock, reset : in std_logic;
		b_up, b_down : in std_logic;
		b_up_filter, b_down_filter : out std_logic);
end button_control;
		
architecture Behavioral of button_control is

signal cnt : natural range 0 to 12500000;
signal b_enable : std_logic;

begin

	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0' or cnt = 8000000) then
				cnt <= 0;
				b_enable <= '1';
			else
				cnt <= cnt + 1;
				b_enable <= '0';
			end if;
		end if;
	end process;
	
	b_up_filter <= b_up when b_enable = '1' else '0';
	b_down_filter <= b_down when b_enable = '1' else '0';

end Behavioral;

