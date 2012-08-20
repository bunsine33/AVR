/************************************************************************
 
  @Name: motor.h

  @Created: 12/01/2009

  @Author: Aaron Reid

  @Modifications: 

     12/01/09  -Created
 
************************************************************************/

#ifndef _motor_h_
#define _motor_h_

#define MOTOR_WAVE      0
#define MOTOR_FULLSTEP  1
#define MOTOR_HALFSTEP  2

#define MOTOR_CW    1
#define MOTOR_CCW  -1

typedef struct
{
	uint8_t  stepMode;
	int8_t   stepCount;

} MotorContext_t;

void vMOTOR_Start (MotorContext_t *tMotorContext, uint8_t mode);

void vMOTOR_Stop (MotorContext_t *tMotorContext);

void vMOTOR_Step (MotorContext_t *tMotorContext, uint8_t direction, uint16_t delay);

#endif
