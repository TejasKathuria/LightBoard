<img width="512" height="512" alt="512_lightboard" src="https://github.com/user-attachments/assets/47403131-b3d3-499c-96f4-c90655c9ee57" />

# LightBoard
### Add fantastic lighting effects to your MacBook's Backlit Keyboard

LightBoard is a lightweight macOS utility that emulates keyboard-backlight effects on Macs that do not provide native software control.
The app uses a virtual HID device to simulate brightness-control key presses, creating smooth lighting effects while keeping everything system-safe.
### [Have a look at it!](https://youtu.be/7tMr4-BPVOU)

## Features
**1. Key-Press Illuminating Effect**

Simulates rapid virtual key presses to mimic an illumination glow. This generates a brief brightness pulse whenever the effect runs.

**2. Breathing Effect**

Smoothly cycles the keyboard illumination by gradually increasing and decreasing brightness through controlled HID key events.

**3. Intensity Adjustment**

Allows users to set a maximum brightness level for all effects.
The utility repeatedly emits brightness-up or brightness-down inputs until the configured intensity is reached.

**4. Speed Adjustment**

Controls the animation speed of all lighting effects, including breathing cycle duration and pulse frequency.

## How it works?
Because macOS offers no public API for third-party keyboard-backlight control, the app uses a virtual HID keyboard device to simulate the brightness function keys.

However, this app internally:
	1.	Creates a virtual HID keyboard via IOHID APIs
	2.	Sends brightness-up and brightness-down key codes at controlled intervals
	3.	Loops these HID events to generate lighting animations
	4.	Allows user customization for speed and intensity

**NOTE:** The utility does not modify system files.

## LIMITATIONS
- The App cannot directly modify hardware brightness, it relies on simulated key presses due to which every time the illumination occurs you'd get a pop-up on your screen
