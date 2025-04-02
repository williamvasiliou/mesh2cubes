#!/usr/bin/env python3

if __name__ == '__main__':
    from sys import path, stdin
    path.append('../../src/python')
    from mesh2cubes import mesh2cubes

    m2c: mesh2cubes = mesh2cubes()
    s: str = stdin.readline()
    while len(s) > 0:
        m2c.vertices.append(float(s))
        s = stdin.readline()

    m2c.size = 3 * (len(m2c.vertices) // 9)
    for i in range(0, m2c.size, 3):
        m2c.elements.append(i)
        m2c.elements.append(i + 1)
        m2c.elements.append(i + 2)

    m2c.translate()
    m2c.triangles()

    print(f'{m2c.max[0]},{m2c.max[1]},{m2c.max[2]},{m2c.t},{m2c.c}')
    print(f'{m2c.xr},{m2c.yr},{m2c.zr}')
    for cube in m2c.grid:
        print(cube)
