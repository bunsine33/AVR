/************************************************************************
 
  @Name: motor.h

  @Created: 12/01/2009

  @Author: Aaron Reid

  @Modifications: 

     12/01/09  -Created
     08/22/12  -Renamed methods
 
************************************************************************/

#include <inttypes.h>
#include <avr/io.h>

#include "bus.h"

void init_bus ()
{
	// set D1/D2 as output pins
    DDRB |= D1 | D2;
}

void select_bus (uint8_t device)
{
	switch(device)
	{
		case DEV1:
		   PORTB |= D1;
		   PORTB &= ~(D2);
		   break;
		case DEV2:
		   PORTB &= ~(D1);
		   PORTB |= D2;
		   break;
		case DEV3:
		   PORTB &= ~(D1 | D2);
		   break;
		case DEV4:
		   PORTB |= (D1 | D2);
		   break;						
		default: 
		   break;
	}
}
