-- This is a testbench for the MCP23S08 spi (switches).
-- The sample signal pulses high, which starts the spi_tx_proc
-- (mosi) process statement. Once the mosi has finished the miso line
-- reads the r_miso_reg.
--
-- FPGA: Nexys-4 DDR
-- Author: Jerome Samuels-Clarke
-- Website: www.jscblog.com

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spi_MCP23S08_switches_tb is
end spi_MCP23S08_switches_tb;

architecture sim of spi_MCP23S08_switches_tb is
    signal c_CLOCKPERIOD : time := 10 ns;
    
	signal r_clk        : std_logic := '0';
    signal r_reset      : std_logic;
        
    -- mosi signals
    signal r_tx_pulse	: std_logic;

    -- miso signals
    signal r_leds      :  std_logic_vector(7 downto 0);
    signal r_op_val    :  std_logic;


    -- spi interface
    signal r_spi_miso	: std_logic;
    signal r_spi_clk	: std_logic;
    signal r_spi_mosi 	: std_logic;
    signal w_cs         : std_logic;
    
    signal r_mosi_reg   : std_logic_vector(15 downto 0) := (others => '0'); -- hold sent data    
    signal r_miso_reg   : std_logic_vector(7 downto 0) := X"12"; -- receive data    
    signal r_tx_cmd     : std_logic := '0';

begin

	spi_MCP23S08_switches_inst: entity work.spi_MCP23S08_switches(rtl)
    	port map (
            i_clk		=> r_clk,	
            i_reset		=> r_reset,
            i_tx_pulse	=> r_tx_pulse,
            o_leds	    => r_leds,
            o_op_val	=> r_op_val,
            i_spi_miso	=> r_spi_miso,
            o_spi_clk	=> r_spi_clk,
            o_spi_mosi 	=> r_spi_mosi,
            o_cs 		=> w_cs);

    clk_gen : r_clk <= not r_clk after c_CLOCKPERIOD / 2;  	

    spi_tx_proc : process
    begin
        r_tx_cmd <= '0';
        wait until w_cs = '0';
        for i in 0 to 15 loop
            wait until rising_edge(r_spi_clk);
            r_mosi_reg(i) <= r_spi_mosi;
        end loop;
        r_tx_cmd <= '1';
        wait;
    end process;
    
    spi_process: process
    begin
        r_spi_miso <= '0';
        r_tx_pulse <= '0';
        r_reset <= '1';
        wait for 100  us;
        r_reset <= '0';
        wait for 100 us;
        r_tx_pulse <= '1';
        wait until rising_edge(r_clk);
        r_tx_pulse <= '0';
        wait until r_tx_cmd = '1';
       
        for i in 7 downto 0 loop
            wait until falling_edge(r_spi_clk);
            r_spi_miso <= r_miso_reg(i);
        end loop;
        
        wait for 1 us;
        
        report "simulation complete" severity failure;
    end process;

end sim;
