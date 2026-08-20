import os

println('Removing old artifacts...')
rmdir_all('bin') or {}
println('Done removing "bin" directory.')

println('\nCreating new output directory "bin"...')
mkdir('bin')!
println('Done creating "bin" directory.')

println('\nChecking if everything is formatted correctly...')
execute_or_panic('${quoted_path(@VEXE)} fmt -verify .')
println('Done checking formatting.')

println('\nCompiling and building executable...')

if '-fast' in os.args {
	execute_or_panic('${quoted_path(@VEXE)} . -o bin/klonol')
} else {
	// Let V pick the platform default C compiler, so an externally set CC is
	// honoured. The one exception is Windows, where MSVC is markedly faster
	// than the bundled tcc for -prod builds.
	mut cmd := '${quoted_path(@VEXE)} -prod'
	$if windows {
		cmd += ' -cc msvc'
	}
	execute_or_panic('${cmd} . -o bin/klonol')
}

println('Done compiling and placing executable in "bin".')
