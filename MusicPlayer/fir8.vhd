LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This is a FIR filter, as described in the lab handout.
-- It is written as an 8-tap filter, although it can easily be changed
-- for more taps. 

ENTITY fir8 IS 
   PORT ( CLOCK_50, valid: in std_logic;
          stream_in : in std_logic_vector(23 downto 0);
          stream_out : out std_logic_vector(23 downto 0));
end fir8;

ARCHITECTURE behaviour of fir8 is
   -- Your code goes here
end behaviour;
