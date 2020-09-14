-- This is a basic testbench to test the clock
-- divider output frequency. The input clock is set
-- to 100Mhz (10 ns).
--
-- FPGA: Nexys-4 DDR
-- Author: Jerome Samuels-Clarke
-- Website: www.jscblog.com

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_div_tb is
end clk_div_tb;

architecture sim of clk_div_tb is

    signal c_CLOCKPERIOD : time := 10 ns;
    
	signal r_clk        : std_logic := '0';
    signal r_reset      : std_logic;
    signal r_o_clk      : std_logic := '0';

begin

	clock_div_inst: entity work.clk_div(rtl)
        generic map (
            g_fin  => 100e6,
            g_fout => 10e6)
    	port map (
            i_clk		=> r_clk,	
            i_reset		=> r_reset, 
            o_clk 		=> r_o_clk);
            

    clk_gen : r_clk <= not r_clk after c_CLOCKPERIOD / 2;  
    
    process
    begin
    
        r_reset <= '1';
        wait for 100 ns;
        r_reset <= '0';
        wait for 100 ms;
        
        report "simulation complete" severity failure;
        
    end process;
    
    
end sim;
