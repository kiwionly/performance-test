package main

import (
	"encoding/binary"
	"fmt"
	"testing"
)

func BenchmarkParsewithSWAR(b *testing.B) {

	buf := make([]byte, 8)

	// Copy your temperature string into it
	tempStr := "-12.3"
	copy(buf, tempStr)

	println(parseWithSWAR(buf, 3))
	b.ResetTimer()

	for b.Loop() {
		parseWithSWAR(buf, 3)
	}
}

func BenchmarkParseIntLoopUnrolling(b *testing.B) {

	buf := make([]byte, 5)

	// Copy your temperature string into it
	tempStr := "-12.3"
	copy(buf, tempStr)

	b.ResetTimer()

	for b.Loop() {
		fastParseIntLoopUnrolling(buf)
	}
}

func BenchmarkParseInt(b *testing.B) {

	buf := make([]byte, 5)

	// Copy your temperature string into it
	tempStr := "-12.3"
	copy(buf, tempStr)

	b.ResetTimer()

	for b.Loop() {
		fastParseInt(buf)
	}
}

func TestBitWise(t *testing.T) {

	buf := make([]byte, 8)

	// Copy your temperature string into it
	tempStr := "-12.3456"
	copy(buf, tempStr)

	word := binary.LittleEndian.Uint64(buf)

	fmt.Printf("Word: %064b\n", (^word << 59))
	fmt.Printf("Word: %064b\n", uint(int64(^word<<59)>>63))
	fmt.Printf("Word: %d\n", int64(^word<<59)>>63)

	// 1. Handle Sign
	signed := int64((^word << 59)) >> 63

	println(signed)
	// mask := ^(uint64(signed) & 0xFF)
}
