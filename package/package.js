// const del = require("del"),
//   makeDir = require("make-dir"),
//   cpy = require("cpy");
const pkg = require("../package.json"),
   arch = require("arch"),
   path = require("path"),
   fs = require("fs"),
   cpy = require("cpy"),
   archiver = require("archiver")

const zipfile = `sedlex-ppx-v${pkg.version}-${process.platform}-${arch()}.zip`,
   build_dir = "_build/install/default/lib/sedlex/ppx/",
   zip_dir = "sedlex-ppx/",
   exe = "ppx.exe"

// FIXME: Does any of these even work on Windows
;(async () => {
   // Copy the executable,
   console.log(path.join(build_dir, exe) + " -> " + zip_dir)
   await cpy(path.join(build_dir, exe), zip_dir)

   // Create a zip-archive,
   console.log(path.join(zip_dir, exe) + " -> " + path.join(__dirname, "..", zipfile))
   const output = fs.createWriteStream(path.join(__dirname, "..", zipfile)),
      archive = archiver("zip", { zlib: { level: 9 } })

   output.on("close", function() {
      console.log(">> Zipped: " + archive.pointer() + " total bytes")
   })

   archive.pipe(output)
   archive.directory(zip_dir, false)
   archive.finalize()
})()
