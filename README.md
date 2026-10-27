## Programming Languages Performance Test

Simple test for programming languages performance.

Test data : Weather station from [1brc](https://github.com/gunnarmorling/1brc)

Note that all code logic is a bit difference than 1brc challenges. 

The logic is simple, it loop through 4 millions records to listed out only min and max city and it temperature.

## Purpose 
  - Maximun code readablility
  - Maximum one CPU usage
  - Minimun memory usage
   
Hence features below is not using :
 - mmap
 - multithread
 - goroutine

## Test platform
 - Windows 11
 - 6.18.33.2-microsoft-standard-WSL2 Ubuntu 26.04.1 LTS

## Setup

Make sure you had install all the languages SDK as below:

 - Asm - NASM version 3.01
 - C - clang version 21.1.8
 - Go - 1.27.3
 - Java - GraalVM CE 25.4.4.1.1+1.1
 - Python - 3.14.4
 - Rust - 1.94.0 
 - Zig - 0.17.0

The following is required for Graalvm native image:
 - GCC - 15.2.0
 - cmake - 3.22.1
 - glibc 2.43.0
 - zlib 1:1.3

First, make the 4 million records file ( out.csv ) with Java.

Assume you already install Graalvm and setup properly, open console:
```sh
cd java
javac CopyTask.java && java CopyTask
```

You should see
`rows count = 4469100`

To run for particular language :
```
cd <language_folder
<Run the command which comment at top of the source file>
```

## Result 

The result for the test is show in this [chart](https://kiwionly.github.io/web/chart.html).

This [slide](https://docs.google.com/presentation/d/1FRcAfCYMBlSTSzyFYsSG0IE9IJdrKi6zAbTePRw1asI/edit?usp=sharing) provides a detailed breakdown of the work.


