import java.util.ArrayList;
import java.util.HashSet;

public final class Cubes {
	public final ArrayList<Cube> cubes;

	public Cubes() {
		this.cubes = new ArrayList<Cube>();
	}

	public void add(Cube cube) {
		this.cubes.add(cube);
	}

	public HashSet<String> layer(int y) {
		final HashSet<String> layer = new HashSet<String>();

		for (Cube cube : this.cubes) {
			if (cube.y == y) {
				layer.add(String.format("%d,%d", cube.z, cube.x));
			}
		}

		return layer;
	}

	public Document render(int zr, int xr, int x, int y, int z) {
		final Document tbody = new Document();
		tbody.setName("tbody");

		final HashSet<String> layer = this.layer(y);

		for (int i = z; i < zr; ++i) {
			final Document tr = new Document();
			tr.setName("tr");

			for (int j = x; j < xr; ++j) {
				final Document td = new Document();
				td.setName("td");
				td.addChild(new Document(String.format("<span%s></span>", layer.contains(String.format("%d,%d", i, j)) ? " class=\"cube\"" : "")));
				tr.addChild(td);
			}

			tbody.addChild(tr);
		}

		return tbody;
	}

	public int size() {
		return this.cubes.size();
	}

	public String toString() {
		final int size = this.cubes.size();
		String Result = "[";

		if (size > 1) {
			Cube cube = this.cubes.get(0);
			Result += String.format("[%d, %d, %d]", cube.x, cube.y, cube.z);

			for (int i = 1; i < size; ++i) {
				cube = this.cubes.get(i);
				Result += String.format(", [%d, %d, %d]", cube.x, cube.y, cube.z);
			}
		} else if (size > 0) {
			final Cube cube = this.cubes.get(0);
			Result += String.format("[%d, %d, %d]", cube.x, cube.y, cube.z);
		}

		return Result + "]";
	}
}
