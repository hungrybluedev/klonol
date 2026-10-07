import os

println('Removing old artifacts...')
rmdir_all('bin') or {}
println('Done removing "bin" directory.')

println('\nCreating new output directory "bin"...')
mkdir('bin')!
println('Done creating "bin" directory.')

println('\nChecking if everything is formatted correctly...')
exec_or_panic([@VEXE, 'fmt', '-verify', '.'])
println('Done checking formatting.')

println('\nCompiling and building executable...')

if '-fast' in os.args {
	exec_or_panic([@VEXE, '.', '-o', 'bin/klonol'])
} else {
	// Let V pick the default C compiler, so an external CC is honoured.
	// Windows is the exception: MSVC beats the bundled tcc for -prod.
	mut cmd := [@VEXE, '-prod']
	$if windows {
		cmd << ['-cc', 'msvc']
	}
	cmd << ['.', '-o', 'bin/klonol']
	exec_or_panic(cmd)
}

println('Done compiling and placing executable in "bin".')
