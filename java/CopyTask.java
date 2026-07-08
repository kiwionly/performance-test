
// javac CopyTask.java && /usr/bin/time -v java CopyTask

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;

public class CopyTask {

	public static void main(String[] args) throws Exception {
		
		String file = "../weather_stations.csv";

		// format all temparature to [-]DD.D and write to file
		String formatFile = "../weather_stations_format.csv";

		try (BufferedReader buf = new BufferedReader(new FileReader(file))) {

			try(BufferedWriter out = new BufferedWriter(new FileWriter(formatFile))) {

				String line = "";
			
				while ((line = buf.readLine()) != null) {

					int pos = line.indexOf(";");

					if(pos < 0) {
						continue;
					}

					String city = line.substring(0, pos);
					String temparature = line.substring(pos + 1);
					
					if(temparature.startsWith("-")) {
						temparature =  temparature.substring(0, 5);
					} else {
						temparature =  temparature.substring(0, 4);
					}
							
					out.write(city + ";" + temparature + "\n");			
				}	
			}	
		}

		// duplication

		try(RandomAccessFile in = new RandomAccessFile(formatFile, "r" );
			
			FileChannel ch = in.getChannel()) {
			
			try(RandomAccessFile out = new RandomAccessFile("../out.csv", "rw" );
				FileChannel ch2 = out.getChannel()) {			
				
				out.setLength(0); // clear old file
				
				final long size = ch.size();
				
				for (int i = 0; i < 100; i++) {   // 100 * 44691 ( records count in weatherstations_format.csv)
	                ch.transferTo(0, size, ch2);
	            }
			}
			
		}
				
		// verify row count

		long count = 0;
		
		BufferedReader buf = new BufferedReader(new FileReader("../out.csv"));
	
		while(buf.readLine() != null) {
			count=count+1;
		}
		
		System.out.println("rows count = " + count);
		
		buf.close();
			
	}
}
