const { mesh2cubes } = require('../../src/javascript/mesh2cubes.mjs');
const { stdin } = require('node:process');

const m2c = new mesh2cubes();
let line = "";

stdin.on('data', (data) => {
	line += data;

	let index = line.indexOf('\n');
	while (index >= 0) {
		const v = Number(line.slice(0, index));
		if (isFinite(v)) {
			m2c.vertices.push(v);
		}

		line = line.slice(index + 1);
		index = line.indexOf('\n');
	}
});

stdin.on('end', () => {
	m2c.size = 3 * Math.floor(m2c.vertices.length / 9);
	for (let i = 0; i < m2c.size; i += 3) {
		m2c.elements.push(i);
		m2c.elements.push(i + 1);
		m2c.elements.push(i + 2);
	}

	m2c.translate();
	m2c.triangles();

	console.log(`${m2c.max[0]},${m2c.max[1]},${m2c.max[2]},${m2c.t},${m2c.c}`);
	console.log(`${m2c.xr},${m2c.yr},${m2c.zr}`);

	for (const cube in m2c.grid) {
		console.log(cube);
	}
});
