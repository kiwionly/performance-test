
#  /usr/bin/time -v /usr/bin/python3 read.py

import time
import os

def fast_parse_int(s):
    """Manual implementation of Java's fastParseInt for logic parity."""
    res = 0
    pos = 0
    neg = False
    
    s = s.strip() # Remove any trailing whitespace/newlines
    if not s:
        return 0
        
    if s.startswith("-"):
        neg = True
        pos = 1
        
    for i in range(pos, len(s)):
        # ord() gets the ASCII value; equivalent to (s.charAt(i) - '0')
        res = res * 10 + (ord(s[i]) - ord('0'))
        
    return -res if neg else res

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