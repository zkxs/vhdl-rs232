-- Author:              Michael Ripley
-- Create Date:         2015-11-12 10:24:38
-- Modification Date:   
-- Description:         1-bit synchronizer

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity synchronizer is
    port(
        clk:  in  STD_LOGIC;
        din:  in  STD_LOGIC;
        dout: out STD_LOGIC
    );
end entity;

architecture Behavioral of synchronizer is
    component d_ff is
        port(
            clk:   in  STD_LOGIC;
            reset: in  STD_LOGIC;
            d:     in  STD_LOGIC;
            q:     out STD_LOGIC
        );
    end component;
    
    signal dsync: STD_LOGIC;
begin
    
    dff1: d_ff
        port map(
            clk   => clk,
            reset => '1',
            d     => din,
            q     => dsync
        );
        
    dff2: d_ff
        port map(
            clk   => clk,
            reset => '1',
            d     => dsync,
            q     => dout
        );
    
end Behavioral;
