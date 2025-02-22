import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

public final class test {
	public static final mesh2cubes m2c = new mesh2cubes();

	public static void read() throws IOException {
		new BufferedReader(new InputStreamReader(System.in)).lines()
			.forEach(v -> m2c.vertices.add(Double.valueOf(v)));

		final int size = m2c.vertices.size() / 3;

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

		System.out.println(String.format("%f,%f,%f,%f,%f", m2c.max[0], m2c.max[1], m2c.max[2], m2c.t, m2c.c));
		System.out.println(String.format("%d,%d,%d", xr, yr, zr));

		final int xl = 2 * xr + 1;
		final int yl = 2 * yr + 1;
		final int zl = 2 * zr + 1;

		for (int y = 0; y < yl; ++y) {
			for (int z = 0; z < zl; ++z) {
				for (int x = 0; x < xl; ++x) {
					if (m2c.grid[x][y][z]) {
						System.out.println(String.format("%d,%d,%d", x - xr, y - yr, z - zr));
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
