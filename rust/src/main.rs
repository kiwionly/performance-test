
// RUSTFLAGS="-C target-cpu=native" && cargo build --release && /usr/bin/time -v ./target/release/rust_read

use memchr::memchr;
use std::fs::File;
use std::io::{self, Read};

const BUF_SIZE: usize = 65536; // 64KB

#[inline(always)]
fn fast_parse_int(b: &[u8]) -> i32 {
    let mut sign = 1;
    let mut i = 0;

    if b[0] == b'-' {
        sign = -1;
        i = 1;
    }

    let mut dot_pos = 0usize;
    let mut val = 0i32;

    while i < b.len() {
        let c = b[i];

        if c >= b'0' && c <= b'9' {
            val = val * 10 + (c - b'0') as i32;
        } else {
            dot_pos = i;
        }

        i += 1;
    }

    if (sign == 1 && dot_pos == 2) || (sign == -1 && dot_pos == 3) {
        val *= 10;
    }

    sign * val
}

fn main() -> io::Result<()> {
    let mut file = File::open("../out.csv")?;
    let mut buf = vec![0u8; BUF_SIZE];
    let mut leftover: usize = 0;

    let mut min_val = i32::MAX;
    let mut max_val = i32::MIN;
    let mut min_city = String::new();
    let mut max_city = String::new();
    let mut count = 0;

    loop {
        // Read into the buffer, starting after the leftover data
        let bytes_read = file.read(&mut buf[leftover..])?;
        if bytes_read == 0 && leftover == 0 { break; }
        
        let total_available = leftover + bytes_read;
        let mut pos = 0;

        while pos < total_available {
            let scan_area = &buf[pos..total_available];
            
            // AVX2 optimized search for newline
            if let Some(nl_idx) = memchr(b'\n', scan_area) {
                let line = &scan_area[..nl_idx];
                
                // AVX2 optimized search for semicolon
                if let Some(semi_idx) = memchr(b';', line) {
                    let city = &line[..semi_idx];
                    let temp = &line[semi_idx + 1..];
                    let val = fast_parse_int(temp);

                    if val < min_val {
                        min_val = val;
                        min_city = String::from_utf8_lossy(city).into_owned();
                    }
                    if val > max_val {
                        max_val = val;
                        max_city = String::from_utf8_lossy(city).into_owned();
                    }
                    count += 1;
                }
                pos += nl_idx + 1;
            } else {
                // No newline found in the rest of the buffer
                break;
            }
        }

        // Move leftover data to the front of the buffer
        leftover = total_available - pos;
        if leftover > 0 {
            // This is essentially a vectorized memmove
            buf.copy_within(pos..total_available, 0);
        }
        
        if bytes_read == 0 { break; }
    }

    if count > 0 {
        println!("Min: {:.1} ({})", min_val as f64 / 100.0, min_city);
        println!("Max: {:.1} ({})", max_val as f64 / 100.0, max_city);
        println!("Rows: {}", count);
    }

    Ok(())
}