{
	vertices[++size] = $0;
}

END {
	size = 3 * floor(length(vertices) / 9);

	for (i = 0; i < size; i += 3) {
		elements[i + 1] = i;
		elements[i + 2] = i + 1;
		elements[i + 3] = i + 2;
	}

	translate();
	triangles();

	print max[1] "," max[2] "," max[3] "," t "," c;
	print xr "," yr "," zr;

	for (cube in grid) {
		print cube;
	}
}
