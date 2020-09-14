-- This top file for the MCP23S08 spi ic (switches).
-- It links together the spi and clock divider modules.
-- The input switch is debounce and set as the pulse trigger
-- to send the commands to the ic.
--
-- FPGA: Nexys-4 DDR
-- Author: Jerome Samuels-Clarke
-- Website: www.jscblog.com

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spi_MCP23S08_switches_top is
    port(
    	i_clk		: in std_logic;
        i_reset 	: in std_logic;
        i_sw        : in std_logic;
        o_leds      : out std_logic_vector(7 downto 0);
        i_spi_miso  : in std_logic;
        o_spi_clk	: out std_logic;
        o_spi_mosi 	: out std_logic;
        o_cs		: out std_logic);
end spi_MCP23S08_switches_top;

architecture rtl of spi_MCP23S08_switches_top is
    signal r_clk_10Mhz : std_logic;
    signal r_db_level : std_logic;
begin

	spi_MCP23S08_switches_inst: entity work.spi_MCP23S08_switches(rtl)
    	port map (
            i_clk		=> r_clk_10Mhz,	
            i_reset		=> i_reset,
            i_tx_pulse	=> r_db_level,
            o_leds	    => o_leds,
            o_op_val	=> open,
            i_spi_miso	=> i_spi_miso,
            o_spi_clk	=> o_spi_clk,
            o_spi_mosi 	=> o_spi_mosi,
            o_cs 		=> o_cs);

	clock_div_10Mhz: entity work.clk_div(rtl)
        generic map (
            g_fin  => 100e6,
            g_fout => 10e6)
    	port map (
            i_clk		=> i_clk,	
            i_reset		=> i_reset, 
            o_clk 		=> r_clk_10Mhz);

	debounce: entity work.debounce(exp_fsmd_arch)
    	port map (
            i_clk		=> i_clk,	
            i_reset		=> i_reset, 
            i_sw        => i_sw,
            o_db_level  => r_db_level,
            o_db_tick 	=> open);           
end rtl;
