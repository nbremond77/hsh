boolean is_safe(void);
boolean check_fire(void);
byte read_rack_switch(void);
void read_select_sws(byte *state);
void set_select_leds(byte *state);
boolean arm(void);
boolean disarm(void);
void launch(byte rack, byte *state);
