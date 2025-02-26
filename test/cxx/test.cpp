#include "../../src/cxx/mesh2cubes.hpp"
#include <iostream>

void read(mesh2cubes& m2c) {
	double v = 0;

	while (std::cin) {
		std::cin >> v;
		m2c.vertices.push_back(v);
	}

	m2c.size = 3 * (m2c.vertices.size() / 9);
	m2c.count = m2c.size;

	for (size_t i = 0; i < m2c.count; i += 3) {
		m2c.elements.push_back(i);
		m2c.elements.push_back(i + 1);
		m2c.elements.push_back(i + 2);
	}
}

void print(const mesh2cubes& m2c) {
	const size_t xr = m2c.xr;
	const size_t yr = m2c.yr;
	const size_t zr = m2c.zr;

	std::cout << m2c.max[0] << ',' << m2c.max[1] << ',' << m2c.max[2] << ',' << m2c.t << ',' << m2c.c << std::endl;
	std::cout << xr << ',' << yr << ',' << zr << std::endl;

	const size_t xl = m2c.xl;
	const size_t yl = m2c.yl;
	const size_t zl = m2c.zl;

	for (size_t y = 0; y < yl; ++y) {
		for (size_t z = 0; z < zl; ++z) {
			for (size_t x = 0; x < xl; ++x) {
				const size_t i = yl * zl * x + zl * y + z;

				if (m2c.grid[i >> 3] & (1 << (i & 7))) {
					std::cout << (long int)(x - xr) << ',' << (long int)(y - yr) << ',' << (long int)(z - zr) << std::endl;
				}
			}
		}
	}
}

int main(int argc, char *argv[]) {
	mesh2cubes m2c;

	read(m2c);
	m2c.translate();
	m2c.triangles();
	print(m2c);

	return 0;
}
