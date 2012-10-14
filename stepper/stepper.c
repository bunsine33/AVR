/*
 * Stepper motor driver test 
 *
 * Author:   Aaron Reid
 * Created:  11/25/2009
 *
 * History
 *
 *  11-25-09   -Creation
 */

#define F_CPU 14745600

#include <avr/pgmspace.h>

#include "../libnerdkits/lcd.h"
#include "../libnerdkits/delay.h"

#include "motor.h"
#include "bus.h"

int main()
{
    // fire up the LCD
    lcd_init();
    lcd_home();
  
    // init motor
    MotorContext tMotorContextA;
    motor_start(&tMotorContextA, MOTOR_HALFSTEP);

    // debug message
    lcd_line_one();
    lcd_write_string(PSTR("DEV3"));
    lcd_line_two();
    lcd_write_string(PSTR("HALFSTEP"));
  
    int i;
 
    init_bus();
    select_bus(DEV3);
  
    while(1)
    {
          
       // drive DEV3
       for(i=0;i<500;i++)
       {
          motor_step(&tMotorContextA, MOTOR_CW, 1);
       }
    
       delay_ms(500);
    }
 
    //motor_stop(&tMotorContextA);
     
    return 0;
}

