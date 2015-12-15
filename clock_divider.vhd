-- Author:              Michael Ripley
-- Create Date:         2015-10-08 01:46:02
-- Modification Date:   2015-10-08 01:46:02
-- Description:         If clock period is 10ns and divisor is 10, Q's period
--                      will be 100ns. Essentially this is a clock divider where
--                      you can specifiy an arbritrary divisor.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library util;
use util.misc.ceil_log2;

entity clock_divider is
    generic(divisor: natural := 10);

    Port (
        clock  : in  STD_LOGIC;
        clear  : in  STD_LOGIC;
        enable : in  STD_LOGIC;
        Q      : out STD_LOGIC
    );
end clock_divider;

architecture Behavioral of clock_divider is
    component counter_0_through_m is
        generic(
            m: natural := divisor-1;
            n: natural := ceil_log2(divisor-1)
        );

        Port (
            clock  : in  STD_LOGIC;
            clear  : in  STD_LOGIC;
            enable : in  STD_LOGIC;
            Q      : out STD_LOGIC;
            count  : out STD_LOGIC_VECTOR(n-1 downto 0)
        );
    end component;

    signal pre_Q : STD_LOGIC;
begin

    Q <= pre_Q;

    -- internal 0-through-m counter
    internalCounter : counter_0_through_m port map(
        clock  => clock,
        clear  => clear,
        enable => enable,
        Q      => pre_Q,
        count  => open
    );

end Behavioral;

