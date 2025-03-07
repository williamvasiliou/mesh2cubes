#ifndef MESH2CUBES_H
#define MESH2CUBES_H

#include <math.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct {
	size_t size;
	double *vertices;
	size_t count;
	size_t *elements;
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
} m2c_t;

m2c_t *m2c_mesh2cubes() {
	m2c_t *m2c = (m2c_t *) calloc((size_t) 1, sizeof(m2c_t));

	m2c->size = 0;
	m2c->vertices = (double *) NULL;
	m2c->count = 0;
	m2c->elements = (size_t *) NULL;
	m2c->grid = (uint8_t *) NULL;
	m2c->min[0] = 0.0;
	m2c->min[1] = 0.0;
	m2c->min[2] = 0.0;
	m2c->max[0] = 0.0;
	m2c->max[1] = 0.0;
	m2c->max[2] = 0.0;
	m2c->mid[0] = 0.0;
	m2c->mid[1] = 0.0;
	m2c->mid[2] = 0.0;
	m2c->c = 1.0;
	m2c->t = 1.0;
	m2c->xr = 0;
	m2c->yr = 0;
	m2c->zr = 0;
	m2c->xl = 0;
	m2c->yl = 0;
	m2c->zl = 0;

	return m2c;
}

static inline double m2c_length(double v1[3]) {
	return sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
}

static void m2c_translate(m2c_t *m2c) {
	if (m2c->size > 0) {
		m2c->min[0] = m2c->vertices[0];
		m2c->min[1] = m2c->vertices[1];
		m2c->min[2] = m2c->vertices[2];
		m2c->max[0] = m2c->vertices[0];
		m2c->max[1] = m2c->vertices[1];
		m2c->max[2] = m2c->vertices[2];

		for (size_t i = 1; i < m2c->size; ++i) {
			const double x = m2c->vertices[3 * i];
			const double y = m2c->vertices[3 * i + 1];
			const double z = m2c->vertices[3 * i + 2];

			if (x < m2c->min[0]) {
				m2c->min[0] = x;
			}

			if (y < m2c->min[1]) {
				m2c->min[1] = y;
			}

			if (z < m2c->min[2]) {
				m2c->min[2] = z;
			}

			if (x > m2c->max[0]) {
				m2c->max[0] = x;
			}

			if (y > m2c->max[1]) {
				m2c->max[1] = y;
			}

			if (z > m2c->max[2]) {
				m2c->max[2] = z;
			}
		}
		m2c->mid[0] = m2c->min[0] / 2.0 + m2c->max[0] / 2.0;
		m2c->mid[1] = m2c->min[1] / 2.0 + m2c->max[1] / 2.0;
		m2c->mid[2] = m2c->min[2] / 2.0 + m2c->max[2] / 2.0;

		for (size_t i = 0; i < m2c->size; ++i) {
			m2c->vertices[3 * i] -= m2c->mid[0];
			m2c->vertices[3 * i + 1] -= m2c->mid[1];
			m2c->vertices[3 * i + 2] -= m2c->mid[2];
		}
		m2c->max[0] -= m2c->mid[0];
		m2c->max[1] -= m2c->mid[1];
		m2c->max[2] -= m2c->mid[2];
		m2c->c = m2c_length(m2c->max) / 25.0;
		m2c->t = m2c->c;
		m2c->xr = (size_t) ceil(m2c->max[0] / m2c->c - 0.5);
		m2c->yr = (size_t) ceil(m2c->max[1] / m2c->c - 0.5);
		m2c->zr = (size_t) ceil(m2c->max[2] / m2c->c - 0.5);
		m2c->xl = 2 * m2c->xr + 1;
		m2c->yl = 2 * m2c->yr + 1;
		m2c->zl = 2 * m2c->zr + 1;

		if (m2c->grid) {
			free(m2c->grid);
		}
		m2c->grid = (uint8_t *) calloc((m2c->xl * m2c->yl * m2c->zl + 8) >> 3, sizeof(uint8_t));
	}
}

static void m2c_cube(m2c_t *m2c, double v1[3]) {
	const size_t x = (size_t) floor(v1[0] / m2c->c + 0.5) + m2c->xr;
	const size_t y = (size_t) floor(v1[1] / m2c->c + 0.5) + m2c->yr;
	const size_t z = (size_t) floor(v1[2] / m2c->c + 0.5) + m2c->zr;

	if (x < m2c->xl && y < m2c->yl && z < m2c->zl) {
		const size_t i = m2c->yl * m2c->zl * x + m2c->zl * y + z;

		m2c->grid[i >> 3] |= 1 << (i & 7);
	}
}

static void m2c_triangle(m2c_t *m2c, size_t a, size_t b, size_t c) {
	const double A[3] = {m2c->vertices[3 * a], m2c->vertices[3 * a + 1], m2c->vertices[3 * a + 2]};
	const double B[3] = {m2c->vertices[3 * b], m2c->vertices[3 * b + 1], m2c->vertices[3 * b + 2]};
	const double C[3] = {m2c->vertices[3 * c], m2c->vertices[3 * c + 1], m2c->vertices[3 * c + 2]};
	double u[3] = {B[0] - A[0], B[1] - A[1], B[2] - A[2]};
	double v[3] = {C[0] - A[0], C[1] - A[1], C[2] - A[2]};
	const double IIuII = m2c_length(u);
	const double IIvII = m2c_length(v);

	if (IIuII > 0.0 && IIvII > 0.0) {
		const double dy1 = fmin(1.0, m2c->t / IIuII);
		const double dy2 = fmin(1.0, m2c->t / IIvII);
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
				m2c_cube(m2c, V);
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

static void m2c_triangles(m2c_t *m2c) {
	for (size_t i = 0; i < m2c->count; i += 3) {
		m2c_triangle(m2c, m2c->elements[i], m2c->elements[i + 1], m2c->elements[i + 2]);
	}
}

#endif // MESH2CUBES_H
