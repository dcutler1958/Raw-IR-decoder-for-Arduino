// Raw IR decoder sketch!
//
// This sketch/program uses an Arduno and a GP1UX311QS to decode IR received.
// This can be used to make a IR receiver (by looking for a particular code)
// or transmitter (by pulsing an IR LED at ~38KHz for the durations detected.
//
// Code is public domain, check out www.ladyada.net and adafruit.com for
// more tutorials!
//
// We need to use the 'raw' pin reading methods because timing is
// very important here and the digitalRead() procedure is too slow.
//
// Digital pin #4 is the same as Pin D4 see
// http://arduino.cc/en/Hacking/PinMapping168 for 'raw' pin mapping.

const int16_t IRpin = 4;

// Mask to access IR decoder input quickly.
const uint16_t IRpinmask = _BV(IRpin);

// Maximum number of transitions that can be recorded.  We will store
// up to 100 pulse pairs (this is a lot).  Even indexed elements record
// High to Low transition durations and odd elements record Low to High
// transition durations.
const int16_t MAX_TRANSITIONS = 200;
uint16_t transitions[MAX_TRANSITIONS];

// The maximum transition time we'll listen.  65 milliseconds is a long time.
const uint16_t MAX_DELAY = 65000;  // Milliseconds

// What our timing resolution should be, larger is better as it's
// more 'precise' but too large and you wont get accurate timing.
const uint16_t RESOLUTION = 20;  // Milliseconds

void setup(void) {
   Serial.begin(115200);
   Serial.println("Ready to decode IR!");
}

void loop(void) {
   uint16_t duration;
   int16_t idx = -1;

   for (;;) {
      duration = 0;

      // Wait for a transition from HIGH to LOW.
      while ((PIND & IRpinmask))  {  // Using "digitalRead(IRpin)" is too slow.
         // Pin is still HIGH, delay.
         delayMicroseconds(RESOLUTION);
         duration += RESOLUTION;
         if (duration < MAX_DELAY)
            continue;

         // Pulse is too long, we 'timed out'.  NOTHING was received or
         // the transmitted code is complete.  Print what we've captured
         // so far, and then reset.
         printtransitions(idx);
         return;
      }

      // We didn't time out, store the reading.
      idx += 1;
      transitions[idx] = duration;

      duration = 0;

     // Similar to above, except waiting for a transition HIGH.
     while (!(PIND & IRpinmask)) {
        // Pin is still LOW, delay.
        delayMicroseconds(RESOLUTION);
        duration += RESOLUTION;
        if (duration < MAX_DELAY)
           continue;

        printtransitions(idx);
        return;
     }

   // We read a high-low-high pulse successfully, continue!
   idx += 1;
   transitions[idx] = duration;
   }
}

void printtransitions(int16_t idx) {
   if (idx < 0)
      return;

   Serial.println("\nReceived:\n   H->L       L->H");

   for (uint8_t i = 0; i <= idx; i += 1) {
      uint32_t j = transitions[i];

      while ((j *= 10) < 100000)  // Columnize values nicely
         Serial.print(" ");

      Serial.print(transitions[i], DEC);

      // Newline after printing duration for L->H transition.
      Serial.print(i & 1 ? " usec\n" : " usec ");
   }
}
