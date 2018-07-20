package hxp.platforms;


import haxe.io.Path;
import haxe.Template;
import hxp.helpers.CPPHelper;
import hxp.helpers.DeploymentHelper;
import hxp.helpers.FileHelper;
import hxp.helpers.IconHelper;
import hxp.helpers.PathHelper;
import hxp.helpers.ProcessHelper;
import hxp.helpers.WebOSHelper;
import hxp.project.AssetType;
import hxp.project.HXProject;
import hxp.project.Icon;
import hxp.project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


class WebOSPlatform extends PlatformTarget {
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map<String, String>) {
		
		super (command, _project, targetFlags);
		
		targetDirectory = project.app.path + "/webos";
		
	}
	
	
	public override function build ():Void {
		
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";
		var destination = targetDirectory + "/bin/";
		
		for (ndll in project.ndlls) {
			
			FileHelper.copyLibrary (project, ndll, "webOS", "", ".so", destination, project.debug);
			
		}
		
		ProcessHelper.runCommand ("", "haxe", [ hxml, "-D", "webos", "-D", "HXCPP_LOAD_DEBUG", "-D", "HXCPP_RTLD_LAZY" ] );
		
		if (noOutput) return;
		
		CPPHelper.compile (project, targetDirectory + "/obj", [ "-Dwebos", "-DHXCPP_LOAD_DEBUG", "-DHXCPP_RTLD_LAZY" ]);
		
		FileHelper.copyIfNewer (targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), targetDirectory + "/bin/" + project.app.file);
		
		WebOSHelper.createPackage (project, targetDirectory + "", "bin");
		
	}
	
	
	public override function clean ():Void {
		
		var targetPath = targetDirectory + "";
		
		if (FileSystem.exists (targetPath)) {
			
			PathHelper.removeDirectory (targetPath);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "webOS");
		
	}
	
	
	public override function display ():Void {
		
		var hxml = PathHelper.findTemplate (project.templatePaths, "webos/hxml/" + buildType + ".hxml");
		
		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		context.OUTPUT_DIR = targetDirectory;
		
		var template = new Template (File.getContent (hxml));
		
		Sys.println (template.execute (context));
		Sys.println ("-D display");
		
	}
	
	
	public override function install ():Void {
		
		WebOSHelper.install (project, targetDirectory + "");
		
	}
	
	
	public override function rebuild ():Void {
		
		CPPHelper.rebuild (project, [[ "-Dwebos" ]]);
		
	}
	
	
	public override function run ():Void {
		
		WebOSHelper.launch (project);
		
	}
	
	
	public override function trace ():Void {
		
		WebOSHelper.trace (project);
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		
		for (asset in project.assets) {
			
			if (asset.embed && asset.sourcePath == "") {
				
				var path = PathHelper.combine (targetDirectory + "/obj/tmp", asset.targetPath);
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path);
				asset.sourcePath = path;
				
			}
			
		}
		
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = project.templateContext;
		context.CPP_DIR = targetDirectory + "/obj";
		context.OUTPUT_DIR = targetDirectory;
		
		var icons = project.icons;
		
		if (icons.length == 0) {
			
			icons = [ new Icon (PathHelper.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
		if (IconHelper.createIcon (icons, 64, 64, PathHelper.combine (destination, "icon.png"))) {
			
			context.APP_ICON = "icon.png";
			
		}
		
		FileHelper.recursiveSmartCopyTemplate (project, "webos/template", destination, context);
		FileHelper.recursiveSmartCopyTemplate (project, "haxe", targetDirectory + "/haxe", context);
		FileHelper.recursiveSmartCopyTemplate (project, "webos/hxml", targetDirectory + "/haxe", context);
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			PathHelper.mkdir (Path.directory (path));
			
			if (asset.type != AssetType.TEMPLATE) {
				
				if (asset.targetPath == "/appinfo.json") {
					
					FileHelper.copyAsset (asset, path, context);
					
				} else {
					
					// going to root directory now, but should it be a forced "assets" folder later?
					
					FileHelper.copyAssetIfNewer (asset, path);
					
				}
				
			} else {
				
				FileHelper.copyAsset (asset, path, context);
				
			}
			
		}
		
	}
	
	
	@ignore public override function uninstall ():Void {}
	
	
}