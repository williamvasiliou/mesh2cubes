with Ada.Containers.Vectors;
with Ada.Containers.Ordered_Sets;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Strings.Unbounded;

use Ada.Containers;

package mesh2cubes is
	type Double is digits 17 range -1.7976931348623157e+308 .. 1.7976931348623157e+308;
	package Math is new Ada.Numerics.Generic_Elementary_Functions (Double);
	package Doubles is new Vectors (Positive, Double);
	package Indices is new Vectors (Positive, Natural);
	package SU renames Ada.Strings.Unbounded;
	use type SU.Unbounded_String;
	package Grid3 is new Ordered_Sets (SU.Unbounded_String);
	type Vector3d is array (1 .. 3) of Double;

	size: Natural := 0;
	vertices: Doubles.Vector := Doubles.Empty_Vector;
	elements: Indices.Vector := Indices.Empty_Vector;
	grid: Grid3.Set := Grid3.Empty_Set;
	min: Vector3d := (0.0, 0.0, 0.0);
	max: Vector3d := (0.0, 0.0, 0.0);
	mid: Vector3d := (0.0, 0.0, 0.0);
	c: Double := 0.0;
	t: Double := 0.0;
	xr: Natural := 0;
	yr: Natural := 0;
	zr: Natural := 0;

	function length (v1: in Vector3d) return Double;
	procedure translate;
	procedure cube (v1: in Vector3d);
	procedure triangle (a: in Natural; b: in Natural; c: in Natural);
	procedure triangles;
end mesh2cubes;
