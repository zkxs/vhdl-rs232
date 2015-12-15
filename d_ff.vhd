-- Author:              Michael Ripley
-- Create Date:         2015-11-12 10:24:38
-- Modification Date:   
-- Description:         d flip-flop

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity d_ff is
    port(
        clk:   in  STD_LOGIC;
        reset: in  STD_LOGIC;
        d:     in  STD_LOGIC;
        q:     out STD_LOGIC
    );
end entity;

architecture Behavioral of d_ff is

begin
    process(clk, reset)
    begin
        if (reset = '0') then
            q <= '0';
        elsif (rising_edge(clk)) then
            q <= d;
        end if;
    end process;
end Behavioral;
