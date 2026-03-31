# performance-check

Simple test  for languages performance.

All code written in difference languages is not exactly like 1brc challenge, 
but it only loop throught out 4 millions records to sort out min and max city and it temperatures. 

The purpose is to test out how fast one cpu and how much memory usage for each languages on same scenario.

Hence, it is not using
 - mmap
 - multithread
 - goroutine

 The goals is emphasize on :
  - Maximun code readablility
  - Maximum CPU usage
  - Minumun memory usage

Make sure you had install all the languages SDK as below:

Asm - NASM version 2.15.05
C - Ubuntu clang version 14.0.0-1ubuntu1.1
Go - 1.26.0
Java - GraalVM CE 25.0.2+10.1 ( using ubuntu snap )
Python - 3
Rust - 1.94.0 
Zig - 0.15.2

First, make the temparature file to 4 million records

Assume you already install Graalvm using ubuntu snap
```
cd java
graalvm-jdk.javac CopyTask.java && graalvm-jdk.java CopyTask
```

You should see
```
rows count = 4469300
```

For the command to run that particular language
```
cd <language_folder>
<Run the command which comment at top of the source file>
```

Weather station sample from [1brc](https://github.com/gunnarmorling/1brc)
