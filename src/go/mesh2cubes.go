package mesh2cubes

import "fmt"
import "math"

type T struct {
	Size uint64
	Vertices []float64
	Elements []uint64
	Grid map[string]bool
	Min [3]float64
	Max [3]float64
	Mid [3]float64
	C float64
	T float64
	Xr uint64
	Yr uint64
	Zr uint64
}

func New() *T {
	var m2c *T = new(T)
	m2c.Size = 0
	m2c.Grid = make(map[string]bool)
	m2c.Min = [3]float64 {0.0, 0.0, 0.0}
	m2c.Max = [3]float64 {0.0, 0.0, 0.0}
	m2c.Mid = [3]float64 {0.0, 0.0, 0.0}
	m2c.C = 1.0
	m2c.T = 1.0
	m2c.Xr = 0
	m2c.Yr = 0
	m2c.Zr = 0
	return m2c
}

func Length(v1 [3]float64) float64 {
	return math.Sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2])
}

func Translate(m2c *T) {
	var i uint64 = 0

	if m2c.Size > 0 {
		m2c.Min = [3]float64 {m2c.Vertices[0], m2c.Vertices[1], m2c.Vertices[2]}
		m2c.Max = [3]float64 {m2c.Vertices[0], m2c.Vertices[1], m2c.Vertices[2]}

		for i = 1; i < m2c.Size; i += 1 {
			var x float64 = m2c.Vertices[3 * i]
			var y float64 = m2c.Vertices[3 * i + 1]
			var z float64 = m2c.Vertices[3 * i + 2]

			if x < m2c.Min[0] {
				m2c.Min[0] = x
			}

			if y < m2c.Min[1] {
				m2c.Min[1] = y
			}

			if z < m2c.Min[2] {
				m2c.Min[2] = z
			}

			if x > m2c.Max[0] {
				m2c.Max[0] = x
			}

			if y > m2c.Max[1] {
				m2c.Max[1] = y
			}

			if z > m2c.Max[2] {
				m2c.Max[2] = z
			}
		}
		m2c.Mid = [3]float64 {m2c.Min[0] / 2.0 + m2c.Max[0] / 2.0, m2c.Min[1] / 2.0 + m2c.Max[1] / 2.0, m2c.Min[2] / 2.0 + m2c.Max[2] / 2.0}

		for i = 0; i < m2c.Size; i += 1 {
			m2c.Vertices[3 * i] -= m2c.Mid[0]
			m2c.Vertices[3 * i + 1] -= m2c.Mid[1]
			m2c.Vertices[3 * i + 2] -= m2c.Mid[2]
		}
		m2c.Max[0] -= m2c.Mid[0]
		m2c.Max[1] -= m2c.Mid[1]
		m2c.Max[2] -= m2c.Mid[2]
		m2c.C = Length(m2c.Max) / 25.0
		m2c.T = m2c.C
		m2c.Xr = uint64(math.Ceil(m2c.Max[0] / m2c.C - 0.5))
		m2c.Yr = uint64(math.Ceil(m2c.Max[1] / m2c.C - 0.5))
		m2c.Zr = uint64(math.Ceil(m2c.Max[2] / m2c.C - 0.5))
	}
}

func Cube(m2c *T, v1 [3]float64) {
	var x int64 = int64(math.Floor(v1[0] / m2c.C + 0.5))
	var y int64 = int64(math.Floor(v1[1] / m2c.C + 0.5))
	var z int64 = int64(math.Floor(v1[2] / m2c.C + 0.5))

	m2c.Grid[fmt.Sprintf("%d,%d,%d", x, y, z)] = true
}

func Triangle(m2c *T, a uint64, b uint64, c uint64) {
	var A [3]float64 = [3]float64 {m2c.Vertices[3 * a], m2c.Vertices[3 * a + 1], m2c.Vertices[3 * a + 2]}
	var B [3]float64 = [3]float64 {m2c.Vertices[3 * b], m2c.Vertices[3 * b + 1], m2c.Vertices[3 * b + 2]}
	var C [3]float64 = [3]float64 {m2c.Vertices[3 * c], m2c.Vertices[3 * c + 1], m2c.Vertices[3 * c + 2]}
	var u [3]float64 = [3]float64 {B[0] - A[0], B[1] - A[1], B[2] - A[2]}
	var v [3]float64 = [3]float64 {C[0] - A[0], C[1] - A[1], C[2] - A[2]}
	var IIuII float64 = Length(u)
	var IIvII float64 = Length(v)
	var y1 float64 = 0.0
	var y2 float64 = 0.0

	if IIuII > 0.0 && IIvII > 0.0 {
		var dy1 float64 = math.Min(1.0, m2c.T / IIuII)
		var dy2 float64 = math.Min(1.0, m2c.T / IIvII)
		u[0] *= dy1
		u[1] *= dy1
		u[2] *= dy1
		v[0] *= dy2
		v[1] *= dy2
		v[2] *= dy2
		var U [3]float64 = [3]float64 {A[0], A[1], A[2]}

		for y1 = 0.0; y1 <= 1.0; y1 += dy1 {
			var V [3]float64 = [3]float64 {U[0], U[1], U[2]}

			for y2 = 0.0; y1 + y2 <= 1.0; y2 += dy2 {
				Cube(m2c, V)
				V[0] += v[0]
				V[1] += v[1]
				V[2] += v[2]
			}
			U[0] += u[0]
			U[1] += u[1]
			U[2] += u[2]
		}
	}
}

func Triangles(m2c *T) {
	var i uint64 = 0
	var count uint64 = uint64(len(m2c.Elements))

	for i = 0; i < count; i += 3 {
		Triangle(m2c, m2c.Elements[i], m2c.Elements[i + 1], m2c.Elements[i + 2])
	}
}
