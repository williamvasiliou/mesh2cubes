import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.lang.Math;
import java.util.ArrayList;

public final class mesh2cubes {
	private final ArrayList<Vector3d> vertices;
	private final ArrayList<Triangle> triangles;
	private Grid grid;

	public mesh2cubes() {
		this.vertices = new ArrayList<Vector3d>();
		this.triangles = new ArrayList<Triangle>();
		this.grid = null;
	}

	public final void translate() {
		final int size = this.vertices.size();

		if (size > 0) {
			Vector3d min = new Vector3d(this.vertices.get(0));
			Vector3d max = new Vector3d(this.vertices.get(0));

			for (int i = 1; i < size; ++i) {
				Vector3d v1 = this.vertices.get(i);
				final double x = v1.x;
				final double y = v1.y;
				final double z = v1.z;

				min.x = Math.min(min.x, x);
				min.y = Math.min(min.y, y);
				min.z = Math.min(min.z, z);
				max.x = Math.max(max.x, x);
				max.y = Math.max(max.y, y);
				max.z = Math.max(max.z, z);
			}

			Vector3d mid = new Vector3d(min.x / 2.0 + max.x / 2.0, min.y / 2.0 + max.y / 2.0, min.z / 2.0 + max.z / 2.0);

			for (Vector3d v1 : this.vertices) {
				v1.sub(mid);
			}

			Vector3d g = new Vector3d(max.x - mid.x, max.y - mid.y, max.z - mid.z);
			final double c = g.length() / 25.0;

			this.grid = new Grid(g.x, g.y, g.z, c, c);
		}
	}

	public final void read(String name) throws IOException {
		FileInputStream s = new FileInputStream(name);
		byte[] b = new byte[50];

		s.skip(84);
		int r = s.read(b);

		while (r > 47) {
			final int size = this.vertices.size();

			this.vertices.add(new Vector3d(b, 12));
			this.vertices.add(new Vector3d(b, 24));
			this.vertices.add(new Vector3d(b, 36));

			this.triangles.add(new Triangle(size, size + 1, size + 2));

			r = s.read(b);
		}

		s.close();
	}

	public final void write(String name) throws IOException {
		this.translate();
		for (Triangle t1 : this.triangles) {
			this.grid.triangle(t1);
		}

		if (name != null) {
			this.grid.write(name);
		} else {
			this.grid.print();
		}
	}

	public static final float intBitsToFloat(byte b1, byte b2, byte b3, byte b4) {
		return Float.intBitsToFloat((b1 & 255) << 24 | (b2 & 255) << 16 | (b3 & 255) << 8 | (b4 & 255));
	}

	public final class Vector3d {
		public double x;
		public double y;
		public double z;

		public Vector3d(byte[] b, int off) {
			this.x = mesh2cubes.intBitsToFloat(b[off + 3], b[off + 2], b[off + 1], b[off]);
			this.y = mesh2cubes.intBitsToFloat(b[off + 7], b[off + 6], b[off + 5], b[off + 4]);
			this.z = mesh2cubes.intBitsToFloat(b[off + 11], b[off + 10], b[off + 9], b[off + 8]);
		}

		public Vector3d(double x, double y, double z) {
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public Vector3d(Vector3d v1) {
			this.x = v1.x;
			this.y = v1.y;
			this.z = v1.z;
		}

		public final void add(Vector3d v1) {
			this.x += v1.x;
			this.y += v1.y;
			this.z += v1.z;
		}

		public final void sub(Vector3d v1) {
			this.x -= v1.x;
			this.y -= v1.y;
			this.z -= v1.z;
		}

		public final void scale(double s) {
			this.x *= s;
			this.y *= s;
			this.z *= s;
		}

		public final double length() {
			return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
		}
	}

	public final class Triangle {
		private final int a;
		private final int b;
		private final int c;

		public Triangle(int a, int b, int c) {
			this.a = a;
			this.b = b;
			this.c = c;
		}

		public final Vector3d getA() {
			return new Vector3d(vertices.get(this.a));
		}

		public final Vector3d getB() {
			return new Vector3d(vertices.get(this.b));
		}

		public final Vector3d getC() {
			return new Vector3d(vertices.get(this.c));
		}
	}

	public final class Grid {
		private final double x;
		private final double y;
		private final double z;
		private final double t;
		private final double c;
		private final int xr;
		private final int xl;
		private final int yr;
		private final int yl;
		private final int zr;
		private final int zl;
		private final boolean[][][] g;

		public Grid(double x, double y, double z, double t, double c) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.t = t;
			this.c = c;
			this.xr = (int)Math.ceil(x / c - 0.5);
			this.yr = (int)Math.ceil(y / c - 0.5);
			this.zr = (int)Math.ceil(z / c - 0.5);
			this.xl = 2 * this.xr + 1;
			this.yl = 2 * this.yr + 1;
			this.zl = 2 * this.zr + 1;
			this.g = new boolean[this.xl][this.yl][this.zl];
		}

		public final void add(Vector3d v1) {
			final int x = this.xr + (int)Math.floor(v1.x / this.c + 0.5);
			final int y = this.yr + (int)Math.floor(v1.y / this.c + 0.5);
			final int z = this.zr + (int)Math.floor(v1.z / this.c + 0.5);

			if (x >= 0 && x < this.xl && y >= 0 && y < this.yl && z >= 0 && z <= this.zl) {
				this.g[x][y][z] = true;
			}
		}

		public final void triangle(Triangle t1) {
			final Vector3d A = t1.getA();

			final Vector3d u = t1.getB();
			final Vector3d v = t1.getC();

			u.sub(A);
			v.sub(A);

			final double IIuII = u.length();
			final double IIvII = v.length();

			if (IIuII > 0 && IIvII > 0) {
				final double dy1 = Math.min(1, this.t / IIuII);
				final double dy2 = Math.min(1, this.t / IIvII);

				u.scale(dy1);
				v.scale(dy2);

				final Vector3d U = new Vector3d(A);
				for (double y1 = 0; y1 <= 1; y1 += dy1) {
					final Vector3d V = new Vector3d(U);
					for (double y2 = 0; y1 + y2 <= 1; y2 += dy2) {
						this.add(V);
						V.add(v);
					}

					U.add(u);
				}
			}
		}

		public final void print() {
			System.out.printf("%f,%f,%f,%f,%f\n", this.x, this.y, this.z, this.t, this.c);
			System.out.printf("%d,%d,%d\n", this.xr, this.yr, this.zr);

			for (int y = 0; y < this.yl; ++y) {
				for (int z = 0; z < this.zl; ++z) {
					for (int x = 0; x < this.xl; ++x) {
						if (this.g[x][y][z]) {
							System.out.printf("%d,%d,%d\n", x - this.xr, y - this.yr, z - this.zr);
						}
					}
				}
			}
		}

		public final void write(String name) throws IOException {
			BufferedWriter s = new BufferedWriter(new FileWriter(name));
			s.write(String.format("%f,%f,%f,%f,%f\n", this.x, this.y, this.z, this.t, this.c));
			s.write(String.format("%d,%d,%d\n", this.xr, this.yr, this.zr));

			for (int y = 0; y < this.yl; ++y) {
				for (int z = 0; z < this.zl; ++z) {
					for (int x = 0; x < this.xl; ++x) {
						if (this.g[x][y][z]) {
							s.write(String.format("%d,%d,%d\n", x - this.xr, y - this.yr, z - this.zr));
						}
					}
				}
			}

			s.flush();
			s.close();
		}
	}

	public static final void main(String[] args) {
		mesh2cubes m2c = new mesh2cubes();

		try {
			switch (args.length) {
				case 1:
					m2c.read(args[0]);
					m2c.write(null);
					break;
				case 2:
					m2c.read(args[0]);
					m2c.write(args[1]);
					break;
				default:
					System.out.println("mesh2cubes <infile> [outfile]");
					break;
			}
		} catch (IOException ex) {
			ex.printStackTrace();
		}
	}
}
