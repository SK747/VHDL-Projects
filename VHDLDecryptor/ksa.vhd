library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity part of the description.  Describes inputs and outputs

entity lab6 is
  port(CLOCK_50 : in  std_logic;  -- Clock pin
       KEY : in  std_logic_vector(3 downto 0);  -- push button switches
       SW : in  std_logic_vector(17 downto 0);  -- slider switches
		 LEDG : out std_logic_vector(7 downto 0);  -- green lights
		 LEDR : out std_logic_vector(17 downto 0));  -- red lights
end lab6;

-- Architecture part of the description

architecture rtl of lab6 is

   -- Declare the component for the ram.  This should match the entity description 
	-- in the entity created by the megawizard. If you followed the instructions in the 
	-- handout exactly, it should match.  If not, look at s_memory.vhd and make the
	-- changes to the component below
	
   COMPONENT s_memory IS
	   PORT (
		   address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   clock		: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;
	
	COMPONENT decrypted_RAM IS
	PORT (
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
	END component;
	
	COMPONENT encrypted_ROM IS
	PORT(
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
	END component;

	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
type state_type is (init, 
                       fill_a,
							  wait_a,
   	 					  done_a,
							  init_b,
							  goto_b_i,
							  wait_b_i,
							  read_b_i,
							  goto_b_j,
							  wait_b_j,
							  write_b_j,
							  write_b_i,
							  done_b,
							  init_c,
							  get_c_i,
							  goto_c_i,
							  wait_c_i,
							  get_c_j,
							  goto_c_j,
							  wait_c_j,
							  swap_c_j,
							  wait_swap_c_i,
							  swap_c_i,
							  get_f_address,
							  goto_f,
							  wait_f,
							  get_f,
							  get_input,
							  get_output,
							  done_c,
							  update_i,
							  update_k,
							  goto_message,
							  wait_message,
							  check_message,
							  done);
								
    -- These are signals that are used to connect to the memory													 
	 signal address, address_RAM, address_ROM : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data, data_RAM : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren, wren_RAM : STD_LOGIC;
	 signal q, q_RAM, q_ROM : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal secret_key : std_logic_vector(23 downto 0) := "000000000000000000000000";

	 begin
	    -- Include the S memory structurally
	
       u0: s_memory port map (
	        address, clock_50, data, wren, q);
			  
		 u1: decrypted_RAM port map (
			  address_RAM, clock_50, data_RAM, wren_RAM, q_RAM);
			  
		 u2: encrypted_ROM port map (
			  address_ROM, clock_50, q_ROM);
			  
		 ledr <= secret_key(17 downto 0);
		
	    process (clock_50)
		 variable c, i, j, k, f, f_address, imod : integer := 0;
		 variable input : std_logic_vector(7 downto 0) := "00000000";
		 variable temp_address, temp_address_ram, temp_address_rom : std_logic_vector(7 downto 0);
		 variable temp_data, temp_data_ram : std_logic_vector(7 downto 0);
		 variable temp_wren, temp_wren_ram : std_logic;
		 variable temp_i, temp_j : std_logic_vector(7 downto 0) := "00000000";
		 variable temp_secret_key : std_logic_vector(7 downto 0) := "00000000";
		 variable current_state : state_type;
		 begin
		 if rising_edge(clock_50) then
			case current_state is
			when init =>
    		 current_state := fill_a;
			 i := 0;
          temp_wren := '1';
          temp_address := std_logic_vector(to_unsigned(i, temp_address'length));
          temp_data := std_logic_vector(to_unsigned(i, temp_data'length));
          ledg(0) <= '0';
    		when fill_a =>
    			if i = 255 then
    				current_state := done_a;
    			else
    				current_state := fill_a;
					i := i + 1;
          end if;
          temp_address := std_logic_vector(to_unsigned(i, temp_address'length));
          temp_data := std_logic_vector(to_unsigned(i, temp_data'length));
    		when done_a =>
          current_state := init_b;
          temp_wren := '0';
/**********************************************************/
		  when init_b =>
          current_state := goto_b_i;
          i := 0;
          j := 0;
        when goto_b_i =>
          current_state := wait_b_i;
          temp_wren := '0';
          temp_address := std_logic_vector(to_unsigned(i, temp_address'length));
        when wait_b_i =>
          current_state := read_b_i;
        when read_b_i =>
          current_state := goto_b_j;
          imod := i mod 3;
          if (imod = 2) then
            temp_secret_key := secret_key(7 downto 0);
          elsif (imod = 1) then
            temp_secret_key := secret_key(15 downto 8);
          elsif (imod = 0) then
            temp_secret_key := secret_key(23 downto 16);
          end if;
          temp_i := q;
          j := (j + to_integer(unsigned(q)) + to_integer(unsigned(temp_secret_key))) mod 256;
        when goto_b_j =>
          current_state := wait_b_j;
          temp_wren := '0';
          temp_address := std_logic_vector(to_unsigned(j, temp_address'length));
        when wait_b_j =>
          current_state := write_b_j;
        when write_b_j =>
          current_state := write_b_i;
          temp_j := q;
          temp_address := std_logic_vector(to_unsigned(j, temp_address'length));
          temp_data := temp_i;
          temp_wren := '1';
        when write_b_i =>
          if (i = 255) then
            current_state := done_b;
          else
            current_state := update_i;
          end if;
          temp_address := std_logic_vector(to_unsigned(i, temp_address'length));
          temp_data := temp_j;
          temp_wren := '1';
		  when update_i =>
          i := i + 1;
			 current_state := goto_b_i;
        when done_b =>
          current_state := init_c;
          ledg <= "00000111";
          temp_wren := '0';
/************************************************************/
		  when init_c =>
			i := 0;
			j := 0;
			k := 0;
			current_state := get_c_i;
			when get_c_i =>
				temp_wren := '0';
				temp_wren_ram := '0';
				i := (i + 1) mod 256;	
				current_state := goto_c_i;
			when goto_c_i =>
				temp_address := std_logic_vector(to_unsigned(i, temp_address'length));
				current_state := wait_c_i;
			when wait_c_i =>
				current_state := get_c_j;
			when get_c_j =>
				temp_i := q;
				j := (j + to_integer(unsigned(q))) mod 256;
				current_state := goto_c_j;
			when goto_c_j =>
				temp_wren := '0';
				temp_address := std_logic_vector(to_unsigned(j, temp_address'length));
				current_state := wait_c_j;
			when wait_c_j =>
				current_state := swap_c_j;
			when swap_c_j =>
				temp_address := std_logic_vector(to_unsigned(j, temp_address'length));
				temp_data := temp_i;
				temp_j := q;
				temp_wren := '1';
				current_state := swap_c_i;
			when swap_c_i =>
				temp_address := std_logic_vector(to_unsigned(i, temp_address'length));
				temp_data := temp_j;
				temp_wren := '1';
				current_state := get_f_address;
			when get_f_address =>
				temp_wren := '0';
				f_address := (to_integer(unsigned(temp_i)) + to_integer(unsigned(temp_j))) mod 256;
				temp_address_rom := std_logic_vector(to_unsigned(k, temp_address_rom'length));
				current_state := goto_f;
			when goto_f =>
				temp_address := std_logic_vector(to_unsigned(f_address, temp_address'length));
				current_state := wait_f;
			when wait_f =>
				current_state := get_f;
			when get_f =>
				f := to_integer(unsigned(q));
				current_state := get_input;
			when get_input =>
				input := std_logic_vector(to_unsigned(f, q_rom'length)) xor q_rom;
				current_state := get_output;
			when get_output =>
				temp_address_ram := std_logic_vector(to_unsigned(k, temp_address_ram'length));
				temp_data_ram := input;
				temp_wren_ram := '1';
				if k = 31 then
					current_state := done_c;
				else
					current_state := update_k;
				end if;
			when update_k =>
				k := k + 1;
				current_state := get_c_i;
			when done_c =>
				ledg <= "00111111";
				current_state := goto_message;
				c := 0;
				temp_wren_RAM := '0';
				temp_wren := '0';
			when goto_message =>
				temp_wren_RAM := '0';
				temp_address_RAM := std_logic_vector(to_unsigned(c, temp_address_RAM'length));
				current_state := wait_message;
			when wait_message =>
				current_state := check_message;
			when check_message =>
				c := c + 1;
				if c = 31 or secret_key = "00111111111111111111111111" then --000000000011000111111111
					current_state := done;
				elsif q_ram >=  "01100001" and q_ram <= "01111010" then -- <97, >122, !32
					current_state := goto_message;
				elsif q_ram = "00100000" then
					current_state := goto_message;
				else 
					current_state := init;
					secret_key <= std_logic_vector(to_unsigned(to_integer(unsigned(secret_key)) + 1, secret_key'length));
				end if;
			when done =>
				temp_wren_RAM := '0';
				ledg <= "11111111";
				current_state := done;
    		when others =>
          current_state := init;
    		end case;
    	end if;
      address <= temp_address;
		address_RAM <= temp_address_ram;
		address_ROM <= temp_address_rom;
      data <= temp_data;
		data_RAM <= temp_data_ram;
      wren <= temp_wren;
		wren_RAM <= temp_wren_ram;
		 end process; 
end RTL;
