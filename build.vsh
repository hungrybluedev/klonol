println('Removing old artifacts...')
rmdir_all('bin') or {}
println('Done removing "bin" directory.')

println('\nCreating new output directory "bin"...')
mkdir('bin')!
println('Done creating "bin" directory.')

println('\nChecking if everything is formatted correctly...')
execute_or_panic('${@VEXE} fmt -verify .')
println('Done checking formatting.')

println('\nCompiling and building executable...')
execute_or_panic('${@VEXE} -prod . -o bin/klonol')
println('Done compiling and placing executable in "bin".')
