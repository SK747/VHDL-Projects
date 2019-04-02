LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Lab 5, with ROM. Plays Lost Woods

ENTITY task2 IS
	PORT (CLOCK_50,AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT			:IN STD_LOGIC;
			CLOCK_27															:IN STD_LOGIC;
			KEY : IN STD_LOGIC_VECTOR (3 downto 0);
			SW																	:IN STD_LOGIC_VECTOR(17 downto 0);
			I2C_SDAT															:INOUT STD_LOGIC;
			I2C_SCLK,AUD_DACDAT,AUD_XCK								:OUT STD_LOGIC);
END task2;

ARCHITECTURE Behavior OF task2 IS

   -- CODEC Cores
	
	COMPONENT clock_generator
		PORT(	CLOCK_27														:IN STD_LOGIC;
		    	reset															:IN STD_LOGIC;
				AUD_XCK														:OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT audio_and_video_config
		PORT(	CLOCK_50,reset												:IN STD_LOGIC;
		    	I2C_SDAT														:INOUT STD_LOGIC;
				I2C_SCLK														:OUT STD_LOGIC);
	END COMPONENT;
	
	COMPONENT audio_codec
		PORT(	CLOCK_50,reset,read_s,write_s							:IN STD_LOGIC;
				writedata_left, writedata_right						:IN STD_LOGIC_VECTOR(23 DOWNTO 0);
				AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK		:IN STD_LOGIC;
				read_ready, write_ready									:OUT STD_LOGIC;
				readdata_left, readdata_right							:OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
				AUD_DACDAT													:OUT STD_LOGIC);
	END COMPONENT;
	
	component rom IS
	PORT
	(address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	end component;
	
	COMPONENT noise
	PORT (CLOCK_50: in STD_LOGIC;
			magnitude : in std_logic_vector(1 downto 0);
	       stream_in : in std_logic_vector(23 downto 0);
	       stream_out : out std_logic_vector(23 downto 0));
		END COMPONENT;

		component fir8 
		PORT ( CLOCK_50, valid: in std_logic;
          stream_in : in std_logic_vector(23 downto 0);
          stream_out : out std_logic_vector(23 downto 0));
		END COMPONENT;
	SIGNAL read_ready, write_ready, read_s, write_s		      :STD_LOGIC;
	SIGNAL writedata_left, writedata_right							:STD_LOGIC_VECTOR(23 DOWNTO 0);	
	--pure, noisy, filtered
	SIGNAL pureleft, pureright											:STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL writedata_left_noise, writedata_right_noise							:STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL writedata_left_filtered, writedata_right_filtered							:STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL readdata_left, readdata_right							:STD_LOGIC_VECTOR(23 DOWNTO 0);	
	SIGNAL reset															:STD_LOGIC;
	SIGNAL valid															:STD_LOGIC;
	
	signal mux : std_LOGIC_VECTOR(1 downto 0);
	
	type state is (read_note_state, rom_note_state, start, writestate, waitstate, rom_timer_state);
	type state2 is (read_rom, writerom);
	SIGNAL vol_pos : std_logic_vector(23 downto 0);
	SIGNAL vol_neg : std_logic_vector(23 downto 0);
	SIGNAL count : integer := 0;
	
	signal rom_input : std_logic_vector(4 downto 0);
	signal rom_music : std_logic_vector(7 downto 0);
	signal rom_counter : unsigned(4 downto 0);
	

BEGIN

	reset <= NOT(KEY(0));
	read_s <= '0';
	rom_input <= std_logic_vector(rom_counter);
	
	MUSIC : rom port map(address => rom_input, clock => clock_50, q => rom_music);
	
	my_clock_gen: clock_generator PORT MAP (CLOCK_27, reset, AUD_XCK);
	cfg: audio_and_video_config PORT MAP (CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
	codec: audio_codec PORT MAP(CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);

	left_noise : noise port map (clock_50, sw(17 downto 16), pureleft, writedata_left_noise);
	right_noise : noise port map (clock_50, sw(17 downto 16), pureright, writedata_right_noise);
	
	left_filter : fir8 port map (clock_50, valid, writedata_left_noise, writedata_left_filtered);
	right_filter : fir8 port map (clock_50, valid, writedata_right_noise, writedata_right_filtered);

	mux <= sw(15 downto 14);
	
	--volume control so we can hear noise 
	volumecontrol: process (all)
	begin
	if sw(5)='1' then
	vol_pos <= "000001000000000000000000";
	vol_neg <= "111111000000000000000000";
	elsif sw(6)='1' then
	vol_pos <= "000010000000000000000000";
	vol_neg <= "111110000000000000000000";
	elsif sw(7)='1' then
	vol_pos <= "001000000000000000000000";
	vol_neg <= "111000000000000000000000";
	else
	vol_pos <= "000000001000000000000000";
	vol_neg <= "111111111000000000000000";
	end if;
	end process; 

	-- sound block with ROM
   process (clock_50)
	variable state : state := read_note_state;
	variable rom_timer : unsigned(28 downto 0);
	variable playnote : unsigned(7 downto 0);
	begin
	if rising_edge(clock_50) then

	case state is
	
	when rom_note_state =>
		if (rom_counter = "10011") then
			rom_counter <= rom_counter + to_unsigned(1, 5);
		else
			rom_counter <= "00000";
		end if;
		state := read_note_state;

	when read_note_state =>
		playnote := unsigned(rom_music);
		state := start;
		
	when start =>
		write_s <= '0';
		if write_ready = '1' then
			state := writestate;
			valid <= '1';
		elsif write_ready = '0' then
			state := start;
			valid <= '0';
		end if;
		
	when writestate =>
		write_s <= '1';
		count <= count + 1;
		if playnote = "00000001" then -- MIDDLE C
		if count > 168 then
			count <= 0;
		end if;
		if count > 84 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00000010" then -- MIDDLE D
		if count > 150 then
			count <= 0;
		end if;
		if count > 75 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00000011" then -- MIDDLE E
		if count > 132 then
			count <= 0;
		end if;
		if count > 66 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00000100" then -- MIDDLE F
		if count > 126 then
			count <= 0;
		end if;
		if count > 63 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00000101" then -- MIDDLE G
		if count > 112 then
			count <= 0;
		end if;
		if count > 56 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00000110" then -- MIDDLE A
		if count > 100 then
			count <= 0;
		end if;
		if count > 50 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00000111" then -- MIDDLE B
		if count > 88 then
			count <= 0;
		end if;
		if count > 44 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00001000" then -- TREBLE C
		if count > 84 then
			count <= 0;
		end if;
		if count > 42 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00001001" then -- TREBLE D
		if count > 74 then
			count <= 0;
		end if;
		if count > 37 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		if playnote = "00001010" then -- TREBLE E
		if count > 66 then
			count <= 0;
		end if;
		if count > 33 then
			pureleft <= vol_neg; 
			pureright <= vol_neg;
		else
			pureleft <= vol_pos;
			pureright <= vol_pos;
		end if;
		end if;
		state := waitstate;
		
		
	when waitstate =>
		if write_ready = '0' then
			state := rom_timer_state;
		end if;
		
	when rom_timer_state =>
	-- for a long note
	if (playnote = "00000011") then
		if (rom_timer >= to_unsigned(42000000, 29)) then
			rom_timer := to_unsigned(0, 29);
			state := rom_note_state;
		else
			state := start;
		end if;
	else
		if (rom_timer >= to_unsigned(18000000, 29)) then
			rom_timer := to_unsigned(0, 29);
			state := rom_note_state;
		else
			state := start;
		end if;
		end if;
	when others => state := start;
	end case;
		rom_timer := rom_timer + to_unsigned(1, 29);
	end if;
	end process;
	
	--Muxer Block.
	Muxer: process (all)
	
	begin
	if (mux = "01") then
	writedata_left <= writedata_left_noise;
	writedata_right <= writedata_right_noise;
	elsif (mux = "10") then
	writedata_left <= writedata_left_filtered;
	writedata_right <= writedata_right_filtered;
	else
	writedata_left <= pureleft;
	writedata_right <= pureright;
	end if;
	
	end process;
	
	
END Behavior;