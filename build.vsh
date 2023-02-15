// Make compilation on windows faster
compiler := $if windows {
	'msvc'
} $else {
	'cc'
}

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
execute_or_panic('${quoted_path(@VEXE)} -cc "${compiler}" -prod . -o bin/klonol')
println('Done compiling and placing executable in "bin".')
