export class mesh2cubes {
	constructor() {
		this.size = 0;
		this.vertices = [];
		this.elements = [];
		this.grid = {};
		this.min = [0.0, 0.0, 0.0];
		this.max = [0.0, 0.0, 0.0];
		this.mid = [0.0, 0.0, 0.0];
		this.c = 1.0;
		this.t = 1.0;
		this.xr = 0;
		this.yr = 0;
		this.zr = 0;
	}

	static length(v1) {
		return Math.sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
	}

	translate() {
		if (this.size > 0) {
			this.min = [this.vertices[0], this.vertices[1], this.vertices[2]];
			this.max = [this.vertices[0], this.vertices[1], this.vertices[2]];

			for (let i = 1; i < this.size; ++i) {
				const x = this.vertices[3 * i];
				const y = this.vertices[3 * i + 1];
				const z = this.vertices[3 * i + 2];

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
			this.mid = [this.min[0] / 2.0 + this.max[0] / 2.0, this.min[1] / 2.0 + this.max[1] / 2.0, this.min[2] / 2.0 + this.max[2] / 2.0];

			for (let i = 0; i < this.size; ++i) {
				this.vertices[3 * i] -= this.mid[0];
				this.vertices[3 * i + 1] -= this.mid[1];
				this.vertices[3 * i + 2] -= this.mid[2];
			}
			this.max[0] -= this.mid[0];
			this.max[1] -= this.mid[1];
			this.max[2] -= this.mid[2];
			this.c = mesh2cubes.length(this.max) / 25.0;
			this.t = this.c;
			this.xr = Math.ceil(this.max[0] / this.c - 0.5);
			this.yr = Math.ceil(this.max[1] / this.c - 0.5);
			this.zr = Math.ceil(this.max[2] / this.c - 0.5);
		}
	}

	cube(v1) {
		const x = Math.floor(v1[0] / this.c + 0.5);
		const y = Math.floor(v1[1] / this.c + 0.5);
		const z = Math.floor(v1[2] / this.c + 0.5);

		this.grid[`${x},${y},${z}`] = true;
	}

	triangle(a, b, c) {
		const A = [this.vertices[3 * a], this.vertices[3 * a + 1], this.vertices[3 * a + 2]];
		const B = [this.vertices[3 * b], this.vertices[3 * b + 1], this.vertices[3 * b + 2]];
		const C = [this.vertices[3 * c], this.vertices[3 * c + 1], this.vertices[3 * c + 2]];
		let u = [B[0] - A[0], B[1] - A[1], B[2] - A[2]];
		let v = [C[0] - A[0], C[1] - A[1], C[2] - A[2]];
		const IIuII = mesh2cubes.length(u);
		const IIvII = mesh2cubes.length(v);

		if (IIuII > 0.0 && IIvII > 0.0) {
			const dy1 = Math.min(1.0, this.t / IIuII);
			const dy2 = Math.min(1.0, this.t / IIvII);
			u[0] *= dy1;
			u[1] *= dy1;
			u[2] *= dy1;
			v[0] *= dy2;
			v[1] *= dy2;
			v[2] *= dy2;
			let U = [A[0], A[1], A[2]];

			for (let y1 = 0.0; y1 <= 1.0; y1 += dy1) {
				let V = [U[0], U[1], U[2]];

				for (let y2 = 0.0; y1 + y2 <= 1.0; y2 += dy2) {
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

	triangles() {
		for (let i = 0; i < this.elements.length; i += 3) {
			this.triangle(this.elements[i], this.elements[i + 1], this.elements[i + 2]);
		}
	}
}
