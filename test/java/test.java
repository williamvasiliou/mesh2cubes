import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

public final class test {
	public static final mesh2cubes m2c = new mesh2cubes();

	public static void read() throws IOException {
		new BufferedReader(new InputStreamReader(System.in)).lines()
			.forEach(v -> m2c.vertices.add(Double.valueOf(v)));

		final int size = 3 * (m2c.vertices.size() / 9);

		for (int i = 0; i < size; i += 3) {
			m2c.elements.add(i);
			m2c.elements.add(i + 1);
			m2c.elements.add(i + 2);
		}

		m2c.size = size;
	}

	public static void print() {
		final int xr = m2c.xr;
		final int yr = m2c.yr;
		final int zr = m2c.zr;

		System.out.printf("%f,%f,%f,%f,%f\n", m2c.max[0], m2c.max[1], m2c.max[2], m2c.t, m2c.c);
		System.out.printf("%d,%d,%d\n", xr, yr, zr);

		final int xl = m2c.xl;
		final int yl = m2c.yl;
		final int zl = m2c.zl;

		for (int y = 0; y < yl; ++y) {
			for (int z = 0; z < zl; ++z) {
				for (int x = 0; x < xl; ++x) {
					if (m2c.grid[x][y][z]) {
						System.out.printf("%d,%d,%d\n", x - xr, y - yr, z - zr);
					}
				}
			}
		}
	}

	public static final void main(String[] args) throws IOException {
		read();
		m2c.translate();
		m2c.triangles();
		print();
	}
}
