library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity response_display is
	port(
		clock : in std_logic;
		display_response, response_type_switch : in std_logic;
		response_switch : in std_logic_vector(5 downto 0);
		resp0, resp55, resp41, resp17 : in std_logic_vector(7 downto 0);
		resp8, resp58 : in std_logic_vector(39 downto 0);
		value_l, value_r : out std_logic_vector(15 downto 0));
end response_display;

architecture Behavioral of response_display is

begin

	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(display_response = '1') then
				if(response_type_switch = '0') then
					if(response_switch(0) = '1') then
						value_l <= x"0000";
						value_r <= x"00" & resp0;
					elsif(response_switch(1) = '1') then
						value_l <= x"0000";
						value_r <= x"00" & resp8(39 downto 32);
					elsif(response_switch(2) = '1') then
						value_l <= x"0000";
						value_r <= x"00" & resp58(39 downto 32);
					elsif(response_switch(3) = '1') then
						value_l <= x"0000";
						value_r <= x"00" & resp55;
					elsif(response_switch(4) = '1') then
						value_l <= x"0000";
						value_r <= x"00" & resp41;
					elsif(response_switch(5) = '1') then
						value_l <= x"0000";
						value_r <= x"00" & resp17;
					else
						value_l <= x"AAAA";
						value_r <= x"AAAA";
					end if;
				else
					if(response_switch = "00010") then
						value_l <= resp8(31 downto 16);
						value_r <= resp8(15 downto 0);
					elsif(response_switch = "00100") then
						value_l <= resp58(31 downto 16);
						value_r <= resp58(15 downto 0);
					else
						value_l <= x"AAAA";
						value_r <= x"AAAA";
					end if;
				end if;
			else
				value_l <= x"AAAA";
				value_r <= x"AAAA";
			end if;
		end if;
	end process;

end Behavioral;

