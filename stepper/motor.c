/************************************************************************
 
  @Name: motor.c

  @Description: Unipolar Stepper Motor Driver

                PF35T-48L4 Wire Diagram (.25amp, 20Ohm/phase)
                   A1 = Brown, A2 = Black, B1 = Orange, B2 = Yellow

                42BYGHM206-07E Wire Diagram (.9amp, 4.4Ohm/phase)
                   A1 = Black, A2 = Green, B1 = Red, B2 = Blue 

                LSG35012E98P Wire Diagram (.375amp, 32Ohm/phase)  
                   A1= White, A2 = Black, B1 = Blue, B2 = Red
                
                Excitation Patterns:

                Wave:      A2,
                           B1,
                           A1,
                           B2

                Full Step: A2/B1,
                           A1/B1,
                           A1/B2,
                           A2/B2

                Half Step: A2,
                           A2/B1,
                           B1,
                           A1/B1,
                           A1, A1/B2,
                           B2,
                           A2/B2

  @Created: 12/09/2009

  @Author: Aaron Reid

  @Modifications: 

     12/09/09  -Created
     09/22/10  -Added 42BYGHM206-07E Wire Diagram
 
************************************************************************/

#define F_CPU 14745600

#include <avr/io.h>
#include <inttypes.h>

#include "../libnerdkits/delay.h"

#include "motor.h"

void _MOTOR_Excite (uint8_t winding, uint16_t delay);
void _MOTOR_Excite_Pair (uint8_t windingA, uint8_t windingB, uint16_t delay);

// port settings

#define DDR   DDRC
#define PORT  PORTC

#define A1  1<<PC1
#define A2  1<<PC2
#define B1  1<<PC3
#define B2  1<<PC4

void vMOTOR_Start (MotorContext_t *tMotorContext, uint8_t mode)
{	
	DDR |= A1 | A2 | B1 | B2;
	
    // set output pins low
	PORT &= ~( A1 | A2 | B1 | B2 );

    tMotorContext->stepMode = mode;
    tMotorContext->stepCount = 0;
}

void vMOTOR_Stop (MotorContext_t *tMotorContext)
{
	// do nothing
}

void vMOTOR_Step (MotorContext_t *tMotorContext, uint8_t direction, uint16_t delay)
{
    tMotorContext->stepCount += direction;	

    if(  (tMotorContext->stepCount > 4 && tMotorContext->stepMode != MOTOR_HALFSTEP)
       ||(tMotorContext->stepCount > 8 && tMotorContext->stepMode == MOTOR_HALFSTEP)
      )
    {
        tMotorContext->stepCount = 1;
    }
    else if(  (tMotorContext->stepCount <= 0)
            &&(tMotorContext->stepMode != MOTOR_HALFSTEP)
           )
    {
        tMotorContext->stepCount = 4;
    }
    else if(tMotorContext->stepCount <= 0)
    {
        tMotorContext->stepCount = 8;
    } 

    switch(tMotorContext->stepMode)
    {
        case MOTOR_WAVE:
            switch(tMotorContext->stepCount)
            { 
	            case 1:
                    _MOTOR_Excite(A2, delay);
                    break;
                case 2:
                    _MOTOR_Excite(B1, delay);
                    break;
                case 3:               
                    _MOTOR_Excite(A1, delay);
	                break;
   		        case 4:			   
                    _MOTOR_Excite(B2, delay);
                    break;
                default:
	                break;
	        }
		    break;
		
        case MOTOR_FULLSTEP:
            switch(tMotorContext->stepCount)
            {
	            case 1:
                    _MOTOR_Excite_Pair(A2, B1, delay);
	                break;
                case 2:
                    _MOTOR_Excite_Pair(A1, B1, delay);
                    break;
                case 3:               
                    _MOTOR_Excite_Pair(A1, B2, delay);
			        break;
                case 4:			   
                    _MOTOR_Excite_Pair(A2, B2, delay);
                    break;
                default:
			        break;
	        }
            break;
   
        case MOTOR_HALFSTEP:
            switch(tMotorContext->stepCount)
            {
	            case 1:
                    _MOTOR_Excite(A2, delay);
		            break;
                case 2:
                   _MOTOR_Excite_Pair(A2, B1, delay);
                   break;
                case 3:               
                    _MOTOR_Excite(B1, delay);
	                break;
                case 4:			   
                    _MOTOR_Excite_Pair(A1, B1, delay);
                    break;
	            case 5:
                    _MOTOR_Excite(A1, delay);
                    break;
                case 6:
                    _MOTOR_Excite_Pair(A1, B2, delay);
                    break;
                case 7:               
                    _MOTOR_Excite(B2, delay);
			        break; 
			    case 8:			   
                    _MOTOR_Excite_Pair(A2, B2, delay);
                    break;
                default:
			        break;
	        }
		    break;

        default:
            // do nothing
            break;
    }
}

void _MOTOR_Excite (uint8_t winding, uint16_t delay)
{
    PORT |= winding;
    delay_ms(delay);
    PORT &= ~(winding);
}

void _MOTOR_Excite_Pair (uint8_t windingA, uint8_t windingB, uint16_t delay)
{
    PORT |= (windingA);
    PORT |= (windingB);
	
    delay_ms(delay);
	
    PORT &= ~(windingA);
    PORT &= ~(windingB);
}


