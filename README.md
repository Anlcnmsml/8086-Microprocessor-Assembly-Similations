8086 Microprocessor Architecture & Hardware Interfacing Labs
This repository contains a collection of low-level programming and hardware interfacing projects developed using 8086 Assembly Language and Proteus ISIS simulations. These projects demonstrate my ability to work with microprocessor architecture, memory mapping, and peripheral device communication.
🛠 Technologies & Components
•	Processor: Intel 8086.
•	Peripherals: 8255 PPI, 8251 USART, 8259 PIC, ADC0804, DAC0830.
•	Simulation: Proteus Design Suite.
•	Language: 8086 Assembly.
________________________________________
📂 Project Details
1. GPIO & Peripheral Control (8255 PPI)
•	Objective: Interfacing an 8-button input unit with a Common Anode 7-Segment display.
•	Technical Details:
o	Configured Port A as Output (for 7-segment) and Port B as Input (for switches) via the 8255 Control Word.
o	Implemented a Lookup Table strategy in Assembly to map binary inputs to specific 7-segment codes.
o	Managed real-time display updates where pressing a button displays a corresponding digit (0-7).

2. Serial Communication & Data Filtering (8251 USART)
•	Objective: Establishing a transmitter-receiver link with data filtering and encryption features.
•	Technical Details:
o	Memory Mapping: Designed an isolated I/O addressing circuit for the 8251 USART starting at address 0158H.
o	Data Filtering: Implemented logic to accept only uppercase (A-Z) characters while ignoring lowercase and symbols.
o	Encryption: Developed a basic Caesar cipher by increasing ASCII values by 3 before transmission (e.g., 'A' -> 'D').
o	Baud Rate: Configured the system for 9600 Hz communication using RxC and TxC clock signals.

3. Autonomous Control System (ADC0804 & DAC0830)
•	Objective: Designing a light-sensitive robot motor control system.
•	Technical Details:
o	Analog-to-Digital: Read light intensity data from an LDR sensor via ADC0804 mapped to address 400H.
o	Digital-to-Analog: Controlled DC motors via DAC0830 at address 200H.
o	Status Monitoring: Monitored the \INTR pin status through a Tri-state buffer at address 800H (D7 bit) to detect conversion completion instead of using delays.
o	Control Logic: Mapped ADC input ranges to DAC output levels to adjust motor speed proportionally to light intensity.

4. Advanced Interrupt Handling (8259 PIC)
•	Objective: Developing an interrupt-driven data logging system using the 8259 Programmable Interrupt Controller.
•	Technical Details:
o	Interrupt Vector Table (IVT): Mapped the Serial Transmission ISR to INT 51H (0x144) and the ADC Read ISR to INT 52H (0x148).
o	Edge-Triggered Logic: Configured the 8259 to handle interrupts from IR1 (Transmitter) and IR2 (ADC) using edge-triggering.
o	Data Logging: Programmed the system to store 5 consecutive 8-bit sensor readings and transmit them as a batch to a Virtual Terminal in Hex Display Mode.
________________________________________
Developed by Anılcan Muşmul - Computer Engineering Student

