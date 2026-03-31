## Languages Performance Test

Simple test  for languages performance.

Test data : Weather station from [1brc](https://github.com/gunnarmorling/1brc)

Note that all code logic is a bit difference than 1brc challenges. 

The logic is simple, it loop through 4 millions records to listed out only min and max city and it temperature.

## Purpose 
To test out how fast one cpu can be and how much memory use for each language.

Hence, it is not using
 - mmap
 - multithread
 - goroutine

## Goals
  - Maximun code readablility
  - Maximum CPU usage
  - Minimun memory usage

## Setup

Make sure you had install all the languages SDK as below:

 - Asm - NASM version 2.15.05
 - C - Ubuntu clang version 14.0.0-1ubuntu1.1
 - Go - 1.26.0
 - Java - GraalVM CE 25.0.2+10.1 ( using `ubuntu snap` )
 - Python - 3
 - Rust - 1.94.0 
 - Zig - 0.15.2
   

First, make the 4 million records file ( out.csv ) with Java.

Assume you already install Graalvm using ubuntu snap, open console:
```sh
cd java
graalvm-jdk.javac CopyTask.java && graalvm-jdk.java CopyTask
```

You should see
`rows count = 4469300`

To run for particular language :
```
cd <language_folder>
<Run the command which comment at top of the source file>
```

