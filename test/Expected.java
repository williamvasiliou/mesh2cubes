import java.util.ArrayList;
import java.util.HashSet;

public final class Expected {
	private static final double epsilon = 1e-5;

	private final double x;
	private final double y;
	private final double z;
	private final double t;
	private final double c;

	private final int xr;
	private final int yr;
	private final int zr;

	private final HashSet<String> expected;

	public Expected(double x, double y, double z, double t, double c, int xr, int yr, int zr) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.t = t;
		this.c = c;

		this.xr = xr;
		this.yr = yr;
		this.zr = zr;

		this.expected = new HashSet<String>();
	}

	public final void expect(String s) {
		this.expected.add(s);
	}

	public final boolean actual(double x, double y, double z, double t, double c, int xr, int yr, int zr) {
		return (
			Math.abs(x - this.x) < epsilon &&
			Math.abs(y - this.y) < epsilon &&
			Math.abs(z - this.z) < epsilon &&
			Math.abs(t - this.t) < epsilon &&
			Math.abs(c - this.c) < epsilon &&
			xr == this.xr &&
			yr == this.yr &&
			zr == this.zr
		);
	}

	public final boolean actual(String s) {
		if (this.expected.contains(s)) {
			this.expected.remove(s);

			return true;
		}

		return false;
	}

	public final boolean actual(ArrayList<String> lines, String error) {
		final int size = lines.size();

		assert size > 1 : error;
		assert size == this.expected.size() + 2 : error;

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
		v[i] = Double.valueOf(s);

		line = lines.get(1).toCharArray();
		s = "";
		i = 0;

		for (char c : line) {
			if (c == ',') {
				assert i < r.length : error;
				assert s.length() > 0 : error;
				r[i++] = Integer.valueOf(s);

				s = "";
			} else {
				s += c;
			}
		}

		assert i == r.length - 1 : error;
		assert s.length() > 0 : error;
		r[i] = Integer.valueOf(s);

		assert this.actual(v[0], v[1], v[2], v[3], v[4], r[0], r[1], r[2]) : error;

		for (i = 2; i < size; ++i) {
			assert this.actual(lines.get(i)) : error;
		}

		assert this.expected.size() == 0 : error;
		return true;
	}
}
