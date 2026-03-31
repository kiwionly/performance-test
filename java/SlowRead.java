
// graalvm-jdk.javac SlowRead.java && /usr/bin/time -v graalvm-jdk.java SlowRead

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
		
	    int res = 0;
	    
	    int pos = 0;
	    
	    boolean neg = false;
        if (s.startsWith("-")) {
            neg = true;
            pos++;
        }
        
	    for (int i = pos; i < s.length(); i++) {
	        // Subtracting '0' gets the numeric value of the ASCII character
	        res = res * 10 + (s.charAt(i) - '0');
	    }
	    
	    if(neg) {
	    	return -res;
	    }    
	    
	    return res;
	}
}
