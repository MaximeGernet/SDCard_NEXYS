library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- CMD0 : resets the SD card
-- CMD8 : sends the SD card information about the supply voltage
-- CMD55 : the next command is going to be an application command
-- ACMD41 : activates the card's initialization process and sends host capacity support information
-- CMD58 : sends the host information about the card capacity support (reads the OCR register)
-- CMD24 : writes one block
-- CMD17 : reads one block

entity SD_driver is
	port(
		clock, reset : in std_logic;
		SCLK_rise, SCLK_fall : in std_logic;
		send_cmd, data_r, data_w : out std_logic;
		transfer_complete : in std_logic;
		new_byte_r, new_byte_w : in std_logic;
		byte_r : in std_logic_vector(7 downto 0);
		byte_w : out std_logic_vector(7 downto 0);
		size : out std_logic_vector(9 downto 0);
		state_led : out std_logic_vector(9 downto 0);
		resp0, resp55, resp41, resp17 : out std_logic_vector(7 downto 0);
		resp8, resp58 : out std_logic_vector(39 downto 0);
		read_block, write_block : in std_logic;
		end_of_block : out std_logic;
		data_out : out std_logic_vector(7 downto 0);
		byte_cnt : out std_logic_vector(9 downto 0);
		new_byte : out std_logic;
		block_addr : in std_logic_vector(10 downto 0);
		high_speed_enable : out std_logic;
		offset : in std_logic_vector(15 downto 0);
		CCS : in std_logic);
end SD_driver;

architecture Behavioral of SD_driver is

signal init_cnt : natural range 0 to 2000000; -- 20 ms delay
signal wait_init : std_logic;
signal CMD : std_logic_vector(5 downto 0);
signal ARG : std_logic_vector(31 downto 0);
signal CRC : std_logic_vector(6 downto 0);
signal send_cmd_enable : std_logic;
signal resp : std_logic_vector(39 downto 0);
signal write_cmd, read_resp : std_logic;
signal resp0_int, resp41_int : std_logic_vector(7 downto 0);
signal byte_cnt_int : std_logic_vector(9 downto 0);

type state is(init, write_cmd0, read_resp0, write_cmd8, read_resp8, write_cmd58, read_resp58, write_cmd55, read_resp55, write_acmd41, read_resp41, idle, write_cmd17, read_resp17, read_data, write_cmd24, read_resp24, write_data);
signal future_state, current_state : state;

begin

	resp41 <= resp41_int;
	resp0 <= resp0_int;
	byte_cnt <= byte_cnt_int;
	
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_rise = '1') then
				if(new_byte_r = '1' and current_state = read_data) then
					new_byte <= '1';
				else
					new_byte <= '0';
				end if;
			end if;
		end if;
	end process;

	FSM : process(current_state, wait_init, transfer_complete, resp41_int(0), resp0_int(0), read_block, write_block)
	begin
		case current_state is
		when init =>	if(wait_init = '1') then
								future_state <= write_cmd0;
							else
								future_state <= init;
							end if;
		when write_cmd0 =>	if(transfer_complete = '1') then
										future_state <= read_resp0;
									else
										future_state <= write_cmd0;
									end if;
		when read_resp0 =>	if(transfer_complete = '1') then
										future_state <= write_cmd8;
									else
										future_state <= read_resp0;
									end if;
		when write_cmd8 =>	if(transfer_complete = '1') then
										future_state <= read_resp8;
									else
										future_state <= write_cmd8;
									end if;
		when read_resp8 =>	if(transfer_complete = '1') then
										future_state <= write_cmd55;
									else
										future_state <= read_resp8;
									end if;
		when write_cmd58 =>	if(transfer_complete = '1') then
										future_state <= read_resp58;
									else
										future_state <= write_cmd58;
									end if;
		when read_resp58 =>	if(transfer_complete = '1') then -- CCS = '0' => base address = unit address
										future_state <= idle;
									else
										future_state <= read_resp58;
									end if;
		when write_cmd55 =>	if(transfer_complete = '1') then
										future_state <= read_resp55;
									else
										future_state <= write_cmd55;
									end if;
		when read_resp55 =>	if(transfer_complete = '1') then
										future_state <= write_acmd41;
									else
										future_state <= read_resp55;
									end if;
		when write_acmd41 =>	if(transfer_complete = '1') then
										future_state <= read_resp41;
									else
										future_state <= write_acmd41;
									end if;
		when read_resp41 =>	if(transfer_complete = '1') then
										if(resp41_int(0) = '1') then
											future_state <= write_cmd55; -- Send acmd41 until the card initialization process is finished
										else
											future_state <= write_cmd58;
										end if;
									else
										future_state <= read_resp41;
									end if;
		when idle =>	if(read_block = '1') then
								future_state <= write_cmd17;
							elsif(write_block = '1') then
								future_state <= write_cmd24;
							else
								future_state <= idle;
							end if;
		when write_cmd17 =>	if(transfer_complete = '1') then
										future_state <= read_resp17;
									else
										future_state <= write_cmd17;
									end if;
		when read_resp17 =>	if(transfer_complete = '1') then
										future_state <= read_data;
									else
										future_state <= read_resp17;
									end if;
		when read_data =>	if(transfer_complete = '1') then
									future_state <= idle;
								else
									future_state <= read_data;
								end if;
		when write_cmd24 =>	if(transfer_complete = '1') then
										future_state <= read_resp24;
									else
										future_state <= write_cmd24;
									end if;
		when read_resp24 =>	if(transfer_complete = '1') then
										future_state <= write_data;
									else
										future_state <= read_resp24;
									end if;
		when write_data =>	if(transfer_complete = '1') then
										future_state <= idle;
									else
										future_state <= write_data;
									end if;
		end case;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				current_state <= init;
			elsif(SCLK_rise = '1') then
				current_state <= future_state;
			end if;
		end if;
	end process;

	output : process(current_state, block_addr, offset, CCS)
	begin
		case current_state is
		when init =>	size <= (others => '0');
							CMD <= (others => '0');
							ARG <= (others => '0');
							CRC <= (others => '0');
							state_led <= (others => '0');
							write_cmd <= '0';
							read_resp <= '0';
							data_w <= '0';
							data_r <= '0';
							high_speed_enable <= '0';
		when write_cmd0 =>	size <= std_logic_vector(to_unsigned(6, 10));
									CMD <= std_logic_vector(to_unsigned(0, 6));
									ARG <= x"00000000";
									CRC <= "1001010";
									state_led <= "0000000001";
									write_cmd <= '1';
									read_resp <= '0';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when read_resp0 =>	size <= std_logic_vector(to_unsigned(1, 10));
									CMD <= (others => '0');
									ARG <= (others => '0');
									CRC <= (others => '0');
									state_led <= "0000000001";
									write_cmd <= '0';
									read_resp <= '1';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when write_cmd8 =>	size <= std_logic_vector(to_unsigned(6, 10));
									CMD <= std_logic_vector(to_unsigned(8, 6));
									ARG <= x"000001AA"; -- [15:8] = VHS ; [7:0] = Check Pattern.  Correct response : x"01000001AA"
									CRC <= "1000011";
									state_led <= "0000000010";
									write_cmd <= '1';
									read_resp <= '0';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when read_resp8 =>	size <= std_logic_vector(to_unsigned(5, 10));
									CMD <= (others => '0');
									ARG <= (others => '0');
									CRC <= (others => '0');
									state_led <= "0000000010";
									write_cmd <= '0';
									read_resp <= '1';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when write_cmd58 =>	size <= std_logic_vector(to_unsigned(6, 10));
									CMD <= std_logic_vector(to_unsigned(58, 6));
									ARG <= x"00000000";
									CRC <= "0000000";
									state_led <= "0000000100";
									write_cmd <= '1';
									read_resp <= '0';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when read_resp58 =>	size <= std_logic_vector(to_unsigned(5, 10));
									CMD <= (others => '0');
									ARG <= (others => '0');
									CRC <= (others => '0');
									state_led <= "0000000100";
									write_cmd <= '0';
									read_resp <= '1';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when write_cmd55 =>	size <= std_logic_vector(to_unsigned(6, 10));
									CMD <= std_logic_vector(to_unsigned(55, 6));
									ARG <= x"00000000";
									CRC <= "0110010";
									state_led <= "0000001000";
									write_cmd <= '1';
									read_resp <= '0';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when read_resp55 =>	size <= std_logic_vector(to_unsigned(1, 10));
									CMD <= (others => '0');
									ARG <= (others => '0');
									CRC <= (others => '0');
									state_led <= "0000001000";
									write_cmd <= '0';
									read_resp <= '1';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when write_acmd41 =>	size <= std_logic_vector(to_unsigned(6, 10));
									CMD <= std_logic_vector(to_unsigned(41, 6));
									ARG <= x"40000000";
									CRC <= "0111011";
									state_led <= "0000010000";
									write_cmd <= '1';
									read_resp <= '0';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when read_resp41 =>	size <= std_logic_vector(to_unsigned(1, 10));
									CMD <= (others => '0');
									ARG <= (others => '0');
									CRC <= (others => '0');
									state_led <= "0000010000";
									write_cmd <= '0';
									read_resp <= '1';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '0';
		when idle =>	size <= (others => '0');
							CMD <= (others => '0');
							ARG <= (others => '0');
							CRC <= (others => '0');
							state_led <= "0000100000";
							write_cmd <= '0';
							read_resp <= '0';
							data_w <= '0';
							data_r <= '0';
							high_speed_enable <= '1';
		when write_cmd17 =>	size <= std_logic_vector(to_unsigned(6, 10));
									CMD <= std_logic_vector(to_unsigned(17, 6));
									if(CCS = '1') then
										ARG <= std_logic_vector(resize(unsigned(block_addr + offset), 32));
									else
										ARG <= "0000000" & (block_addr + offset) & "000000000";
									end if;
									CRC <= "0000000";
									state_led <= "0001000000";
									write_cmd <= '1';
									read_resp <= '0';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '1';
		when read_resp17 =>	size <= std_logic_vector(to_unsigned(1, 10));
									CMD <= (others => '0');
									ARG <= (others => '0');
									CRC <= (others => '0');
									state_led <= "0001000000";
									write_cmd <= '0';
									read_resp <= '1';
									data_w <= '0';
									data_r <= '1';
									high_speed_enable <= '1';
		when read_data =>	size <= std_logic_vector(to_unsigned(514, 10));
								CMD <= (others => '0');
								ARG <= (others => '0');
								CRC <= (others => '0');
								state_led <= "0001000000";
								write_cmd <= '0';
								read_resp <= '0';
								data_w <= '0';
								data_r <= '0';
								high_speed_enable <= '1';
		when write_cmd24 =>	size <= std_logic_vector(to_unsigned(6, 10));
									CMD <= std_logic_vector(to_unsigned(24, 6));
									ARG <= x"00000000";
									CRC <= "0000000";
									state_led <= "0001000000";
									write_cmd <= '1';
									read_resp <= '0';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '1';
		when read_resp24 =>	size <= std_logic_vector(to_unsigned(1, 10));
									CMD <= (others => '0');
									ARG <= (others => '0');
									CRC <= (others => '0');
									state_led <= "0001000000";
									write_cmd <= '0';
									read_resp <= '1';
									data_w <= '1';
									data_r <= '0';
									high_speed_enable <= '1';
		when write_data =>	size <= std_logic_vector(to_unsigned(514, 10));
									CMD <= (others => '0');
									ARG <= (others => '0');
									CRC <= (others => '0');
									state_led <= "0001000000";
									write_cmd <= '0';
									read_resp <= '0';
									data_w <= '0';
									data_r <= '0';
									high_speed_enable <= '1';
		end case;
	end process;
	
	process(current_state, new_byte_r, byte_cnt_int)
	begin
		if(current_state = read_data and new_byte_r = '1' and byte_cnt_int = "0111111111") then
			end_of_block <= '1';
		else
			end_of_block <= '0';
		end if;
	end process;
	
	send_cmd_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				send_cmd_enable <= '1';
				send_cmd <= '0';
			elsif(SCLK_rise = '1') then
				if(transfer_complete = '1') then
					send_cmd_enable <= '1';
				elsif(write_cmd = '1') then
					if(send_cmd_enable = '1') then
						send_cmd <= '1';
						send_cmd_enable <= '0';
					else
						send_cmd <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
			
	byte_cnt_int_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				byte_cnt_int <= (others => '0');
			elsif(SCLK_rise = '1') then
				if(transfer_complete = '1') then
					byte_cnt_int <= (others => '0');
				elsif(new_byte_w = '1' or new_byte_r = '1') then
					byte_cnt_int <= byte_cnt_int + "0000000001";
				end if;
			end if;
		end if;
	end process;
					
	write_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_fall = '1') then
				case byte_cnt_int is
				when "0000000000"	=>	byte_w <= "01" & CMD(5 downto 0);
				when "0000000001" => byte_w <= ARG(31 downto 24);
				when "0000000010" => byte_w <= ARG(23 downto 16);
				when "0000000011" => byte_w <= ARG(15 downto 8);
				when "0000000100" => byte_w <= ARG(7 downto 0);
				when "0000000101" => byte_w <= CRC(6 downto 0) & '1';
				when others => byte_w <= x"00";
				end case;
			end if;
		end if;
	end process;
	
	read_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_fall = '1' and new_byte_r = '1') then
				if(read_resp = '1') then
					case byte_cnt_int is
					when "0000000000" => resp(39 downto 32) <= byte_r;
					when "0000000001" => resp(31 downto 24) <= byte_r;
					when "0000000010" => resp(23 downto 16) <= byte_r;
					when "0000000011" => resp(15 downto 8) <= byte_r;
					when "0000000100" => resp(7 downto 0) <= byte_r;
					when others => resp(7 downto 0) <= byte_r;
					end case;
				elsif(current_state = read_data) then
					data_out <= byte_r;
				end if;
			end if;
		end if;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				resp0_int <= (others => '0');
				resp58 <= (others => '0');
				resp55 <= (others => '0');
				resp41_int <= (others => '1');
				resp17 <= (others => '1');
			elsif(SCLK_rise = '1' and transfer_complete = '1') then
				if(current_state = read_resp0) then
					resp0_int <= resp(39 downto 32);
				elsif(current_state = read_resp8) then
					resp8 <= resp;
				elsif(current_state = read_resp58) then
					resp58 <= resp;
				elsif(current_state = read_resp55) then
					resp55 <= resp(39 downto 32);
				elsif(current_state = read_resp41) then
					resp41_int <= resp(39 downto 32);
				elsif(current_state = read_resp17) then
					resp17 <= resp(39 downto 32);
				end if;
			end if;
		end if;
	end process;
	
	init_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				init_cnt <= 2000000;
				wait_init <= '0';
			elsif(init_cnt = 0) then
				wait_init <= '1';
			else
				init_cnt <= init_cnt - 1;
				wait_init <= '0';
			end if;
		end if;
	end process;
	
	
	
	
end Behavioral;

