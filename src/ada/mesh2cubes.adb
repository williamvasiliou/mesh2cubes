package body mesh2cubes is
	size: Index;
	vertices: double array (Positive range <>) of Double;
	elements: index array (Positive range <>) of Index;
	grid: Grid;
	min: Vector3d;
	max: Vector3d;
	mid: Vector3d;
	c: Double;
	t: Double;
	xr: Index;
	yr: Index;
	zr: Index;
	xl: Index;
	yl: Index;
	zl: Index;

	function length (v1: in Vector3d) return double is
	begin
		return sqrt (v1 (1) * v1 (1) + v1 (2) * v1 (2) + v1 (3) * v1 (3));
	end length;

	procedure translate is
	begin
		if size > 0 then
			min := vertices (1 .. 3);
			max := vertices (1 .. 3);

			i: Index := 1;
			while i < size loop
				x: constant Double := vertices (3 * i + 1);
				y: constant Double := vertices (3 * i + 2);
				z: constant Double := vertices (3 * i + 3);

				if x < min (1) then
					min (1) := x;
				end if;

				if y < min (2) then
					min (2) := y;
				end if;

				if z < min (3) then
					min (3) := z;
				end if;

				if x > max (1) then
					max (1) := x;
				end if;

				if y > max (2) then
					max (2) := y;
				end if;

				if z > max (3) then
					max (3) := z;
				end if;
				i := i + 1;
			end loop;
			mid := (min (1) / 2.0 + max (1) / 2.0, min (2) / 2.0 + max (2) / 2.0, min (3) / 2.0 + max (3) / 2.0);

			i: Index := 0;
			while i < size loop
				vertices (3 * i + 1) := vertices (3 * i + 1) - mid (1);
				vertices (3 * i + 2) := vertices (3 * i + 2) - mid (2);
				vertices (3 * i + 3) := vertices (3 * i + 3) - mid (3);
				i := i + 1;
			end loop;
			max (1) := max (1) - mid (1);
			max (2) := max (2) - mid (2);
			max (3) := max (3) - mid (3);
			c := length (max) / 25.0;
			t := c;
			xr := Ceil(max (1) / c - 0.5);
			yr := Ceil(max (2) / c - 0.5);
			zr := Ceil(max (3) / c - 0.5);
			xl := 2 * xr + 1;
			yl := 2 * yr + 1;
			zl := 2 * zr + 1;
			grid: Grid(1 .. xl, 1 .. yl, 1 .. zl) := (others => False);
		end if;
	end translate;

	procedure cube (v1: in Vector3d) is
	begin
		x: constant Index := Floor(v1 (1) / c + 0.5) + xr;
		y: constant Index := Floor(v1 (2) / c + 0.5) + yr;
		z: constant Index := Floor(v1 (3) / c + 0.5) + zr;

		grid (x, y, z) := True;
	end cube;

	procedure triangle (a: in Index, b: in Index, c: in Index) is
	begin
		A: constant Vector3d := vertices (3 * a + 1 .. 3 * a + 3);
		B: constant Vector3d := vertices (3 * b + 1 .. 3 * b + 3);
		C: constant Vector3d := vertices (3 * c + 1 .. 3 * c + 3);
		u: Vector3d := (B (1) - A (1), B (2) - A (2), B (3) - A (3));
		v: Vector3d := (C (1) - A (1), C (2) - A (2), C (3) - A (3));
		IIuII: constant Double := length (u);
		IIvII: constant Double := length (v);

		if IIuII > 0.0 and then IIvII > 0.0 then
			dy1: constant Double := Min(1.0, t / IIuII);
			dy2: constant Double := Min(1.0, t / IIvII);
			u (1) := u (1) * dy1;
			u (2) := u (2) * dy1;
			u (3) := u (3) * dy1;
			v (1) := v (1) * dy2;
			v (2) := v (2) * dy2;
			v (3) := v (3) * dy2;
			U: Vector3d := A (1 .. 3);

			y1: Double := 0.0;
			while y1 <= 1.0 loop
				V: Vector3d := U (1 .. 3);

				y2: Double := 0.0;
				while y1 + y2 <= 1.0 loop
					cube (V);
					V (1) := V (1) + v (1);
					V (2) := V (2) + v (2);
					V (3) := V (3) + v (3);
					y2 := y2 + dy2;
				end loop;
				U (1) := U (1) + u (1);
				U (2) := U (2) + u (2);
				U (3) := U (3) + u (3);
				y1 := y1 + dy1;
			end loop;
		end if;
	end triangle;

	procedure triangles is
	begin
		i: Index := 0;
		while i < elements'Range'Last loop
			triangle (elements (i + 1), elements (i + 2), elements (i + 3));
			i := i + 3;
		end loop;
	end triangles;
begin
	size: Index := 0;
	min: Vector3d := (0.0, 0.0, 0.0);
	max: Vector3d := (0.0, 0.0, 0.0);
	mid: Vector3d := (0.0, 0.0, 0.0);
	c: Double := 1.0;
	t: Double := 1.0;
	xr: Index := 0;
	yr: Index := 0;
	zr: Index := 0;
	xl: Index := 0;
	yl: Index := 0;
	zl: Index := 0;
end mesh2cubes;
