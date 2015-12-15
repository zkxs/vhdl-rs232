-- Author:              Michael Ripley
-- Create Date:         2015-10-07 21:18:04
-- Modification Date:   2015-10-07 21:18:04
-- Description:         n-bit counter. LSB is clock signal / 2

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity counter is
    generic(n: natural := 2);
    Port(
        clock : in  STD_LOGIC;
        clear : in  STD_LOGIC;
        count : in  STD_LOGIC;
        Q     : out STD_LOGIC_VECTOR(n-1 downto 0)
    );
end counter;

architecture Behavioral of counter is
    signal pre_Q: std_logic_vector(n-1 downto 0);
begin
    Q <= pre_Q;

    process(clock, clear, pre_Q)
    begin
        if clear = '1' then
            pre_Q <= pre_Q - pre_Q;
        elsif (rising_edge(clock)) then
            if count = '1' then
                pre_Q <= pre_Q + 1;
            end if;
        end if;
    end process;
end Behavioral;

