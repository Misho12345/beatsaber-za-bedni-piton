# SDF Experiment

An experimental SDF ray marching project made in Python. It renders a 3D shader scene with terrain, Among Us-style characters, and a controllable sword.

![Project screenshot](ss.png)

## Tech

- Python
- ModernGL / ModernGL Window
- GLSL
- Arduino input support

## Setup

Install the Python dependencies:

```bash
pip install moderngl-window pyserial pywin32 screeninfo numpy pynput
```

Run the project:

```bash
python main.py
```

## Controls

- WASD: move
- Mouse: look around
- Space: jump
- Click: hide cursor for screenshots

Arduino sword input is disabled by default in `main.py`. Set `ARDUINO_ENABLED = True` if you want to use the hardware input.
