
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

				int temp = fastParseInt(temparature);

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
