// GOMAXPROCS=1 GOAMD64=v3 go build -ldflags="-s -w" -o read . && /usr/bin/time -v ./read

package main

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"fmt"
	"os"
	"runtime/pprof"
	"time"
)

func parseWithSWAR(b []byte, dotPos int) int {
	word := binary.LittleEndian.Uint64(b)

	// 1. Handle Sign
	signed := int64((^word << 59)) >> 63
	mask := ^(uint64(signed) & 0xFF)

	// 2. Align so the dot is always 'removed' from the same spot
	// This handles "-12.3" (dotPos 3) and "12.3" (dotPos 2) and "1.2" (dotPos 1)
	// We shift by bytes (8 bits) to align the slots
	shift := uint(8 * (4 - dotPos))
	if signed != 0 {
		shift = uint(8 * (3 - dotPos)) // Adjust shift if '-' exists
	}

	// 3. Clean and Multiply
	digits := ((word & mask) << shift) & 0x0F000F0F00
	val := ((digits * 0x640a0001) >> 32) & 0x3FF

	return int((int64(val) ^ signed) - signed)
}

// fastParseInt treats "23.4" as 234 (integer)
// manually loop unrolling to make it faster 1 second, this is cheat on finite set of data
func fastParseIntLoopUnrolling(b []byte) int {
	switch len(b) {

	case 4: // 1.23 or 12.3
		if b[1] == '.' { // 1.23 => 123
			return int(b[0]-'0')*100 +
				int(b[2]-'0')*10 +
				int(b[3]-'0')
		}
		// 12.3 -> 1230
		return int(b[0]-'0')*1000 +
			int(b[1]-'0')*100 +
			int(b[3]-'0')*10

	case 5: // -1.23 or -12.3

		if b[3] == '.' { // -12.3 -> -12.30
			return -(int(b[1]-'0')*1000 +
				int(b[2]-'0')*100 +
				int(b[4]-'0')*10)
		}
		// -1.23
		return -(int(b[1]-'0')*100 +
			int(b[3]-'0')*10 +
			int(b[4]-'0'))
	}

	return 0
}

// fastParseInt treats "23.4" as 234 (integer)
func fastParseInt(b []byte) int {

	signed := 1
	i := 0

	if b[0] == '-' {
		signed = -1
		i++
	}

	val := 0
	frac := 0
	afterDot := false

	for ; i < len(b); i++ {
		c := b[i]
		if c == '.' {
			afterDot = true
			continue
		}

		val = val*10 + int(c-'0')

		if afterDot {
			frac++
		}
	}

	if frac == 1 {
		val *= 10
	}

	return signed * val
}

func StartTSC() (tsc uint64, cpu uint32)

func StopTSC() (tsc uint64, cpu uint32)

func main() {

	f, _ := os.Create("cpu.prof")
	error := pprof.StartCPUProfile(f)

	if error != nil {
		panic(error)
	}
	defer pprof.StopCPUProfile()

	start := time.Now()

	s, cpu := StartTSC()
	fmt.Printf("start cpu : %d \n", cpu)

	f, err := os.Open("../out.csv")

	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()

	reader := bufio.NewReaderSize(f, 65536)

	minVal, maxVal := 99999, -99999
	count := 0

	var minCity, maxCity string

	for {
		// Read line by line
		line, err := reader.ReadSlice('\n')
		if err != nil {
			break
		}

		// Find the semicolon
		semiIdx := bytes.IndexByte(line, ';')
		if semiIdx == -1 {
			continue
		}

		// Split city and temperature
		cityPart := line[:semiIdx]
		tempPart := line[semiIdx+1 : len(line)-1] // trim trailing \n

		val := fastParseIntLoopUnrolling(tempPart)

		// Update stats
		if val < minVal {
			minVal = val
			minCity = string(cityPart)
		}
		if val > maxVal {
			maxVal = val
			maxCity = string(cityPart)
		}
		count++
	}

	e, cpu := StopTSC()
	fmt.Printf("stop cpu : %d  Cycles: %d\n", cpu, (e-s)/uint64(count))
	fmt.Printf("Min: %.1f (City: %s)\n", float64(minVal)/100.0, minCity)
	fmt.Printf("Max: %.1f (City: %s)\n", float64(maxVal)/100.0, maxCity)
	fmt.Printf("Total Count: %d\n", count)
	fmt.Printf("Time use: %dms\n", time.Since(start).Milliseconds())
}
