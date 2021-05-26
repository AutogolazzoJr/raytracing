import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class zzzIncluder {

	public static void main(String[] args) throws IOException {
		List<String> list = include(args[0]);
		FileWriter writer = new FileWriter(args[1]);
		for (String s : list) {
			writer.write(s + "\n");
		}
		writer.close();
	}

	public static List<String> include(String fileName) throws FileNotFoundException {
		List<String> file = new ArrayList();
		Scanner scan = new Scanner(new File(fileName));
		List<String> ret = new ArrayList();
		while(scan.hasNextLine()) {
			file.add(scan.nextLine());
		}
		for (int i = 0; i < file.size(); i++) {
			if (file.get(i).trim().length() >= 8 && file.get(i).trim().substring(0, 8).equals("#include")) {
				String name = file.get(i).trim();
				name = name.substring(name.indexOf("\"") + 1, name.length() - 1);
				List<String> included = include(name);
				for (String s : included) {
					ret.add(s);
				}
			} else {
				ret.add(file.get(i));
			}
		}
		return ret;
	}
}