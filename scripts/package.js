// This is run on Travis, and presumably eventually AppVeyor, builds. It's supposed to be as
// cross-platform as possible, unlike the adjacent release-script, which I only care if *I* can run.
const pkg = require("../package.json"),
   arch = require("arch"),
   path = require("path"),
   fs = require("fs"),
   cpy = require("cpy"),
   makeDir = require("make-dir"),
   archiver = require("archiver")

const zipfile = `ppx-sedlex-v${pkg.version}-${process.platform}-${arch()}.zip`,
   dist_dir = "dist/",
   submodule_ppx_dir = `ppx-sedlex/ppx-sedlex-v${pkg.version}-${process.platform}-${arch()}/`
   build_dir = "_build/install/default/lib/sedlex/ppx/",
   zip_dir = "ppx/",
   exe = "ppx.exe"

// FIXME: Does any of these even work on Windows
;(async () => {
   // Copy the executable to the submodule,
   console.log(path.join(build_dir, exe) + " -> " + submodule_ppx_dir)
   await cpy(path.join(build_dir, exe), submodule_ppx_dir)

   // ... and again to the zip-directory,
   console.log(path.join(build_dir, exe) + " -> " + zip_dir)
   await cpy(path.join(build_dir, exe), zip_dir)

   // Create a zip-archive,
   const dist = await makeDir(dist_dir)
   console.log(path.join(zip_dir, exe) + " >>> " + path.join(dist, zipfile))
   const output = fs.createWriteStream(path.join(dist, zipfile)),
      archive = archiver("zip", { zlib: { level: 9 } })

   output.on("close", function() {
      console.log(">> Zipped: " + archive.pointer() + " total bytes")
   })

   archive.pipe(output)
   archive.directory(zip_dir, false)
   archive.finalize()
})()
