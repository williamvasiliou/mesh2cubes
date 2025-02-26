#include "../../src/c/mesh2cubes.h"
#include <stdio.h>

void read(m2c_t *m2c) {
	char *line = NULL;
	size_t size = 0;

	m2c->size = 1;
	m2c->vertices = (double *) calloc(m2c->size, sizeof(double));

	if (m2c->vertices) {
		while (getline(&line, &size, stdin) != -1) {
			const double v = atof(line);

			if (m2c->count < m2c->size) {
				m2c->vertices[m2c->count++] = v;
			} else {
				double *const vertices = (double *) reallocarray(m2c->vertices, m2c->size * 2, sizeof(double));

				if (vertices) {
					m2c->vertices = vertices;
					m2c->vertices[m2c->count++] = v;
					m2c->size *= 2;
				}
			}
		}

		free(line);

		m2c->size = 3 * (m2c->count / 9);
		if (m2c->size > 0) {
			m2c->count = m2c->size;
			m2c->elements = (size_t *) calloc(m2c->count, sizeof(size_t));

			if (m2c->elements) {
				for (size_t i = 0; i < m2c->count; i += 3) {
					m2c->elements[i] = i;
					m2c->elements[i + 1] = i + 1;
					m2c->elements[i + 2] = i + 2;
				}
			} else {
				m2c->count = 0;
			}
		} else {
			m2c->count = 0;
		}
	}
}

void print(m2c_t *m2c) {
	const size_t xr = m2c->xr;
	const size_t yr = m2c->yr;
	const size_t zr = m2c->zr;

	printf("%f,%f,%f,%f,%f\n", m2c->max[0], m2c->max[1], m2c->max[2], m2c->t, m2c->c);
	printf("%lu,%lu,%lu\n", xr, yr, zr);

	const size_t xl = m2c->xl;
	const size_t yl = m2c->yl;
	const size_t zl = m2c->zl;

	for (size_t y = 0; y < yl; ++y) {
		for (size_t z = 0; z < zl; ++z) {
			for (size_t x = 0; x < xl; ++x) {
				const size_t i = yl * zl * x + zl * y + z;

				if (m2c->grid[i >> 3] & (1 << (i & 7))) {
					printf("%ld,%ld,%ld\n", x - xr, y - yr, z - zr);
				}
			}
		}
	}
}

int main(int argc, char *argv[]) {
	m2c_t* m2c = m2c_mesh2cubes();

	read(m2c);
	m2c_translate(m2c);
	m2c_triangles(m2c);
	print(m2c);

	if (m2c->vertices) {
		free(m2c->vertices);
	}

	if (m2c->elements) {
		free(m2c->elements);
	}

	if (m2c->grid) {
		free(m2c->grid);
	}

	free(m2c);
	return 0;
}
