#!/usr/bin/env python3
"""Generate the checked-in Xcode project using only the Python standard library."""
from pathlib import Path
import hashlib
import json
import plistlib

ROOT = Path(__file__).resolve().parents[1]
objects = {}

def uid(value):
    return hashlib.sha1(value.encode()).hexdigest()[:24].upper()

def obj(key, isa, **fields):
    identifier = uid(key)
    objects[identifier] = {"isa": isa, **fields}
    return identifier

def file_ref(path, kind=None):
    kinds = {".swift": "sourcecode.swift", ".xcstrings": "text.json.xcstrings",
             ".shortcut": "file", ".xcconfig": "text.xcconfig", ".plist": "text.plist.xml", ".entitlements": "text.plist.entitlements"}
    return obj("file:" + path, "PBXFileReference", lastKnownFileType=kind or kinds.get(Path(path).suffix, "text"),
               name=Path(path).name, path=path, sourceTree="SOURCE_ROOT")

base = file_ref("Config/Base.xcconfig")
package = obj("core-package", "XCLocalSwiftPackageReference", relativePath="PickupCore")
target_ids = {name: uid("target:" + name) for name in ["Pickup", "PickupWidgets", "PickupReport"]}
products = {}
all_files = {base}

for name in target_ids:
    is_app = name == "Pickup"
    info = {"CFBundleDevelopmentRegion": "$(DEVELOPMENT_LANGUAGE)", "CFBundleDisplayName": "drop it." if is_app else name,
            "CFBundleExecutable": "$(EXECUTABLE_NAME)", "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
            "CFBundleInfoDictionaryVersion": "6.0", "CFBundleName": "$(PRODUCT_NAME)",
            "CFBundlePackageType": "APPL" if is_app else "XPC!", "CFBundleShortVersionString": "$(MARKETING_VERSION)",
            "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)", "UIAppFonts": ["Caprasimo-Regular.ttf", "Figtree.ttf"], "PickupAppGroup": "$(PICKUP_APP_GROUP)"}
    if is_app:
        info.update({"NSSupportsLiveActivities": True, "LSRequiresIPhoneOS": True,
                     "PickupSigningTeam": "$(DEVELOPMENT_TEAM)",
                     "UILaunchScreen": {"UIColorName": "LaunchBackground"},
                     "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                     "CFBundleURLTypes": [{"CFBundleURLName": "pickup.session", "CFBundleURLSchemes": ["pickup"]}],
                     "ITSAppUsesNonExemptEncryption": False})
    else:
        info["NSExtension"] = {"NSExtensionPointIdentifier": "com.apple.widgetkit-extension" if name == "PickupWidgets"
                               else "com.apple.deviceactivityui.report-extension"}
    (ROOT / name / "Info.plist").write_bytes(plistlib.dumps(info, sort_keys=False))
    entitlements = {"com.apple.security.application-groups": ["$(PICKUP_APP_GROUP)"]}
    if name != "PickupWidgets": entitlements["com.apple.developer.family-controls"] = True
    (ROOT / name / (name + ".entitlements")).write_bytes(plistlib.dumps(entitlements))
    all_files.add(file_ref(f"{name}/Info.plist"))
    all_files.add(file_ref(f"{name}/{name}.entitlements"))

    shared = ["Shared/L10n.swift", "Shared/Color+Hex.swift", "Shared/DropItDesign.swift", "Shared/BrainView.swift", "Shared/DropItUsageViews.swift"]
    if name != "PickupReport": shared.append("Shared/SessionActivityAttributes.swift")
    if name != "PickupWidgets": shared.append("Shared/ReportContexts.swift")
    sources = sorted(str(p.relative_to(ROOT)) for p in (ROOT / name).glob("*.swift")) + shared
    source_builds = []
    for path in sources:
        ref = file_ref(path)
        all_files.add(ref)
        source_builds.append(obj(name + ":build:" + path, "PBXBuildFile", fileRef=ref))
    resources = ["Shared/Localizable.xcstrings", "Shared/PrivacyInfo.xcprivacy"]
    resources += sorted(str(p.relative_to(ROOT)) for p in (ROOT / "Shared/Fonts").glob("*"))
    if name != "PickupReport": resources.append("Shared/Assets.xcassets")
    if is_app:
        resources.append("Pickup/Assets.xcassets")
        resources += sorted(str(p.relative_to(ROOT)) for p in (ROOT / "Pickup/ShortcutResources").glob("*") if p.is_file())
    resource_builds = []
    for path in resources:
        ref = file_ref(path, "folder.assetcatalog" if path.endswith(".xcassets") else None)
        all_files.add(ref)
        resource_builds.append(obj(name + ":build:" + path, "PBXBuildFile", fileRef=ref))
    package_product = obj(name + ":core", "XCSwiftPackageProductDependency", package=package, productName="PickupCore")
    phases = [obj(name + ":sources", "PBXSourcesBuildPhase", buildActionMask=2147483647, files=source_builds,
                  runOnlyForDeploymentPostprocessing=0),
              obj(name + ":frameworks", "PBXFrameworksBuildPhase", buildActionMask=2147483647,
                  files=[obj(name + ":core-link", "PBXBuildFile", productRef=package_product)], runOnlyForDeploymentPostprocessing=0),
              obj(name + ":resources", "PBXResourcesBuildPhase", buildActionMask=2147483647, files=resource_builds,
                  runOnlyForDeploymentPostprocessing=0)]
    product = obj(name + ":product", "PBXFileReference", explicitFileType="wrapper.application" if is_app else "wrapper.app-extension",
                  includeInIndex=0, path=name + (".app" if is_app else ".appex"), sourceTree="BUILT_PRODUCTS_DIR")
    products[name] = product
    configs = []
    for configuration in ["Debug", "Release"]:
        settings = {"PRODUCT_BUNDLE_IDENTIFIER": "$(BUNDLE_PREFIX).pickup" + ("" if is_app else "." + name),
                    "PRODUCT_NAME": "$(TARGET_NAME)", "INFOPLIST_FILE": f"{name}/Info.plist",
                    "CODE_SIGN_ENTITLEMENTS": f"{name}/{name}.entitlements",
                    "GENERATE_INFOPLIST_FILE": "NO", "SDKROOT": "iphoneos", "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
                    "SWIFT_OPTIMIZATION_LEVEL": "-Onone" if configuration == "Debug" else "-O",
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG" if configuration == "Debug" else "",
                    "ONLY_ACTIVE_ARCH": "YES" if configuration == "Debug" else "NO",
                    "DEBUG_INFORMATION_FORMAT": "dwarf" if configuration == "Debug" else "dwarf-with-dsym",
                    "SKIP_INSTALL": "NO" if is_app else "YES", "APPLICATION_EXTENSION_API_ONLY": "NO" if is_app else "YES"}
        if is_app: settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
        configs.append(obj(name + ":" + configuration, "XCBuildConfiguration", baseConfigurationReference=base,
                           buildSettings=settings, name=configuration))
    config_list = obj(name + ":configs", "XCConfigurationList", buildConfigurations=configs,
                      defaultConfigurationIsVisible=0, defaultConfigurationName="Release")
    obj("target:" + name, "PBXNativeTarget", buildConfigurationList=config_list, buildPhases=phases,
        buildRules=[], dependencies=[], name=name, packageProductDependencies=[package_product],
        productName=name, productReference=product,
        productType="com.apple.product-type.application" if is_app else "com.apple.product-type.app-extension")

app = objects[target_ids["Pickup"]]
embed = []
for name in ["PickupWidgets", "PickupReport"]:
    proxy = obj(name + ":proxy", "PBXContainerItemProxy", containerPortal=uid("project"), proxyType=1,
                remoteGlobalIDString=target_ids[name], remoteInfo=name)
    app["dependencies"].append(obj(name + ":dependency", "PBXTargetDependency", target=target_ids[name], targetProxy=proxy))
    embed.append(obj(name + ":embed", "PBXBuildFile", fileRef=products[name], settings={"ATTRIBUTES": ["RemoveHeadersOnCopy"]}))
app["buildPhases"].append(obj("embed-extensions", "PBXCopyFilesBuildPhase", buildActionMask=2147483647,
    dstPath="", dstSubfolderSpec=13, files=embed, name="Embed App Extensions", runOnlyForDeploymentPostprocessing=0))

product_group = obj("products", "PBXGroup", children=list(products.values()), name="Products", sourceTree="<group>")
root_documents = [file_ref("README.md"), file_ref("KNOWN_TODOS.md")]
for path in sorted((ROOT / "Docs").glob("*.md")):
    all_files.add(file_ref(str(path.relative_to(ROOT))))
source_groups = []
for directory in ["Pickup", "PickupWidgets", "PickupReport", "Shared", "Config", "Docs"]:
    children = sorted([ref for ref in all_files if objects[ref]["path"].startswith(directory + "/")],
                      key=lambda ref: objects[ref]["path"])
    source_groups.append(obj("group:" + directory, "PBXGroup", children=children, name=directory, sourceTree="<group>"))
main_group = obj("main", "PBXGroup", children=root_documents + source_groups + [product_group], sourceTree="<group>")
project_configs = []
for configuration in ["Debug", "Release"]:
    project_configs.append(obj("project:" + configuration, "XCBuildConfiguration", buildSettings={
        "CLANG_ENABLE_OBJC_ARC": "YES", "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "GCC_WARN_UNUSED_FUNCTION": "YES", "GCC_WARN_UNUSED_VARIABLE": "YES",
        "ENABLE_TESTABILITY": "YES" if configuration == "Debug" else "NO"}, name=configuration))
project_config_list = obj("project-configs", "XCConfigurationList", buildConfigurations=project_configs,
                          defaultConfigurationIsVisible=0, defaultConfigurationName="Release")
obj("project", "PBXProject", attributes={"LastUpgradeCheck": "2600", "BuildIndependentTargetsInParallel": "YES",
    "TargetAttributes": {target_ids[name]: {"CreatedOnToolsVersion": "26.0", "SystemCapabilities": {
        "com.apple.ApplicationGroups.iOS": {"enabled": 1}, **({"com.apple.FamilyControls": {"enabled": 1}} if name != "PickupWidgets" else {})}}
        for name in target_ids}}, buildConfigurationList=project_config_list, compatibilityVersion="Xcode 15.0",
    developmentRegion="en", hasScannedForEncodings=0, knownRegions=["en", "Base"], mainGroup=main_group,
    packageReferences=[package], productRefGroup=product_group, projectDirPath="", projectRoot="", targets=list(target_ids.values()))

def render(value, level=0):
    tab = "\t" * level
    if isinstance(value, dict):
        return "{\n" + "".join(tab + "\t" + json.dumps(k) + " = " + render(v, level + 1) + ";\n" for k, v in value.items()) + tab + "}"
    if isinstance(value, list):
        return "(\n" + "".join(tab + "\t" + render(v, level + 1) + ",\n" for v in value) + tab + ")"
    return str(value) if isinstance(value, int) else json.dumps(value)

project_dir = ROOT / "Pickup.xcodeproj"
project_dir.mkdir(exist_ok=True)
(project_dir / "project.pbxproj").write_text("// !$*UTF8*$!\n" + render({"archiveVersion": 1, "classes": {},
    "objectVersion": 60, "objects": objects, "rootObject": uid("project")}) + "\n")
scheme_dir = project_dir / "xcshareddata/xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_ids["Pickup"]}" BuildableName="Pickup.app" BlueprintName="Pickup" ReferencedContainer="container:Pickup.xcodeproj"/>'
(scheme_dir / "Pickup.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print("Generated Pickup.xcodeproj with Pickup, PickupWidgets, and PickupReport.")
