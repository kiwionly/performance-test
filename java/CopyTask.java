
// javac CopyTask.java && /usr/bin/time -v java CopyTask

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;

public class CopyTask {

	public static void main(String[] args) throws Exception {
		
		String fileName = "../weather_stations.csv";
		
		try(RandomAccessFile in = new RandomAccessFile(fileName, "r" );
				FileChannel ch = in.getChannel()) {
			
			try(RandomAccessFile out = new RandomAccessFile("../out.csv", "rw" );
					FileChannel ch2 = out.getChannel()) {			
				
				final long size = ch.size();
				
				for (int i = 0; i < 100; i++) {   // 100 * 44693 ( records count in weather stations.csv)
	                ch.transferTo(0, size, ch2);
	            }
			}
			
		}
				
		long count = 0;
		
		BufferedReader buf = new BufferedReader(new FileReader("../out.csv"));
	
		while(buf.readLine() != null) {
			count=count+1;
		}
		
		System.out.println("rows count = " + count);
		
		buf.close();
			
	}
}
