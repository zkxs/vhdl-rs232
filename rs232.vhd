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
        
        i1BtnStore:           in  STD_LOGIC; -- store switches into TxBuffer_byte
        i1BtnRead:            in  STD_LOGIC; -- read data from RxBuffer_byte
        i1BtnTx:              in  STD_LOGIC; -- transmit data from TxBuffer_bytes
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
    
    -- debouncer
    component debouncer is
        port (
            clock:     in  STD_LOGIC;
            bouncy:    in  STD_LOGIC;
            debounced: out STD_LOGIC := '0'
        );
    end component;
    
    ----------------------------------------------------------------------------
    -- signal declarations
    ----------------------------------------------------------------------------
    
    signal TxBuffer: STD_LOGIC_VECTOR(10 downto 0);
    signal RxBuffer: STD_LOGIC_VECTOR(10 downto 0);
    signal TxBuffer_byte: STD_LOGIC_VECTOR(7 downto 0);
    signal RxBuffer_byte: STD_LOGIC_VECTOR(7 downto 0);
    signal TxBuffer_in_use: STD_LOGIC;
    signal RxBuffer_in_use: STD_LOGIC;
    
    signal clock_sampling: STD_LOGIC;
    signal clock_sampling_reset: STD_LOGIC;
    signal clock_transmit: STD_LOGIC;
    
    signal CTSout: STD_LOGIC;
    signal RTSout: STD_LOGIC := '0';
    
    signal btnStore: STD_LOGIC;
    signal btnRead:  STD_LOGIC;
    signal btnTx:    STD_LOGIC;
    signal btnClear: STD_LOGIC;
    signal btnStore_old: STD_LOGIC := '0';
    signal btnRead_old:  STD_LOGIC := '0';
    signal btnTx_old:    STD_LOGIC := '0';
    signal btnClear_old: STD_LOGIC := '0';
    signal Rx_old: STD_LOGIC := '0';
    
    signal xor_cascade_calculate: STD_LOGIC_VECTOR(6 downto 0);
    
    signal TxBuffer_index: natural;
    signal transmitting: STD_LOGIC := '0';
    
    signal RxBuffer_index: natural;
    signal receiving: STD_LOGIC;
    signal receiving_clock_odd: STD_LOGIC;
    signal receive_reset: STD_LOGIC := '0';
begin
    ----------------------------------------------------------------------------
    -- glue logic
    ----------------------------------------------------------------------------
    debug_clock <= clock_sampling;
    o1CTSout <= CTSout;
    o1RTSout <= RTSout;
    o1CTSout_led <= CTSout;
    o1RTSout_led <= RTSout;
    o1TxBuffer_in_use <= TxBuffer_in_use;
    o1RxBuffer_in_use <= RxBuffer_in_use;
    
    CTSout <= not RxBuffer_in_use;
    RTSout <= transmitting;
    
    RxBuffer_byte <= RxBuffer(8 downto 1);
    TxBuffer(8 downto 1) <= TxBuffer_byte;
    TxBuffer(0) <= '0'; -- start bit
    TxBuffer(9) <= not xor_cascade_calculate(0); -- set parity bit
    TxBuffer(10) <= '1'; -- stop bit
    
    -- calculate parity
    xor_cascade_calculate(6) <= TxBuffer_byte(7) xor TxBuffer_byte(6);
    parity_calculate: for i in 5 downto 0 generate
        xor_cascade_calculate(i) <= xor_cascade_calculate(i+1) xor TxBuffer_byte(i);
    end generate;
    
    
    -- zero things i'm not using yet FIXME
    RxBuffer_in_use <= '0';
    
    ----------------------------------------------------------------------------
    -- processes
    ----------------------------------------------------------------------------
    
    -- transmit process
    process (clock_transmit)
        variable var_transmitting: STD_LOGIC;
        variable var_TxBuffer_index: natural;
        
        variable btnClear_rising: STD_LOGIC;
        variable btnStore_rising: STD_LOGIC;
        variable btnTx_rising:    STD_LOGIC;
    begin
        if rising_edge(clock_transmit) then
            var_transmitting := transmitting;
            var_TxBuffer_index := TxBuffer_index;
            btnClear_rising := btnClear and (not btnClear_old);
            btnStore_rising := btnStore and (not btnStore_old);
            btnTx_rising    := btnTx    and (not btnTx_old   );
            btnClear_old <= btnClear;
            btnStore_old <= btnStore;
            btnTx_old    <= btnTx   ;
            
            
            if btnClear_rising = '1' then
                var_transmitting := '0';
                TxBuffer_in_use <= '0';
            --elsif btnTx_rising = '1' and TxBuffer_in_use = '1' and var_transmitting = '0' then -- if we want to send
            elsif btnTx = '1' and TxBuffer_in_use = '1' and var_transmitting = '0' then -- FIXME REMOVE THIS LINE
                var_transmitting := '1';
                var_TxBuffer_index := 0;
            end if;
            
            -- if we want to send and it's ok to send
            --if var_transmitting = '1' and i1CTSin = '0' then -- FIXME REENABLE THIS LINE
            if var_transmitting = '1' then -- FIXME REMOVE THIS LINE
                o1Tx <= TxBuffer(var_TxBuffer_index);
                if var_TxBuffer_index = 10 then
                    var_transmitting := '0';
                    --TxBuffer_in_use <= '0'; -- FIXME REENABLE THIS LINE
                else
                    var_TxBuffer_index := var_TxBuffer_index + 1;
                end if;
            else -- if not transmitting
                o1Tx <= '1';
                
                if btnStore_rising = '1' then
                    TxBuffer_byte <= i8switch;
                    TxBuffer_in_use <= '1';
                end if;
                
            end if;
            
            transmitting <= var_transmitting;
            TxBuffer_index <= var_TxBuffer_index;
        end if;
    end process;
    
    -- receive process
    process (clock_sampling, receive_reset)
    begin
        if receive_reset = '1' then
            receiving <= '1';
            receiving_clock_odd <= '0';
            RxBuffer_index <= 0;
        elsif rising_edge(clock_sampling) then
            
            -- if we need to take a sample
            if receiving_clock_odd = '1' then
                
            end if;
            
            receiving_clock_odd <= not receiving_clock_odd;
        end if;
    end process;
    
    -- process that checks if we need to start receiving
    process (clock)
        variable Rx_falling:  STD_LOGIC;
    begin
        if rising_edge(clock) then
        
            Rx_falling := (not i1Rx) and Rx_old;
            Rx_old <= i1Rx;
        
            if Rx_falling = '1' and receiving /= '1' then
                clock_sampling_reset <= '1';
                receive_reset <= '1';
            elsif receiving = '1' then
                clock_sampling_reset <= '0';
                receive_reset <= '0';
            end if;
            
        end if;
    end process;
    
    
    
    process (btnRead)
        
        variable btnRead_rising:  STD_LOGIC;
        
        
    begin
        if rising_edge(btnRead) then
            
            -- btnRead_rising  := btnRead  and (not btnRead_old );
            -- btnRead_old  <= btnRead ;
            
            
            if transmitting = '0' then
                
            end if;
        end if;
    end process;
    
    
    ----------------------------------------------------------------------------
    -- port maps
    ----------------------------------------------------------------------------
    
    -- 7-seg selector
    selector: sevenseg_selector
        port map (
            clock       => clock,
            i4seg4      => TxBuffer_byte(7 downto 4),
            i4seg3      => TxBuffer_byte(3 downto 0),
            i4seg2      => RxBuffer_byte(7 downto 4),
            i4seg1      => RxBuffer_byte(3 downto 0),
            o8seg       => o8SevenSeg,
            o4selection => o4SelectSeg
        );
        
    -- sampling clock
    clock_divider_sampling: clock_divider
        generic map(
            divisor => 20834 -- ((2400 hz * 10 ns) ^ -1) / 2
        )
        port map (
            clock => clock,
            clear => clock_sampling_reset,
            enable => '1',
            Q     => clock_sampling
        );
        
    -- transmitting clock
    clock_divider_transmit: clock_divider
        generic map(
            divisor => 41667 -- (2400 hz * 10 ns) ^ -1
        )
        port map (
            clock => clock,
            clear => '0',
            enable => '1',
            Q     => clock_transmit
        );
        
    -- debouncers
    debouncer0: debouncer
        port map (
            clock => clock,
            bouncy => i1BtnStore,
            debounced => btnStore
        );
        
    -- debouncers
    debouncer1: debouncer
        port map (
            clock => clock,
            bouncy => i1BtnRead,
            debounced => btnRead
        );
        
    -- debouncers
    debouncer2: debouncer
        port map (
            clock => clock,
            bouncy => i1BtnTx,
            debounced => btnTx
        );
        
    -- debouncers
    debouncer3: debouncer
        port map (
            clock => clock,
            bouncy => i1BtnClear,
            debounced => btnClear
        );
    
end Behavioral;
