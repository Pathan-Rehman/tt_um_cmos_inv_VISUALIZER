## How it works

The Reactive Plasma CMOS Inverter is an educational hardware visualizer that generates a 640x480 @ 60Hz VGA signal entirely in logic gates. It visually illustrates the fundamental physical operation of a classic CMOS NOT gate. 

At its core, the logic is driven by an internal frame counter that continuously toggles an "input" signal at varying speeds. The screen displays three main educational components:
1. **Transistor-Level Circuit:** A schematic representation of a CMOS inverter (a PMOS transistor connected to VDD, and an NMOS transistor connected to GND). When the input changes, an animated, dashed line illustrates the flow of electricity. If the input is Low (0), the PMOS turns on, and current flows from VDD to the output node. If the input is High (1), the NMOS turns on, and the output node drains into GND.
2. **Live Oscilloscope:** A continuously scrolling waveform graph tracks the history of the input signal and the inverted output signal in real-time.
3. **Active Truth Table:** A truth table clearly maps the Input (A) to the Output (Y), highlighting the current active row based on the live simulation state.

Additionally, the chip generates a simple PWM audio tone that dynamically changes pitch based on the high/low state of the input signal.

## How to test

The demonstration is completely self-driven, meaning you do not need to manually flip switches to see the circuit animate. 

1. Provide a **25.175 MHz** clock to the `clk` input (the standard frequency required for 640x480 VGA timing).
2. Pulse the reset pin (`rst_n`) low, then high, to initialize the internal coordinate and frame counters.
3. Ensure the design is enabled (`ena` = 1).
4. Connect a VGA monitor to the output pins. The animation will immediately begin playing, cycling through different scrolling speeds.
5. *(Optional)* Connect an audio output device to listen to the state changes.

## External hardware

To fully experience the demo, the following external hardware is recommended:

* **Tiny VGA PMOD:** Connect to the dedicated output pins (`uo[7:0]`) using the standard Tiny Tapeout VGA pin mapping.
* **Audio PMOD (or Piezo Buzzer):** Connect to the first bidirectional pin (`uio[0]`) to hear the dynamic PWM synthesizer.
