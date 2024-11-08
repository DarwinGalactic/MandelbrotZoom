using PackageCompiler

app_name = "MandelbrotZoom"

# Define source and output paths
source_path = app_name       # Your main source directory
output_path = "output/$(app_name).app/Contents"  # Output directory for the .app bundle

# Create the app bundle

create_app(
    source_path,
    output_path,
    #include_transitive_dependencies = true,
    #include_lazy_artifacts = true,
    #force = true,
    incremental = true,
)

# Build .app Bundle Structure

println("Add icon")
resources_path = joinpath(output_path, "Resources")
mkpath(resources_path)
icon_path = "MandelbrotZoom/art/MandelbrotZoom.icns"
cp(icon_path, joinpath(resources_path, "icon.icns"), force = true)

# Create `Info.plist` for macOS metadata
info_plist = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$(app_name)</string>
    <key>CFBundleDisplayName</key>
    <string>$(app_name)</string>
    <key>CFBundleIdentifier</key>
    <string>com.darwingalactic.mandelbrotzoom</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>$(app_name)</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
"""
plist_path = joinpath(output_path, "Info.plist")
open(plist_path, "w") do f
    write(f, info_plist)
end
println("Info.plist created successfully.")

macos_path = joinpath(output_path, "MacOS")
mkpath(macos_path)
mv(joinpath(output_path, "bin/$(app_name)"),
   joinpath(macos_path, app_name))
println("completed moving the binary into position for MacOS app bundle")

# TODO
# do code signing
