#ifndef MESH2CUBES_H
#include <cmath>
#include <cstdint>
#include <vector>

class mesh2cubes {
	public:
		size_t size;
		std::vector<double> vertices;
		size_t count;
		std::vector<size_t> elements;
		uint8_t *grid;
		double min[3];
		double max[3];
		double mid[3];
		double c;
		double t;
		size_t xr;
		size_t yr;
		size_t zr;
		size_t xl;
		size_t yl;
		size_t zl;

		mesh2cubes() :
			size(0),
			vertices(),
			count(0),
			elements(),
			grid((uint8_t *) NULL),
			min{0.0, 0.0, 0.0},
			max{0.0, 0.0, 0.0},
			mid{0.0, 0.0, 0.0},
			c(1.0),
			t(1.0),
			xr(0),
			yr(0),
			zr(0),
			xl(0),
			yl(0),
			zl(0)
		{}

		static inline double length(double v1[3]) {
			return sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
		}

		void translate() {
			if (this->size > 0) {
				this->min[0] = this->vertices[0];
				this->min[1] = this->vertices[1];
				this->min[2] = this->vertices[2];
				this->max[0] = this->vertices[0];
				this->max[1] = this->vertices[1];
				this->max[2] = this->vertices[2];

				for (size_t i = 1; i < this->size; ++i) {
					const double x = this->vertices[3 * i];
					const double y = this->vertices[3 * i + 1];
					const double z = this->vertices[3 * i + 2];

					if (x < this->min[0]) {
						this->min[0] = x;
					}

					if (y < this->min[1]) {
						this->min[1] = y;
					}

					if (z < this->min[2]) {
						this->min[2] = z;
					}

					if (x > this->max[0]) {
						this->max[0] = x;
					}

					if (y > this->max[1]) {
						this->max[1] = y;
					}

					if (z > this->max[2]) {
						this->max[2] = z;
					}
				}
				this->mid[0] = this->min[0] / 2.0 + this->max[0] / 2.0;
				this->mid[1] = this->min[1] / 2.0 + this->max[1] / 2.0;
				this->mid[2] = this->min[2] / 2.0 + this->max[2] / 2.0;

				for (size_t i = 0; i < this->size; ++i) {
					this->vertices[3 * i] -= this->mid[0];
					this->vertices[3 * i + 1] -= this->mid[1];
					this->vertices[3 * i + 2] -= this->mid[2];
				}
				this->max[0] -= this->mid[0];
				this->max[1] -= this->mid[1];
				this->max[2] -= this->mid[2];
				this->c = length(this->max) / 25.0;
				this->t = this->c;
				this->xr = (size_t) ceil(this->max[0] / this->c - 0.5);
				this->yr = (size_t) ceil(this->max[1] / this->c - 0.5);
				this->zr = (size_t) ceil(this->max[2] / this->c - 0.5);
				this->xl = 2 * this->xr + 1;
				this->yl = 2 * this->yr + 1;
				this->zl = 2 * this->zr + 1;

				if (this->grid) {
					delete[] this->grid;
				}
				this->grid = (uint8_t *) new uint8_t[(this->xl * this->yl * this->zl + 8) >> 3] {};
			}
		}

		void cube(double v1[3]) {
			const size_t x = (size_t) floor(v1[0] / this->c + 0.5) + this->xr;
			const size_t y = (size_t) floor(v1[1] / this->c + 0.5) + this->yr;
			const size_t z = (size_t) floor(v1[2] / this->c + 0.5) + this->zr;

			if (x < this->xl && y < this->yl && z < this->zl) {
				const size_t i = this->yl * this->zl * x + this->zl * y + z;

				this->grid[i >> 3] |= 1 << (i & 7);
			}
		}

		void triangle(size_t a, size_t b, size_t c) {
			const double A[3] = {this->vertices[3 * a], this->vertices[3 * a + 1], this->vertices[3 * a + 2]};
			const double B[3] = {this->vertices[3 * b], this->vertices[3 * b + 1], this->vertices[3 * b + 2]};
			const double C[3] = {this->vertices[3 * c], this->vertices[3 * c + 1], this->vertices[3 * c + 2]};
			double u[3] = {B[0] - A[0], B[1] - A[1], B[2] - A[2]};
			double v[3] = {C[0] - A[0], C[1] - A[1], C[2] - A[2]};
			const double IIuII = length(u);
			const double IIvII = length(v);

			if (IIuII > 0.0 && IIvII > 0.0) {
				const double dy1 = fmin(1.0, this->t / IIuII);
				const double dy2 = fmin(1.0, this->t / IIvII);
				u[0] *= dy1;
				u[1] *= dy1;
				u[2] *= dy1;
				v[0] *= dy2;
				v[1] *= dy2;
				v[2] *= dy2;
				double U[3] = {A[0], A[1], A[2]};

				for (double y1 = 0.0; y1 <= 1.0; y1 += dy1) {
					double V[3] = {U[0], U[1], U[2]};

					for (double y2 = 0.0; y1 + y2 <= 1.0; y2 += dy2) {
						this->cube(V);
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
			for (size_t i = 0; i < this->count; i += 3) {
				this->triangle(this->elements[i], this->elements[i + 1], this->elements[i + 2]);
			}
		}

		~mesh2cubes() {
			if (this->grid) {
				delete[] this->grid;
			}
		}
};

#endif // MESH2CUBES_H
