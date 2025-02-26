import java.util.ArrayList;

public final class Static {
	public static final Header header(ArrayList<String> lines, String error) {
		final double[] v = new double[] {0.0, 0.0, 0.0, 0.0, 0.0};
		final int[] r = new int[] {0, 0, 0};

		char[] line = lines.get(0).toCharArray();
		String s = "";
		int i = 0;

		for (char c : line) {
			if (c == ',') {
				assert i < v.length : error;
				assert s.length() > 0 : error;
				v[i++] = Double.valueOf(s);

				s = "";
			} else {
				s += c;
			}
		}

		assert i == v.length - 1 : error;
		assert s.length() > 0 : error;
		v[i++] = Double.valueOf(s);

		line = lines.get(1).toCharArray();
		s = "";
		int j = 0;

		for (char c : line) {
			if (c == ',') {
				assert j < r.length : error;
				assert s.length() > 0 : error;
				r[j++] = Integer.valueOf(s);

				s = "";
			} else {
				s += c;
			}
		}

		assert j == r.length - 1 : error;
		assert s.length() > 0 : error;
		r[j++] = Integer.valueOf(s);

		if (i == v.length && j == r.length) {
			return new Header(v[0], v[1], v[2], v[3], v[4], r[0], r[1], r[2], error);
		} else {
			return null;
		}
	}

	public static final Cubes cubes(ArrayList<String> lines, String error) {
		final int size = lines.size();
		assert size > 2 : error;

		final Cubes cubes = new Cubes();
		for (int i = 2; i < size; ++i) {
			final int[] r = new int[] {0, 0, 0};
			final char[] line = lines.get(i).toCharArray();

			String s = "";
			int j = 0;

			for (char c : line) {
				if (c == ',') {
					assert j < r.length : error;
					assert s.length() > 0 : error;
					r[j++] = Integer.valueOf(s);

					s = "";
				} else {
					s += c;
				}
			}

			assert j == r.length - 1 : error;
			assert s.length() > 0 : error;
			r[j++] = Integer.valueOf(s);

			if (j == r.length) {
				cubes.add(new Cube(r[0], r[1], r[2]));
			}
		}

		return cubes;
	}

	public static final Document getDocument(ArrayList<String> lines, String error) {
		final Header header = header(lines, error);
		assert header != null : error;

		final int xr = header.xr;
		final int yr = header.yr;
		final int zr = header.zr;

		final int xl = 2 * xr + 1;
		final int yl = 2 * yr + 1;
		final int zl = 2 * zr + 1;

		final Cubes cubes = cubes(lines, error);
		assert cubes.size() > 0: error;

		final Document document = new Document();
		document.setName("html", "lang=\"en\"");

		final Document head = new Document();
		head.setName("head");
		head.addChild(new Document(new String[] {
			"<meta charset=\"UTF-8\" />",
			"<meta name=\"viewport\" content=\"width=device-width, scale=1.0\" />",
			"<title>mesh2cubes</title>",
		}));

		final Document style = new Document();
		style.setName("style");
		style.addChild(new Document(new String[] {
			"div {",
			"\twhite-space: pre;",
			"}",
			"",
			"table,",
			"tr,",
			"td {",
			"\tborder-collapse: collapse;",
			"\tpadding: 0;",
			"}",
			"",
			"td {",
			"\tdisplay: inline-block;",
			"\twidth: 2em;",
			"\theight: 2em;",
			"}",
			"",
			"span {",
			"\tdisplay: inline-block;",
			"\twidth: 100%;",
			"\theight: 100%;",
			"}",
			"",
			".cube {",
			"\tbackground: #000;",
			"}",
		}));
		head.addChild(style);

		final Document body = new Document();
		body.setName("body");
		body.addChild(header.render());
		body.addChild(new Document("<br>"));
		body.addChild(new Document(String.format("<input id=\"layerY\" max=\"%d\" min=\"%d\" placeholder=\"0\" type=\"number\" value=\"%d\" />", yr, -yr, -yr)));
		body.addChild(new Document("<hr>"));

		final Document div = new Document();
		div.setName("div");
		body.addChild(div);

		final Document table = new Document();
		table.setName("table", "id=\"grid\"");
		table.addChild(cubes.render(zr, xr, -xr, -yr, -zr));
		div.addChild(table);

		final Document script = new Document();
		script.setName("script");
		script.addChild(new Document(new String[] {
			String.format("const x = %g;", header.x),
			String.format("const y = %g;", header.y),
			String.format("const z = %g;", header.z),
			String.format("const t = %g;", header.t),
			String.format("const c = %g;", header.c),
			"",
			"const grid = document.getElementById(\"grid\");",
			String.format("const xr = %d;", xr),
			String.format("const yr = %d;", yr),
			String.format("const zr = %d;", zr),
			String.format("const xl = %d;", xl),
			String.format("const yl = %d;", yl),
			String.format("const zl = %d;", zl),
			"",
			String.format("const cubes = %s;", cubes.toString()),
			"",
			"const layer = (y) => ([cubeX, cubeY, cubeZ]) => cubeY == y;",
			"",
			"const layerString = ([cubeX, cubeY, cubeZ]) => String(cubeZ).concat(\",\").concat(String(cubeX));",
			"",
			"function render(y) {",
			"\tif (!isFinite(y) || y < -yr || y > yr) {",
			"\t\treturn;",
			"\t}",
			"",
			"\tconst set = cubes.filter(layer(y)).map(layerString).reduce((cubes, cube) => ({",
			"\t\t...cubes,",
			"\t\t[cube]: 1,",
			"\t}), {});",
			"",
			"\tgrid.innerText = \"\";",
			"\tconst tbody = document.createElement(\"tbody\");",
			"",
			"\tfor (let i = -zr; i < zr; ++i) {",
			"\t\tconst tr = document.createElement(\"tr\");",
			"",
			"\t\tfor (let j = -xr; j < xr; ++j) {",
			"\t\t\tconst td = document.createElement(\"td\");",
			"\t\t\tconst span = document.createElement(\"span\");",
			"",
			"\t\t\tif (String(i).concat(\",\").concat(String(j)) in set) {",
			"\t\t\t\tspan.setAttribute(\"class\", \"cube\");",
			"\t\t\t}",
			"",
			"\t\t\ttd.appendChild(span);",
			"\t\t\ttr.appendChild(td);",
			"\t\t}",
			"",
			"\t\ttbody.appendChild(tr);",
			"\t}",
			"",
			"\tgrid.appendChild(tbody);",
			"}",
			"",
			"document.getElementById(\"layerY\").addEventListener(\"change\", (e) => {",
			"\trender(parseInt(e.target.value));",
			"});",
		}));
		body.addChild(script);

		document.addChild(head);
		document.addChild(body);
		return document;
	}

	public static final String format(Document document) {
		return String.format("<!doctype html>\n%s", document.toString());
	}
}
