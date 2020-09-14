-- This code interfaces with the MCP23S08 spi ic to read the gpio port.
-- The I/O direction register on reset is set as inputs, meaning it 
-- is already set. 
--
-- The i_tx_pulse is from a debounced input switch, o_spi_clk is 
-- set to 10Mhz, both from the top module.
--
-- FPGA: Nexys-4 DDR
-- Author: Jerome Samuels-Clarke
-- Website: www.jscblog.com

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_MCP23S08_switches is
	port (
    	i_clk		: in std_logic;
        i_reset 	: in std_logic;
        
        -- mosi signal 
        i_tx_pulse	: in std_logic;
        
        -- miso signals
        o_leds      : out std_logic_vector(7 downto 0);
        o_op_val    : out std_logic;
        
        -- spi interface
        i_spi_miso  : in std_logic;
        o_spi_clk	: out std_logic;
        o_spi_mosi 	: out std_logic;
        o_cs		: out std_logic);
end spi_MCP23S08_switches;

architecture rtl of spi_MCP23S08_switches is
    type t_ctrl_path is (s_idle, s_enable, s_xmit, s_capture);
    signal r_state : t_ctrl_path := s_idle;
    
--    constant c_MCP23S08_ADDR_W 	: std_logic_vector(7 downto 0) := X"40"; -- address of mcp23s08 for write command
--    constant c_MCP23S08_IODIR  	: std_logic_vector(7 downto 0) := X"00"; -- i/o direction register
--    constant c_MCP23S08_IODIR_W	: std_logic_vector(7 downto 0) := X"11"; -- set switches as output
    constant c_MCP23S08_ADDR_R 	: std_logic_vector(7 downto 0) := X"41"; -- address of mcp23s08 for read command
    constant c_MCP23S08_GPIO   	: std_logic_vector(7 downto 0) := X"09"; -- gpio register
    constant c_spi_read_length  : integer := 8;
    
    signal r_tx_reg 	: std_logic_vector(15 downto 0) := (others => '0'); -- transmit register for c_MCP23S08_ADDR_R & c_MCP23S08_GPIO
    signal r_rx_reg 	: std_logic_vector(7 downto 0) := (others => '0'); -- receive register for miso line
    signal r_tmr_reg	: std_logic_vector(23 downto 0) := (others => '0'); -- shift counter  for transmission
    signal r_load_tx	: std_logic := '0'; -- signal to load mosi data
	signal r_done_tick	: std_logic := '0'; -- set after transmission is complete
    
    signal r_cap_cnt	: integer range 0 to 7; -- counter for bits recieved 
begin

	fsm_proc : process (i_clk, i_reset)
	begin
        if (i_reset = '1') then
            o_cs <= '1';
        	r_load_tx <= '0';
        	o_leds <= (others => '0');
        	o_op_val <= '0';
        	r_cap_cnt <= 0;
        elsif (rising_edge(i_clk)) then
        	r_load_tx <= '0';
        	o_op_val <= '0';
        	case (r_state) is
            	when s_idle =>
                	o_cs <= '1';	-- active low
                	if (i_tx_pulse = '1') then
                    	r_state <= s_enable;
                        o_cs <= '0';
                    end if;
                    
                when s_enable =>
                	r_load_tx <= '1';
                    r_state <= s_xmit;
                    
                when s_xmit =>
                	if (r_done_tick = '1') then
                    	r_state <= s_capture;
                    	r_cap_cnt <= 0;
                    end if;            
                
                when s_capture =>
                    if (r_cap_cnt = c_spi_read_length-1) then
                        r_state <= s_idle;
                        o_op_val <= '1';
                        o_leds <= r_rx_reg;
                    else
                        r_cap_cnt <= r_cap_cnt + 1;
                    end if;
             end case;            
        end if;
    end process;
    
    spi_mosi : process (i_clk, i_reset)
    begin
    	if (i_reset = '1') then
        	r_tx_reg  	<= (others => '0');
            r_tmr_reg 	<= (others => '0');
        elsif (falling_edge(i_clk)) then
        	if (r_load_tx = '1') then
                r_tx_reg <= c_MCP23S08_ADDR_R & c_MCP23S08_GPIO;
                r_tmr_reg <= (others => '1'); -- start o_spi_clk
          	else
            	r_tx_reg <= r_tx_reg(r_tx_reg'high-1 downto r_tx_reg'low) & '0';
            	r_tmr_reg <= r_tmr_reg(r_tmr_reg'high-1 downto r_tmr_reg'low) & '0';
            end if;
        end if;
    end process;
    
    spi_miso : process (i_clk, i_reset)
    begin
        if (i_reset = '1') then
            r_rx_reg <= (others => '0');
        elsif (rising_edge(i_clk)) then
            r_rx_reg <= r_rx_reg(r_rx_reg'high-1 downto r_rx_reg'low) & i_spi_miso;
        end if;
    end process;
    
    r_done_tick <= '1' when r_tmr_reg(15 downto 0) = X"0000" else '0';
    o_spi_mosi <= r_tx_reg(r_tx_reg'high);
    o_spi_clk	<= i_clk when r_tmr_reg /= X"000000" else '0';

end rtl;
