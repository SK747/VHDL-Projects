library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity lab3 is
    port(CLOCK_50            : in  std_logic;
     KEY                 : in  std_logic_vector(3 downto 0);
     SW                  : in  std_logic_vector(17 downto 0);
     VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
     VGA_HS              : out std_logic;
     VGA_VS              : out std_logic;
     VGA_BLANK           : out std_logic;
     VGA_SYNC            : out std_logic;
     VGA_CLK             : out std_logic);
end lab3;
 
architecture rtl of lab3 is
 
 --Component from the Verilog file: vga_adapter.v
 
    component vga_adapter
        generic(RESOLUTION : string);
        port (  resetn                                       : in  std_logic;
                clock                                        : in  std_logic;
                colour                                       : in  std_logic_vector(2 downto 0);
                x                                            : in  std_logic_vector(7 downto 0);
                y                                            : in  std_logic_vector(6 downto 0);
                plot                                         : in  std_logic;
                VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
                VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
    end component;
 
    signal x      : std_logic_vector(7 downto 0);
    signal y      : std_logic_vector(6 downto 0);
    signal colour : std_logic_vector(2 downto 0);
    signal plot, XDONE, YDONE, INITY, INITX, LOADY, LOADX   : std_logic;
    --signal current_state, next_state : std_logic_vector(1 downto 0);
    signal current_state : std_logic_vector(4 downto 0);
    --constant INITALL : std_logic_vector(1 downto 0)   := "00";
    --constant DRAW_COL : std_logic_vector(1 downto 0)  := "01";
    --constant SHIFT_COL : std_logic_vector(1 downto 0)     := "10";
    --constant DONE : std_logic_vector(1 downto 0)      := "11";
 
    constant INITALL : std_logic_vector(4 downto 0)     := "00000";
    constant DRAW_COL : std_logic_vector(4 downto 0)    := "00001";
    constant SHIFT_COL : std_logic_vector(4 downto 0)   := "00010";
    constant CIRC_INIT : std_logic_vector(4 downto 0)   := "00011";
    constant LOOP_GUARD : std_logic_vector(4 downto 0)  := "00100";
    constant OCT1 : std_logic_vector(4 downto 0)        := "00101";
    constant OCT2 : std_logic_vector(4 downto 0)        := "00110";
    constant OCT3 : std_logic_vector(4 downto 0)        := "00111";
    constant OCT4 : std_logic_vector(4 downto 0)        := "01000";
    constant OCT5 : std_logic_vector(4 downto 0)        := "01001";
    constant OCT6 : std_logic_vector(4 downto 0)        := "01010";
    constant OCT7 : std_logic_vector(4 downto 0)        := "01011";
    constant OCT8 : std_logic_vector(4 downto 0)        := "01100";
    constant INC_OFFY : std_logic_vector(4 downto 0)    := "01101";
    constant CRIT_LEQ_0 : std_logic_vector(4 downto 0)  := "01110";
    constant CRIT_GT_0 : std_logic_vector(4 downto 0)   := "01111";
 
    constant DONE : std_logic_vector(4 downto 0)        := "10000";
 
    constant center_x : unsigned(7 downto 0) := to_unsigned(60,8);
    constant center_y : unsigned(7 downto 0) := to_unsigned(60,8);
    constant radius : unsigned(7 downto 0) := to_unsigned(30,8);
 
begin
 
    -- colour <= "111";
    vga_u0 : vga_adapter
        generic map(RESOLUTION => "160x120")
        port map(resetn    => KEY(3),
                 clock     => CLOCK_50,
                 colour    => colour,
                 x         => x,
                 y         => y,
                 plot      => plot,
                 VGA_R     => VGA_R,
                 VGA_G     => VGA_G,
                 VGA_B     => VGA_B,
                 VGA_HS    => VGA_HS,
                 VGA_VS    => VGA_VS,
                 VGA_BLANK => VGA_BLANK,
                 VGA_SYNC  => VGA_SYNC,
                 VGA_CLK   => VGA_CLK);
 

 
    --process(CLOCK_50) -- Y counter and datapath
    --variable Y : unsigned(5 downto 0);
    --begin
    --  if rising_edge(CLOCK_50) then
    --    if (INITY = '1') then
    --      Y := (others => '0');
    --    elsif (LOADY = '1') then
    --      Y := Y+1;
    --    end if;
    --    YDONE <= '0';
    --    if (Y = 119) then
    --      YDONE <= '1';
    --    end if;
    --  end if;
    --end process;
 
    --process(CLOCK_50)     -- datapath for fill
    --  variable localY : unsigned(6 downto 0);
    --  variable localX : unsigned(7 downto 0);
    --begin
    --  if rising_edge(CLOCK_50) then
    --      if (INITY = '1') then
    --          localY := (others => '0');
    --      elsif (LOADY = '1') then
    --          localY := localY+1;
    --      end if;
    --      if (INITX = '1') then
    --          localX := (others => '0');
    --      elsif (LOADX = '1') then
    --          localX := localX+1;
    --      end if;
    --      XDONE <= '0';
    --      YDONE <= '0';
    --      if (localY = 119) then
    --          YDONE <= '1';
    --      end if;
    --      if (localX = 159) then
    --          XDONE <= '1';
    --      end if;
    --  end if;
    --  if(XDONE = '0' AND YDONE = '0') then        -- Only if we're not done filling
    --      x <= std_logic_vector(localX);
    --      y <= std_logic_vector(localY);
    --      --colour <= std_logic_vector(localX(2 downto 0));   -- rainbow
    --      colour <= "000";                                    -- clear screen for the circle drawing
    --  else x <= x;
    --  end if;
    --end process;
 
    process(CLOCK_50)       -- state machine
        variable localY : unsigned(7 downto 0);
        variable localX : unsigned(7 downto 0);
        variable offset_x, offset_y : unsigned(7 downto 0);
        variable crit : signed(15 downto 0);
    begin
	  localx := to_integer(unsigned(x));
            localy := to_integer(unsigned(y));
        if rising_edge(CLOCK_50) then
            case current_state is
                when INITALL =>
                    --INITX <= '1';
                    --INITY <= '1';
                    --LOADX <= '1';
                    --LOADY <= '1';
                    localY := (others => '0');
                    localX := (others => '0');
                    plot <= '0';
                    current_state <= DRAW_COL;
                when DRAW_COL =>
                    --INITX <= '0';
                    --INITY <= '0';
                    --LOADX <= '0';
                    --LOADY <= '1';
                    localY := localY+1;
                    plot <= '1';
                    if (YDONE = '1' and XDONE = '0') then
                        current_state <= SHIFT_COL;
                    elsif (XDONE = '1') then
                        current_state <= DONE;
                    else
                        current_state <= DRAW_COL;
                    end if;
                when SHIFT_COL =>
                    --INITX <= '0';
                    --INITY <= '1';
                    --LOADX <= '1';
                    --LOADY <= '0';
                    localX := localX+1;
                    plot <= '0';
                    current_state <= DRAW_COL; -- unconditional jump
                when CIRC_INIT =>
                    offset_y := to_unsigned(0,8);
                    offset_x := radius;
                    crit := to_signed(1,16) - signed(radius);
                    current_state <= LOOP_GUARD;
                when LOOP_GUARD =>
                    if (offset_y <= offset_x) then
                        current_state <= OCT1;
                    else
                        current_state <= DONE;
                    end if;
                when OCT1 =>
                    localX := center_x + offset_x;
                    localY := center_y + offset_y;
                    current_state <= OCT2;
                when OCT2 =>
                    localX := center_x + offset_y;
                    localY := center_y + offset_x;
                    current_state <= OCT3;
                when OCT3 =>
                    localX := center_x - offset_x;
                    localY := center_y + offset_y;
                    current_state <= OCT4;
                when OCT4 =>
                    localX := center_x - offset_y;
                    localY := center_y + offset_y;
                    current_state <= OCT5;
                when OCT5 =>
                    localX := center_x - offset_x;
                    localY := center_y - offset_y;
                    current_state <= OCT6;
                when OCT6 =>
                    localX := center_x - offset_y;
                    localY := center_y - offset_x;
                    current_state <= OCT7;
                when OCT7 =>
                    localX := center_x + offset_x;
                    localY := center_y - offset_y;
                    current_state <= OCT8;
                when OCT8 =>
                    localX := center_x + offset_y;
                    localY := center_y - offset_x;
                    current_state <= INC_OFFY;
                when INC_OFFY =>
                    offset_y := offset_y + 1;
                    if (crit <= 0) then
                        current_state <= CRIT_LEQ_0;
                    elsif (crit > 0) then
                        current_state <= CRIT_GT_0;
                    end if;
                when CRIT_LEQ_0 =>
                    crit := crit + 2*signed(offset_y) + to_signed(1,16);
                    current_state <= LOOP_GUARD;
                when CRIT_GT_0 =>
                    crit := crit + signed(2*(offset_y - offset_x - to_unsigned(1,8))) + to_signed(1,16);
                    offset_x := offset_x - to_unsigned(1,8);
                    current_state <= LOOP_GUARD;
                --when
                when DONE =>    current_state <= DONE; -- when we are done, we are done.
                when others => current_state <= INITALL;
            end case;
            if(current_state /= DONE AND current_state /= "000--") then
                x <= std_logic_vector(localX);
                y <= std_logic_vector(localY(6 downto 0));
                colour <= "111";
            else x <= x;
            end if;
        end if;
 
    end process;
 
end rtl;
 
 
 
 
    --process(CLOCK_50)     -- state logic for the filler
    --begin
    --  if rising_edge(CLOCK_50) then
    --      case current_state is
    --          when INITALL =>
    --              INITX <= '1';
    --              INITY <= '1';
    --              LOADX <= '1';
    --              LOADY <= '1';
    --              plot <= '0';
    --              current_state <= DRAW_COL;
    --          when DRAW_COL =>
    --              INITX <= '0';
    --              INITY <= '0';
    --              LOADX <= '0';
    --              LOADY <= '1';
    --              plot <= '1';
    --              if (YDONE = '1' and XDONE = '0') then
    --                  current_state <= SHIFT_COL;
    --              elsif (XDONE = '1') then
    --                  current_state <= DONE;
    --              else
    --                  current_state <= DRAW_COL;
    --              end if;
    --          when SHIFT_COL =>
    --              INITX <= '0';
    --              INITY <= '1';
    --              LOADX <= '1';
    --              LOADY <= '0';
    --              plot <= '0';
    --              current_state <= DRAW_COL; -- unconditional jump
    --          when DONE => current_state <= DONE; -- when we are done, we are done.
    --          when others =>
    --              current_state <= INITALL;
    --      end case;
    --  end if;
 
    --end process;
