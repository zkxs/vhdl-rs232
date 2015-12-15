-- Author:              Michael Ripley
-- Create Date:         2015-12-01 06:57:11
-- Modification Date:   
-- Description:         

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rs232 is
    port (
        clock:                in  STD_LOGIC; -- CLK
        o8SevenSeg:           out STD_LOGIC_VECTOR(7 downto 0); -- seven seg
        o4SelectSeg:          out STD_LOGIC_VECTOR(3 downto 0); -- seven seg anodes
        
        debug_clock:          out STD_LOGIC
    );
end rs232;

architecture Behavioral of rs232 is
    
    ----------------------------------------------------------------------------
    -- component declarations
    ----------------------------------------------------------------------------
    
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
    
    -- 7-seg selector
    component sevenseg_selector is
        port (
            clock      : in  STD_LOGIC;
            i4seg1     : in  STD_LOGIC_VECTOR(3 downto 0);
            i4seg2     : in  STD_LOGIC_VECTOR(3 downto 0);
            i4seg3     : in  STD_LOGIC_VECTOR(3 downto 0);
            i4seg4     : in  STD_LOGIC_VECTOR(3 downto 0);
            o8seg      : out STD_LOGIC_VECTOR(7 downto 0);
            o4selection: out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
    
    ----------------------------------------------------------------------------
    -- signal declarations
    ----------------------------------------------------------------------------
    
    
begin
    ----------------------------------------------------------------------------
    -- glue logic
    ----------------------------------------------------------------------------
    
    
    ----------------------------------------------------------------------------
    -- process
    ----------------------------------------------------------------------------
    
    
    ----------------------------------------------------------------------------
    -- port maps
    ----------------------------------------------------------------------------
    
    -- 7-seg selector
    selector: sevenseg_selector
        port map (
            clock       => clock,
            i4seg4      => "0001",
            i4seg3      => "0010",
            i4seg2      => "0100",
            i4seg1      => "1000",
            o8seg       => o8SevenSeg,
            o4selection => o4SelectSeg
        );
    
end Behavioral;
