/************************************************************************
 
  @Name: bus.h

  @Created: 12/01/2009

  @Author: Aaron Reid

  @Modifications: 

     12/01/09  -Created
     08/22/12  -Renamed methods
 
************************************************************************/

#define D1  1<<PB1
#define D2  1<<PB2

#define DEV1 1
#define DEV2 2
#define DEV3 3
#define DEV4 4

void init_bus();
void select_bus(uint8_t device);
