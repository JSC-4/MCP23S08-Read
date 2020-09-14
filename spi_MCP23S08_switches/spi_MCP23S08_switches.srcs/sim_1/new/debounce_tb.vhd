-- This testbench tests the debouncing of a switch.
-- The o_db_level is for state change transitions and
-- the o_db_tick is for 0-to-1 transitions.
--
-- FPGA: Nexys-4 DDR
-- Author: Jerome Samuels-Clarke
-- Website: www.jscblog.com

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debounce_tb is
end debounce_tb;

architecture sim of debounce_tb is
    signal c_CLOCKPERIOD : time := 10 ns;

	signal r_clk        : std_logic := '0';
    signal r_reset      : std_logic;
    signal r_sw         : std_logic;
    signal r_db_level	: std_logic;
    signal r_db_tick 	: std_logic;

begin

	debounce_inst: entity work.debounce(exp_fsmd_arch)
    	port map (
            i_clk		=> r_clk,	
            i_reset		=> r_reset, 
            i_sw        => r_sw,
            o_db_level  => r_db_level,
            o_db_tick 	=> r_db_tick);           

    clk_gen : r_clk <= not r_clk after c_CLOCKPERIOD / 2;  	

    process
    begin
        r_sw <= '0';
        r_reset <= '1';
        wait for 100 ns;
        r_reset <= '0';
        wait for 100 ns;
        r_sw <= '1';
        wait for 100 ns;
        r_sw <= '0';
        
        wait for 100 ns;
        
       report "simulation complete" severity failure;
       
    end process;
end sim;
