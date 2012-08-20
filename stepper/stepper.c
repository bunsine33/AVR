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
#include "motor.h"

int main()
{
    // fire up the LCD
    lcd_init();
    lcd_home();
  
    // init motor
    MotorContext_t tMotorContextA;
    vMOTOR_Start(&tMotorContextA, MOTOR_HALFSTEP);

    // debug message
    lcd_line_one();
    lcd_write_string(PSTR("MODE:"));
    lcd_line_two();
    lcd_write_string(PSTR("HALFSTEP"));
               
    // drive motor
    while(1)
    {
	    vMOTOR_Step(&tMotorContextA, MOTOR_CW, 75);
    }

    //vMOTOR_Stop(&tMotorContextA);
  
    return 0;
}
