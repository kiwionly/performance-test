
// javac Read.java && /usr/bin/time -v java Read

// native-image Read && /usr/bin/time -v ./read

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Arrays;

public class Read {

	private final static int SIZE = 65536;

	public static void main(String[] args) throws IOException {

		long start = System.currentTimeMillis();

		try (FileInputStream in = new FileInputStream("../out.csv")) {

			byte[] buffer = new byte[SIZE + 64];
			int offset = 0;
			int n;
		
			int max = 0;
			int min = 0;
			int count = 0;	
			byte[] maxCity = null;
			byte[] minCity = null;


			while ((n = in.read(buffer, offset, SIZE)) != -1) {

				int bufSize = n + offset;
				int currentPosition = 0;

				int semi = -1;

				for(int i = currentPosition; i < bufSize; i++) {

					byte val = buffer[i];

					if(val == ';') {
						semi = i;
					} 
					
					if(val == '\n') {

						int temp = loopUnrollingParseInt(buffer, semi + 1, i);

						count++;

						if (temp > max) {
							max = temp;
							maxCity = Arrays.copyOfRange(buffer, currentPosition, i);
						} else if (temp < min) {
							min = temp;
							minCity = Arrays.copyOfRange(buffer, currentPosition, i);
						}													
						
						currentPosition = i + 1; // next index after \n
						semi = -1;	 // reset semi
					}
				}

				offset = bufSize - currentPosition;
				
				if(offset > 0) {
					System.arraycopy(buffer, currentPosition, buffer, 0, offset);
				}
			}

			long end = System.currentTimeMillis() - start;

			System.out.println("max = " + new String(maxCity) + "\nmin = " + new String(minCity) + "\ncount = " + count + "\ntime use = " + end);
		}

	}

	public static int fastParseInt(byte[] b, int start, int end) {
				
		int signed = 1;
		int i = start;

		if (b[i] == '-') {
			signed = -1;
			i++;
		}
		
		int dotcurrentPosition = -1;

		int val = 0;
		for (; i < end; i++) {
			byte c = b[i];
			if (c >= '0' && c <= '9') {
				val = val * 10 + (c - '0');
			} else {
				dotcurrentPosition = i - start;
			}
		}

		if ((signed == 1 && dotcurrentPosition == 2) || (signed == -1 && dotcurrentPosition == 3)) {
			val *= 10;
		}
		
		return signed * val;
	}

	public static int loopUnrollingParseInt(byte[] b, int start, int end) {
		
		int size = end - start;
		
		int val = 0;		
		
		switch(size) {
				
			case 5 :  // -1.23 or -12.3 or 12.34 
				
				int d0 = b[start + 0];
				
				if(d0 == '-') {
					
					int d2 = b[start + 2];
					
					if(d2 == '.') {
						int d1 = b[start + 1];
						val = val + 100 * (d1 - '0');
						
						int d3 = b[start + 3];					
						val = val + 10 * (d3 - '0');
						
						int d4 = b[start + 4];
						val = val + 1 * (d4 - '0');
						
						return -val;
						
					} else {
						
						int d1 = b[start + 1];
						val = val + 1000 * (d1 - '0');					
								
						val = val + 100 * (d2 - '0');
												
						int d4 = b[start + 4];	
						val = val + 10 * (d4 - '0');
						
						return -val;						
					}				
					
				} 
				else {
					
					val = val + 1000 * (d0 - '0');
					
					int d1 = b[start + 1];
					val = val + 100 * (d1 - '0');
										
					int d3 = b[start + 3];
					val = val + 10 * (d3 - '0');
					
					int d4 = b[start + 4];	
					val = val + 1 * (d4 - '0');					
						
					return val;					
				}				
				
			case 4 : // 1.23 or 12.3
				
				int d1 = b[start + 1];
				
				if(d1 == '.') {
																	
					int d00 = b[start + 0];
					val = val + 100 * (d00 - '0');
										
					int d2 = b[start + 2];		
					val = val + 10 * (d2 - '0');
					
					int d3 = b[start + 3];
					val = val + 1 * (d3 - '0');
					
					return val;
					
				} else {
					
					int d00 = b[start + 0];
					val = val + 1000 * (d00 - '0');
												
					val = val + 100 * (d1 - '0');
					
					int d3 = b[start + 3];
					val = val + 10 * (d3 - '0');
					
					return val;					
				}
						
				
			default: // -12.34 
				
				int d11 = b[start + 1];
				val = val + 1000 * (d11 - '0');
				
				int d22 = b[start + 2];			
				val = val + 100 * (d22 - '0');
												
				int d4 = b[start + 4];	
				val = val + 10 * (d4 - '0');
				
				int d5 = b[start + 5];
				val = val + 1 * (d5 - '0');
				
				return -val;	
		}
				
	}
	
}
