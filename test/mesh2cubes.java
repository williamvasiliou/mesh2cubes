import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.lang.Class;
import java.lang.ProcessBuilder;
import java.util.ArrayList;
import java.util.HashMap;

public final class mesh2cubes {
	public static final String mesh2cubes = "mesh2cubes";
	public static final String[] tests = new String[] {"Teapot"};

	public static final HashMap<String, String> extensions = new HashMap<String, String>(2);

	static {
		extensions.put("awk", "awk");
		extensions.put("bash", "sh");
		extensions.put("c", "");
		extensions.put("cxx", "");
		extensions.put("java", "java");
	}

	public static final float intBitsToFloat(byte b1, byte b2, byte b3, byte b4) {
		return Float.intBitsToFloat((b1 & 255) << 24 | (b2 & 255) << 16 | (b3 & 255) << 8 | (b4 & 255));
	}

	public static final void read(String name, DataOutputStream out) throws IOException {
		FileInputStream s = new FileInputStream(name);
		byte[] b = new byte[50];

		s.skip(84);
		int r = s.read(b);

		while (r > 47) {
			write(b, 12, out);
			write(b, 24, out);
			write(b, 36, out);

			r = s.read(b);
		}

		s.close();
		out.close();
	}

	public static final void write(byte[] b, int off, DataOutputStream out) throws IOException {
		out.writeBytes(String.format("%g\n", intBitsToFloat(b[off + 3], b[off + 2], b[off + 1], b[off])));
		out.writeBytes(String.format("%g\n", intBitsToFloat(b[off + 7], b[off + 6], b[off + 5], b[off + 4])));
		out.writeBytes(String.format("%g\n", intBitsToFloat(b[off + 11], b[off + 10], b[off + 9], b[off + 8])));
	}

	public static final ProcessBuilder builder(String target, String extension, String argument) {
		switch (target) {
			case "awk":
				return new ProcessBuilder(target, "-f", "../../src/awk/" + mesh2cubes + "." + extension, "-f", argument);
			case "c":
			case "cxx":
				return new ProcessBuilder(argument);
			case "java":
				return new ProcessBuilder(target, "-cp", "../../src/java", argument);
			default:
				return new ProcessBuilder(target, argument);
		}
	}

	public static final void start(String test, ProcessBuilder pb, String outfile) throws ClassNotFoundException, IllegalAccessException, InterruptedException, IOException, NoSuchFieldException {
		final ArrayList<String> lines = new ArrayList<String>();

		final Class testClass = Class.forName(test);
		final String name = (String)testClass.getDeclaredField("name").get(null);
		final Expected expected = (Expected)testClass.getDeclaredField("expected").get(null);

		final String error = String.format("%s ('%s')", test, name);
		Process p = pb.start();
		read(name, new DataOutputStream(p.getOutputStream()));
		new BufferedReader(new InputStreamReader(p.getInputStream())).lines().forEach(line -> lines.add(line));
		p.waitFor();

		assert expected.actual(lines, error) : error;

		if (outfile != null) {
			final String document = Static.format(Static.getDocument(lines, error));

			if (outfile.length() > 0) {
				File path = new File(outfile);

				if (path.exists()) {
					outfile = null;
				} else {
					PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(path)));
					out.println(document);
					out.close();
				}
			} else {
				outfile = null;
			}

			if (outfile == null) {
				System.out.println(document);
			}
		}
	}

	public static final void main(String[] args) throws ClassNotFoundException, IllegalAccessException, InterruptedException, IOException, NoSuchFieldException {
		if (args.length > 0) {
			String target = args[0];
			File directory = new File(target);

			if (directory.exists() && directory.isDirectory()) {
				String extension = extensions.get(target);
				File path = new File(directory, "test" + (extension.length() > 0 ? "." + extension : ""));

				if (path.exists()) {
					String argument = path.getAbsolutePath();

					if (args.length > 1) {
						ProcessBuilder pb = builder(target, extension, argument);
						pb.directory(directory);
						pb.redirectErrorStream(true);

						start(args[1], pb, args.length > 2 ? args[2] : "");
					} else {
						for (String test : tests) {
							ProcessBuilder pb = builder(target, extension, argument);
							pb.directory(directory);
							pb.redirectErrorStream(true);

							start(test, pb, null);
						}
					}
				}
			}
		}
	}
}
