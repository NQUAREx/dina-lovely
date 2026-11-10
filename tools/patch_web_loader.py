"""Keep Godot's Web loader promises rejectable when a network/initialization stream fails."""
from pathlib import Path

def patch_loader(path: Path):
 s=path.read_text()
 if 'gardenFetchAsset' in s:return
 old='return fetch(file).then(function (response) {'
 assert old in s
 s=s.replace(old,'return (window.gardenFetchAsset ? window.gardenFetchAsset(file) : fetch(file)).then(function (response) {',1)
 old='''onloadprogress(reader, controller).then(function () {
					controller.close();
				});'''
 assert old in s
 s=s.replace(old,'''onloadprogress(reader, controller).then(function () {
					controller.close();
				}).catch(function (error) { controller.error(error); });''',1)
 start=s.index('\t\t\t\tfunction doInit(promise) {');end=s.index('\n\t\t\t\tpreloader.setProgressFunc',start)
 s=s[:start]+'''				function doInit(promise) {
					return promise.then(function (response) {
						const cloned = new Response(response.body, { headers: [['content-type', 'application/wasm']] });
						return Godot(me.config.getModuleConfig(loadPath, cloned));
					}).then(function (module) {
						return module['initFS'](me.config.persistentPaths).then(function (err) {
							if (err) { throw err; }
							me.rtenv = module;
							if (me.config.unloadAfterInit) { Engine.unload(); }
						});
					});
				}
''' +s[end:]
 # Emscripten's callback-based instantiate path otherwise leaves its module pending.
 failure="function (error) { window.dispatchEvent(new CustomEvent('garden-asset-error', { detail: String(error) })); }"
 s=s.replace('WebAssembly.instantiateStreaming(Promise.resolve(r), imports).then(done);','WebAssembly.instantiateStreaming(Promise.resolve(r), imports).then(done).catch('+failure+');')
 s=s.replace('WebAssembly.instantiate(buffer, imports).then(done);','return WebAssembly.instantiate(buffer, imports).then(done);')
 s=s.replace('\t\t\t\t\t});\n\t\t\t\t}\n\t\t\t\tr = null;','\t\t\t\t\t}).catch('+failure+');\n\t\t\t\t}\n\t\t\t\tr = null;')
 path.write_text(s)
