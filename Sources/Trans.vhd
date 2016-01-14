library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Trans is
	port(
		val_num : in std_logic_vector(15 downto 0);
		val_7seg_0 : out std_logic_vector(6 downto 0);
		val_7seg_1 : out std_logic_vector(6 downto 0);
		val_7seg_2 : out std_logic_vector(6 downto 0);
		val_7seg_3 : out std_logic_vector(6 downto 0));
end Trans;

architecture arc of Trans is

signal seg_0_int, seg_1_int, seg_2_int, seg_3_int : unsigned(3 downto 0);

begin	
	seg_0_int(0) <= val_num(0);
	seg_0_int(1) <= val_num(1);
	seg_0_int(2) <= val_num(2);
	seg_0_int(3) <= val_num(3);
	
	seg_1_int(0) <= val_num(4);
	seg_1_int(1) <= val_num(5);
	seg_1_int(2) <= val_num(6);
	seg_1_int(3) <= val_num(7);
	
	seg_2_int(0) <= val_num(8);
	seg_2_int(1) <= val_num(9);
	seg_2_int(2) <= val_num(10);
	seg_2_int(3) <= val_num(11);
	
	seg_3_int(0) <= val_num(12);
	seg_3_int(1) <= val_num(13);
	seg_3_int(2) <= val_num(14);
	seg_3_int(3) <= val_num(15);
	
	with seg_3_int select
		val_7seg_3 <=	"0000001" when "0000",
							"1001111" when "0001",
							"0010010" when "0010",
							"0000110" when "0011",
							"1001100" when "0100",
							"0100100" when "0101",
							"0100000" when "0110",
							"0001111" when "0111",
							"0000000" when "1000",
							"0000100" when "1001",
							"0001000" when "1010",
							"1100000" when "1011",
							"0110001" when "1100",
							"1000010" when "1101",
							"0110000" when "1110",
							"0111000" when others;
							
	with seg_2_int select
		val_7seg_2 <=	"0000001" when "0000",
							"1001111" when "0001",
							"0010010" when "0010",
							"0000110" when "0011",
							"1001100" when "0100",
							"0100100" when "0101",
							"0100000" when "0110",
							"0001111" when "0111",
							"0000000" when "1000",
							"0000100" when "1001",
							"0001000" when "1010",
							"1100000" when "1011",
							"0110001" when "1100",
							"1000010" when "1101",
							"0110000" when "1110",
							"0111000" when others;
							
	with seg_1_int select
		val_7seg_1 <=	"0000001" when "0000",
							"1001111" when "0001",
							"0010010" when "0010",
							"0000110" when "0011",
							"1001100" when "0100",
							"0100100" when "0101",
							"0100000" when "0110",
							"0001111" when "0111",
							"0000000" when "1000",
							"0000100" when "1001",
							"0001000" when "1010",
							"1100000" when "1011",
							"0110001" when "1100",
							"1000010" when "1101",
							"0110000" when "1110",
							"0111000" when others;
	
	with seg_0_int select
		val_7seg_0 <=	"0000001" when "0000",
							"1001111" when "0001",
							"0010010" when "0010",
							"0000110" when "0011",
							"1001100" when "0100",
							"0100100" when "0101",
							"0100000" when "0110",
							"0001111" when "0111",
							"0000000" when "1000",
							"0000100" when "1001",
							"0001000" when "1010",
							"1100000" when "1011",
							"0110001" when "1100",
							"1000010" when "1101",
							"0110000" when "1110",
							"0111000" when others;

end arc;

