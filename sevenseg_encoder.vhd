-- Author:         Michael Ripley
-- Create Date:    03:13:14 10/08/2015
-- Module Name:    sevenseg_encoder - Behavioral
-- Description:    Encodes a 4-bit binary number to a hexadecimal value ready
--                 for output to a 7-segment display. This assumes a value of
--                 '0' will light up a segment.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sevenseg_encoder is
    Port (
        number : in  STD_LOGIC_VECTOR (3 downto 0);
        encoded : out  STD_LOGIC_VECTOR (7 downto 0)
    );
end sevenseg_encoder;

architecture Behavioral of sevenseg_encoder is
    signal A:  STD_LOGIC;
    signal B:  STD_LOGIC;
    signal C:  STD_LOGIC;
    signal D:  STD_LOGIC;
    signal E:  STD_LOGIC;
    signal F:  STD_LOGIC;
    signal G:  STD_LOGIC;
    signal H:  STD_LOGIC;
    signal DP: STD_LOGIC;

    signal W:  STD_LOGIC;
    signal X:  STD_LOGIC;
    signal Y:  STD_LOGIC;
    signal Z:  STD_LOGIC;
begin
    encoded(7) <= A ;
    encoded(6) <= B ;
    encoded(5) <= C ;
    encoded(4) <= D ;
    encoded(3) <= E ;
    encoded(2) <= F ;
    encoded(1) <= G ;
    encoded(0) <= DP;

    W  <=  number(3);
    X  <=  number(2);
    Y  <=  number(1);
    Z  <=  number(0);

    A <= (w and x and not y and z) or (w and not x and y and z) or (not w and x and not z) or (not w and not x and not y and z);
    B <= (w and x and not z) or (w and y and z) or (not w and x and not y and z) or (x and y and not z);
    C <= (w and x and y) or (w and x and not z) or (not w and not x and y and not z);
    D <= (w and not x and y and not z) or (not w and x and not y and not z) or (x and y and z) or (not x and not y and z);
    E <= (not w and x and not y) or (not w and z) or (not x and not y and z);
    F <= (w and x and not y and z) or (not w and not x and y) or (not w and not x and z) or (not w and y and z);
    G <= (w and x and not y and not z) or (not w and x and y and z) or (not w and not x and not y);

    DP <= '1'; -- Turn off the Decimal Point

end Behavioral;

