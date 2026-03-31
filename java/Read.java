
// graalvm-jdk.javac Read.java && /usr/bin/time -v graalvm-jdk.java Read

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Arrays;

public class Read {

	public static void main(String[] args) throws IOException {

		long start = System.currentTimeMillis();

		try (FileInputStream in = new FileInputStream("../out.csv")) {

			byte[] buffer = new byte[65536 + 1024];
			int leftover = 0;
			int byteRead;
		
			int max = 0;
			int min = 0;
			int count = 0;	
			byte[] maxCity = null;
			byte[] minCity = null;


			while ((byteRead = in.read(buffer, leftover, 65536)) != -1) {

				int totalAvailable = byteRead + leftover;
				int pos = 0;
				
				for(int i = pos; i < totalAvailable; i++) {

					if('\n' == buffer[i]) {

						for (int j = i - 1; j >= pos; j--) {

							if(';' == buffer[j]) {
								count++;
								int temp = fastParseInt(buffer, j + 1, i);

								if (temp > max) {
									max = temp;
									maxCity = Arrays.copyOfRange(buffer, pos, i);
								} else if (temp < min) {
									min = temp;
									minCity = Arrays.copyOfRange(buffer, pos, i);
								}
								
								break;
							}
						}

						pos = i + 1; // next index after \n
					}
				}

				leftover = totalAvailable - pos;
				
				if(leftover > 0) {
					System.arraycopy(buffer, pos, buffer, 0, leftover);
				} else {
			        leftover = 0;
			    }
			}


			long end = System.currentTimeMillis() - start;

			System.out.println("max = " + new String(maxCity) + "\nmin = " + new String(minCity) + "\ncount = " + count + "\ntime use = " + end);
		}

	}

	public static int fastParseInt(byte[] b, int start, int end) {
		
		int val = 0;
		boolean neg = false;
		int i = start;

		if (b[i] == '-') {
			neg = true;
			i++;
		}

		for (; i < end; i++) {
			byte c = b[i];
			if (c >= '0' && c <= '9') {
				val = val * 10 + (c - '0');
			}
			// Automatically skips '.' just like your other versions
		}

		return neg ? -val : val;
	}
}
