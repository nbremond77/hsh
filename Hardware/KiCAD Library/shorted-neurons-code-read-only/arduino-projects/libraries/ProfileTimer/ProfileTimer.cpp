/*
 ProfileTimer.cpp
 
 Written by Nick Gammon on 14 February 2011.
 Modified 11 May 2011 to use microseconds.
 Modified 12 May 2011 to rename class and some minor improvements.

 
 PERMISSION TO DISTRIBUTE
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
 and associated documentation files (the "Software"), to deal in the Software without restriction, 
 including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in 
 all copies or substantial portions of the Software.
 
 
 LIMITATION OF LIABILITY
 
 The software is provided "as is", without warranty of any kind, express or implied, 
 including but not limited to the warranties of merchantability, fitness for a particular 
 purpose and noninfringement. In no event shall the authors or copyright holders be liable 
 for any claim, damages or other liability, whether in an action of contract, 
 tort or otherwise, arising from, out of or in connection with the software 
 or the use or other dealings in the software. 
 
 */

#include "ProfileTimer.h"

 // constructor remembers time it was constructed
  ProfileTimer::ProfileTimer (const char * reason) : 
  sReason_ (reason)
  {
    Serial.print ("Start     : ");
    Serial.println (sReason_);
    start_ = micros ();
  }

 // destructor gets current time, displays difference
  ProfileTimer::~ProfileTimer ()
  {
    unsigned long interval = micros () - start_;
    Serial.print ("Time taken: ");
    Serial.print (sReason_);
    Serial.print (" = ");
    Serial.print (interval);
    Serial.println (" uS.");
  }
