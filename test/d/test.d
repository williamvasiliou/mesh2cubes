import mesh2cubes;

import std.conv;
import std.stdio;
import std.string;

void read(m2c_t *m2c) {
	char[] line;
	while (readln(line)) {
		m2c.vertices ~= to!double(chomp(line));
	}

	m2c.size = 3 * (m2c.vertices.length / 9);
	for (size_t i = 0; i < m2c.size; i += 3) {
		m2c.elements ~= i;
		m2c.elements ~= i + 1;
		m2c.elements ~= i + 2;
	}
}

void print(m2c_t *m2c) {
	writefln("%f,%f,%f,%f,%f", m2c.max[0], m2c.max[1], m2c.max[2], m2c.t, m2c.c);
	writefln("%u,%u,%u", m2c.xr, m2c.yr, m2c.zr);

	foreach (x; m2c.grid.keys) {
		foreach (y; m2c.grid[x].keys) {
			foreach (z; m2c.grid[x][y].keys) {
				writefln("%d,%d,%d", x, y, z);
			}
		}
	}
}

void main() {
	m2c_t m2c = new m2c_t;

	read(&m2c);
	m2c.translate;
	m2c.triangles;
	print(&m2c);
}
