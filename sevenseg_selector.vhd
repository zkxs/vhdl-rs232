-- Author:         Michael Ripley
-- Create Date:    2015-10-08 03:25:57
-- Modified:       2015-12-14 19:52:50
-- Description:    An internal 2-bit clock drives a simple counter 0 through 3.
--                 The counter's state is used as the input to two multiplexers,
--                 one connecting a input 7-seg to the single output, the other
--                 selecting the appropriate 7-seg to write to.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sevenseg_selector is
    port (
        clock      : in  STD_LOGIC;
        i4seg1     : in  STD_LOGIC_VECTOR(3 downto 0);
        i4seg2     : in  STD_LOGIC_VECTOR(3 downto 0);
        i4seg3     : in  STD_LOGIC_VECTOR(3 downto 0);
        i4seg4     : in  STD_LOGIC_VECTOR(3 downto 0);
        o8seg      : out STD_LOGIC_VECTOR(7 downto 0);
        o4selection: out STD_LOGIC_VECTOR(3 downto 0)
    );
end sevenseg_selector;

architecture Behavioral of sevenseg_selector is
    -- internal simple counter
    component counter is
        generic(n: natural := 2);
        Port (
            clock : in  STD_LOGIC;
            clear : in  STD_LOGIC;
            count : in  STD_LOGIC;
            Q     : out STD_LOGIC_VECTOR (n-1 downto 0)
        );
    end component;
    
    -- 7-seg encoder
    component sevenseg_encoder is
        port (
            number:  in  STD_LOGIC_VECTOR (3 downto 0);
            encoded: out STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;
    
    -- clock divider
    component clock_divider is
        generic (
            divisor: natural
        );
        port (
            clock:  in  STD_LOGIC;
            clear:  in  STD_LOGIC;
            enable: in  STD_LOGIC;
            Q:      out STD_LOGIC
        );
    end component;
    
    signal clock_3millisecond: STD_LOGIC;
    signal count: STD_LOGIC_VECTOR(1 downto 0);
    signal currentNumber: STD_LOGIC_VECTOR(3 downto 0);
begin

    -- internal simple counter
    simpleCounter : counter port map(
        clock => clock_3millisecond,
        clear => '0',
        count => '1',
        Q     => count
    );
    
    -- 3-ms clock (drives 7-seg switching)
    clock_divider_3ms: clock_divider
        generic map(
            divisor => 300E3
        )
        port map (
            clock => clock,
            clear => '0',
            enable => '1',
            Q     => clock_3millisecond
        );
    
    -- encoder
    encoder: sevenseg_encoder
        port map (
            number  => currentNumber,
            encoded => o8seg
        );
    
    with (count) SELECT
        o4selection <= "1110" when "00",
                       "1101" when "01",
                       "1011" when "10",
                       "0111" when "11";
                       
    with (count) SELECT
        currentNumber <= i4seg1 when "00",
                         i4seg2 when "01",
                         i4seg3 when "10",
                         i4seg4 when "11";

end Behavioral;

