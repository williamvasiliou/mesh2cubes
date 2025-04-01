package main

import . "mesh2cubes"
import "bufio"
import "fmt"
import "os"

func Read(m2c *T) {
	var r *bufio.Reader = bufio.NewReader(os.Stdin)
	var s string = ""
	var err error = nil
	var v float64 = 0.0

	for err == nil {
		s, err = r.ReadString('\n')
		fmt.Sscanf(s, "%f", &v)
		m2c.Vertices = append(m2c.Vertices, v)
	}

	m2c.Size = 3 * uint64(len(m2c.Vertices) / 9)

	var i uint64 = 0
	for i = 0; i < m2c.Size; i += 3 {
		m2c.Elements = append(m2c.Elements, i, i + 1, i + 2)
	}
}

func Print(m2c *T) {
	fmt.Printf("%f,%f,%f,%f,%f\n", m2c.Max[0], m2c.Max[1], m2c.Max[2], m2c.T, m2c.C)
	fmt.Printf("%d,%d,%d\n", m2c.Xr, m2c.Yr, m2c.Zr)

	var key string = ""
	for key = range m2c.Grid {
		fmt.Printf("%s\n", key)
	}
}

func main() {
	var m2c *T = New()
	Read(m2c)
	Translate(m2c)
	Triangles(m2c)
	Print(m2c)
}
