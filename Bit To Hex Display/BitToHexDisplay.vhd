LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.ALL;

-----------------------------------------------------
--
--  This block will contain a decoder to decode a 4-bit number
--  to a 7-bit vector suitable to drive a HEX dispaly
--
--
--------------------------------------------------------

ENTITY digit7seg IS
	PORT(
          digit : IN  UNSIGNED(3 DOWNTO 0);  -- number 0 to 0xF
          seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)  -- one per segment
	);
END;


ARCHITECTURE behavioral OF digit7seg IS
BEGIN

-- Your code goes here
PROCESS(ALL)
BEGIN

-- Since not using base16, 11-16 print LOSER
  if digit = 0 then
    seg7 <= "1000000";
  elsif digit = 1 then
    seg7 <= "1111001";
  elsif digit = 2 then
    seg7 <= "0100100";
  elsif digit = 3 then
    seg7 <= "0110000";
  elsif digit = 4 then
    seg7 <= "0011001";
  elsif digit = 5 then
    seg7 <= "0010010";
  elsif digit = 6 then
    seg7 <= "0000010";
  elsif digit = 7 then
    seg7 <= "1111000";
  elsif digit = 8 then
    seg7 <= "0000000";
  elsif digit = 9 then
    seg7 <= "0010000";
  elsif digit = 10 then
    seg7 <= "0001000"; -- Display an A
  elsif digit = 11 then
    seg7 <= "0000110"; -- Display L
  elsif digit = 12 then
    seg7 <= "0010010"; -- display O
  elsif digit = 13 then
    seg7 <= "1000000"; -- display S
  elsif digit = 14 then
    seg7 <= "1000111"; -- display an E
  elsif digit = 15 then
    seg7 <= "0001110"; -- display an R
  else
    seg7 <= "1111111"; -- display nothing
  end if;
END PROCESS;


END;
