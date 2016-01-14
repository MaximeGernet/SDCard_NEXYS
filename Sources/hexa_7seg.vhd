library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity hexa_7seg is
	port(
		clock, reset : in std_logic;
		value_l : in std_logic_vector(15 downto 0);
		value_r : in std_logic_vector(15 downto 0);
		S : out std_logic_vector(6 downto 0);
		AN : out std_logic_vector(7 downto 0));
end hexa_7seg;

architecture Behavioral of hexa_7seg is

signal ce_perception : std_logic;
signal sortie_mod8 : std_logic_vector(2 downto 0);
signal val_7seg_r3, val_7seg_r2, val_7seg_r1, val_7seg_r0 : std_logic_vector(6 downto 0);
signal val_7seg_l3, val_7seg_l2, val_7seg_l1, val_7seg_l0 : std_logic_vector(6 downto 0);

component gestion_freq
	port(
		clock  : in std_logic;
		reset : in std_logic;
		ce_perception : out std_logic);
end component;

component Trans
	port(
		val_num : in std_logic_vector(15 downto 0);
		val_7seg_0 : out std_logic_vector(6 downto 0);
		val_7seg_1 : out std_logic_vector(6 downto 0);
		val_7seg_2 : out std_logic_vector(6 downto 0);
		val_7seg_3 : out std_logic_vector(6 downto 0));
end component;

component mod8
	port(
		clock : in std_logic;
		reset : in std_logic;
		ce : in std_logic;
		AN : out std_logic_vector(7 downto 0);
		sortie : out std_logic_vector(2 downto 0));
end component;

component mux8_1
	port(
		commande : in std_logic_vector(2 downto 0);
		E0, E1, E2, E3, E4, E5, E6, E7 : in std_logic_vector(6 downto 0);
		S : out std_logic_vector(6 downto 0));
end component;

begin	
	inst1 : gestion_freq port map (clock, reset, ce_perception);
	trans_r : Trans port map (value_r, val_7seg_r0, val_7seg_r1, val_7seg_r2, val_7seg_r3);
	trans_l : Trans port map (value_l, val_7seg_l0, val_7seg_l1, val_7seg_l2, val_7seg_l3);
	inst3 : mod8 port map (clock, reset, ce_perception, AN, sortie_mod8);
	inst4 : mux8_1 port map (sortie_mod8, val_7seg_r0, val_7seg_r1, val_7seg_r2, val_7seg_r3, val_7seg_l0, val_7seg_l1, val_7seg_l2, val_7seg_l3, S);
end Behavioral;

