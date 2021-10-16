---
title: Rotor Blade Tracking System Integration
date: 2021-10-16
collection: resume
resume_tag: rmci
i_order: 30
---

- Developed and integrated shared libraries in C for communication and control of
  third-party tracker system

  - Libraries utilized two communications channels over `RS-485` and `RS-232` for
    configuration transmission and data retrieval
  - Protocols included `ASCII` and non-`ASCII` binary packets with checksums and
    `ASCII` hex representations
  - Configuration parameters were retrieved from SQLite Database and `ASCII`
    configuration file
  - Developed and integrated libraries for tokenizing and parsing `ASCII` file
    contents with comments

- Integrated tracker communications, acquisition, and processing libraries with
  framework for collecting RTB data

  - Developed lightweight logging library using variadic functions for creating
    and writing to log files, as well as writing messages to `stdout` for real-time
    feedback during developmental testing of framework libraries
  - Assisted with aircraft installation and testing on the airframes `OH-58C` and
    `OH-6A` of the entire embedded system in aspects of vibration data collections and
    rotor track height data collections
