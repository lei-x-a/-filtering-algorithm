# -filtering-algorithm
The on-board ADC is used to collect the signal and output the binary sequence in serial. After the serial to parallel code function, the binary data is input to the filter module in parallel. The low-pass FIR filtering algorithm is used to process the binary data. Finally, the processed binary data is output to analog through digital to analog conversion to generate waveform