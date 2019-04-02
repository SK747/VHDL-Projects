

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------
--
--  This is the entity part of the top level file
--  
----------------------------------------------------------

entity phase3 is
   port (KEY: in std_logic_vector(3 downto 0);  -- push-button switches
         SW : in std_logic_vector(17 downto 0);  -- slider switches
         CLOCK_50: in std_logic;                 -- 50MHz clock input
	 HEX0 : out std_logic_vector(6 downto 0); -- output to drive digit 0
	 
	 HEX1 : out std_logic_vector(6 downto 0); -- output for second segment
	 CLOCK_27: in std_logic                -- 27MHz for second clock
   );     
end phase3;

------------------------------------------------------------
--
-- This is the architecture part of the top level file
--
-------------------------------------------------------------

architecture structural of phase3 is

   -- declare the state machine component (think of this as a header
   -- specification in C).  This has to match the entity part of your
   -- state machine entity (from state_machine.vhd) exactly.  If you
   -- add pins to state_machine, they need to be reflected here

   component state_machine
      port (clk : in std_logic;   -- clock input
         resetb : in std_logic;   -- active-low reset input
         skip : in std_logic;      -- skip switch value
         hex0 : out std_logic_vector(6 downto 0)  -- drive digit 0
      );
   end component;

   -- These two signals are used in the clock divider (see below).
   -- slow_clock is the output of the clock divider, and count50 is
   -- an internal signal used within the clock divider.
   -- add two more signals for the second state machine
	
   signal slow_clock : std_logic;
   signal count50 : unsigned(28 downto 0) := (others => '0'); --length of unsigned vector increased to increase the period (and therefore decrease the frequency
   signal clock27 : std_logic;
   signal count27 :unsigned(28 downto 0) := (others => '0'); --length of unsigned vector increased to increase the period (and therefore decrease the frequency
	
	--CHALLENGE: swspeeds
	signal swspeed0: integer;
	signal swspeed1: integer;

   -- Note: the above syntax (others=>'0') is a short cut for initializing
   -- all bits in this 26 bit wide bus to 0. 

begin

    -- This is the clock divider process.  It converts a 50Mhz clock to a slower clock
	 
	 --CHALLENGE PHASE ADD
	 swspeed0 <=to_integer (unsigned(sw(9 downto 2)));
	 swspeed1 <=to_integer (unsigned(sw(17 downto 10)));

    PROCESS (CLOCK_50)	
    BEGIN
        if rising_edge (CLOCK_50) THEN
            count50 <= count50 + swspeed0;
        end if;
    END process;
    slow_clock <= count50(28);   -- the output is the MSB of the counter
	
	-- Add second clock process
	PROCESS (CLOCK_27)
	BEGIN
	if rising_edge (CLOCK_27) THEN
	count27 <= count27 + swspeed1;
	end if;
	END process;
	clock27 <= count27(28);

    -- instantiate the state machine component, which is defined in 
    -- state_machine.vhd (which you will write).    

    u0: state_machine port map(slow_clock,  -- the clock input to the state machine
                                            -- is the slow clock
                               KEY(0),  -- the reset input to the state machine is
                                        -- pushbutton # 0
                               SW(0),   -- the skip input to the state machine is
                                        -- slider switch # 0,
                               HEX0);	-- the output of the state machine is connected
                                        -- to hex digit 0
	-- now we add second statemachine map
	u1: state_machine port map (clock27,
	KEY(0),
	SW(1),
	HEX1);
end structural;
