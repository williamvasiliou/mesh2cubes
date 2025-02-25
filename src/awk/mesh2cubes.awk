BEGIN {
	size = 0;
	min[1] = 0.0;
	min[2] = 0.0;
	min[3] = 0.0;
	max[1] = 0.0;
	max[2] = 0.0;
	max[3] = 0.0;
	mid[1] = 0.0;
	mid[2] = 0.0;
	mid[3] = 0.0;
	c = 1.0;
	t = 1.0;
	xr = 0;
	yr = 0;
	zr = 0;
}

function ceil(x, y) {
	y = x % 1;

	if (x > 0) {
		if (y > 0) {
			return x - y + 1;
		} else {
			return x;
		}
	} else {
		return x - y;
	}
}

function floor(x, y) {
	y = x % 1;

	if (x < 0) {
		if (y < 0) {
			return x - y - 1;
		} else {
			return x;
		}
	} else {
		return x - y;
	}
}

function fmin(x, y) {
	return (x < y) ? x : y;
}

function lengthVector3d(v1) {
	return sqrt(v1[1] * v1[1] + v1[2] * v1[2] + v1[3] * v1[3]);
}

function translate() {
	if (size > 0) {
		min[1] = vertices[1];
		min[2] = vertices[2];
		min[3] = vertices[3];
		max[1] = vertices[1];
		max[2] = vertices[2];
		max[3] = vertices[3];

		for (i = 1; i < size; ++i) {
			x = vertices[3 * i + 1];
			y = vertices[3 * i + 2];
			z = vertices[3 * i + 3];

			if (x < min[1]) {
				min[1] = x;
			}

			if (y < min[2]) {
				min[2] = y;
			}

			if (z < min[3]) {
				min[3] = z;
			}

			if (x > max[1]) {
				max[1] = x;
			}

			if (y > max[2]) {
				max[2] = y;
			}

			if (z > max[3]) {
				max[3] = z;
			}
		}
		mid[1] = min[1] / 2.0 + max[1] / 2.0;
		mid[2] = min[2] / 2.0 + max[2] / 2.0;
		mid[3] = min[3] / 2.0 + max[3] / 2.0;

		for (i = 0; i < size; ++i) {
			vertices[3 * i + 1] -= mid[1];
			vertices[3 * i + 2] -= mid[2];
			vertices[3 * i + 3] -= mid[3];
		}
		max[1] -= mid[1];
		max[2] -= mid[2];
		max[3] -= mid[3];
		c = lengthVector3d(max) / 25.0;
		t = c;
		xr = ceil(max[1] / c - 0.5);
		yr = ceil(max[2] / c - 0.5);
		zr = ceil(max[3] / c - 0.5);
	}
}

function addCube(v1) {
	x = floor(v1[1] / c + 0.5);
	y = floor(v1[2] / c + 0.5);
	z = floor(v1[3] / c + 0.5);
	grid[x "," y "," z] = 1;
}

function triangle(a, b, c) {
	A[1] = vertices[3 * a + 1];
	A[2] = vertices[3 * a + 2];
	A[3] = vertices[3 * a + 3];
	B[1] = vertices[3 * b + 1];
	B[2] = vertices[3 * b + 2];
	B[3] = vertices[3 * b + 3];
	C[1] = vertices[3 * c + 1];
	C[2] = vertices[3 * c + 2];
	C[3] = vertices[3 * c + 3];
	u[1] = B[1] - A[1];
	u[2] = B[2] - A[2];
	u[3] = B[3] - A[3];
	v[1] = C[1] - A[1];
	v[2] = C[2] - A[2];
	v[3] = C[3] - A[3];
	IIuII = lengthVector3d(u);
	IIvII = lengthVector3d(v);

	if (IIuII > 0.0 && IIvII > 0.0) {
		dy1 = fmin(1.0, t / IIuII);
		dy2 = fmin(1.0, t / IIvII);
		u[1] *= dy1;
		u[2] *= dy1;
		u[3] *= dy1;
		v[1] *= dy2;
		v[2] *= dy2;
		v[3] *= dy2;
		U[1] = A[1];
		U[2] = A[2];
		U[3] = A[3];

		for (y1 = 0.0; y1 <= 1.0; y1 += dy1) {
			V[1] = U[1];
			V[2] = U[2];
			V[3] = U[3];

			for (y2 = 0.0; y1 + y2 <= 1.0; y2 += dy2) {
				addCube(V);
				V[1] += v[1];
				V[2] += v[2];
				V[3] += v[3];
			}
			U[1] += u[1];
			U[2] += u[2];
			U[3] += u[3];
		}
	}
}

function triangles() {
	for (i = 0; i < length(elements); i += 3) {
		triangle(elements[i + 1], elements[i + 2], elements[i + 3]);
	}
}
