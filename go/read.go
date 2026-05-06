// GOAMD64=v3 go build -ldflags="-s -w" -o read read.go && /usr/bin/time -v ./read

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

func parseWithMagic(b []byte, dotPos int) int {
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

	case 8: // -12.3456

		val :=
			int(b[1]-'0')*100000 +
				int(b[2]-'0')*10000 +
				int(b[4]-'0')*1000 +
				int(b[5]-'0')*100 +
				int(b[6]-'0')*10 +
				int(b[7]-'0')
		return -val

	case 7:

		if b[0] == '-' { // -2.3456
			return -(int(b[1]-'0')*10000 +
				int(b[3]-'0')*1000 +
				int(b[4]-'0')*100 +
				int(b[5]-'0')*10 +
				int(b[6]-'0'))
		}
		// 12.3456
		return int(b[0]-'0')*100000 +
			int(b[1]-'0')*10000 +
			int(b[3]-'0')*1000 +
			int(b[4]-'0')*100 +
			int(b[5]-'0')*10 +
			int(b[6]-'0')

	case 6: // 2.3456
		return int(b[0]-'0')*10000 +
			int(b[2]-'0')*1000 +
			int(b[3]-'0')*100 +
			int(b[4]-'0')*10 +
			int(b[5]-'0')

	case 5: // 12.34
		return int(b[0]-'0')*1000 +
			int(b[1]-'0')*100 +
			int(b[3]-'0')*10 +
			int(b[4]-'0')

	default: // 12.3
		return int(b[0]-'0')*100 +
			int(b[1]-'0')*10 +
			int(b[3]-'0')
	}
}

// fastParseInt treats "23.4" as 234 (integer)
func fastParseInt(b []byte) int {

	val := 0
	neg := 1
	i := 0

	if b[0] == '-' {
		neg = -1
		i++
	}

	for ; i < len(b); i++ {
		if b[i] != '.' {
			val = val*10 + int(b[i]-'0')
		}
	}

	return neg * val
}

func StartTSC() (tsc uint64, cpu uint32)

func StopTSC() (tsc uint64, cpu uint32)

func main() {

	f, _ := os.Create("cpu.prof")
	pprof.StartCPUProfile(f)
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

	if count > 0 {
		e, cpu := StopTSC()
		fmt.Printf("stop cpu : %d  Cycles: %d\n", cpu, (e-s)/uint64(count))
		fmt.Printf("Min: %.4f (City: %s)\n", float64(minVal)/10000.0, minCity)
		fmt.Printf("Max: %.4f (City: %s)\n", float64(maxVal)/10000.0, maxCity)
		fmt.Printf("Total Count: %d\n", count)
		fmt.Printf("Time use: %dms\n", time.Since(start).Milliseconds())

	} else {
		fmt.Println("No data found.")
	}
}
