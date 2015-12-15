-- Author:              Michael Ripley
-- Create Date:         2015-10-07 21:54:19
-- Modification Date:   2015-10-07 21:54:19
-- Description:         Counts from 0 to m, inclusive.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.to_unsigned;

library util;
use util.misc.highBit;
use util.string_conversion.to_std_logic;

entity counter_0_through_m is
    generic(
        -- maximal number (inclusive) this counter counts to
        m: natural := 2; -- 9
        -- number of bits this couter has
        n: natural := 0 -- ceil_log(9 + 1) = 4

        -- note that I purposely chose invalid values here
    );

    Port (
        clock  : in  STD_LOGIC; -- input clock signal; tested at 100MHz
        clear  : in  STD_LOGIC; -- clear pin
        enable : in  STD_LOGIC; -- enable pin
        Q      : out STD_LOGIC; -- output
        count  : out STD_LOGIC_VECTOR(n-1 downto 0)
    );
end counter_0_through_m;

architecture Behavioral of counter_0_through_m is

    -- convert m into a STD_LOGIC_VECTOR
    constant goal: STD_LOGIC_VECTOR(n-1 downto 0) :=
            STD_LOGIC_VECTOR(to_unsigned(m, n));
    
    signal pre_count: STD_LOGIC_VECTOR(n-1 downto 0);
    signal goal_met_now: STD_LOGIC; -- if the goal is currently met
    signal goal_met_previously: STD_LOGIC; -- if goal was met last clock cycle
begin
    -- make sure the user didn't make count too small
    -- 2**4 = 16, 16 >= 15 + 1 is ok, 16 >= 16 + 1 is not ok

    -- also there is apparently NO WAY to make this fail synthesis if the
    -- assertion fails. this is an awful language.
    assert (2 ** n) >= (m + 1) report "Not enough bits to count to M";

    -- check if goal is met
    goal_met_now <= to_std_logic(pre_count = goal);

    -- connect outputs
    Q <= goal_met_previously;
    count <= pre_count;
    
    process(clock, clear, pre_count)
    begin
        if clear = '1' then -- external clear
            pre_count <= pre_count - pre_count;
        elsif (rising_edge(clock)) then
            if (enable = '1') then
                if (goal_met_now = '1') then
                    goal_met_previously <= '1';
                    pre_count <= pre_count - pre_count;
                else
                    goal_met_previously <= '0';
                    pre_count <= pre_count + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;

