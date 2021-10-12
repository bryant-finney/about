---
title: Embedded Systems Engineer
date: 2021-10-11
collection: resume
resume_tag: rmci
i_order: 30
---

- Developed and integrated shared libraries in C for communication and control of
  third-party tracker system

  - Libraries utilized two communications channels over `RS-485` and `RS-232` for
    configuration transmission and data retrieval
  - Protocols included ASCII and non-ASCII binary packets with checksums and
    ASCII hex representations
  - Configuration parameters were retrieved from SQLite Database and ASCII
    configuration file
  - Developed and integrated libraries for tokenizing and parsing ASCII file
    contents with comments

- Integrated tracker communications, acquisition, and processing libraries with
  framework for collecting RTB data

  - Developed lightweight logging library using variadic functions for creating
    and writing to log files, as well as writing messages to std-out for real-time
    feedback during developmental testing of framework libraries
  - Assisted with aircraft installation and testing on the airframes OH-58C and
    OH-6A of the entire embedded system in aspects of vibration data collections and
    rotor track height data collections

- Developed and tested vibration data analysis algorithms for condition-based
  maintenance from an embedded OS
  - Implemented the algorithms in C for utilization by an ARM cortex 335x series
    microcontroller. The focus of the algorithms was on time domain, frequency
    domain, and synchronous domain analyses
  - Developed a high-level framework in C incorporated with the Yocto project
    for handling onboard processing
    - Designed and integrated communication functions with an embedded SQLite
      database for retrieving algorithm parameters, as well as loading and storing
      both raw and processed data
    - Interfaced with low-level routines for collecting raw data and
      monitoring system state via a watchdog timer
    - Established communications protocol for system-wide integration in order
      to perform all onboard data acquisitions and processing upon triggers either
      by the user or by flight regime
  - Performed software verification testing by comparing results from the data
    analysis framework with a Python transliteration of the original MatLab scripts.
    The results were displayed and analyzed
- Designed and tested firmware for the PIC24F08KL301 MCU using MPLAB X, Eclipse,
  and PICKIT3

  - The microcontroller was used to emulate tachometer signals with two 8-bit
    timers and to translate between RS-485 and RS-232 message protocols for
    interfacing with a rotor blade tracking system
  - The two UART peripherals were utilized for the serial communications: one
    dedicated to RS-485 communication with the controlling OS, and the other was
    dedicated to RS-232 communication with the tracking system
  - Implemented a communications protocol for responding to various control
    bytes transmitted over RS-485
  - Developed a boot loader for executing firmware updates over serial traffic:
    created host side in Python using minimal packages for ease of deployment on the
    embedded Linux system, and tested the MCU side written in C
  - Phase 1 development was done on the SAMD21G18A MCU with Eclipse and the
    Arduino IDE for programming

- Led a multidisciplinary team to design a new product for tracking helicopter
  rotor blades

  - Performed individual research and bench-marking, theoretical modeling using
    linear algebra and geometry, and data visualization for demonstrating theoretical
    system performance characteristics. Provided the recommendation for the selected
    design and continued to lead the development of this design
  - Conducted electro-optical radiometric modeling of solid state sensors for
    blade detection
  - Completed optical design of system hardware using matrix ray tracing in
    MathCAD, Python, and Matlab
  - Developed opto-mechanical design of illuminator and sensor to
    minimize space requirements while considering reliability, affordability, and
    maintainability
  - Reviewed materials and manufacturing processes for component design and
    selection
    - Design criteria included the following: overall size, weight, and cost; IR
      safety compliance according to IEC 60825-1 and IEC 62471; insensitivity to
      environmental lighting conditions; environmental qualification according to
      DO-160 and MIL-STD-810; hardware reliability, aesthetic appeal, and convenience
      of operation to the end user
  - The system is currently entering the prototype stage and is estimated to cost less than
    existing systems while improving performance and reducing maintenance costs

- Performed all engineering analysis, design, and fabrication of a stand for testing
  developmental systems
  - The stand replicated a scaled rotor of approximately 8 ft. diameter, capable of
    rotational speed over 300 rpm
  - Used finite airfoil drag analysis to model the transient and steady-state speed based
    on input power. Total cost was under \$1000, and the test stand was used for rotor track
    and balance tests
