-- Author:              Michael Ripley
-- Create Date:         2015-12-14 22:20:53
-- Modification Date:   
-- Description:         Debounces buttons


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debouncer is
    port (
        clock:     in  STD_LOGIC;
        bouncy:    in  STD_LOGIC;
        debounced: out STD_LOGIC := '0'
    );
end debouncer;

architecture Behavioral of debouncer is
   

    signal count: STD_LOGIC_VECTOR(19 downto 0);
begin
    
    process(clock, bouncy, count)
    begin
        if bouncy = '0' then -- external clear
            count <= count - count;
            debounced <= '0';
        elsif (rising_edge(clock)) then
            count <= count + 1;
            if (count = "11111111111111111111") then
                debounced <= '1';
            end if;
        end if;
    end process;
    

end Behavioral;

