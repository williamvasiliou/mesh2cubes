module mesh2cubes;

import std.math;
import std.stdint;

class m2c_t {
	public:
		size_t size;
		double[] vertices;
		size_t[] elements;
		bool[int][int][int] grid;
		double[3] min;
		double[3] max;
		double[3] mid;
		double c;
		double t;
		size_t xr;
		size_t yr;
		size_t zr;

		this() {
			this.size = 0;
			this.min = [0.0, 0.0, 0.0];
			this.max = [0.0, 0.0, 0.0];
			this.mid = [0.0, 0.0, 0.0];
			this.c = 1.0;
			this.t = 1.0;
			this.xr = 0;
			this.yr = 0;
			this.zr = 0;
		}

		pragma(inline, true) static double length(double[3] v1) {
			return sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
		}

		void translate() {
			if (this.size > 0) {
				this.min[0] = this.vertices[0];
				this.min[1] = this.vertices[1];
				this.min[2] = this.vertices[2];
				this.max[0] = this.vertices[0];
				this.max[1] = this.vertices[1];
				this.max[2] = this.vertices[2];

				for (size_t i = 1; i < this.size; ++i) {
					const double x = this.vertices[3 * i];
					const double y = this.vertices[3 * i + 1];
					const double z = this.vertices[3 * i + 2];

					if (x < this.min[0]) {
						this.min[0] = x;
					}

					if (y < this.min[1]) {
						this.min[1] = y;
					}

					if (z < this.min[2]) {
						this.min[2] = z;
					}

					if (x > this.max[0]) {
						this.max[0] = x;
					}

					if (y > this.max[1]) {
						this.max[1] = y;
					}

					if (z > this.max[2]) {
						this.max[2] = z;
					}
				}
				this.mid[0] = this.min[0] / 2.0 + this.max[0] / 2.0;
				this.mid[1] = this.min[1] / 2.0 + this.max[1] / 2.0;
				this.mid[2] = this.min[2] / 2.0 + this.max[2] / 2.0;

				for (size_t i = 0; i < this.size; ++i) {
					this.vertices[3 * i] -= this.mid[0];
					this.vertices[3 * i + 1] -= this.mid[1];
					this.vertices[3 * i + 2] -= this.mid[2];
				}
				this.max[0] -= this.mid[0];
				this.max[1] -= this.mid[1];
				this.max[2] -= this.mid[2];
				this.c = length(this.max) / 25.0;
				this.t = this.c;
				this.xr = cast(size_t) ceil(this.max[0] / this.c - 0.5);
				this.yr = cast(size_t) ceil(this.max[1] / this.c - 0.5);
				this.zr = cast(size_t) ceil(this.max[2] / this.c - 0.5);
			}
		}

		void cube(double[3] v1) {
			const int x = cast(int) floor(v1[0] / this.c + 0.5);
			const int y = cast(int) floor(v1[1] / this.c + 0.5);
			const int z = cast(int) floor(v1[2] / this.c + 0.5);

			this.grid[x][y][z] = true;
		}

		void triangle(size_t a, size_t b, size_t c) {
			const double[3] A = [this.vertices[3 * a], this.vertices[3 * a + 1], this.vertices[3 * a + 2]];
			const double[3] B = [this.vertices[3 * b], this.vertices[3 * b + 1], this.vertices[3 * b + 2]];
			const double[3] C = [this.vertices[3 * c], this.vertices[3 * c + 1], this.vertices[3 * c + 2]];
			double[3] u = [B[0] - A[0], B[1] - A[1], B[2] - A[2]];
			double[3] v = [C[0] - A[0], C[1] - A[1], C[2] - A[2]];
			const double IIuII = length(u);
			const double IIvII = length(v);

			if (IIuII > 0.0 && IIvII > 0.0) {
				const double dy1 = fmin(1.0, this.t / IIuII);
				const double dy2 = fmin(1.0, this.t / IIvII);
				u[0] *= dy1;
				u[1] *= dy1;
				u[2] *= dy1;
				v[0] *= dy2;
				v[1] *= dy2;
				v[2] *= dy2;
				double[3] U = [A[0], A[1], A[2]];

				for (double y1 = 0.0; y1 <= 1.0; y1 += dy1) {
					double[3] V = [U[0], U[1], U[2]];

					for (double y2 = 0.0; y1 + y2 <= 1.0; y2 += dy2) {
						this.cube(V);
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

		void triangles() {
			for (size_t i = 0; i < this.elements.length; i += 3) {
				this.triangle(this.elements[i], this.elements[i + 1], this.elements[i + 2]);
			}
		}
}
