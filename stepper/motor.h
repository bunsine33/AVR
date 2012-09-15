/************************************************************************
 
  @Name: motor.h

  @Created: 12/01/2009

  @Author: Aaron Reid

  @Modifications: 

     12/01/09  -Created
     08/22/12  -Renamed methods
 
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

} MotorContext;

void motor_start (MotorContext *tMotorContext, uint8_t mode);

void motor_stop (MotorContext *tMotorContext);

void motor_step (MotorContext *tMotorContext, uint8_t direction, uint16_t delay);

#endif
