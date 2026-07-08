
#  /usr/bin/time -v /usr/bin/python3 read.py

import time
import os

def fast_parse_int(s: str) -> int:
    signed = 1
    i = 0

    if s[0] == '-':
        signed = -1
        i = 1

    dot_pos = 0
    val = 0

    while i < len(s):
        c = s[i]

        if '0' <= c <= '9':
            val = val * 10 + (ord(c) - ord('0'))
        else:
            dot_pos = i

        i += 1

    if (signed == 1 and dot_pos == 2) or \
       (signed == -1 and dot_pos == 3):
        val *= 10

    return signed * val

def main():
    start_time = time.time()  # Seconds since epoch

    max_city = ""
    min_city = ""
    max_temp = 0
    min_temp = 0
    count = 0

    try:
        # 'with' handles closing the file automatically, like Java's try-with-resources
        with open("../out.csv", "r") as file:
            for line in file:
                line = line.strip()
                pos = line.find(";")

                if pos < 0:
                    continue

                temperature_str = line[pos + 1:]
                
                # In Python, you'd normally just use int(temperature_str)
                # but we'll use the custom function to match your Java code.
                temp = fast_parse_int(temperature_str)

                if temp > max_temp:
                    max_temp = temp
                    max_city = line
                if temp < min_temp:
                    min_temp = temp
                    min_city = line
                
                count += 1

    except FileNotFoundError:
        print("Error: out.csv not found.")
        return

    # Convert seconds to milliseconds to match Java's output
    elapsed_time = int((time.time() - start_time) * 1000)

    print(f"max = {max_city}")
    print(f"min = {min_city}")
    print(f"count = {count}")
    print(f"time user = {elapsed_time}")

if __name__ == "__main__":
    main()