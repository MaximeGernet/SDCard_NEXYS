-- Appui sur bouton droit ou gauche : changement d'image
-- Appui sur bouton haut ou bas : changement de la luminosité

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity FSM is
	port(
		clock, reset : in std_logic;
		ADDR         : out  std_logic_vector(18 downto 0);
		pixel_value  : out  std_logic_vector(11 downto 0);
		data_write   : out  std_logic;
		SCLK_rise, SCLK_fall : in std_logic;
		byte_cnt : in std_logic_vector(9 downto 0);
		end_of_block : in std_logic;
		data_in : in std_logic_vector(7 downto 0);
		read_block, write_block : out std_logic;
		new_byte : in std_logic;
		block_addr : out std_logic_vector(10 downto 0);
		offset : out std_logic_vector(15 downto 0);
		b_left, b_right, b_up, b_down, b_center : in std_logic;
		pixel_in : in std_logic_vector(11 downto 0));
end FSM;

architecture Behavioral of FSM is

type state is(read_SDC, idle, change_lum);
type ram_state is(read_ram, write_ram);
signal lum_state : ram_state;
signal future_state, current_state : state;
signal pixel_cnt : natural range 0 to 307199;
signal block_cnt : natural range 0 to 1800;
signal current_color : natural range 0 to 2; -- 0 -> R, 1 -> G, 2 -> B
signal pixel_value_int : std_logic_vector(11 downto 0);
signal b_up_filter, b_down_filter : std_logic;
signal img : natural range 0 to 2;
signal change_completed : std_logic;
signal pixel_read, pixel_write : natural range 0 to 307199;
signal lum_pixel : std_logic_vector(11 downto 0);
signal lum_cnt : std_logic_vector(2 downto 0);
signal incr_lum : std_logic;
signal pixel_temp : std_logic_vector(11 downto 0);

component button_control
	port(
		clock, reset : in std_logic;
		b_up, b_down : in std_logic;
		b_up_filter, b_down_filter : out std_logic);
end component;

begin

	inst : button_control port map(clock, reset, b_up, b_down, b_up_filter, b_down_filter);
	
	block_addr <= std_logic_vector(to_unsigned(block_cnt, 11));
	
	offset_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(img = 0) then
				offset <= x"0001";
			elsif(img = 1) then
				offset <= x"29D0";
			else
				offset <= x"31A0";
			end if;
		end if;
	end process;

	-------------------------------------------------------------------------------------
	-- FSM
	
	FSM : process(current_state, block_cnt, b_left, b_right, b_up_filter, b_down_filter, b_center, change_completed)
	begin
		case current_state is
		when read_SDC =>	if(block_cnt = 1800)  then
									future_state <= idle;
								else
									future_state <= read_SDC;
								end if;
		when idle =>	if(b_left = '1' or b_right = '1' or b_center = '1') then
								future_state <= read_SDC;
							elsif(b_up_filter = '1' or b_down_filter = '1') then
								future_state <= change_lum;
							else
								future_state <= idle;
							end if;
		when change_lum =>	if(change_completed = '1') then
										future_state <= idle;
									else
										future_state <= change_lum;
									end if;
		end case;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				current_state <= read_SDC;
			elsif(future_state = change_lum)
				then current_state <= change_lum;
			elsif(SCLK_rise = '1') then
				current_state <= future_state;
			end if;
		end if;
	end process;
	
	output : process(current_state, pixel_cnt, pixel_read, pixel_write, lum_state)
	begin
		case current_state is
		when read_SDC =>	data_write <= '1';
								if(pixel_cnt = 0) then
									ADDR <= (others => '0');
								else
									ADDR <= std_logic_vector(to_unsigned(pixel_cnt - 1, 19));
								end if;
								read_block <= '1';
								write_block <= '0';
		when idle =>	data_write <= '0';
							ADDR <= (others => '0');
							read_block <= '0';
							write_block <= '0';
		when change_lum =>	if(lum_state = read_ram) then
										data_write <= '1';
										ADDR <= std_logic_vector(to_unsigned(pixel_write, 19));
									else
										data_write <= '0';
										ADDR <= std_logic_vector(to_unsigned(pixel_read, 19));
									end if;
									read_block <= '0';
									write_block <= '0';
		end case;
	end process;
	
	-------------------------------------------------------------------------------------
	-- lum control
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0' or current_state = idle or current_state = read_SDC) then
				lum_state <= read_ram;
			else
				if(lum_state = read_ram) then
					lum_state <= write_ram;
				else
					lum_state <= read_ram;
				end if;
			end if;
		end if;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0' or current_state = idle or current_state = read_SDC) then
				pixel_read <= 0;
				pixel_write <= 0;
				change_completed <= '0';
			else
				if(lum_state = write_ram) then
					if(pixel_write = 307199) then
						pixel_write <= 0;
						change_completed <= '1';
					elsif(pixel_read > 2) then
						pixel_write <= pixel_write + 1;
					end if;
				else
					if(pixel_read = 307199) then
						pixel_read <= 0;
					else
						pixel_read <= pixel_read + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0' or current_state = idle or current_state = read_SDC) then
				pixel_temp <= (others => '0');
			else
				if(lum_state = read_ram) then
					pixel_temp <= pixel_in;
				else
					if(incr_lum = '1') then
						if(pixel_temp(3 downto 0) < "1110") then
							lum_pixel(3 downto 0) <= pixel_temp(3 downto 0) + "0001";
						else
							lum_pixel(3 downto 0) <= "1111";
						end if;
						if(pixel_temp(7 downto 4) < "1110") then
							lum_pixel(7 downto 4) <= pixel_temp(7 downto 4) + "0001";
						else
							lum_pixel(7 downto 4) <= "1111";
						end if;
						if(pixel_temp(11 downto 8) < "1110") then
							lum_pixel(11 downto 8) <= pixel_temp(11 downto 8) + "0001";
						else
							lum_pixel(11 downto 8) <= "1111";
						end if;
					else
						if(pixel_temp(3 downto 0) > "0001") then
							lum_pixel(3 downto 0) <= pixel_temp(3 downto 0) - "0001";
						else
							lum_pixel(3 downto 0) <= "0000";
						end if;
						if(pixel_temp(7 downto 4) > "0001") then
							lum_pixel(7 downto 4) <= pixel_temp(7 downto 4) - "0001";
						else
							lum_pixel(7 downto 4) <= "0000";
						end if;
						if(pixel_temp(11 downto 8) > "0001") then
							lum_pixel(11 downto 8) <= pixel_temp(11 downto 8) - "0001";
						else
							lum_pixel(11 downto 8) <= "0000";
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	lum_cnt_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				lum_cnt <= "011";
			else
				if(b_up_filter = '1') then
					if(lum_cnt < "111") then
						lum_cnt <= lum_cnt + "001";
						incr_lum <= '1';
					end if;
				elsif(b_down_filter = '1') then
					if(lum_cnt > "000") then
						lum_cnt <= lum_cnt - "001";
						incr_lum <= '0';
					end if;
				elsif(b_left = '1' or b_right = '1' or b_center = '1') then
					lum_cnt <= "011";
				end if;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------------------
	-- pixel conversion (24 bits/pixel -> 12 bits/pixel) and address conversion
	
	current_color_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0' or current_state = idle) then
				current_color <= 0;
			elsif(SCLK_rise = '1') then
				if(new_byte = '1' and byte_cnt < "1000000001") then
					if(current_color = 2) then
						current_color <= 0;
					else
						current_color <= current_color + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	pixel_cnt_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0' or current_state = idle or current_state = change_lum) then
				pixel_cnt <= 0;
			elsif(SCLK_rise = '1') then
				if(current_color = 2 and new_byte = '1' and byte_cnt < "1000000001") then
					if(pixel_cnt < 307199) then
						pixel_cnt <= pixel_cnt + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	block_cnt_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0' or current_state = idle) then
				block_cnt <= 0;
			elsif(SCLK_rise = '1') then
				if(end_of_block = '1') then
					if(block_cnt < 1800) then
						block_cnt <= block_cnt + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	pixel_value_int_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_fall  ='1' and new_byte = '1' and byte_cnt < "1000000001") then
				if(current_color = 0) then
					pixel_value_int(11 downto 8) <= data_in(7 downto 4);
				elsif(current_color = 1) then
					pixel_value_int(7 downto 4) <= data_in(7 downto 4);
				else
					pixel_value_int(3 downto 0) <= data_in(7 downto 4);
				end if;
			end if;
		end if;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(current_state = change_lum) then
				pixel_value <= lum_pixel;
			elsif(SCLK_rise = '1') then
				if(current_color = 2 and new_byte = '1' and byte_cnt < "1000000001") then
					pixel_value <= pixel_value_int;
				end if;
			end if;
		end if;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				img <= 0;
			elsif(SCLK_rise = '1') then
				if(current_state = idle) then
					if(b_right = '1') then
						if(img = 2) then
							img <= 0;
						else
							img <= img + 1;
						end if;
					elsif(b_left = '1') then
						if(img = 0) then
							img <= 2;
						else
							img <= img - 1;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

