library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Utilisation du mode 0 du protocole SPI (latch sur front montant)

entity SPI_driver is
	port(
		clock, reset : in std_logic;
		SCLK_rise, SCLK_fall : in std_logic;
		send_cmd, write_data, read_data : in std_logic;
		transfer_complete : out std_logic;
		new_byte_w, new_byte_r : out std_logic;
		byte_w : in std_logic_vector(7 downto 0);
		byte_r : out std_logic_vector(7 downto 0);
		size : in std_logic_vector(9 downto 0);
		CS, MOSI, SCLK : out std_logic;
		MISO : in std_logic);
end SPI_driver;

architecture Behavioral of SPI_driver is

signal bit_cnt_w, bit_cnt_r : natural range 0 to 7;
signal byte_cnt_int : std_logic_vector(9 downto 0);
signal new_byte_w_int, new_byte_r_int : std_logic;
signal transfer_complete_int : std_logic;

type state is(idle, send, listen, receive, delay);
signal future_state, current_state : state;

begin

	new_byte_w <= new_byte_w_int;
	new_byte_r <= new_byte_r_int;
	transfer_complete <= transfer_complete_int;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_rise = '1') then
				SCLK <= '1';
			elsif(SCLK_fall = '1') then
				SCLK <= '0';
			end if;
		end if;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_fall = '1') then
				if(current_state = idle) then
					CS <= '1';
				else
					CS <= '0';
				end if;
			end if;
		end if;
	end process;
	
	bit_cnt_pro: process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				bit_cnt_w <= 7;
				bit_cnt_r <= 0;
			elsif(SCLK_rise = '1') then
				if(current_state = idle) then
					bit_cnt_w <= 7;
				else
					if(bit_cnt_w = 0) then
						bit_cnt_w <= 7;
					else
						bit_cnt_w <= bit_cnt_w - 1;
					end if;
				end if;
			elsif(SCLK_fall = '1') then
				if(current_state = idle) then
					bit_cnt_r <= 0;
				else
					if(bit_cnt_r = 0) then
						bit_cnt_r <= 7;
					else
						bit_cnt_r <= bit_cnt_r - 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	pro_new_byte_r : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_rise = '1') then
				if(bit_cnt_r = 0 and current_state = receive) then
					new_byte_r_int <= '1';
				else
					new_byte_r_int <= '0';
				end if;
			end if;
		end if;
	end process;
	
	pro_new_byte_w : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_fall = '1') then
				if(bit_cnt_w = 1 and current_state = send) then
					new_byte_w_int <= '1';
				else
					new_byte_w_int <= '0';
				end if;
			end if;
		end if;
	end process;
	
	pro_transfer_complete : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				transfer_complete_int <= '0';
			elsif(SCLK_fall = '1') then
				if(current_state = delay) then
					if(bit_cnt_r = 1) then
						transfer_complete_int <= '1';
					else
						transfer_complete_int <= '0';
					end if;
				elsif(current_state = receive and new_byte_r_int = '1' and read_data = '1') then
					transfer_complete_int <= '1';
				elsif(current_state = send) then
					if(byte_cnt_int = "0000000000" and new_byte_w_int = '1') then
						transfer_complete_int <= '1';
					else
						transfer_complete_int <= '0';
					end if;
				else
					transfer_complete_int <= '0';
				end if;
			end if;
		end if;
	end process;
				

	write_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_fall = '1') then
				if(current_state = idle or current_state = listen or current_state = delay or current_state = receive) then
					MOSI <= '1';
				else
					MOSI <= byte_w(bit_cnt_w);
				end if;
			end if;
		end if;
	end process;
	
	read_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				byte_r <= x"FF";
			elsif(SCLK_rise = '1') then
				byte_r(bit_cnt_r) <= MISO;
			end if;
		end if;
	end process;
	
	byte_cnt_pro : process(clock)
	begin
		if(clock'event and clock = '1') then
			if(SCLK_rise = '1') then
				if(current_state = idle or current_state = listen or current_state = delay) then
					byte_cnt_int <= size;
				elsif(new_byte_w_int = '1') then
					if(byte_cnt_int > "0000000000") then
						byte_cnt_int <= byte_cnt_int - "000000001";
					end if;
				end if;
			elsif(SCLK_fall = '1') then
				if(new_byte_r_int = '1') then
					byte_cnt_int <= byte_cnt_int - "000000001";
				end if;
			end if;
		end if;
	end process;
					
	
	FSM : process(current_state, transfer_complete_int, send_cmd, MISO, bit_cnt_r, read_data, write_data, byte_cnt_int, new_byte_r_int)
	begin
		case current_state is
		when idle =>	if(send_cmd = '1') then
								future_state <= send;
							else
								future_state <= idle;
							end if;
		when send =>	if(transfer_complete_int = '1') then
								future_state <= listen;
							else
								future_state <= send;
							end if;
		when listen =>	if(MISO = '0') then
								future_state <= receive;
							else
								future_state <= listen;
							end if;
		when receive =>	if(new_byte_r_int = '1' and byte_cnt_int = "0000000000") then
									if(read_data = '1') then
										future_state <= listen;
									else
										future_state <= delay;
									end if;
								else
									future_state <= receive;
								end if;
		when delay =>	if(bit_cnt_r = 0) then
								future_state <= idle;
							else
								future_state <= delay;
							end if;
		end case;
	end process;
	
	process(clock)
	begin
		if(clock'event and clock = '1') then
			if(reset = '0') then
				current_state <= idle;
			elsif(SCLK_rise = '1') then
				current_state <= future_state;
			end if;
		end if;
	end process;
	
end Behavioral;

