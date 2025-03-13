with mesh2cubes;
use mesh2cubes;

with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body IO is
	package T_IO renames Ada.Text_IO;

	procedure read is
		package F_IO is new T_IO.Float_IO (Double);
		v: Double := 0.0;
		i: Natural := 0;
	begin
		while not T_IO.End_Of_File loop
			F_IO.Get (T_IO.Get_Line, v, i);
			vertices.Append (v);
		end loop;

		size := 3 * Natural (Double'Floor (Double (vertices.Length) / 9.0));

		i := 0;
		while i < size loop
			elements.Append (i);
			elements.Append (i + 1);
			elements.Append (i + 2);
			i := i + 3;
		end loop;
	end read;

	procedure print is
		max1: constant Double := max (1);
		max2: constant Double := max (2);
		max3: constant Double := max (3);

		procedure process (Position: in Grid3.Cursor) is
		begin
			T_IO.Put_Line (SU.To_String (grid.Element (Position)));
		end process;

		function trim (Image: in String) return String is
			use Ada.Strings;
			use Ada.Strings.Fixed;
		begin
			return Trim (Image, Left);
		end trim;
	begin
		T_IO.Put_Line (trim (max1'Image) & "," & trim (max2'Image) & "," & trim (max3'Image) & "," & trim (t'Image) & "," & trim (c'Image));
		T_IO.Put_Line (trim (xr'Image) & "," & trim (yr'Image) & "," & trim (zr'Image));
		grid.Iterate (process'Access);
	end print;
end IO;
