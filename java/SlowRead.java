
// javac SlowRead.java && /usr/bin/time -v java SlowRead

// native-image SlowRead && /usr/bin/time -v ./slowread

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class SlowRead {

	public static void main(String[] args) throws IOException {
		
		long start = System.currentTimeMillis();

		try (BufferedReader buf = new BufferedReader(new FileReader("../out.csv"))) {

			String maxCity = "";
			String minCity = "";

			int max = 0;
			int min = 0;
			int count = 0;

			String line = null;
			while ((line = buf.readLine()) != null) {

				// using indexOf really save some memory
				
				int pos = line.indexOf(";");

				if(pos < 0) {
					continue;
				}

				String temparature = line.substring(pos + 1);

				// if(temparature.charAt(0) != '-' && temparature.indexOf(".") == 3) {
				// 	System.out.println(line);
				// }

				// if(temparature.length() == 6) {
				// 	System.out.println(line);
				// }

				int temp = loopUnrollingParseInt(temparature);

				// Taking more cpu and memory if u using code below 

				// String[] tokens = line.split(";");

				// if(tokens.length == 1) {
				// 	continue;
				// }

				// int temp = fastParseInt(tokens[1]);

				if (temp > max) {
					max = temp;
					maxCity = line;
				}  if (temp < min) {
					min = temp;
					minCity = line;
				}
				
				count += 1;
			}
			
			long end = System.currentTimeMillis() - start;

			System.out.println("max = " + maxCity + "\nmin = " + minCity + "\ncount = " + count + "\ntime user = " + end);
		}

	}

	public static int loopUnrollingParseInt(String value) {
		
		int size = value.length();
		
		int val = 0;
		
		
		switch(size) {
				
			case 5 :  // -1.23 or -12.3 or 12.34 
				
				char d0 = value.charAt(0);
				
				if(d0 == '-') {
					
					char d2 = value.charAt(2);
					
					if(d2 == '.') {
						char d1 = value.charAt(1);
						val = val + 100 * (d1 - '0');
						
						char d3 = value.charAt(3);						
						val = val + 10 * (d3 - '0');
						
						char d4 = value.charAt(4);
						val = val + 1 * (d4 - '0');
						
						return -val;
						
					} else {
						
						char d1 = value.charAt(1);
						val = val + 1000 * (d1 - '0');					
								
						val = val + 100 * (d2 - '0');
												
						char d4 = value.charAt(4);
						val = val + 10 * (d4 - '0');
						
						return -val;						
					}				
					
				} 
				// else {
					
				// 	val = val + 1000 * (d0 - '0');
					
				// 	char d1 = value.charAt(1);
				// 	val = val + 100 * (d1 - '0');
										
				// 	char d3 = value.charAt(3);						
				// 	val = val + 10 * (d3 - '0');
					
				// 	char d4 = value.charAt(4);
				// 	val = val + 1 * (d4 - '0');					
						
				// 	return val;					
				// }				
				
			case 4 : // 1.23 or 12.3
				
				char d1 = value.charAt(1);
				
				if(d1 == '.') {
																	
					char d00 = value.charAt(0);				
					val = val + 100 * (d00 - '0');
										
					char d2 = value.charAt(2);			
					val = val + 10 * (d2 - '0');
					
					char d3 = value.charAt(3);						
					val = val + 1 * (d3 - '0');
					
					return val;
					
				} else {
					
					char d00 = value.charAt(0);				
					val = val + 1000 * (d00 - '0');
												
					val = val + 100 * (d1 - '0');
					
					char d3 = value.charAt(3);						
					val = val + 10 * (d3 - '0');
					
					return val;					
				}
						
				
			// default: // -12.34 
				
			// 	char d11 = value.charAt(1);
			// 	val = val + 1000 * (d11 - '0');
				
			// 	char d22 = value.charAt(2);						
			// 	val = val + 100 * (d22 - '0');
												
			// 	char d4 = value.charAt(4);
			// 	val = val + 10 * (d4 - '0');
				
			// 	char d5 = value.charAt(5);
			// 	val = val + 1 * (d5 - '0');
				
			// 	return -val;

		}	

		return 0;  
		
	}


	public static int fastParseInt(String s) {
		
		int signed = 1;
		int i = 0;

		if (s.charAt(i) == '-') {
			signed = -1;
			i++;
		}

		int dotPos = 0;
		
		int val = 0;
		for (; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c >= '0' && c <= '9') {
				val = val * 10 + (c - '0');
			} else {
				dotPos = i;
			}
		}
	
		if ((signed == 1 && dotPos == 2) || (signed == -1 && dotPos == 3)) {
			val *= 10;
		}

		return signed * val;
	}	
	
}
