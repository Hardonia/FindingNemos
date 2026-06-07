import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "fs";
import path from "path";
import os from "os";

// Following the memory directive, we import from the compiled dist folder
import { maxMtime } from "../../dist/lib/stale-dist-check.js";

describe("maxMtime", () => {
  let tmpdir: string;

  beforeEach(() => {
    tmpdir = fs.mkdtempSync(path.join(os.tmpdir(), "max-mtime-test-"));
  });

  afterEach(() => {
    fs.rmSync(tmpdir, { recursive: true, force: true });
  });

  it("returns 0 for an empty directory", () => {
    expect(maxMtime(tmpdir, () => true)).toBe(0);
  });

  it("returns 0 if the root directory does not exist", () => {
    expect(maxMtime(path.join(tmpdir, "does-not-exist"), () => true)).toBe(0);
  });

  it("finds the maximum mtime of matching files", () => {
    const file1 = path.join(tmpdir, "file1.ts");
    fs.writeFileSync(file1, "test");
    fs.utimesSync(file1, new Date(), new Date(1000));

    const file2 = path.join(tmpdir, "file2.ts");
    fs.writeFileSync(file2, "test");
    fs.utimesSync(file2, new Date(), new Date(3000));

    const file3 = path.join(tmpdir, "file3.js");
    fs.writeFileSync(file3, "test");
    fs.utimesSync(file3, new Date(), new Date(5000));

    // Match all files
    expect(maxMtime(tmpdir, () => true)).toBe(5000);

    // Match only .ts files
    expect(maxMtime(tmpdir, (name) => name.endsWith(".ts"))).toBe(3000);

    // Match only .js files
    expect(maxMtime(tmpdir, (name) => name.endsWith(".js"))).toBe(5000);
  });

  it("traverses subdirectories", () => {
    const subDir = path.join(tmpdir, "subdir");
    fs.mkdirSync(subDir);

    const file1 = path.join(subDir, "file1.ts");
    fs.writeFileSync(file1, "test");
    fs.utimesSync(file1, new Date(), new Date(2000));

    const subSubDir = path.join(subDir, "subsubdir");
    fs.mkdirSync(subSubDir);

    const file2 = path.join(subSubDir, "file2.ts");
    fs.writeFileSync(file2, "test");
    fs.utimesSync(file2, new Date(), new Date(4000));

    expect(maxMtime(tmpdir, () => true)).toBe(4000);
  });

  it("ignores node_modules and hidden directories", () => {
    const file1 = path.join(tmpdir, "file1.ts");
    fs.writeFileSync(file1, "test");
    fs.utimesSync(file1, new Date(), new Date(1000));

    const nodeModulesDir = path.join(tmpdir, "node_modules");
    fs.mkdirSync(nodeModulesDir);
    const file2 = path.join(nodeModulesDir, "file2.ts");
    fs.writeFileSync(file2, "test");
    fs.utimesSync(file2, new Date(), new Date(5000));

    const hiddenDir = path.join(tmpdir, ".hidden");
    fs.mkdirSync(hiddenDir);
    const file3 = path.join(hiddenDir, "file3.ts");
    fs.writeFileSync(file3, "test");
    fs.utimesSync(file3, new Date(), new Date(6000));

    expect(maxMtime(tmpdir, () => true)).toBe(1000);
  });

  it("skips unreadable directories without throwing", () => {
    const subDir = path.join(tmpdir, "unreadable");
    fs.mkdirSync(subDir);
    const file1 = path.join(subDir, "file1.ts");
    fs.writeFileSync(file1, "test");
    fs.utimesSync(file1, new Date(), new Date(2000));

    const file2 = path.join(tmpdir, "file2.ts");
    fs.writeFileSync(file2, "test");
    fs.utimesSync(file2, new Date(), new Date(1000));

    // Make directory unreadable
    fs.chmodSync(subDir, 0o000);

    try {
      // It should gracefully skip the unreadable directory and process file2
      expect(maxMtime(tmpdir, () => true)).toBe(1000);
    } finally {
      // Restore permissions so it can be deleted in afterEach
      fs.chmodSync(subDir, 0o755);
    }
  });
});
