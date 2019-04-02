LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.ALL;

----------------------------------------------------------------------
--
--  Roulette game you can play on your DE2.
--
-----------------------------------------------------------------------

ENTITY roulette IS
	PORT(   CLOCK_27 : IN STD_LOGIC; -- the fast clock for spinning wheel
		KEY : IN STD_LOGIC_VECTOR(3 downto 0);  -- includes slow_clock and reset
		SW : IN STD_LOGIC_VECTOR(17 downto 0);
		LEDG : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);  -- ledg
		HEX7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 7
		HEX6 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 6
		HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 5
		HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 4
		HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 3
		HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 2
		HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- digit 1
		HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)   -- digit 0
	);
END roulette;


ARCHITECTURE structural OF roulette IS
 
	-- Declare components
	COMPONENT win IS
	PORT(spin_result_latched : in unsigned(5 downto 0);  -- result of the spin (the winning number)
             bet_target : in unsigned(5 downto 0); -- target number for bet
             bet_modifier : in unsigned(3 downto 0); -- as described in the handout
             win_straightup : out std_logic;  -- whether it is a straight-up winner
             win_split : out std_logic;  -- whether it is a split bet winner
             win_corner : out std_logic); -- whether it is a corner bet winner
	END COMPONENT;
	
	COMPONENT new_balance IS
	PORT(
		
		money : in unsigned(15 downto 0);
       bet_amount : in unsigned(2 downto 0);
       win_straightup : in std_logic;
       win_split : in std_logic;
       win_corner : in std_logic;
       new_money : out unsigned(15 downto 0)); 
	END COMPONENT;
	
	COMPONENT spinwheel IS
	PORT(
		fast_clock : IN  STD_LOGIC;  -- This will be a 27 Mhz Clock
		resetb : IN  STD_LOGIC;      -- asynchronous reset
		spin_result  : OUT UNSIGNED(5 downto 0));  -- current value of the wheel
	END COMPONENT;
	
	COMPONENT digit7seg IS
	PORT(
          digit : IN  UNSIGNED(3 downto 0);  -- number 0 to 0xF
          seg7 : OUT STD_LOGIC_VECTOR(6 downto 0)  -- one per segment
	);
	END COMPONENT;
	
	COMPONENT finalval IS
	PORT(finalval: in unsigned (15 downto 0); -- this will be assigned the final value of new money, max value 65506..
          sigfigure1 : out unsigned (3 downto 0); -- these will go into the hex...
          sigfigure2 : out unsigned(3 downto 0);  
          sigfigure3 : out unsigned(3 downto 0);  
          sigfigure4 : out unsigned(3 downto 0)); 
	END COMPONENT;
	
	-- Declare signals used in architecture
	signal spin_result_latched: unsigned (5 downto 0);
	signal bet_target : unsigned (5 downto 0);
	signal bet_modifier: unsigned (3 downto 0);
	signal win_straightup: std_logic;
	signal win_split : std_logic;
   signal win_corner : std_logic;
	signal money: unsigned (15 downto 0);
	signal bet_amount: unsigned (2 downto 0);
	signal new_money: unsigned (15 downto 0);
	--signal new_balance: unsigned (15 downto 0);
	signal spin_result : unsigned (5 downto 0);
	signal hex0display: unsigned (3 downto 0);
	signal hex1display: unsigned (3 downto 0);
	signal hex2display: unsigned (3 downto 0);
	signal hex3display: unsigned (3 downto 0);
	signal hex4display: unsigned (3 downto 0);
	signal hex5display: unsigned (3 downto 0);
	signal hex6display: unsigned (3 downto 0);
	signal hex7display: unsigned (3 downto 0);
	signal resetb: std_logic;
	signal fast_clock: std_logic;
	signal slow_clock: std_logic;
	
BEGIN
	-- port maps
	win_port: win port map(spin_result_latched, bet_target, bet_modifier, win_straightup, win_split, win_corner);
	
	new_balance_map: new_balance port map(money, bet_amount, win_straightup, win_split, win_corner, new_money);
	spinport : spinwheel port map(fast_clock, resetb, spin_result);
	
	finalval_map: finalval port map(finalval => new_money, sigfigure1 => hex0display, sigfigure2 => hex1display, sigfigure3 => hex2display, sigfigure4 => hex3display);
	
	digit7seg0 : digit7seg port map(hex0display, HEX0);-- sends digit value of first sigfigure to print on HEX0
	
	digit7seg1 : digit7seg port map(hex1display, HEX1);
	
	digit7seg2 : digit7seg port map(hex2display, HEX2);
	
	digit7seg3 : digit7seg port map(hex3display, HEX3);
	-- give final val new value
	finalval_map2 : finalval port map(finalval => "0000000000" & spin_result_latched, sigfigure1 => hex6display, sigfigure2 => hex7display);
	
	digit7seg6 : digit7seg port map(hex6display,HEX6);
	
	digit7seg7 : digit7seg port map(hex7display,HEX7);
	
	-- LEDS
	LEDG(0) <= win_straightup;
	LEDG(1) <= win_split;
	LEDG(2) <= win_corner;
	
	-- Register logic. Separate process for each register
	fast_clock <= CLOCK_27;
	resetb <= KEY(1);
	slow_clock <= KEY(0);
	
	
	sixbitregister : PROCESS(all)
	BEGIN
		if rising_edge(slow_clock) then
				spin_result_latched <= spin_result;
			end if;
			if resetb = '0' then
				spin_result_latched <= to_unsigned(0,6);
		end if;	
	END PROCESS;
	
	sixbitregister2 : PROCESS(all)
	BEGIN
		if rising_edge(slow_clock) then
			
				bet_target <= unsigned(SW(5 downto 0));
			end if;
			if resetb = '0' then
				bet_target <= to_unsigned(0,6);
			
		end if;		
	END PROCESS;
	
	fourbitregister : PROCESS(all)
	BEGIN
		if rising_edge(slow_clock) then
			
				bet_modifier <= unsigned(SW(9 downto 6));
			end if;
			if resetb = '0' then
				bet_modifier <= to_unsigned(0,4);
			
		end if;		
	END PROCESS;
	
	threebitregister : PROCESS(all)
	BEGIN
		if rising_edge(slow_clock) then
			
				bet_amount <= unsigned(SW(12 downto 10));
			end if;
			if resetb = '0' then
				bet_amount <= to_unsigned(0,3);
			
		end if;	
	END PROCESS;
	
	
	sixteenbitregister : PROCESS(all)
	BEGIN
		if rising_edge(slow_clock) then
				money <= new_money;
			end if;
		if resetb = '0' then
				money <= to_unsigned(32,16);
		end if;	
	END PROCESS;
	
END;
