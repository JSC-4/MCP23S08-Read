-- This debounce code uses a 40 ms state check,
-- based on the 100mhz clock. Taken from FPGA
-- Prototyping By VHDL Examples book, written by
-- Pong P. Chu
--
-- o_db_tick is the 0-to-1 transition and o_db_level
-- is the change in states. Either can be used or left
-- open.
-- 
-- FPGA: Nexys-4 DDR
-- Author: Jerome Samuels-Clarke
-- Website: www.jscblog.com

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce is
    Port ( i_clk : in STD_LOGIC;
           i_reset : in STD_LOGIC;
           i_sw : in STD_LOGIC;
           o_db_level : out STD_LOGIC;
           o_db_tick : out STD_LOGIC);
end debounce;

architecture exp_fsmd_arch of debounce is
    constant N: integer := 22; --fliter of 2^N * 10ns = 40 ms
    type t_state_type is (s_zero, s_wait1, s_one, s_wait0);
    signal r_state_reg, r_state_next : t_state_type;
    signal r_q_reg, r_q_next : unsigned(N - 1 downto 0);
    signal r_q_load, r_q_dec, r_q_zero : std_logic;
begin

    --FSMD state and data register
    process(i_clk, i_reset)
    begin
        if (i_reset = '1') then
            r_state_reg <= s_zero;
            r_q_reg <= (others => '0');
            r_q_next <= (others => '0');
        elsif (rising_edge(i_clk)) then
            r_state_reg <= r_state_next;
            r_q_reg <= r_q_next;
        end if;
    end process;
    
    --FSMD data path (counter) next-state logic
    r_q_next <= (others => '1') when (r_q_load = '1') else
                (r_q_reg - 1) when (r_q_dec = '1') else
                r_q_reg;
                
    r_q_zero <= '1' when r_q_next = 0;
    
    --FSMD control path next-state logic
    process(r_state_reg, i_sw, r_q_zero)
    begin
        r_state_next <= r_state_reg;
        r_q_dec <= '0';
        r_q_load <= '0';
        o_db_tick <= '0';
        case (r_state_reg) is
            when s_zero =>
                o_db_level <= '0';
                if (i_sw = '1') then
                    r_q_load <= '1';
                    r_state_next <= s_wait1;
                end if;
                
            when s_wait1 =>
                o_db_level <= '0';
                if (i_sw = '1') then
                    r_q_dec <= '1';
                    if (r_q_zero = '1') then
                        o_db_tick <= '1';
                        r_state_next <= s_one;
                    end if;        
                else
                    r_state_next <= s_zero;
                end if;
                
            when s_one =>
                o_db_level <= '1';
                if (i_sw = '0') then
                    r_q_load <= '1';
                    r_state_next <= s_wait0;
                end if;
                
            when s_wait0 =>
                o_db_level <= '1';
                if (i_sw = '0') then
                    r_q_dec <= '1';
                    if (r_q_zero = '1') then
                        r_state_next <= s_zero;
                    end if;
                else
                    r_state_next <= s_one;
                end if;
        end case;
    end process;

end exp_fsmd_arch;