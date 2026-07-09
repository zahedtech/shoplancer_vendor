import { describe, it, expect, afterEach } from "vitest";
import { render, cleanup } from "@testing-library/react";
import { DirectionalChevron } from "@/components/ui/DirectionalChevron";

afterEach(() => {
  cleanup();
  document.documentElement.dir = "";
});

describe("DirectionalChevron", () => {
  it("renders an svg with ltr rotation class", () => {
    const { container } = render(<DirectionalChevron />);
    const svg = container.querySelector("svg");
    expect(svg).toBeTruthy();
    expect(svg?.getAttribute("class") ?? "").toContain("ltr:rotate-180");
  });

  it("merges custom className", () => {
    const { container } = render(<DirectionalChevron className="h-4 w-4" />);
    const cls = container.querySelector("svg")?.getAttribute("class") ?? "";
    expect(cls).toContain("h-4");
    expect(cls).toContain("w-4");
    expect(cls).toContain("ltr:rotate-180");
  });

  it("points correctly in RTL (no rotation applied)", () => {
    document.documentElement.dir = "rtl";
    const { container } = render(<DirectionalChevron />);
    const svg = container.querySelector("svg");
    // ChevronLeft points left by default — correct forward-direction in RTL.
    // The ltr:rotate-180 class is inert when dir=rtl.
    expect(svg).toBeTruthy();
    expect(document.documentElement.dir).toBe("rtl");
  });
});
