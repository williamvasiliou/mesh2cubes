import java.lang.Math;
import java.util.ArrayList;

public final class mesh2cubes {
	public int size;
	public final ArrayList<Double> vertices;
	public final ArrayList<Integer> elements;
	public boolean[][][] grid;
	public double[] min;
	public double[] max;
	public double[] mid;
	public double c;
	public double t;
	public int xr;
	public int yr;
	public int zr;
	public int xl;
	public int yl;
	public int zl;

	public mesh2cubes () {
		this.size = 0;
		this.vertices = new ArrayList<Double>();
		this.elements = new ArrayList<Integer>();
		this.min = new double[] {0.0, 0.0, 0.0};
		this.max = new double[] {0.0, 0.0, 0.0};
		this.mid = new double[] {0.0, 0.0, 0.0};
		this.c = 1.0;
		this.t = 1.0;
		this.xr = 0;
		this.yr = 0;
		this.zr = 0;
		this.xl = 0;
		this.yl = 0;
		this.zl = 0;
	}

	public double length (double[] v1) {
		return Math.sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
	}

	public void translate () {
		if (size > 0) {
			min = new double[] {this.vertices.get(0), this.vertices.get(1), this.vertices.get(2)};
			max = new double[] {this.vertices.get(0), this.vertices.get(1), this.vertices.get(2)};

			for (int i = 1; i < size; ++i) {
				final double x = this.vertices.get(3 * i);
				final double y = this.vertices.get(3 * i + 1);
				final double z = this.vertices.get(3 * i + 2);

				if (x < min[0]) {
					min[0] = x;
				}

				if (y < min[1]) {
					min[1] = y;
				}

				if (z < min[2]) {
					min[2] = z;
				}

				if (x > max[0]) {
					max[0] = x;
				}

				if (y > max[1]) {
					max[1] = y;
				}

				if (z > max[2]) {
					max[2] = z;
				}
			}
			mid = new double[] {min[0] / 2.0 + max[0] / 2.0, min[1] / 2.0 + max[1] / 2.0, min[2] / 2.0 + max[2] / 2.0};

			for (int i = 0; i < size; ++i) {
				this.vertices.set(3 * i, this.vertices.get(3 * i) - mid[0]);
				this.vertices.set(3 * i + 1, this.vertices.get(3 * i + 1) - mid[1]);
				this.vertices.set(3 * i + 2, this.vertices.get(3 * i + 2) - mid[2]);
			}
			max[0] -= mid[0];
			max[1] -= mid[1];
			max[2] -= mid[2];
			c = length(max) / 25.0;
			t = c;
			xr = (int) Math.ceil(max[0] / c - 0.5);
			yr = (int) Math.ceil(max[1] / c - 0.5);
			zr = (int) Math.ceil(max[2] / c - 0.5);
			xl = 2 * xr + 1;
			yl = 2 * yr + 1;
			zl = 2 * zr + 1;
			this.grid = new boolean[xl][yl][zl];
		}
	}

	public void cube (double[] v1) {
		final int x = (int) Math.floor(v1[0] / c + 0.5) + xr;
		final int y = (int) Math.floor(v1[1] / c + 0.5) + yr;
		final int z = (int) Math.floor(v1[2] / c + 0.5) + zr;

		if (x >= 0 && x < xl && y >= 0 && y < yl && z >= 0 && z < zl) {
			this.grid[x][y][z] = true;
		}
	}

	public void triangle (int a, int b, int c) {
		final double[] A = new double[] {this.vertices.get(3 * a), this.vertices.get(3 * a + 1), this.vertices.get(3 * a + 2)};
		final double[] B = new double[] {this.vertices.get(3 * b), this.vertices.get(3 * b + 1), this.vertices.get(3 * b + 2)};
		final double[] C = new double[] {this.vertices.get(3 * c), this.vertices.get(3 * c + 1), this.vertices.get(3 * c + 2)};
		double[] u = new double[] {B[0] - A[0], B[1] - A[1], B[2] - A[2]};
		double[] v = new double[] {C[0] - A[0], C[1] - A[1], C[2] - A[2]};
		final double IIuII = length(u);
		final double IIvII = length(v);

		if (IIuII > 0.0 && IIvII > 0.0) {
			final double dy1 = Math.min(1.0, t / IIuII);
			final double dy2 = Math.min(1.0, t / IIvII);
			u[0] *= dy1;
			u[1] *= dy1;
			u[2] *= dy1;
			v[0] *= dy2;
			v[1] *= dy2;
			v[2] *= dy2;
			double[] U = new double[] {A[0], A[1], A[2]};

			for (double y1 = 0.0; y1 <= 1.0; y1 += dy1) {
				double[] V = new double[] {U[0], U[1], U[2]};

				for (double y2 = 0.0; y1 + y2 <= 1.0; y2 += dy2) {
					cube(V);
					V[0] += v[0];
					V[1] += v[1];
					V[2] += v[2];
				}
				U[0] += u[0];
				U[1] += u[1];
				U[2] += u[2];
			}
		}
	}

	public void triangles () {
		for (int i = 0; i < this.elements.size(); i += 3) {
			triangle(this.elements.get(i), this.elements.get(i + 1), this.elements.get(i + 2));
		}
	}
}
