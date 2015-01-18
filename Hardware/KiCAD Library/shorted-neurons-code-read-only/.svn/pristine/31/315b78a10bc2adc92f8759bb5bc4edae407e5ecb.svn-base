#include <ProfileTimer.h>

void setup ()
{
  Serial.begin (115200);
}  // end setup

 
void loop ()
{
  delay (500);
  
  ProfileTimer t ("analog read");
  analogRead (A1);

  {
    ProfileTimer t1 ("multiple reads");
    for (int i = A0; i <= A5; i++)
      analogRead (i);
  }  // end timed bit of code

}  // end loop


