
-- SCLK frequency is 400 kHz when high_speed_enable = '0'
-- SCLK frequency is 25 MHz when high_speed_enable = '1'

---------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity SCLK_generator is
	port(
		clock : in std_logic;
		reset : in std_logic;
		high_speed_enable : in std_logic;
		SCLK_rise : out std_logic;
		SCLK_fall : out std_logic);
end SCLK_generator;

architecture Behavioral of SCLK_generator is

signal SCLK_cnt : natural range 0 to 249;

begin
	
	pro_SCLK : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(high_speed_enable = '0') then
				if(reset = '0' or SCLK_cnt = 249) then
					SCLK_cnt <= 0;
					SCLK_rise <= '1';
				elsif(SCLK_cnt = 124) then
					SCLK_cnt <= 125;
					SCLK_fall <= '1';
				else
					SCLK_cnt <= SCLK_cnt + 1;
					SCLK_rise <= '0';
					SCLK_fall <= '0';
				end if;
			else
				if(SCLK_cnt = 3) then
					SCLK_cnt <= 0;
					SCLK_rise <= '1';
				elsif(SCLK_cnt = 1) then
					SCLK_cnt <= 2;
					SCLK_fall <= '1';
				else
					SCLK_cnt <= SCLK_cnt + 1;
					SCLK_rise <= '0';
					SCLK_fall <= '0';
				end if;
			end if;
		end if;
	end process;

end Behavioral;

