# Non-Invasive Hemoglobin & Vital Signs Detector Using FPGA

A hardware-accelerated, air-gapped biomedical monitoring system designed and synthesized on the **Sipeed Tang Nano 20K FPGA (Gowin GW2AR-LV18QN88PC7/I6)**. The system performs non-invasive optical photoplethysmography (PPG) acquisition, real-time digital filtering, biometric calculation for hemoglobin and vital estimation, and local OLED rendering entirely within synthesizable Verilog HDL logic.

---

## Key Features

* **Zero-Cloud Data Sovereignty:** 100% offline, air-gapped architecture eliminates external network vulnerabilities and guarantees complete biometric data privacy.
* **Hardware I2C Sensor Acquisition:** Dedicated synthesizable finite state machine (FSM) acting as an I2C master to directly configure and stream multi-wavelength optical data from the **MAX30102** sensor.
* **On-Chip Digital Signal Conditioning:** Hardware-implemented moving-average filter to attenuate high-frequency noise and baseline wandering from raw optical waveforms in real time.
* **Hardware Biometric Pipeline:** Silicon-level calculation module extracting peak characteristics, optical attenuation ratios, and vital parameters without an operating system or software runtime overhead.
* **Local Telemetry Engine:** Custom hardware graphics/text controller interfacing an **SSD1306 OLED** over I2C to render diagnostic parameters on an untethered platform.

---

## System Architecture

```text
[ MAX30102 Sensor ]
        |
        v  (Raw Optical Data via I2C)
[ i2c_master_max30102.v ]
        |
        v  (Unfiltered Waveform)
[ moving_average_filter.v ]
        |
        v  (Conditioned PPG Stream)
[ biometric_calculator.v ]
        |
        +-----------------------------------+
        |                                   |
        v                                   v
[ ssd1306_oled.v ]                  [ top.v (Status & Routing) ]
        |                                   |
        v                                   v
[ 128x64 OLED Display ]             [ Onboard Status Pin Indicators ]
├── moving_average_filter.gprj       # Gowin EDA Project Configuration
├── impl/                            # Synthesis, Place & Route outputs and bitstream (.fs)
└── src/
    ├── top.v                        # Top-level integration & clock/pin routing
    ├── i2c_master_max30102.v        # Synthesizable I2C master interface for MAX30102
    ├── moving_average_filter.v      # Hardware moving-average DSP filter
    ├── biometric_calculator.v       # Parameter extraction & hemoglobin calculation logic
    ├── ssd1306_oled.v               # Hardware OLED controller & font renderer
    └── pinss.cst                    # Physical pin constraints for Tang Nano 20K
+------------------------------------+---------------------------------------------------------------+
| Component                          | Role / Interface                                              |
+------------------------------------+---------------------------------------------------------------+
| Gowin GW2AR-18 (Tang Nano 20K)     | Central FPGA processing logic and hardware state machines     |
| MAX30102 Sensor                    | High-sensitivity optical biometric acquisition via I2C        |
| SSD1306 Display                    | 128x64 Monochrome OLED screen via I2C                         |
| Gowin EDA                          | Toolchain for synthesis, placement, routing, and bitstream    |
+------------------------------------+---------------------------------------------------------------+
1. Launch Gowin FPGA Designer (V1.9.12 or compatible).
2. Click File > Open Project and select moving_average_filter.gprj.
3. Verify target device configuration matches GW2AR-LV18QN88PC7/I6.
4. In the Process pane, double-click Synthesize to compile the Verilog source modules.
5. Run Place & Route with pin mappings assigned in src/pinss.cst.
6. Open Programmer, connect your Tang Nano 20K over USB, and program the generated .fs bitstream.
'''
