---
title: XRDS™️ Software Development
date: 2021-10-11
collection: resume
resume_tag: rmci
i_order: 38
---

- Developed and tested vibration data analysis algorithms for condition-based
  maintenance from an embedded OS

  - Implemented the algorithms in C for utilization by an
    [`ARM cortex 335x series`](https://www.ti.com/lit/ds/symlink/am3359.pdf?ts=1634308387318&ref_url=https%253A%252F%252Fwww.google.com%252F)
    microcontroller. The focus of the algorithms was on time domain, frequency domain,
    and synchronous domain analyses
  - Developed a high-level framework in C incorporated with the
    [Yocto project](https://www.yoctoproject.org/) for handling onboard processing
    - Designed and integrated communication functions with an embedded
      [SQLite](https://www.sqlite.org/index.html) database for retrieving algorithm
      parameters, as well as loading and storing both raw and processed data
    - Interfaced with low-level routines for collecting raw data and
      monitoring system state via a watchdog timer
    - Established communications protocol for system-wide integration in order
      to perform all onboard data acquisitions and processing upon triggers either
      by the user or by flight regime
  - Performed software verification testing by comparing results from the data
    analysis framework with a Python transliteration of the original `MatLab` scripts.
    The results were displayed and analyzed

- Designed and tested firmware for the `PIC24F08KL301 MCU` using `MPLAB X`, Eclipse,
  and `PICKIT3`

  - The microcontroller was used to emulate tachometer signals with two 8-bit
    timers and to translate between `RS-485` and `RS-232` message protocols for
    interfacing with a rotor blade tracking system
  - The two `UART` peripherals were utilized for the serial communications: one
    dedicated to `RS-485` communication with the controlling OS, and the other was
    dedicated to `RS-232` communication with the tracking system
  - Implemented a communications protocol for responding to various control
    bytes transmitted over `RS-485`
  - Developed a boot loader for executing firmware updates over serial traffic:
    created host side in Python using minimal packages for ease of deployment on the
    embedded Linux system, and tested the MCU side written in C
  - Phase 1 development was done on the `SAMD21G18A MCU` with Eclipse and the
    Arduino IDE for programming


