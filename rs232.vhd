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
        
        i1Rx:                 in  STD_LOGIC;
        o1Tx:                 out STD_LOGIC;
        i1RTSin:              in  STD_LOGIC;
        o1RTSout:             out STD_LOGIC;
        i1CTSin:              in  STD_LOGIC;
        o1CTSout:             out STD_LOGIC;
        
        o1TxBuffer_in_use:    out STD_LOGIC;
        o1RxBuffer_in_use:    out STD_LOGIC;
        o1CTSout_led:         out STD_LOGIC;
        o1RTSout_led:         out STD_LOGIC;
        
        i8switch:             in  STD_LOGIC_VECTOR(7 downto 0);
        
        i1BtnStore:           in  STD_LOGIC; -- store switches into TxBuffer
        i1BtnRead:            in  STD_LOGIC; -- read read data from RxBuffer
        i1BtnTx:              in  STD_LOGIC; -- transmit data from TxBuffers
        i1BtnClear:           in  STD_LOGIC; -- clear error status
        
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
    
    signal TxBuffer: STD_LOGIC_VECTOR(7 downto 0);
    signal RxBuffer: STD_LOGIC_VECTOR(7 downto 0);
    signal clock_sampling: STD_LOGIC;
    signal clock_sampling_reset: STD_LOGIC;
    
    signal CTSout: STD_LOGIC;
    signal RTSout: STD_LOGIC;
begin
    ----------------------------------------------------------------------------
    -- glue logic
    ----------------------------------------------------------------------------
    debug_clock <= clock_sampling;
    o1CTSout <= CTSout;
    o1RTSout <= RTSout;
    o1CTSout_led <= CTSout;
    o1RTSout_led <= RTSout;
    
    CTSout <= '0';
    RTSout <= '0';
    
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
            i4seg4      => TxBuffer(7 downto 4),
            i4seg3      => TxBuffer(3 downto 0),
            i4seg2      => RxBuffer(7 downto 4),
            i4seg1      => RxBuffer(3 downto 0),
            o8seg       => o8SevenSeg,
            o4selection => o4SelectSeg
        );
        
    -- sampling clock
    clock_divider_3ms: clock_divider
        generic map(
            divisor => 41667 -- (2400 hz * 10 ns) ^ -1
        )
        port map (
            clock => clock,
            clear => clock_sampling_reset,
            enable => '1',
            Q     => clock_sampling
        );
    
end Behavioral;
