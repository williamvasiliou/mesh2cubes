import java.util.ArrayList;

public final class Document {
	private ArrayList<Document> children;
	private ArrayList<String> lines;

	public Document() {
		this.children = new ArrayList<Document>();
		this.lines = null;
	}

	public Document(String s) {
		this.children = null;
		this.lines = new ArrayList<String>();

		this.lines.add(s);
	}

	public Document(String[] s) {
		if (s == null) {
			this.children = null;
			this.lines = new ArrayList<String>();

			this.lines.add("");
		} else {
			this.children = null;
			this.lines = new ArrayList<String>();

			for (String line : s) {
				this.lines.add(line);
			}
		}
	}

	public void addChild(Document document) {
		if (document != null) {
			this.children.add(document);
		}
	}

	public void getName(String[] names) {
		if (this.lines != null) {
			final int size = this.lines.size();

			if (size > 1) {
				names[0] = this.lines.get(0);
				names[1] = this.lines.get(1);
			} else if (size > 0) {
				names[0] = this.lines.get(0);
			}
		}
	}

	public void setName(String name) {
		if (this.lines == null) {
			this.lines = new ArrayList<String>();
		}

		if (this.lines.size() == 0) {
			this.lines.add(name);
		} else {
			this.lines.set(0, name);
		}
	}

	public void setName(String name, String attributes) {
		if (this.lines == null) {
			this.lines = new ArrayList<String>();
		}

		final int size = this.lines.size();

		if (size == 0) {
			this.lines.add(name);
			this.lines.add(attributes);
		} else if (size == 1) {
			this.lines.set(0, name);
			this.lines.add(attributes);
		} else {
			this.lines.set(0, name);
			this.lines.set(1, attributes);
		}
	}

	public ArrayList<String> render() {
		final ArrayList<String> Result = new ArrayList<String>();

		if (this.children == null) {
			for (String line : this.lines) {
				Result.add(line);
			}
		} else {
			final int size = this.children.size();
			ArrayList<String> lines = null;

			final String[] names = new String[] {"", ""};
			this.getName(names);

			final String name = names[0];
			final String attributes = names[1];

			final boolean hasName = name.length() > 0;
			final boolean hasAttributes = attributes.length() > 0;

			if (hasName) {
				if (hasAttributes) {
					Result.add(String.format("<%s %s>", name, attributes));
				} else {
					Result.add(String.format("<%s>", name));
				}
			}

			for (int i = 0; i < size; ++i) {
				lines = this.children.get(i).render();

				for (String line : lines) {
					Result.add(String.format("\t%s", line));
				}
			}

			if (hasName) {
				Result.add(String.format("</%s>", name));
			}
		}

		return Result;
	}

	public String toString(ArrayList<String> lines) {
		final int size = lines.size();

		String Result = "";

		if (size > 1) {
			Result = lines.get(0);

			for (int i = 1; i < size; ++i) {
				Result += "\n" + lines.get(i);
			}
		} else if (size > 0) {
			Result = lines.get(0);
		}

		return Result;
	}

	public String toString() {
		return this.toString(this.render());
	}
}
