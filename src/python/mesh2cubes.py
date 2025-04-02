#!/usr/bin/env python3

from math import ceil, floor, sqrt

class mesh2cubes:
	def __init__(self):
		self.size: int = 0
		self.vertices: list[float] = []
		self.elements: list[int] = []
		self.grid: set[str] = set()
		self.min: list[float] = [0.0, 0.0, 0.0]
		self.max: list[float] = [0.0, 0.0, 0.0]
		self.mid: list[float] = [0.0, 0.0, 0.0]
		self.c: float = 1.0
		self.t: float = 1.0
		self.xr: int = 0
		self.yr: int = 0
		self.zr: int = 0

	@staticmethod
	def length(v1: list[float]) -> float:
		return sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2])

	def translate(self) -> None:
		if self.size > 0:
			self.min = self.vertices[0:3]
			self.max = self.vertices[0:3]

			i: int = 1
			while i < self.size:
				x: float = self.vertices[3 * i]
				y: float = self.vertices[3 * i + 1]
				z: float = self.vertices[3 * i + 2]

				if x < self.min[0]:
					self.min[0] = x

				if y < self.min[1]:
					self.min[1] = y

				if z < self.min[2]:
					self.min[2] = z

				if x > self.max[0]:
					self.max[0] = x

				if y > self.max[1]:
					self.max[1] = y

				if z > self.max[2]:
					self.max[2] = z
				i += 1
			self.mid = [self.min[0] / 2.0 + self.max[0] / 2.0, self.min[1] / 2.0 + self.max[1] / 2.0, self.min[2] / 2.0 + self.max[2] / 2.0]

			i: int = 0
			while i < self.size:
				self.vertices[3 * i] -= self.mid[0]
				self.vertices[3 * i + 1] -= self.mid[1]
				self.vertices[3 * i + 2] -= self.mid[2]
				i += 1
			self.max[0] -= self.mid[0]
			self.max[1] -= self.mid[1]
			self.max[2] -= self.mid[2]
			self.c = self.length(self.max) / 25.0
			self.t = self.c
			self.xr = ceil(self.max[0] / self.c - 0.5)
			self.yr = ceil(self.max[1] / self.c - 0.5)
			self.zr = ceil(self.max[2] / self.c - 0.5)

	def cube(self, v1: list[float]) -> None:
		x: int = floor(v1[0] / self.c + 0.5)
		y: int = floor(v1[1] / self.c + 0.5)
		z: int = floor(v1[2] / self.c + 0.5)

		self.grid.add(f'{x},{y},{z}')

	def triangle(self, a: int, b: int, c: int) -> None:
		A: list[float] = self.vertices[3 * a:3 * a + 3]
		B: list[float] = self.vertices[3 * b:3 * b + 3]
		C: list[float] = self.vertices[3 * c:3 * c + 3]
		u: list[float] = [B[0] - A[0], B[1] - A[1], B[2] - A[2]]
		v: list[float] = [C[0] - A[0], C[1] - A[1], C[2] - A[2]]
		IIuII: float = self.length(u)
		IIvII: float = self.length(v)

		if IIuII > 0.0 and IIvII > 0.0:
			dy1: float = min(1.0, self.t / IIuII)
			dy2: float = min(1.0, self.t / IIvII)
			u[0] *= dy1
			u[1] *= dy1
			u[2] *= dy1
			v[0] *= dy2
			v[1] *= dy2
			v[2] *= dy2
			U: list[float] = A[0:3]

			y1: float = 0.0
			while y1 <= 1.0:
				V: list[float] = U[0:3]

				y2: float = 0.0
				while y1 + y2 <= 1.0:
					self.cube(V)
					V[0] += v[0]
					V[1] += v[1]
					V[2] += v[2]
					y2 += dy2
				U[0] += u[0]
				U[1] += u[1]
				U[2] += u[2]
				y1 += dy1

	def triangles(self) -> None:
		i: int = 0
		while i < len(self.elements):
			self.triangle(self.elements[i], self.elements[i + 1], self.elements[i + 2])
			i += 3
