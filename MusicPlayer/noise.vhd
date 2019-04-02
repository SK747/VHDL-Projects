LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This module is given to you for Lab 5 Task 4.   The module takes an
-- input stream, stream_in, and adds noise to it, producing the output 
-- stream stream_out.  The 2 bit magnitude vector indicates how much 
-- noise to add ("11" means quite a bit of noise, "00" means just a little
-- bit).  

-- This is a pretty simple noise generator.  More complex generators are 
-- possible, but this will be sufficient for this lab .

ENTITY noise IS 
   PORT ( CLOCK_50: in std_logic;
	       magnitude : in std_logic_vector(1 downto 0);
	       stream_in : in std_logic_vector(23 downto 0);
	       stream_out : out std_logic_vector(23 downto 0));
end noise;

ARCHITECTURE behaviour of noise is

   -- You can adjust the constant to increase the overall magnitude of the
	-- noise.  You might need to do this, depending on the volume of your
	-- sine wave generator from Task 3.  Adjust it so that you can clearly
	-- hear the noise, but can still here the sine wave signal as well.
	-- You may want to play with it to understand the limitations of your filter.
	
   constant MAGNITUDE_BASE : integer := 2048;
	
	-- Some local signals 
   signal lfsr: signed(2 downto 0) := "000";
	signal noise : std_logic_vector(23 downto 0);
	signal adjusted_magnitude : signed(2 downto 0);
begin

    -- This process describes a 3-bit linear feedback shift register.
	 -- A LFSR counts through all states, just as a counter does, but in a 
	 -- strange order.  It is often used as a random number generator (which is
	 -- what we are using it as here).  Note that a LFSR uses a lot less hardware
	 -- than a normal counter.  
	 
    process(CLOCK_50)
	 begin
	    if (rising_edge(CLOCK_50)) then
   		    lfsr <= (lfsr(1) xnor lfsr(0)) & lfsr (2 downto 1);
		 end if;
	 end process;

    -- We want the magnitude to go from 1 to 4, not 0 to 3.	 
	 adjusted_magnitude <= signed('0' & magnitude) + to_signed(1,adjusted_magnitude'length);
	 
    -- Generate the noise signal
	 noise <= std_logic_vector(adjusted_magnitude*
	                           lfsr*
										to_signed(MAGNITUDE_BASE, noise'length-adjusted_magnitude'length-lfsr'length));
	
    -- Combine the input stream with the noise signal to produce the output stream	
	 stream_out <= std_logic_vector(signed(stream_in) + signed(noise));	 
end behaviour;
