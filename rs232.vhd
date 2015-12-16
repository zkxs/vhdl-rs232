-- Author:              Michael Ripley
-- Create Date:         2015-12-01 06:57:11
-- Modification Date:   
-- Description:         

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rs232 is
    port (
        clock:               in  STD_LOGIC; -- CLK
        o8SevenSeg:          out STD_LOGIC_VECTOR(7 downto 0); -- seven seg
        o4SelectSeg:         out STD_LOGIC_VECTOR(3 downto 0); -- seven seg anodes
        
        i1Rx:                in  STD_LOGIC;
        o1Tx:                out STD_LOGIC;
        i1RTSin:             in  STD_LOGIC;
        o1RTSout:            out STD_LOGIC;
        i1CTSin:             in  STD_LOGIC;
        o1CTSout:            out STD_LOGIC;
        
        o1TxBuffer_in_use:   out STD_LOGIC;
        o1RxBuffer_in_use:   out STD_LOGIC;
        o1CTSout_led:        out STD_LOGIC;
        o1RTSout_led:        out STD_LOGIC;
        
        i8switch:            in  STD_LOGIC_VECTOR(7 downto 0);
        
        i1BtnStore:          in  STD_LOGIC; -- store switches into TxBuffer_byte
        i1BtnRead:           in  STD_LOGIC; -- read data from RxBuffer_byte
        i1BtnTx:             in  STD_LOGIC; -- transmit data from TxBuffer_bytes
        i1BtnClear:          in  STD_LOGIC; -- clear error status
        
        debug_clock:         out STD_LOGIC;
        debug_rx_bad:        out STD_LOGIC;
        debug_rx_forced:     out STD_LOGIC;
        debug_firstrun:      out STD_LOGIC;
        debug_tx_forced_indicator: out STD_LOGIC;
        i1debug_clear_error: in  STD_LOGIC;
        debug_tx_forced:     in  STD_LOGIC
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
    
    -- synchronizer
    component synchronizer is
        port(
            clk:  in  STD_LOGIC;
            din:  in  STD_LOGIC;
            dout: out STD_LOGIC
        );
    end component;
    
    ----------------------------------------------------------------------------
    -- signal declarations
    ----------------------------------------------------------------------------
    
    signal debug_clear_error: STD_LOGIC;
    
    signal TxBuffer: STD_LOGIC_VECTOR(10 downto 0);
    signal RxBuffer: STD_LOGIC_VECTOR(10 downto 0) := "10111011110";    -- EF
    signal TxBuffer_byte: STD_LOGIC_VECTOR(7 downto 0) := "10111110"; -- BE
    signal RxBuffer_byte: STD_LOGIC_VECTOR(7 downto 0);
    signal TxBuffer_in_use: STD_LOGIC;
    signal RxBuffer_in_use: STD_LOGIC;
    
    signal clock_sampling: STD_LOGIC;
    signal clock_sampling_reset: STD_LOGIC;
    signal clock_transmit: STD_LOGIC;
    
    signal CTSin_cached: STD_LOGIC := '1'; -- active low, just like CTS
    
    signal CTSout: STD_LOGIC;
    signal CTSout_ondemand: STD_LOGIC;
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
    
    signal TxParity: STD_LOGIC_VECTOR(6 downto 0);
    signal RxParity: STD_LOGIC_VECTOR(6 downto 0);
    
    signal TxBuffer_index: natural;
    signal transmitting: STD_LOGIC := '0';
    
    signal RxBuffer_index: natural;
    signal receiving: STD_LOGIC := '1'; -- this happens implicitly, so it's better to make it explicit
    signal receiving_clock_odd: STD_LOGIC;
    signal receiving_synchronized: STD_LOGIC;
    signal receive_reset: STD_LOGIC := '0';
    
    -- ignoring the first receive looks better, because I can't set receiving := 0 on startup
    signal receive_ignored: STD_LOGIC := '0';
begin
    ----------------------------------------------------------------------------
    -- glue logic
    ----------------------------------------------------------------------------
    
    o1CTSout <= CTSout;
    o1RTSout <= RTSout;
    o1CTSout_led <= CTSout;
    o1RTSout_led <= RTSout;
    o1TxBuffer_in_use <= TxBuffer_in_use;
    o1RxBuffer_in_use <= RxBuffer_in_use;
    
    -- if I wanted to set CTSout simplisticly, I could do this:
    --CTSout <= RxBuffer_in_use;
    
    -- if I wanted to set CTSout on demand, I could do this:
    CTSout <= CTSout_ondemand;
    
    RTSout <= not transmitting;
    
    RxBuffer_byte <= RxBuffer(8 downto 1);
    TxBuffer(8 downto 1) <= TxBuffer_byte;
    TxBuffer(0) <= '0'; -- start bit
    TxBuffer(9) <= not TxParity(0); -- set parity bit
    TxBuffer(10) <= '1'; -- stop bit
    
    -- calculate parity for transmitting
    TxParity(6) <= TxBuffer_byte(7) xor TxBuffer_byte(6);
    tx_parity_calculate: for i in 5 downto 0 generate
        TxParity(i) <= TxParity(i+1) xor TxBuffer_byte(i);
    end generate;
    
    -- debug things
    debug_clock <= receiving_clock_odd;
    debug_firstrun <= not receive_ignored;
    debug_rx_bad <= (not RxBuffer(0))
                and (RxBuffer(9) xnor RxParity(0))
                and (RxBuffer(10))
                and (not receiving);
    debug_tx_forced_indicator <= '1' when debug_tx_forced = '1' else '0';
    
    -- calculate parity for receiving
    RxParity(6) <= RxBuffer_byte(7) xor RxBuffer_byte(6);
    rx_parity_calculate: for i in 5 downto 0 generate
        RxParity(i) <= RxParity(i+1) xor RxBuffer_byte(i);
    end generate;
    
    
    ----------------------------------------------------------------------------
    -- processes
    ----------------------------------------------------------------------------
    
    -- transmit process
    process (clock_transmit)
        variable var_transmitting: STD_LOGIC;
        variable var_TxBuffer_index: natural;
        variable var_CTSin_cached: STD_LOGIC;
        
        variable btnClear_rising: STD_LOGIC;
        variable btnStore_rising: STD_LOGIC;
        variable btnTx_rising:    STD_LOGIC;
    begin
        if rising_edge(clock_transmit) then
            var_transmitting := transmitting;
            var_TxBuffer_index := TxBuffer_index;
            var_CTSin_cached := CTSin_cached;
            btnClear_rising := btnClear and (not btnClear_old);
            btnStore_rising := btnStore and (not btnStore_old);
            btnTx_rising    := btnTx    and (not btnTx_old   );
            btnClear_old <= btnClear;
            btnStore_old <= btnStore;
            btnTx_old    <= btnTx   ;
            
            
            if btnClear_rising = '1' then
                var_transmitting := '0';
                TxBuffer_in_use <= '0';
            elsif ((btnTx_rising = '1' and TxBuffer_in_use = '1') or debug_tx_forced = '1') and var_transmitting = '0' then -- if we want to send
                var_transmitting := '1';
                var_TxBuffer_index := 0;
            end if;
            
            -- if we want to send and it's ok to send
            if var_transmitting = '1' then
                
                -- check CTSin
                if i1CTSin = '0' then
                    var_CTSin_cached := '0';
                end if;
                
                if (var_CTSin_cached = '0') or (debug_tx_forced = '1') then
                    o1Tx <= TxBuffer(var_TxBuffer_index);
                    if var_TxBuffer_index = 10 then
                        -- we're done sending
                        var_transmitting := '0';
                        TxBuffer_in_use <= '0';
                        var_CTSin_cached := '1';
                    else
                        var_TxBuffer_index := var_TxBuffer_index + 1;
                    end if;
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
            CTSin_cached <= var_CTSin_cached;
        end if;
    end process;
    
    -- receive process
    process (clock_sampling, receive_reset)
        variable var_RxBuffer_index: natural;
        variable btnRead_rising: STD_LOGIC;
    begin
        if receive_reset = '1' then
            receiving_clock_odd <= '0';
            RxBuffer_index <= 0;
            receiving <= '1';
        elsif rising_edge(clock_sampling) then
            btnRead_rising  := btnRead  and (not btnRead_old);
            btnRead_old  <= btnRead;
            var_RxBuffer_index := RxBuffer_index;
            
            if btnRead_rising = '1' and transmitting = '0' then
                RxBuffer_in_use <= '0';
            end if;
            
            if RxBuffer_in_use = '0' and i1RTSin = '0' then
                CTSout_ondemand <= '0';
            end if;
            
            if receive_ignored = '1' then
                -- if we need to take a sample (rising edge of receiving_clock_odd)
                if receiving_clock_odd = '0' and receiving = '1' then
                    
                    RxBuffer(var_RxBuffer_index) <= i1Rx;
                    
                    if var_RxBuffer_index = 10 then
                        -- we're done receiving
                        receiving <= '0';
                        RxBuffer_in_use <= '1';
                        CTSout_ondemand <= '1';
                    else
                        var_RxBuffer_index := var_RxBuffer_index + 1;
                    end if;
                    
                end if;
            else
                receiving <= '0';
                receive_ignored <= '1';
                RxBuffer_in_use <= '0';
                CTSout_ondemand <= '1';
            end if;
            
            RxBuffer_index <= var_RxBuffer_index;
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
            clock_sampling_reset <= '0';
            receive_reset <= '0';
            
            if (Rx_falling = '1') and (receiving_synchronized /= '1') then -- Do I need to check if CTS is enabled?
            
                if CTSout /= '0' then
                    debug_rx_forced <= '1';
                end if;
            
                clock_sampling_reset <= '1';
                receive_reset <= '1';
            end if;
            
            if debug_clear_error = '1' then
                debug_rx_forced <= '0';
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
    debouncer1: debouncer
        port map (
            clock => clock,
            bouncy => i1BtnRead,
            debounced => btnRead
        );
    debouncer2: debouncer
        port map (
            clock => clock,
            bouncy => i1BtnTx,
            debounced => btnTx
        );
    debouncer3: debouncer
        port map (
            clock => clock,
            bouncy => i1BtnClear,
            debounced => btnClear
        );
    debouncer4: debouncer
        port map (
            clock => clock,
            bouncy => i1debug_clear_error,
            debounced => debug_clear_error
        );
    
    -- synchronizer
    sync0: synchronizer
        port map (
            clk => clock,
            din => receiving,
            dout => receiving_synchronized
        );
    
end Behavioral;
