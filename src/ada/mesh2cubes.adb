package body mesh2cubes is
	function length (v1: in Vector3d) return Double is
	begin
		return Math.Sqrt (v1 (1) * v1 (1) + v1 (2) * v1 (2) + v1 (3) * v1 (3));
	end length;

	procedure translate is
		i: Natural := 0;
		x: Double := 0.0;
		y: Double := 0.0;
		z: Double := 0.0;
	begin
		if size > 0 then
			min := (vertices.Element (1), vertices.Element (2), vertices.Element (3));
			max := (vertices.Element (1), vertices.Element (2), vertices.Element (3));

			i := 1;
			while i < size loop
				x := vertices.Element (3 * i + 1);
				y := vertices.Element (3 * i + 2);
				z := vertices.Element (3 * i + 3);

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

			i := 0;
			while i < size loop
				vertices.Replace_Element (3 * i + 1, vertices.Element (3 * i + 1) - mid (1));
				vertices.Replace_Element (3 * i + 2, vertices.Element (3 * i + 2) - mid (2));
				vertices.Replace_Element (3 * i + 3, vertices.Element (3 * i + 3) - mid (3));
				i := i + 1;
			end loop;
			max (1) := max (1) - mid (1);
			max (2) := max (2) - mid (2);
			max (3) := max (3) - mid (3);
			c := length (max) / 25.0;
			t := c;
			xr := Natural (Double'Ceiling (max (1) / c - 0.5));
			yr := Natural (Double'Ceiling (max (2) / c - 0.5));
			zr := Natural (Double'Ceiling (max (3) / c - 0.5));
		end if;
	end translate;

	procedure cube (v1: in Vector3d) is
		x: constant Natural := Natural (Double'Floor (v1 (1) / c + 0.5) + Double (xr));
		y: constant Natural := Natural (Double'Floor (v1 (2) / c + 0.5) + Double (yr));
		z: constant Natural := Natural (Double'Floor (v1 (3) / c + 0.5) + Double (zr));
	begin
		grid.Insert (SU.To_Unbounded_String (x'Image & "," & y'Image & "," & z'Image));
	end cube;

	procedure triangle (a: in Natural; b: in Natural; c: in Natural) is
		AA: constant Vector3d := (vertices.Element (3 * a + 1), vertices.Element (3 * a + 2), vertices.Element (3 * a + 3));
		BB: constant Vector3d := (vertices.Element (3 * b + 1), vertices.Element (3 * b + 2), vertices.Element (3 * b + 3));
		CC: constant Vector3d := (vertices.Element (3 * c + 1), vertices.Element (3 * c + 2), vertices.Element (3 * c + 3));
		u: Vector3d := (BB (1) - AA (1), BB (2) - AA (2), BB (3) - AA (3));
		v: Vector3d := (CC (1) - AA (1), CC (2) - AA (2), CC (3) - AA (3));
		IIuII: Double := length (u);
		IIvII: Double := length (v);
		dy1: Double := 0.0;
		dy2: Double := 0.0;
		UU: Vector3d := (0.0, 0.0, 0.0);
		y1: Double := 0.0;
		VV: Vector3d := (0.0, 0.0, 0.0);
		y2: Double := 0.0;
	begin
		if IIuII > 0.0 and then IIvII > 0.0 then
			dy1 := t / IIuII;

			if dy1 > 1.0 then
				dy1 := 1.0;
			end if;
			dy2 := t / IIvII;

			if dy2 > 1.0 then
				dy2 := 1.0;
			end if;
			u (1) := u (1) * dy1;
			u (2) := u (2) * dy1;
			u (3) := u (3) * dy1;
			v (1) := v (1) * dy2;
			v (2) := v (2) * dy2;
			v (3) := v (3) * dy2;
			UU := AA (1 .. 3);

			y1 := 0.0;
			while y1 <= 1.0 loop
				VV := UU (1 .. 3);

				y2 := 0.0;
				while y1 + y2 <= 1.0 loop
					cube (VV);
					VV (1) := VV (1) + v (1);
					VV (2) := VV (2) + v (2);
					VV (3) := VV (3) + v (3);
					y2 := y2 + dy2;
				end loop;
				UU (1) := UU (1) + u (1);
				UU (2) := UU (2) + u (2);
				UU (3) := UU (3) + u (3);
				y1 := y1 + dy1;
			end loop;
		end if;
	end triangle;

	procedure triangles is
		i: Count_Type := 0;
		count: constant Count_Type := elements.Length;
	begin
		i := 0;
		while i < count loop
			triangle (elements.Element (Positive (i + 1)), elements.Element (Positive (i + 2)), elements.Element (Positive (i + 3)));
			i := i + 3;
		end loop;
	end triangles;
end mesh2cubes;
