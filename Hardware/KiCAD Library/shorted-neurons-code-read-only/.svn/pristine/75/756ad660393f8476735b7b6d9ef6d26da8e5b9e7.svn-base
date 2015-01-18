boolean arm(void) {
  if (status == status_safe) {
    status = status_both_armed;
    digitalWrite(safety_coil, HIGH);
    return true;
  } else {
    return false;
  }
}

boolean disarm(void) {
  digitalWrite(safety_coil, LOW);
  if (!enter_orbit()) {
    //error!
  }
  status = status_safe;
  return true;
  //add logic for dealing with comms success/failure
}

boolean engage(byte select_coils, byte warp_coils) {
  byte coil_state = B00000000;
  if (warp_coils == select_coils) {
    if (status == status_both_armed) {
      status = status_firing;
      for (i = 0; i < sizeof(coil_select); i++) {
        //this is only possible because the numeric value of
        //pin #s 4-7 happen to match their place in the PORTD bitmap
        bitWrite(coil_state, coil_select[i], bitRead(warp_coils, i));
      }
      PORTD |= coil_state;
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}

boolean enter_orbit(void) {
  PORTD &= coil_portd_alloff;
  status = status_both_armed;
  return true;
  //add logic for dealing with comms success/failure
}
    
    
