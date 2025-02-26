public final class Header {
	public final double x;
	public final double y;
	public final double z;
	public final double t;
	public final double c;

	public final int xr;
	public final int yr;
	public final int zr;

	public final String header;

	public Header(double x, double y, double z, double t, double c, int xr, int yr, int zr, String header) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.t = t;
		this.c = c;

		this.xr = xr;
		this.yr = yr;
		this.zr = zr;

		this.header = header;
	}

	public Document render() {
		return new Document(new String[] {
			String.format("<h1>%s</h1>", this.header),
			String.format("<div>%g, %g, %g, %g, %g</div>", this.x, this.y, this.z, this.t, this.c),
			String.format("<div>%d, %d, %d</div>", this.xr, this.yr, this.zr),
		});
	}
}
